import os
import sys

# Add the project directory to sys.path
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'server.settings')

import django
django.setup()

from core.models import User, Bet, Game, GameResult
from core.views import GameResultViewSet
from rest_framework.test import APIRequestFactory

def test_fourth_prize():
    # Setup
    factory = APIRequestFactory()
    viewset = GameResultViewSet()
    
    # Create a user with prizes
    user, _ = User.objects.get_or_create(username='test_user', defaults={'role': 'AGENT'})
    user.prize_super_4 = 100.0
    user.comm_super_4 = 10.0
    user.save()
    
    # Create a game
    game, _ = Game.objects.get_or_create(name='Test Game', defaults={'time': '12:00:00'})
    
    # Create a bet for 147
    Bet.objects.filter(user=user, game=game).delete() # Cleanup
    bet = Bet.objects.create(
        user=user,
        game=game,
        number='147',
        amount=10.0,
        count=1,
        type='SUPER'
    )
    
    # Create a result where 147 is 4th prize
    res_data = {
        'game': game.id,
        'date': '2026-03-12',
        'winning_number': '000',
        'second_prize': '111',
        'third_prize': '222',
        'fourth_prize': '147',
        'fifth_prize': '444',
        'complimentary_numbers': '555, 666'
    }
    
    # Trigger winner calculation
    res_data.pop('game') # Remove ID to avoid conflict with instance
    game_result, _ = GameResult.objects.update_or_create(
        game=game, date='2026-03-12',
        defaults=res_data
    )
    
    viewset._calculate_winners(game_result)
    
    # Check results
    bet.refresh_from_db()
    print(f"Bet Number: {bet.number}")
    print(f"Is Winner: {bet.is_winner}")
    print(f"Prize Type: {bet.winning_prize_type}")
    print(f"Prize Amount: {bet.winning_amount}")

if __name__ == '__main__':
    test_fourth_prize()
