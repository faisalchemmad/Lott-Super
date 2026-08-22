from core.models import Bet, GameResult
from core.views import GameResultViewSet

# Re-trigger _calculate_winners for result id=28
r = GameResult.objects.get(id=28)
print(f"Result: {r.game.name} date={r.date} 1st={r.winning_number}")

# Manually call _calculate_winners
vs = GameResultViewSet()
vs._calculate_winners(r)

# Check winners now
bets = Bet.objects.filter(game=r.game, is_winner=True)
print(f"\nWinning bets after recalculation:")
for b in bets:
    print(f"  id={b.id} type={b.type} num={b.number} state={b.state} prize_type={b.winning_prize_type} amount={b.winning_amount}")
