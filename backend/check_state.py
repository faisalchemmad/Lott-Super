import sys
p = r'd:\Gemini\Android\Lott_super\backend\core\views.py'
with open(p, 'r', encoding='utf-8') as f:
    c = f.read()

# Check what happens with bets - particularly the Bet TYPE_CHOICES
# Look for where 'state' is referenced in _calculate_winners
idx = c.find('def _calculate_winners')
func_block = c[idx:idx+8000]

# Find how state is fetched
for line in func_block.split('\n'):
    if 'state' in line.lower():
        print(repr(line))
