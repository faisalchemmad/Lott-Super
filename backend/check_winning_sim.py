from core.models import Bet, GameResult

r = GameResult.objects.get(id=28)
print(f"Result: game={r.game.name} date={r.date} 1st={r.winning_number}")

matching = Bet.objects.filter(game=r.game, created_at__date=r.date)
print(f"\nBets matching result date {r.date}:")
for b in matching:
    print(f"  id={b.id} type={b.type} num={b.number} state={b.state} winner={b.is_winner}")

# Now manually simulate _calculate_winners for 1st prize
win_num = (r.winning_number or "").strip()
print(f"\n1st prize win_num: '{win_num}' len={len(win_num)}")
base_win = win_num[-3:] if len(win_num) >= 3 else win_num
print(f"base_win (last 3): '{base_win}'")
print(f"A={base_win[0] if base_win else ''}, B={base_win[1] if len(base_win)>1 else ''}, C={base_win[2] if len(base_win)>2 else ''}")
print(f"AB={base_win[0:2] if len(base_win)>=2 else ''}, BC={base_win[1:3] if len(base_win)>=3 else ''}, AC={base_win[0]+base_win[2] if len(base_win)>=3 else ''}")

# Check which bets would match
for b in matching:
    b_type = b.type.upper()
    b_num = b.number.strip()
    target = ""
    if len(base_win) >= 3:
        if b_type == 'AB': target = base_win[0:2]
        elif b_type == 'BC': target = base_win[1:3]
        elif b_type == 'AC': target = base_win[0] + base_win[2]
        elif b_type == 'A': target = base_win[0]
        elif b_type == 'B': target = base_win[1]
        elif b_type == 'C': target = base_win[2]
    match = (target and b_num == target)
    if match:
        print(f"  MATCH: id={b.id} type={b_type} bet={b_num} target={target}")
