import sys
p = r'd:\Gemini\Android\Lott_super\backend\core\views.py'
with open(p, 'r', encoding='utf-8') as f:
    c = f.read()

search = "elif b_type in ['AB', 'BC', 'AC', 'A', 'B', 'C']:"
idx = c.find(search)
sys.stdout.buffer.write(c[idx:idx+2500].encode('utf-8'))
