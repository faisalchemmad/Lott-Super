import os
import sys
from django.test import RequestFactory
from rest_framework.test import APIRequestFactory

# Add the project directory to sys.path
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'server.settings')

import django
django.setup()

from core.models import User, Bet, Game, GameResult
from core.views import WinningReportView, GameResultViewSet

def test_unfolding_report():
    # Setup
    admin, _ = User.objects.get_or_create(username='test_admin', defaults={'role': 'ADMIN'})
    user, _ = User.objects.get_or_create(username='test_user', defaults={'role': 'AGENT', 'parent': admin})
    user.prize_super_1 = 5000.0
    user.comm_super_1 = 400.0
    user.prize_super_4 = 100.0
    user.comm_super_4 = 10.0
    user.save()
    
    game, _ = Game.objects.get_or_create(name='Test Game', defaults={'time': '12:00:00'})
    
    # Create a bet for 147
    Bet.objects.filter(user=user, game=game).delete()
    bet = Bet.objects.create(
        user=user,
        game=game,
        number='147',
        amount=10.0,
        count=1,
        type='SUPER',
        created_at='2026-03-12 10:00:00'
    )
    
    # Create result: 1st=000, 4th=147
    res_data = {
        'game': game,
        'date': '2026-03-12',
        'winning_number': '000',
        'second_prize': '111',
        'third_prize': '222',
        'fourth_prize': '147',
        'fifth_prize': '444'
    }
    game_result, _ = GameResult.objects.update_or_create(
        game=game, date='2026-03-12', defaults=res_data
    )
    
    # Calculate winners
    viewset = GameResultViewSet()
    viewset._calculate_winners(game_result)
    
    # Check WinningReportView
    factory = APIRequestFactory()
    request = factory.get('/api/report/winning/', {'from': '2026-03-12', 'to': '2026-03-12'})
    request.user = admin
    
    view = WinningReportView.as_view()
    response = view(request)
    
    print(f"Status Code: {response.status_code}")
    if response.status_code == 200:
        winners = response.data.get('winners', [])
        print(f"Found {len(winners)} winner rows")
        for w in winners:
            print(f"Row: {w['winning_prize_type']}, Amount: {w['winning_amount']}")

if __name__ == '__main__':
    test_unfolding_report()
