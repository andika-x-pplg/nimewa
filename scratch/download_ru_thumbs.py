import urllib.request
import urllib.parse

base = "https://archive.org/download/solo-leveling-s1_202610/"
for ts in ['000600', '000720', '000840', '000960']:
    path = f"solo-leveling-s1_202610.thumbs/Поднятие уровня в одиночку С1Э01 (2024) 1080p_{ts}.jpg"
    encoded = urllib.parse.quote(path).replace('%2F', '/')
    u = base + encoded
    dest = f"scratch/ru_{ts}.jpg"
    try:
        urllib.request.urlretrieve(u, dest)
        print("Downloaded:", dest)
    except Exception as e:
        print("Error:", e)

