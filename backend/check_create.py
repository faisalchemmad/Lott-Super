import sys
p = r'd:\Gemini\Android\Lott_super\backend\core\views.py'
with open(p, 'r', encoding='utf-8') as f:
    c = f.read()

# Check the create() method
idx = c.find('def create(self, request, *args, **kwargs):')
sys.stdout.buffer.write(c[idx:idx+1500].encode('utf-8'))
