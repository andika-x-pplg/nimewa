import urllib.request

base = "https://archive.org/download/sijjhub-media-1265314136-1794664214/sijjhub-media-1265314136-1794664214.thumbs/"
for ts in ['000300', '000360', '000420', '000480']:
    u = f"{base}Solo_Leveling_S01_2024_480p_1265314136_{ts}.jpg"
    dest = f"scratch/sijj_{ts}.jpg"
    try:
        urllib.request.urlretrieve(u, dest)
        print("Downloaded:", dest)
    except Exception as e:
        print("Error:", e)

