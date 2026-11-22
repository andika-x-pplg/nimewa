import re

with open("C:/Users/Administrator/.gemini/antigravity/brain/229aafc4-8b5f-49b2-a7f8-7a363b91d9bc/.system_generated/steps/11739/output.txt", "r", encoding="utf-8", errors="ignore") as f:
    text = f.read()

# find all MATCH blocks
matches = re.findall(r'MATCH:\s*([^\s|]+)\s*\|\s*([^|]+)\|\s*(\d+)\s*video files:\n((?:\s*->[^\n]+\n)+)', text)
print(f"Total matches parsed: {len(matches)}")
for ident, title, count, file_block in matches:
    count = int(count)
    if count >= 3 or 's01' in ident.lower() or 's1' in ident.lower() or 'season' in title.lower():
        print(f"\n=== {ident} ({count} files) : {title.strip()} ===")
        for line in file_block.strip().split('\n'):
            print(line)

