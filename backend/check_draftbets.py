import sys
p = r'd:\Gemini\Android\Lott_super\frontend\lib\views\betting_screen.dart'
with open(p, 'r', encoding='utf-8') as f:
    c = f.read()

# Find all _draftBets.insert occurrences to understand how each type is saved
idx = 0
count = 0
while count < 8:
    idx = c.find('_draftBets.', idx)
    if idx == -1:
        break
    print(f"=== _draftBets at {idx} ===")
    sys.stdout.buffer.write(c[max(0,idx-100):idx+500].encode('utf-8'))
    print("\n---\n")
    idx += 10
    count += 1
