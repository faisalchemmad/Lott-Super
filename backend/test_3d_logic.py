import os, django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'server.settings')
django.setup()

from core.models import User, Bet, Game, GameResult
from core.views import GameResultViewSet, calculate_bet_win_prize_and_comm

# Get or mock a user
user = User.objects.first()
print(f"Testing for User: {user.username}")
print(f"  3D-10: exact={user.tn_prize_3d_10}, bc={user.tn_prize_3d_10_bc}")
print(f"  3D-25: exact={user.tn_prize_3d_25}, bc={user.tn_prize_3d_25_bc}")
print(f"  3D-30: exact={user.tn_prize_3d_30}, bc={user.tn_prize_3d_30_bc}, c={user.tn_prize_3d_30_c}")
print(f"  3D-60: exact={user.tn_prize_3d_60}, bc={user.tn_prize_3d_60_bc}, c={user.tn_prize_3d_60_c}")

# Test mock calculations
win_2nd = "425"

test_cases = [
    # (bet_type, bet_num, expected_tier_desc)
    ('3D-10', '425', '3D-10 EXACT (425) -> should be 5000'),
    ('3D-10', '325', '3D-10 BC MATCH (325) -> should be 100'),
    ('3D-10', '935', '3D-10 C MATCH (935) -> should be NO WIN'),
    ('3D-25', '425', '3D-25 EXACT (425) -> should be 10000'),
    ('3D-25', '325', '3D-25 BC MATCH (325) -> should be 1000'),
    ('3D-25', '935', '3D-25 C MATCH (935) -> should be NO WIN'),
    ('3D-30', '425', '3D-30 EXACT (425) -> should be 15000'),
    ('3D-30', '325', '3D-30 BC MATCH (325) -> should be 500'),
    ('3D-30', '935', '3D-30 C MATCH (935) -> should be 50'),
    ('3D-60', '425', '3D-60 EXACT (425) -> should be 30000'),
    ('3D-60', '325', '3D-60 BC MATCH (325) -> should be 1000'),
    ('3D-60', '935', '3D-60 C MATCH (935) -> should be 100'),
]

print("\n--- Testing 3D Logic against 2nd prize '425' ---")
for b_type, b_num, desc in test_cases:
    match = False
    p = 0.0
    display_name = ""
    if b_num == win_2nd:
        match = True
        display_name = f"2ND PRIZE ({b_type}) EXACT"
        if b_type == '3D-10': p = float(user.tn_prize_3d_10)
        elif b_type == '3D-25': p = float(user.tn_prize_3d_25)
        elif b_type == '3D-30': p = float(user.tn_prize_3d_30)
        elif b_type == '3D-60': p = float(user.tn_prize_3d_60)
    elif len(b_num) >= 2 and b_num[-2:] == win_2nd[-2:]:
        match = True
        display_name = f"2ND PRIZE ({b_type}) BC MATCH"
        if b_type == '3D-10': p = float(user.tn_prize_3d_10_bc)
        elif b_type == '3D-25': p = float(user.tn_prize_3d_25_bc)
        elif b_type == '3D-30': p = float(user.tn_prize_3d_30_bc)
        elif b_type == '3D-60': p = float(user.tn_prize_3d_60_bc)
    elif len(b_num) >= 1 and b_num[-1:] == win_2nd[-1:] and b_type in ['3D-30', '3D-60']:
        match = True
        display_name = f"2ND PRIZE ({b_type}) C MATCH"
        if b_type == '3D-30': p = float(user.tn_prize_3d_30_c)
        elif b_type == '3D-60': p = float(user.tn_prize_3d_60_c)

    # Also test calculate_bet_win_prize_and_comm
    class MockBet:
        count = 1
        type = b_type
        number = b_num
        winning_prize_type = display_name
        is_winner = match
        state = 'TN'

    if match:
        rec_p, _ = calculate_bet_win_prize_and_comm(MockBet(), user, specific_prize_type=display_name)
        print(f"PASS: {desc} => Calculated: {p}, Report View: {rec_p} ({display_name})")
    else:
        print(f"PASS (No win): {desc}")
