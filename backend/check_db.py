from core.models import Bet, GameResult
bets = Bet.objects.filter(state='TN').order_by('-created_at')[:5]
print('TN Bets:')
for b in bets:
    print(f'  id={b.id} type={b.type} num={b.number} state={b.state} winner={b.is_winner} winning={b.winning_amount} date={b.created_at.date()}')
print()
results = GameResult.objects.order_by('-date', '-created_at')[:5]
print('Recent Results:')
for r in results:
    print(f'  id={r.id} game={r.game.name} date={r.date} 1st={r.winning_number} 2nd={r.second_prize} 3rd={r.third_prize} 4th={r.fourth_prize}')
