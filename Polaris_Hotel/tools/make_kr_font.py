import io, os, re, urllib.parse, urllib.request

ROOT = "/var/games/game-20260803-34856639"

chars = set()
for dirpath, _, files in os.walk(os.path.join(ROOT, "scripts")):
    for f in files:
        if f.endswith(".gd"):
            s = io.open(os.path.join(dirpath, f), encoding="utf-8").read()
            for ch in s:
                if ch != "\n" and ch != "\t" and ch != "\r":
                    chars.add(ch)

text = "".join(sorted(chars))
text += " 0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"
text += "[]()<>/%—…·『』\"'-:;.,!?_|+=@#&*~^"
seen = set()
out = []
for ch in text:
    if ch not in seen:
        seen.add(ch)
        out.append(ch)
text = "".join(out)

q = urllib.parse.quote(text)
url = "https://fonts.googleapis.com/css2?family=Noto+Sans+KR:wght@400&text=" + q
print("url length:", len(url), "chars:", len(text))
UA = "Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10_6_4; en-us) AppleWebKit/533.18.1 (KHTML, like Gecko) Version/5.0.2 Safari/533.18.5"
css = urllib.request.urlopen(urllib.request.Request(url, headers={"User-Agent": UA}), timeout=25).read().decode("utf-8")
urls = re.findall(r"url\((https://[^)]+)\)", css)
print("font urls:", len(urls))
assert urls, css[:500]
data = urllib.request.urlopen(urllib.request.Request(urls[0], headers={"User-Agent": UA}), timeout=60).read()
print("magic:", data[:4].hex(), "bytes:", len(data))
assert data[:4] == b"\x00\x01\x00\x00" or data[:4] == b"OTTO", "not a TTF/OTF"
os.makedirs(os.path.join(ROOT, "assets", "fonts"), exist_ok=True)
out_path = os.path.join(ROOT, "assets", "fonts", "noto_sans_kr.ttf")
io.open(out_path, "wb").write(data)
print("saved:", out_path)
