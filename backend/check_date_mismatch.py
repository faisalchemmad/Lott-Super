from core.models import Bet, GameResult
from django.utils import timezone

# Check what date the result has vs when bets were placed
r = GameResult.objects.get(id=28)
print(f"Result: game={r.game.name} date={r.date} 1st={r.winning_number}")

bets = Bet.objects.filter(game=r.game).order_by('-created_at')[:10]
print(f"\nBets for game {r.game.name}:")
for b in bets:
    print(f"  id={b.id} type={b.type} num={b.number} state={b.state} date={b.created_at.date()} winner={b.is_winner}")

# Check what date filter gives
matching = Bet.objects.filter(game=r.game, created_at__date=r.date)
print(f"\nBets matching result date {r.date}: {matching.count()}")
