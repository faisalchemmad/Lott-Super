import os
import sys
import django

# Add the project directory to sys.path
sys.path.append(os.path.dirname(os.path.abspath(__file__)))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'server.settings')
django.setup()

from core.models import User, Bet, Game, GameResult
from core.views import GameResultViewSet

def test_derived_prizes():
    viewset = GameResultViewSet()
    user, _ = User.objects.get_or_create(username='test_user', defaults={'role': 'AGENT'})
    user.prize_ab_bc_ac_1 = 700.0
    user.save()
    
    game, _ = Game.objects.get_or_create(name='Test Game', defaults={'time': '12:00:00'})
    
    # Bet AB 14
    Bet.objects.filter(user=user, game=game).delete()
    bet = Bet.objects.create(
        user=user, game=game, number='14', amount=10.0, count=1, type='AB'
    )
    
    # Result 4th Prize 147
    res_data = {
        'game': game,
        'date': '2026-03-12',
        'winning_number': '000',
        'fourth_prize': '147'
    }
    game_result, _ = GameResult.objects.update_or_create(
        game=game, date='2026-03-12', defaults=res_data
    )
    
    viewset._calculate_winners(game_result)
    
    bet.refresh_from_db()
    print(f"Bet Number: {bet.number}")
    print(f"Is Winner: {bet.is_winner}")
    print(f"Prize Type: {bet.winning_prize_type}")
    print(f"Prize Amount: {bet.winning_amount}")

if __name__ == '__main__':
    test_derived_prizes()
