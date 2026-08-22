import sys
p = r'd:\Gemini\Android\Lott_super\backend\core\views.py'
with open(p, 'r', encoding='utf-8') as f:
    c = f.read()

# Check how Bet TYPE_CHOICES look - if TN types are registered
search = "TYPE_CHOICES"
idx = c.find(search)
sys.stdout.buffer.write(c[idx:idx+800].encode('utf-8'))
