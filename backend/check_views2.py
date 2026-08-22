import sys
p = r'd:\Gemini\Android\Lott_super\backend\core\views.py'
with open(p, 'r', encoding='utf-8') as f:
    c = f.read()

# Show context around "base_win = win_num[-3:]" to understand the current TN A/B/C logic
search = "base_win = win_num[-3:] if len(win_num) >= 3 else win_num"
idx = c.find(search)
sys.stdout.buffer.write(c[max(0, idx-200):idx+600].encode('utf-8'))
