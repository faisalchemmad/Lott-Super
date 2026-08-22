import sys
p = r'd:\Gemini\Android\Lott_super\backend\core\views.py'
with open(p, 'r', encoding='utf-8') as f:
    c = f.read()

# Check: how does _calculate_winners filter bets by date?
search = "all_bets_qs = Bet.objects.filter"
idx = c.find(search)
sys.stdout.buffer.write(c[max(0, idx-200):idx+400].encode('utf-8'))
