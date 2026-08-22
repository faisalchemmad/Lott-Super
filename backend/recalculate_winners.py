from core.models import Bet, GameResult
from core.views import GameResultViewSet

# Get latest TN result
results = GameResult.objects.filter(winning_number__isnull=False).order_by('-date', '-created_at')[:3]
for r in results:
    print(f"id={r.id} game={r.game.name} date={r.date} 1st={r.winning_number}")

# Get the most recent one
r = results[0]
print(f"\nRecalculating for: {r.game.name} date={r.date} 1st={r.winning_number}")

# Call _calculate_winners
vs = GameResultViewSet()
vs._calculate_winners(r)

# Check winners now
from datetime import timedelta
bets = Bet.objects.filter(game=r.game, created_at__date__gte=r.date - timedelta(days=1), created_at__date__lte=r.date)
print(f"\nAll bets for this game/date window:")
for b in bets:
    print(f"  id={b.id} type={b.type} num={b.number} state={b.state} winner={b.is_winner} prize_type={b.winning_prize_type} amount={b.winning_amount}")
