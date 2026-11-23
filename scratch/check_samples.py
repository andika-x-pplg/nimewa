import subprocess
import json
import os

items = [
    {
        "name": "dn_guidance",
        "url": "https://archive.org/download/death-note-22-guidance/Death%20Note%20-%2001%20-%20Rebirth.mp4"
    },
    {
        "name": "hxh_horrible",
        "url": "https://archive.org/download/horrible-subs-hunter-x-hunter-135-480p/%5BHorribleSubs%5D%20Hunter%20x%20Hunter%20-%2001%20%5B480p%5D.mp4"
    },
    {
        "name": "bleach_complete",
        "url": "https://archive.org/download/bleach-complete/Bleach/S01/Bleach%20-%20S01E01.mp4"
    }
]

for item in items:
    name = item["name"]
    url = item["url"]
    out_mp4 = f"scratch/{name}_sample.mp4"
    out_jpg = f"scratch/{name}_frame.jpg"
    print(f"\n================ Testing {name} ================")
    # Download 12MB with curl
    cmd_curl = f'curl.exe -L -r 0-12000000 -s -o "{out_mp4}" "{url}"'
    subprocess.run(cmd_curl, shell=True)
    size = os.path.getsize(out_mp4) if os.path.exists(out_mp4) else 0
    print(f"Downloaded size: {size} bytes")

    if size > 1000:
        # ffprobe
        res = subprocess.run(f'ffprobe -v error -show_entries stream=index,codec_type,codec_name:stream_tags=language,title -of json "{out_mp4}"', shell=True, capture_output=True, text=True)
        print("Probe output:")
        try:
            data = json.loads(res.stdout)
            for s in data.get('streams', []):
                print(" ", s)
        except Exception:
            print(res.stdout)

        # ffmpeg extract frame at 120s or 240s
        for ss in ["00:02:00", "00:04:30"]:
            fpath = f"scratch/{name}_{ss.replace(':', '_')}.jpg"
            subprocess.run(f'ffmpeg -y -ss {ss} -i "{out_mp4}" -vframes 1 "{fpath}"', shell=True, capture_output=True)
            if os.path.exists(fpath):
                print(f"Frame at {ss} created: {os.path.getsize(fpath)} bytes")

