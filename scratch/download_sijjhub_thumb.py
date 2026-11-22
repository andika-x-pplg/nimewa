import urllib.request
import urllib.parse

u = "https://archive.org/download/sijjhub-media-1265314136-1794664214/sijjhub-media-1265314136-1794664214.thumbs/Solo_Leveling_S01_2024_720p_1265314136_000339.jpg"
req = urllib.request.Request(u, headers={'User-Agent': 'Mozilla/5.0'})
try:
    with urllib.request.urlopen(req) as r:
        with open("scratch/sijjhub_thumb.jpg", "wb") as f:
            f.write(r.read())
    print("Downloaded sijjhub_thumb.jpg successfully")
except Exception as e:
    print("Error:", e)

