from core.models import Bet, GameResult, User

# Get a TN bet to find the user
b = Bet.objects.filter(state='TN').order_by('-created_at').first()
if b:
    u = b.user
    print(f"User: {u.username}")
    print(f"KL AB/BC/AC prize: {u.prize_ab_bc_ac_1}  comm: {u.comm_ab_bc_ac_1}")
    print(f"KL A/B/C prize:    {u.prize_abc_1}  comm: {u.comm_abc_1}")
    print(f"TN AB/BC/AC prize: {u.tn_prize_ab_bc_ac}")
    print(f"TN A/B/C prize:    {u.tn_prize_abc}")
    
    # Also show winning_commission
    winners = Bet.objects.filter(state='TN', is_winner=True)
    print(f"\nTN winners:")
    for w in winners:
        print(f"  type={w.type} num={w.number} amount={w.winning_amount} commission={w.winning_commission} prize_type={w.winning_prize_type}")
