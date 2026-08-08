class_name TextDB
extends RefCounted
# Every Korean string in the game, in one place.
# tools/make_kr_font.py scans this file to build the font subset.

const RULES := {
	"r1": "기상 후 등불이 세 개 모두 켜져 있다면, 당신은 아직 오늘에 있습니다. 두 개라면 한 번 실패한 것이고, 하나라면 호텔도 당신을 기억하기 시작합니다.",
	"r2": "창밖을 오래 바라보지 마십시오. 극야에는 아무것도 움직이지 않습니다. 움직이는 것이 보인다면, 그것은 밖에 있는 것이 아닙니다.",
	"r3": "복도의 객실문은 항상 여섯 개입니다. 일곱 번째 문이 보인다면, 절대 열지 마십시오.",
	"r4": "객실 번호는 301호부터 306호까지입니다. 307호는 존재하지 않습니다. 누군가 307호를 찾아도 대답하지 마십시오.",
	"r5": "복도의 벽등은 항상 따뜻한 노란빛입니다. 푸른빛으로 바뀌어 있다면, 즉시 301호로 돌아오십시오.",
	"r6": "복도 끝에서 누군가 당신의 이름을 부른다면, 절대 뒤돌아보지 마십시오. 호텔은 당신의 이름을 모릅니다.",
	"r7": "아침의 침대 이불이 정리되어 있다면 안전합니다. 누군가 누웠던 흔적이 있다면, 정리하기 전까지 방 밖으로 나가지 마십시오.",
	"r8": "문을 닫았는데도 복도의 소리가 들린다면, 귀를 막지 마십시오. 막는 순간, 소리는 방 안에서 들리기 시작합니다.",
	"r9": "규칙문이 젖어 있다면 읽지 마십시오. 오늘의 규칙은 당신을 위한 것이 아닙니다.",
	"r10": "등불이 하나뿐이라면, 침대 밑을 확인하지 마십시오. 이미 늦었습니다.",
}

const RULE_HEADER := "301호 투숙객께.\n당신은 아직 살아 있습니다.\n아래의 규칙을 지키십시오."
const RULE_WET := "…종이가 흠뻑 젖어 있다.\n잉크가 번져 읽을 수 없다.\n\n…읽으려고, 하면 안 된다."
const RULE_WET_READ_CHOICE := "그래도 읽는다"
const RULE_WET_PUT_DOWN := "종이를 뒤집어 낸다"

const INTRO_LINES := [
	"폭풍우 속에서 길을 잃었다.",
	"눈 덮인 산등성이 아래, 불 켜진 호텔이 하나 서 있었다.",
	"『폴라리스 호텔』은 30년 전 눈사태로 폐쇄된 호텔.",
	"문은 잠겨 있지 않았다. 프런트에는 사람이 없었다.",
	"열쇠 걸이에는 301호의 열쇠만이 놓여 있었다.",
	"그리고 침대 옆에는, 누군가 남긴 쪽지가 있었다.",
]

const DAY_NAMES := {
	1: "첫째 날", 2: "둘째 날", 3: "셋째 날", 4: "넷째 날",
	5: "다섯째 날", 6: "여섯째 날", 7: "일곱째 날",
}

const MORNING_LINE := "아침이다. — 시계는 여전히 새벽 3시를 가리키고 있다."
const MORNING_NOTE := "침대 옆에 오늘의 규칙이 놓여 있다."
const MORNING_NOTE_WET := "침대 옆의 쪽지가… 젖어 있다."

const LOCATION_NAMES := {
	"room_301": "301호",
	"room_302": "302호",
	"room_303": "303호",
	"room_304": "304호",
	"room_305": "305호",
	"room_306": "306호",
	"corridor": "3층 복도",
	"elevator_hall": "엘리베이터 홀",
	"lobby": "로비",
}

const HINT_KEYS := "[F] 상호작용   [E] 규칙   [T] 카메라   [TAB] 지도   [J] 기록부"
const CAMERA_HINT := "[클릭/F] 촬영 — 거리 상관없이 조준만 하면 된다     [T] 카메라 내리기"
const CAMERA_NOTHING := "—찰칵. …사진에는 아무것도 찍히지 않았다."

# 근접 시 떠오르는 행동 안내 (핫스폿 종류별)
const PROMPT := {
	"flavor": "[F] 살펴본다",
	"sconce": "[F] 살펴본다",
	"bed": "[F] 침대로 간다",
	"note": "[F] 규칙을 읽는다",
	"window": "[F] 창밖을 본다",
	"under_bed": "[F] 침대 밑을 들여다본다",
	"door": "[F] 들어간다",
	"exit": "[F] 나간다",
	"exit_east": "[F] 복도 끝으로 간다",
	"elevator": "[F] 로비로 내려간다",
	"stairs": "[F] 3층으로 올라간다",
	"anomaly": "[F] 촬영한다",
	"seventh_door": "[F] 문을 연다",
}

const FLAVOR := {
	"paint_301": "낡은 초상화. 눈동자가 유난히 젖어 보인다.",
	"paint_guest": "풍경화. 설산인데… 눈이 녹아 있다.",
	"paint_hall": "초상화의 시선이 복도 쪽을 향해 있다.",
	"mirror": "거울 속의 방이, 어째서인지 이쪽보다 어둡다.",
	"bed_guest": "차갑게 식은 침대. 오래전에 아무도 묵지 않은 침대.",
	"dresser": "서랍 안은 비어 있다. 먼지만 쌓였다.",
	"window_guest": "커튼 틈으로 눈발만 보인다. 움직이는 것은 없다.",
	"sconce": "벽등이 희미하게 흔들린다. 바람은 없는데.",
	"flowers": "꽃병의 꽃이 시들지 않았다. 30년 동안.",
	"desk": "방명록이 펼쳐져 있다. 마지막 이름은… 당신의 이름이다. 필적은 당신의 것이 아니다.",
	"call_button": "호출 버튼이 살짝 눌려 있다. 누가 눌렀을까.",
	"window_301": "극야. 눈발만이 창을 두드린다. 움직이는 것은… 없어야 한다.",
	"window_lobby": "로비의 큰 창. 밖은 완전한 밤이다.",
	"chair": "방석에 누군가 앉았던 자국이 남아 있다.",
	"door_locked": "잠겨 있다. 안에서는 아무 소리도 들리지 않는다.",
	"tv": "텔레비전이 꺼져 있다. 화면에 희미하게 먼지 자국.",
	"lantern_stand": "등불 받침. 따뜻한 빛이 당신의 것이다.",
	"wardrobe_302": "옷장 안에는 겨울 외투가 그대로 걸려 있다. 주인은 나가지 못했다.",
	"radiator_302": "라디에이터는 얼어붙어 있다. 손을 대면 손이 더 따뜻하다.",
	"paint_302": "산맥의 유화. …산의 모양이 조금씩 달라지고 있다.",
	"table_302": "찻잔이 두 개다. 하나는 아직 김이 나는 것처럼 보인다.",
	"vanity_303": "화장대의 거울이 흐릿하다. …방금, 반사가 한 박자 늦었다.",
	"stool_303": "둥근 방석에 앉았던 자국. 아직 눌려 있다.",
	"paint_303": "풍경화 속의 집. 창문에 불이 켜져 있다. 이 호텔이다.",
	"bed_303": "베개에 머리 모양의 움푹한 자국. 만지면 차갑다.",
	"desk_304": "편지가 쓰다 만 채다. 『자꾸만 복도에서…』 — 다음은 없다.",
	"shelf_304": "책장의 책이 전부 같은 책이다. 제목은 읽히지 않는다.",
	"coat_304": "코트걸이의 외투. 주머니에서 손톱 자국이… 아니다, 먼지다.",
	"trunk_304": "여행 가방. 자물쇠가 안쪽에서 걸려 있다.",
	"bed_305": "낡은 침대가 가운데부터 꺼져 있다. 위에서 뛴 것처럼.",
	"paint_305": "액자가 전부 기울어 있다. 바로잡아도 다음 날이면 다시 기울어 있다.",
	"dresser_305": "화장대의 먼지 위로 손가락 자국. 세 개.",
	"debris_305": "천장에서 떨어진 잔해. 위를 올려다보지 않는 것이 낫다.",
	"fireplace_306": "재가 아직 미지근하다. 30년 전의 불인데.",
	"armchair_306": "가죽 의자. 누군가 아주 오래 앉아 있던 형태가 남아 있다.",
	"cameo_306": "타원형 초상. 눈동자만 선명하다.",
	"mirror_306": "높은 거울. 비치는 것이 하나 적다. …당신이다."
}

const ANOMALY_FIX_LINES := {
	"eyes": "찰칵. —플래시가 꺼진 자리에서, 눈들이 천천히 감겼다.",
	"writing": "찰칵. —벽지의 글자가 사진 속으로 빨려 들어갔다.",
	"stain": "찰칵. —얼룩이 마르며 사라졌다.",
	"door_number": "찰칵. —호실 표지가 제 번호를 되찾았다.",
	"ajar": "찰칵. —문이 조용히 닫혔다.",
	"elevator": "찰칵. —엘리베이터 문이 다물렸다. 안은 텅 비어 있었다.",
	"paint_eyes": "찰칵. —그림이 다시 이쪽을 보지 않는다.",
	"figure_window": "찰칵. —창밖의 형체가 눈발 속으로 흩어졌다.",
}

# 기록부(도감)에 적히는 이상현상의 이름
const ANOMALY_NAMES := {
	"eyes": "벽의 눈",
	"writing": "배어 나오는 손글씨",
	"stain": "검은 얼룩",
	"paint_eyes": "그림의 시선",
	"figure_window": "창밖의 형체",
	"door_number": "뒤바뀐 호실 표지",
	"ajar": "열린 문",
	"elevator": "엘리베이터의 어둠",
}

const JOURNAL_TITLE := "기록부 — 촬영한 이상"
const JOURNAL_EMPTY := "아직 기록이 없다.\n이상한 곳을 카메라에 담아 보자."
const JOURNAL_COUNT := "기록된 이상: %d종 / 8종"
const JOURNAL_ENTRY := "%s — %s (%s)"
const MAP_TITLE := "호텔 지도"

const ANOMALY_HINT_LINES := {
	"eyes": "벽지 사이로 눈이 훔쳐보고 있다.",
	"writing": "벽지 밑으로 손글씨가 배어 나온다.",
	"stain": "검은 얼룩이 번져 있다. 젖어 있다.",
	"door_number": "문의 번호가 틀어져 있다.",
	"ajar": "문이 살짝 열려 있다. 들여다보지 않는 것이 좋다.",
	"elevator": "엘리베이터 문이 벌어져 있다. 어둠만 보인다.",
	"paint_eyes": "그림 속 인물이, 이쪽을 보고 있다.",
	"figure_window": "창 밖에, 서 있는 형체가 있다.",
}

const SUBS := {
	"enter_corridor": "복도. 여섯 개의 문. 불빛은 따뜻하다.",
	"enter_301": "내 방. 유일하게 숨이 쉬어지는 곳.",
	"enter_lobby": "로비. 사람의 흔적만 남은 넓은 어둠.",
	"enter_elevator": "엘리베이터. 오래전에 멈춘 기계.",
	"bed_sleep_ok": "오늘의 이상은 모두 바로잡았다. …잘 수 있다.",
	"bed_sleep_left": "아직 이상한 곳이 남아 있다. 그래도 잠든다면—",
	"bed_messy_block": "이불을 정리하기 전까지는 방을 떠날 수 없다.",
	"slept_clean": "깊이 잠들었다. 밤은 당신을 지나쳐 갔다.",
	"slept_dirty": "잠든 사이, 등불 하나가 꺼졌다.",
	"lantern_lost": "등불이 하나 꺼졌다. 당신의 일부가 함께 흐려졌다.",
	"note_read": "오늘의 규칙을 확인했다.",
	"fix_hint_first": "뭔가 잘못되어 있다. [F]를 눌러 바로잡는다.",
	"under_bed_safe": "침대 밑. 어둠과 먼지뿐이다. …지금은.",
	"seventh_door": "일곱 번째 문. 열지 않는다. 보지 않는다. 지나간다.",
	"loop_corridor": "…복도가, 조금 전과 같다. 같은 문. 같은 벽등.",
	"huldra_far": "복도 저 끝에, 누군가 서 있었던 것 같다.",
	"door_gone": "문이 하나… 없다. 원래 없었던 것처럼.",
	"snow_inside": "복도에 눈이 쌓여 있다. 창은 닫혀 있는데.",
	"elevator_ding_far": "멀리서 엘리베이터 종소리. 이 호텔은 멈춰 있을 텐데.",
	"child_laugh_far": "아이의 웃음소리. 이 호텔에 아이는 없다.",
	"footsteps_far": "복도 너머로 발소리. 당신 말고는, 아무도 없을 텐데.",
	"tv_static": "스피커에서 잡음이 새어 나온다. 전원은 꺼져 있다.",
	"pause_title": "잠시 멈춤",
	"enter_302": "302호. 녹색 벽지. 침대가 너무 정갈하다.",
	"enter_303": "303호. 붉은 벽지. 거울이 마주 보고 있다.",
	"enter_304": "304호. 책 냄새. …아니다, 책은 냄새가 없다.",
	"enter_305": "305호. 벽지가 벗겨져 있다. 이 방만, 유독.",
	"enter_306": "306호. 벽난로의 재. …따뜻하다."
}

const TRAP := {
	"whistle_warn": "—휘파람 소리가 들린다. 바로 뒤에서. 움직이지 마라—",
	"whistle_pass": "휘파람이 멀어졌다. …지나갔다.",
	"window_stare_warn": "밖에서 뭔가 움직였다. …눈을 떼라.",
	"window_safe": "창밖. 아무것도 움직이지 않는다. 그래야 한다.",
	"blue_sconce_start": "벽등이 푸르다. —301호로 돌아가야 한다—",
	"blue_sconce_clear": "벽등이 노란빛으로 돌아왔다.",
	"name_call_offer": "복도 저편에서, 누군가 당신을 부른다. 당신의 이름으로.",
	"name_call_pass": "뒤돌아보지 않았다. 목소리는 이내 멎었다.",
	"knock_307": "문을 두드리는 소리. —307호는 어디 있지? 나는 307호에 묵어야 하는데—",
	"knock_pass": "발소리가 멀어졌다. 307호는 존재하지 않는다.",
	"ear_sounds": "닫힌 문 너머로 소리가 들린다. …귀를 막고 싶어진다.",
	"ear_pass": "소리가 잦아들었다. 귀를 막지 않길 잘했다.",
	"messy_morning": "이불이 헝클어져 있다. 누군가 누웠던 흔적. —정리하기 전까지 밖에 나가지 마라—",
	"messy_fixed": "이불을 정리했다. 방이 다시 당신의 것이다.",
	"wet_read": "번진 잉크를 읽으려는 순간, 글자들이 꿈틀거렸다.",
}

const WARN := {
	"whistle": "규칙 위반 — 소리에 반응해 움직였다.",
	"window": "규칙 위반 — 움직이는 것을 끝까지 보았다.",
	"blue_sconce": "규칙 위반 — 푸른 등불 아래 너무 오래 있었다.",
	"name_call": "규칙 위반 — 뒤돌아보았다.",
	"knock_307": "규칙 위반 — 307호에 대답했다.",
	"ear_cover": "규칙 위반 — 귀를 막았다. 소리는 이제 방 안에 있다.",
	"messy_leave": "규칙 위반 — 어질러진 침대를 두고 방을 나섰다.",
	"wet_read": "규칙 위반 — 젖은 규칙을 읽었다.",
	"seventh_door": "규칙 위반 — 일곱 번째 문을 열었다.",
	"generic": "규칙 위반 — 호텔이 당신을 주목한다.",
}

const VIOLATION_RESULT := "— 규칙을 어겼다. 호텔이 처음으로 되돌린다. 첫째 날로. —"
const UNDER_BED_END := "침대 밑에는 어둠이 있었다. 어둠은, 당신을 기다리고 있었다."

const ENDING_GOOD := [
	"일곱 번째 아침. 창밖이… 밝다.",
	"극야가 끝났다. 40일 만의 새벽.",
	"복도의 여섯 개의 문이 전부 열려 있다. 안은 텅 비어 있다.",
	"프런트의 방명록에서 당신의 이름이 지워져 있다.",
	"문을 나서는 순간, 뒤를 돌아보았다.",
	"호텔은 없었다. 눈 덮인 산등성이만이 새벽 빛에 서 있었다.",
	"— 당신은 체크아웃했다. —",
]

const ENDING_BAD := [
	"세 번째 등불이 꺼졌다.",
	"어둠 속에서, 누군가 침대 곁에 서 있는 것이 보였다.",
	"낯익은 얼굴. 당신과 똑같은 얼굴.",
	"호텔은 당신을 기억한다. 이제 당신도 호텔의 일부다.",
	"다음 투숙객을 위해, 규칙을 써야 한다.",
	"펜을 들었다. 잉크는 아직 젖어 있다.",
	"『301호 투숙객께. 당신은 아직 살아 있습니다.』",
	"— 당신은 체크아웃하지 못했다. —",
]

const ENDING_UNDER_BED := [
	"침대 밑의 어둠이 눈을 떴다.",
	"등불은 이미 하나뿐이었다. 규칙은 말했었다. 이미 늦었다고.",
	"— 당신은 체크아웃하지 못했다. —",
]

const BTN_LOOK_BACK := "돌아본다"
const BTN_DONT_LOOK := "뒤돌아보지 않는다"
const BTN_ANSWER := "대답한다"
const BTN_IGNORE := "무시한다"
const BTN_COVER_EARS := "귀를 막는다"
const BTN_KEEP_LISTEN := "소리를 듣는다"
const BTN_SLEEP := "잠든다"
const BTN_STAY_UP := "더 둘러본다"
const BTN_CONTINUE := "계속한다"
const BTN_RESTART := "처음부터"
const BTN_MENU := "메인 메뉴로"
const BTN_RESUME := "계속"
const BTN_CLOSE := "닫는다"
const BTN_READ_RULES := "규칙을 읽는다"

const CHOICE_LINE_LOOK := "돌아보시겠습니까?"
const CHOICE_LINE_307 := "문 너머의 목소리가 다시 묻는다. —거기… 누구 있습니까?—"
const CHOICE_LINE_EARS := "소리가 점점 커진다."
const CHOICE_LINE_SLEEP := "아직 고치지 못한 곳이 있습니다. 잠들면 등불이 하나 꺼집니다."

const HUD_RULES_TITLE := "오늘의 규칙"
const HUD_RULES_WET := "(젖어서 읽을 수 없다)"
const HUD_DAY := "%s — %d일째"
const HUD_LANTERN := "등불"
const HUD_ANOMALY_LEFT := "오늘의 이상: %d곳 남음"
const HUD_ALL_CLEAR := "오늘의 이상은 모두 바로잡았다"
const MINIMAP := {
	"corridor": "복도", "ev": "EV", "lobby": "로비",
	"r301": "301", "r302": "302", "r303": "303",
	"r304": "304", "r305": "305", "r306": "306",
}

const SUBTITLE_HINT := "(눌러서 넘기기)"

const LANTERN_LOST_LINES := {
	2: "등불이 두 개 남았다. 복도가 조금 길어진 것 같다.",
	1: "등불이 하나 남았다. 호텔이 당신을 기억하기 시작한다.",
}

static func rule_text(id: String) -> String:
	return RULES.get(id, "")

static func flavor(id: String) -> String:
	return FLAVOR.get(id, "")

static func sub(id: String) -> String:
	return SUBS.get(id, "")

static func trap_line(id: String) -> String:
	return TRAP.get(id, "")

static func warn(id: String) -> String:
	return WARN.get(id, WARN["generic"])
