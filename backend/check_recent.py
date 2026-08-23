from core.models import Bet, GameResult
from datetime import timedelta

# Check most recent bets and their types
print("=== Latest Bets ===")
bets = Bet.objects.order_by('-created_at')[:10]
for b in bets:
    print(f"  id={b.id} type={b.type} num={b.number} state={b.state} count={b.count} amount={b.amount} winner={b.is_winner} winning={b.winning_amount}")

# Check user's prize settings
print("\n=== User Prize Settings ===")
b = Bet.objects.order_by('-created_at').first()
if b:
    u = b.user
    print(f"User: {u.username}")
    print(f"KL prize_abc_1: {u.prize_abc_1}")
    print(f"TN tn_prize_abc: {u.tn_prize_abc}")

# Check latest result
print("\n=== Latest Results ===")
results = GameResult.objects.order_by('-date', '-created_at')[:3]
for r in results:
    print(f"  id={r.id} game={r.game.name} date={r.date} 1st={r.winning_number}")
