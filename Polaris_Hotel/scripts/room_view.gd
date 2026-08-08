class_name RoomView
extends Control
# Builds one room: background, per-room sconce lights, anomaly overlays,
# event overlays, passive hotspots, and the traveler. Rebuilt on every
# room change. Movement/animation state is pushed in from game_world.

const TEX_SIDE_IDLE := "res://assets/sprites/characters/traveler_cam/traveler_cam_idle.png"
const TEX_SIDE_WALK := "res://assets/sprites/characters/traveler_cam/traveler_cam_walk.png"
const TEX_FRONT_IDLE := "res://assets/sprites/characters/traveler_front/traveler_front_idle.png"
const TEX_FRONT_WALK := "res://assets/sprites/characters/traveler_front/traveler_front_walk.png"
const TEX_BACK_IDLE := "res://assets/sprites/characters/traveler_back/traveler_back_idle.png"
const TEX_BACK_WALK := "res://assets/sprites/characters/traveler_back/traveler_back_walk.png"
const TEX_HULDRA := "res://assets/sprites/characters/huldra_idle.png"
const TEX_SHADOW := "res://assets/sprites/characters/shadow_figure_idle.png"
const TEX_DOOR := "res://assets/sprites/items/hotel_door.png"
const TEX_RADIAL := "res://assets/textures/fx/light_radial.png"
const TEX_SNOW := "res://assets/textures/fx/snow_dot.png"

const PLAYER_H := 300.0            # display height of a 256px-tall sprite
const PX := PLAYER_H / 256.0       # sprite pixel -> screen pixel
const DEPTH_MIN := 0.88            # scale at the far edge of the walk band
const STEP_RATE := 2.2             # full step cycles per second while walking

var room_id: String = ""
var player: TextureRect = null
var player_light: PointLight2D = null

var _overlays: Control = null
var _hotspot_layer: Control = null
var _pulsers: Array = []
var _sconce_lights: Array = []     # [{node, warm}]
var _anomaly_nodes: Dictionary = {}   # uid -> [nodes...]
var _time: float = 0.0

var _tex: Dictionary = {}          # state name -> Texture2D
var _anim_state: String = ""       # "side_idle" | "side_walk" | "front_idle" | ...
var _facing_left: bool = false
var _moving: bool = false
var _feet: Vector2 = Vector2.ZERO
var _step_phase: float = 0.0       # advances while walking; 1.0 = full L+R cycle
var _step_stride: bool = true      # which frame of the step cycle is showing

func build(p_room_id: String, view_state: Dictionary) -> void:
	room_id = p_room_id
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	var bg := TextureRect.new()
	bg.texture = load(RoomData.bg_for(room_id))
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	_overlays = Control.new()
	_overlays.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_overlays)
	_overlays.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	_hotspot_layer = Control.new()
	_hotspot_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_hotspot_layer)
	_hotspot_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# warm sconce lights before the player so the player sits in the light
	_add_room_lights(view_state)
	_add_anomalies()
	_add_messy_overlay()
	if bool(view_state.get("seventh_door", false)):
		_spawn_seventh_door()
	if room_id == "corridor":
		_add_snow()
	_add_static_hotspots()
	_add_player()

# --- lights -------------------------------------------------------------------
func _make_light(pos: Vector2, energy: float, scale_: float, color: Color) -> PointLight2D:
	var l := PointLight2D.new()
	l.texture = load(TEX_RADIAL)
	l.position = pos
	l.energy = energy
	l.texture_scale = scale_
	l.color = color
	l.shadow_enabled = false
	add_child(l)
	return l

func _add_room_lights(view_state: Dictionary) -> void:
	var blue: bool = bool(view_state.get("blue", false))
	for spec in RoomData.lights_for(room_id):
		var warm := Color(1.0, 0.78, 0.45)
		var l := _make_light(Vector2(spec[0], spec[1]), float(spec[2]), float(spec[3]), warm)
		_sconce_lights.append({"node": l, "warm": warm})
	if blue:
		set_blue_sconces(true)

func set_blue_sconces(on: bool) -> void:
	for e in _sconce_lights:
		var l: PointLight2D = e["node"]
		if is_instance_valid(l):
			l.color = Color(0.35, 0.5, 1.0) if on else e["warm"]

# --- player -------------------------------------------------------------------
func _add_player() -> void:
	for key in ["side_idle", "side_walk", "front_idle", "front_walk", "back_idle", "back_walk"]:
		_tex[key] = load(_tex_path(key))
	player = TextureRect.new()
	player.texture = _tex["front_idle"]
	player.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	player.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	player.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(player)
	player_light = _make_light(Vector2.ZERO, 0.65, 2.0, Color(1.0, 0.82, 0.50))
	player.modulate = Color(0.92, 0.84, 0.70, 1.0)  # warm amber to match sconce lighting
	_anim_state = "front_idle"
	place_player(RoomData.entry_for(room_id))

func _tex_path(state: String) -> String:
	match state:
		"side_idle": return TEX_SIDE_IDLE
		"side_walk": return TEX_SIDE_WALK
		"front_idle": return TEX_FRONT_IDLE
		"front_walk": return TEX_FRONT_WALK
		"back_idle": return TEX_BACK_IDLE
		"back_walk": return TEX_BACK_WALK
	return TEX_FRONT_IDLE

func depth_scale_at(feet_y: float) -> float:
	var band: Rect2 = RoomData.walk_band(room_id)
	if band.size.y <= 1.0:
		return 1.0
	var t: float = clampf((feet_y - band.position.y) / band.size.y, 0.0, 1.0)
	return lerpf(DEPTH_MIN, 1.0, t)

func place_player(feet: Vector2) -> void:
	if player == null:
		return
	_feet = feet
	var s: float = depth_scale_at(feet.y)
	var tex: Texture2D = player.texture
	var disp: Vector2 = Vector2(tex.get_width(), tex.get_height()) * PX * s
	player.size = disp
	player.position = Vector2(feet.x - disp.x * 0.5, feet.y - disp.y)
	player.pivot_offset = Vector2(disp.x * 0.5, disp.y)  # rock around the feet
	player_light.position = Vector2(feet.x, feet.y - disp.y * 0.5)

func player_feet() -> Vector2:
	return _feet

# dir: current input direction (normalized-ish, zero when idle)
func set_player_anim(dir: Vector2, moving: bool) -> void:
	if player == null:
		return
	_moving = moving
	var want: String = _anim_state
	if moving:
		if absf(dir.x) >= absf(dir.y) * 1.2:
			want = "side_walk"
			_facing_left = dir.x < 0.0
		elif dir.y < 0.0:
			want = "back_walk"
		else:
			want = "front_walk"
	else:
		if _anim_state.begins_with("side"):
			want = "side_idle"
		elif _anim_state.begins_with("back"):
			want = "back_idle"
		else:
			want = "front_idle"
	if want != _anim_state:
		_anim_state = want
		player.texture = _tex[want]
		player.flip_h = _facing_left and _anim_state.begins_with("side")
		place_player(_feet)  # re-anchor feet for the new texture's size
	elif player.flip_h != (_facing_left and _anim_state.begins_with("side")):
		player.flip_h = _facing_left and _anim_state.begins_with("side")

# --- hotspots -------------------------------------------------------------------
func hotspots() -> Array:
	return _hotspot_layer.get_children()

func _add_static_hotspots() -> void:
	for spec in RoomData.hotspots_for(room_id):
		var hs := Hotspot.new()
		hs.hs_id = String(spec.get("id", ""))
		hs.kind = String(spec.get("kind", "flavor"))
		hs.data = spec
		hs.position = RoomData.rect(spec["rect"]).position
		hs.size = RoomData.rect(spec["rect"]).size
		_hotspot_layer.add_child(hs)

# --- anomalies ------------------------------------------------------------------
func _add_anomalies() -> void:
	for a in GameState.anomalies():
		if bool(a.get("fixed", false)):
			continue
		if String(a.get("room", "")) != room_id:
			continue
		_spawn_anomaly(a)

func _spawn_anomaly(a: Dictionary) -> void:
	var anchor_key: String = String(a.get("anchor", ""))
	var anchors: Dictionary = RoomData.anchors_for(room_id)
	if not anchors.has(anchor_key):
		return
	var r: Rect2 = RoomData.rect(anchors[anchor_key])
	var uid: String = String(a.get("uid", ""))
	var type: String = String(a.get("type", ""))
	var overlay: CanvasItem = null
	var extra_nodes: Array = []

	match type:
		"door_number":
			var lab := Label.new()
			lab.text = "307" if anchor_key == "door_301" else "301"
			lab.add_theme_font_size_override("font_size", 44)
			lab.add_theme_color_override("font_color", Color(0.88, 0.82, 0.66))
			lab.position = r.position + Vector2(r.size.x * 0.5 - 26, 26)
			lab.mouse_filter = Control.MOUSE_FILTER_IGNORE
			overlay = lab
		"ajar":
			var gap := ColorRect.new()
			gap.color = Color(0.0, 0.0, 0.02, 0.96)
			gap.position = r.position + Vector2(6, 10)
			gap.size = Vector2(r.size.x * 0.45, r.size.y - 20)
			gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
			_overlays.add_child(gap)
			extra_nodes.append(gap)
			var door := TextureRect.new()
			door.texture = load(TEX_DOOR)
			door.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			door.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
			door.position = r.position + Vector2(r.size.x * 0.4, 0)
			door.size = Vector2(r.size.x * 0.75, r.size.y)
			door.modulate = Color(0.45, 0.42, 0.5)
			door.mouse_filter = Control.MOUSE_FILTER_IGNORE
			overlay = door
		"elevator":
			var dark := ColorRect.new()
			dark.color = Color(0.0, 0.0, 0.03, 0.97)
			dark.position = r.position + Vector2(60, 20)
			dark.size = Vector2(r.size.x - 120, r.size.y - 20)
			dark.mouse_filter = Control.MOUSE_FILTER_IGNORE
			_overlays.add_child(dark)
			extra_nodes.append(dark)
			var eyes := TextureRect.new()
			eyes.texture = load(AnomalyData.sprite_for("eyes"))
			eyes.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			eyes.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			eyes.position = r.position + Vector2(r.size.x * 0.5 - 70, r.size.y * 0.35)
			eyes.size = Vector2(140, 100)
			eyes.mouse_filter = Control.MOUSE_FILTER_IGNORE
			overlay = eyes
			_pulsers.append({"node": eyes, "base": 0.55, "amp": 0.3, "speed": 1.4})
		_:
			var sprite_path: String = AnomalyData.sprite_for(type)
			if sprite_path == "":
				return
			var tr := TextureRect.new()
			tr.texture = load(sprite_path)
			tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			if type == "paint_eyes":
				tr.position = r.get_center() - Vector2(45, 30)
				tr.size = Vector2(90, 60)
				_pulsers.append({"node": tr, "base": 0.7, "amp": 0.25, "speed": 1.1})
			elif type == "figure_window":
				tr.position = r.position + Vector2(r.size.x * 0.5 - 70, r.size.y * 0.25)
				tr.size = Vector2(140, 210)
				tr.modulate = Color(1, 1, 1, 0.55)
				_pulsers.append({"node": tr, "base": 0.7, "amp": 0.25, "speed": 1.1})
			elif type == "eyes":
				tr.position = r.position + r.size * 0.12
				tr.size = r.size * 0.76
				# red glow halo behind the eyes for atmosphere
				var glow := TextureRect.new()
				glow.texture = load(TEX_RADIAL)
				glow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				glow.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				glow.size = tr.size * 1.7
				glow.position = tr.position + tr.size * 0.5 - glow.size * 0.5
				glow.modulate = Color(0.85, 0.1, 0.05, 0.0)
				glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
				_overlays.add_child(glow)
				extra_nodes.append(glow)
				_pulsers.append({"node": glow, "base": 0.3, "amp": 0.35, "speed": 0.75})
				_pulsers.append({"node": tr, "base": 0.5, "amp": 0.45, "speed": 0.85})
			else:
				tr.position = r.position + r.size * 0.1
				tr.size = r.size * 0.8
				_pulsers.append({"node": tr, "base": 0.7, "amp": 0.25, "speed": 1.1})
			tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
			overlay = tr

	if overlay != null:
		_overlays.add_child(overlay)
		var hs := Hotspot.new()
		hs.hs_id = uid
		hs.kind = "anomaly"
		hs.data = a
		hs.position = r.position
		hs.size = r.size
		_hotspot_layer.add_child(hs)
		_anomaly_nodes[uid] = extra_nodes + [overlay, hs]

func remove_anomaly(uid: String) -> void:
	if not _anomaly_nodes.has(uid):
		return
	var pair: Array = _anomaly_nodes[uid]
	for n in pair:
		if is_instance_valid(n):
			n.queue_free()
	_anomaly_nodes.erase(uid)
	for i in range(_pulsers.size() - 1, -1, -1):
		if not is_instance_valid(_pulsers[i]["node"]):
			_pulsers.remove_at(i)

# --- messy bed (rule r7 day) ---------------------------------------------------
func _add_messy_overlay() -> void:
	if room_id != "room_301" or not GameState.messy_day():
		return
	var stain := TextureRect.new()
	stain.texture = load(AnomalyData.sprite_for("stain"))
	stain.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stain.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	stain.position = Vector2(560, 560)
	stain.size = Vector2(460, 260)
	stain.modulate = Color(0.9, 0.85, 0.8)
	stain.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stain.name = "MessyBed"
	_overlays.add_child(stain)
	_pulsers.append({"node": stain, "base": 0.85, "amp": 0.15, "speed": 0.7})

func clear_messy() -> void:
	var n: Node = _overlays.find_child("MessyBed", false, false)
	if n != null:
		n.queue_free()

# --- event overlays ---------------------------------------------------------------
func show_shadow_figure(duration: float) -> void:
	if player == null:
		return
	var fig := TextureRect.new()
	fig.texture = load(TEX_SHADOW)
	fig.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	fig.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var behind: float = -230.0 if _facing_left else 230.0
	fig.size = Vector2(280, 340)
	fig.position = Vector2(player.position.x + behind, player.position.y - 40)
	fig.modulate = Color(1, 1, 1, 0.0)
	fig.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlays.add_child(fig)
	var tw := fig.create_tween()
	tw.tween_property(fig, "modulate:a", 0.85, 0.8)
	tw.tween_interval(maxf(0.1, duration - 1.8))
	tw.tween_property(fig, "modulate:a", 0.0, 1.0)
	tw.tween_callback(fig.queue_free)

func show_huldra(pos: Vector2, duration: float, far: bool) -> void:
	var fig := TextureRect.new()
	fig.texture = load(TEX_HULDRA)
	fig.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	fig.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var h: float = 260.0 if far else 340.0
	fig.size = Vector2(h, h)
	fig.position = pos - Vector2(h * 0.5, h)
	fig.modulate = Color(1, 1, 1, 0.0)
	fig.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlays.add_child(fig)
	var tw := fig.create_tween()
	tw.tween_property(fig, "modulate:a", 0.55, 1.2)
	tw.tween_interval(maxf(0.2, duration - 2.6))
	tw.tween_property(fig, "modulate:a", 0.0, 1.4)
	tw.tween_callback(fig.queue_free)

func show_window_movement() -> void:
	var anchors: Dictionary = RoomData.anchors_for(room_id)
	if not anchors.has("window"):
		return
	var r: Rect2 = RoomData.rect(anchors["window"])
	var fig := TextureRect.new()
	fig.texture = load(TEX_SHADOW)
	fig.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	fig.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	fig.size = Vector2(120, 200)
	fig.position = r.position + Vector2(-60, r.size.y - 200)
	fig.modulate = Color(1, 1, 1, 0.7)
	fig.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlays.add_child(fig)
	var tw := fig.create_tween()
	tw.tween_property(fig, "position:x", r.position.x + r.size.x + 40.0, 0.9)
	tw.tween_callback(fig.queue_free)

func show_seventh_door() -> void:
	if room_id != "corridor":
		return
	_spawn_seventh_door()

func _spawn_seventh_door() -> void:
	if _overlays.find_child("SeventhDoor", false, false) != null:
		return
	var r: Rect2 = RoomData.rect(RoomData.anchors_for("corridor")["seventh_door"])
	var door := TextureRect.new()
	door.name = "SeventhDoor"
	door.texture = load(TEX_DOOR)
	door.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	door.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
	door.position = r.position
	door.size = r.size
	door.modulate = Color(0.55, 0.6, 0.75)
	door.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlays.add_child(door)
	var hs := Hotspot.new()
	hs.hs_id = "seventh_door"
	hs.kind = "seventh_door"
	hs.position = r.position
	hs.size = r.size
	_hotspot_layer.add_child(hs)

# --- snow ----------------------------------------------------------------------
func _add_snow() -> void:
	var p := CPUParticles2D.new()
	p.amount = 70
	p.lifetime = 4.0
	p.preprocess = 4.0
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(120, 260)
	p.position = Vector2(150, 400)
	p.direction = Vector2(0.35, 1.0)
	p.spread = 12.0
	p.gravity = Vector2(0, 18)
	p.initial_velocity_min = 25.0
	p.initial_velocity_max = 60.0
	p.scale_amount_min = 1.5
	p.scale_amount_max = 3.5
	p.color = Color(0.9, 0.93, 1.0, 0.75)
	p.texture = load(TEX_SNOW)
	add_child(p)

# --- ambient motion ---------------------------------------------------------------
func _process(delta: float) -> void:
	_time += delta
	for p in _pulsers:
		var n: CanvasItem = p["node"]
		if is_instance_valid(n):
			var c: Color = n.modulate
			c.a = float(p["base"]) + float(p["amp"]) * sin(_time * float(p["speed"]))
			n.modulate = c
	# walk cycle — smooth bob/sway, no texture swap (prevents clothing silhouette jump)
	if player != null:
		if _moving and _anim_state.ends_with("_walk"):
			_step_phase += delta * STEP_RATE
			var bob: float = -1.6 * sin(_step_phase * TAU)
			player.position.y = _feet.y - player.size.y + bob
			if _anim_state.begins_with("side"):
				player.rotation = deg_to_rad(0.5) * sin(_step_phase * TAU)
			else:
				player.rotation = 0.0
				player.position.x = _feet.x - player.size.x * 0.5 + 1.0 * sin(_step_phase * TAU)
		elif player.rotation != 0.0 or _step_phase != 0.0:
			_step_phase = 0.0
			_step_stride = true
			player.rotation = 0.0
			place_player(_feet)
