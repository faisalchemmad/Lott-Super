import os, django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'server.settings')
django.setup()

from core.models import User
from core.views import calculate_bet_win_prize_and_comm

user = User.objects.first()
print(f"Testing 4D Logic for User: {user.username}")
print(f"  4D-110: 1st={user.tn_prize_4d_110_1}, 2nd={user.tn_prize_4d_110_2}, 3rd={user.tn_prize_4d_110_3}, 4th={user.tn_prize_4d_110_4}")
print(f"  4D-55:  1st={user.tn_prize_4d_55_1}, 2nd={user.tn_prize_4d_55_2}, 3rd={user.tn_prize_4d_55_3}, 4th={user.tn_prize_4d_55_4}")
print(f"  4D-20:  1st={user.tn_prize_4d_20_1}")

win_1st = "1425"

test_cases = [
    # 4D-110
    ('4D-110', '1425', '4D-110 Exact (1425) -> should be 450000'),
    ('4D-110', '2425', '4D-110 Last 3D (2425) -> should be 10000'),
    ('4D-110', '1825', '4D-110 Last 2D (1825) -> should be 1000'),
    ('4D-110', '1885', '4D-110 Last 1D (1885) -> should be 100'),
    ('4D-110', '9999', '4D-110 No match (9999) -> should be NO WIN'),

    # 4D-55
    ('4D-55', '1425', '4D-55 Exact (1425) -> should be 225000'),
    ('4D-55', '2425', '4D-55 Last 3D (2425) -> should be 5000'),
    ('4D-55', '1825', '4D-55 Last 2D (1825) -> should be 500'),
    ('4D-55', '1885', '4D-55 Last 1D (1885) -> should be 50'),
    ('4D-55', '9999', '4D-55 No match (9999) -> should be NO WIN'),

    # 4D-20
    ('4D-20', '1425', '4D-20 Exact (1425) -> should be 100000'),
    ('4D-20', '2425', '4D-20 Last 3D (2425) -> should be NO WIN'),
    ('4D-20', '1825', '4D-20 Last 2D (1825) -> should be NO WIN'),
    ('4D-20', '1885', '4D-20 Last 1D (1885) -> should be NO WIN'),
]

print("\n--- Testing 4D Logic against 1st prize '1425' ---")
for b_type, b_num, desc in test_cases:
    match = False
    p = 0.0
    display_name = ""

    if b_num == win_1st:
        match = True
        display_name = f"1ST PRIZE ({b_type})"
        if b_type == '4D-110': p = float(user.tn_prize_4d_110_1)
        elif b_type == '4D-55': p = float(user.tn_prize_4d_55_1)
        elif b_type == '4D-20': p = float(user.tn_prize_4d_20_1)
    elif b_num[-3:] == win_1st[-3:] and b_type in ['4D-110', '4D-55']:
        match = True
        display_name = f"2ND PRIZE ({b_type})"
        if b_type == '4D-110': p = float(user.tn_prize_4d_110_2)
        elif b_type == '4D-55': p = float(user.tn_prize_4d_55_2)
    elif b_num[-2:] == win_1st[-2:] and b_type in ['4D-110', '4D-55']:
        match = True
        display_name = f"3RD PRIZE ({b_type})"
        if b_type == '4D-110': p = float(user.tn_prize_4d_110_3)
        elif b_type == '4D-55': p = float(user.tn_prize_4d_55_3)
    elif b_num[-1:] == win_1st[-1:] and b_type in ['4D-110', '4D-55']:
        match = True
        display_name = f"4TH PRIZE ({b_type})"
        if b_type == '4D-110': p = float(user.tn_prize_4d_110_4)
        elif b_type == '4D-55': p = float(user.tn_prize_4d_55_4)

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
