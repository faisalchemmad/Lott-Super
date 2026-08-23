import sys
p = r'd:\Gemini\Android\Lott_super\backend\core\views.py'
with open(p, 'r', encoding='utf-8') as f:
    c = f.read()

# Find the AB/BC/AC A/B/C prize logic
search = "if state == 'TN':"
all_idx = []
idx = 0
while True:
    idx = c.find(search, idx)
    if idx == -1:
        break
    all_idx.append(idx)
    sys.stdout.buffer.write(c[max(0,idx-100):idx+300].encode('utf-8'))
    print("\n---\n")
    idx += 10
