import sys
p = r'd:\Gemini\Android\Lott_super\backend\core\views.py'
with open(p, 'r', encoding='utf-8') as f:
    c = f.read()

# Check the full _calculate_winners function 
idx_start = c.find('def _calculate_winners(self, game_result):')
idx_end = c.find('\n    def ', idx_start + 10)
sys.stdout.buffer.write(c[idx_start:idx_end].encode('utf-8'))
