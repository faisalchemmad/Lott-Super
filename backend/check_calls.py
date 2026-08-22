import sys
p = r'd:\Gemini\Android\Lott_super\backend\core\views.py'
with open(p, 'r', encoding='utf-8') as f:
    c = f.read()

# Look at how evaluate_wins is called for regular bets and forwarded bets
search = "wins = evaluate_wins"
idx = 0
while True:
    idx = c.find(search, idx)
    if idx == -1:
        break
    sys.stdout.buffer.write(c[max(0, idx-50):idx+150].encode('utf-8'))
    print("\n---")
    idx += 10

# Also check what the 'prizes' list looks like for TN game - especially if 1ST PRIZE = 4-digit
# Check if there is TN specific prizes logic
search2 = "prizes = ["
idx2 = c.find(search2)
sys.stdout.buffer.write(c[idx2:idx2+600].encode('utf-8'))
