import os
import django
import sys

# Set up Django environment
sys.path.append(os.path.dirname(os.path.abspath(__file__)))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'server.settings')
django.setup()

from core.models import User, Game, Bet, GameResult
from core.views import GameResultViewSet
from django.utils import timezone
from decimal import Decimal

def test_box_logic():
    print("Testing BOX logic...")
    
    # Get or create a test user
    user, _ = User.objects.get_or_create(username='test_dealer', defaults={'role': 'DEALER'})
    # Ensure they have settings
    user.prize_box_3d_1 = Decimal('3000')
    user.prize_box_3d_2 = Decimal('800')
    user.save()
    
    # Get or create a game
    game, _ = Game.objects.get_or_create(name='Test Game', defaults={'time': '12:00:00'})
    
    date = timezone.localtime().date()
    print(f"Test Date: {date}")
    
    # Clear existing bets for this test
    Bet.objects.filter(game=game, created_at__date=date).delete()
    
    # Create test bets
    b1 = Bet.objects.create(user=user, game=game, number='325', amount=10, count=1, type='BOX')
    b2 = Bet.objects.create(user=user, game=game, number='532', amount=10, count=1, type='BOX')
    
    # Check count
    count = Bet.objects.filter(game=game, created_at__date=date).count()
    print(f"Bets created: {count}")

    # Trigger winner calculation
    result = GameResult(game=game, date=date, winning_number='325')
    viewset = GameResultViewSet()
    viewset._calculate_winners(result)
    
    # Verify
    b1.refresh_from_db()
    b2.refresh_from_db()
    
    print(f"Bet 325 (BOX): Win={b1.is_winner}, Type={b1.winning_prize_type}, Amount={b1.winning_amount}")
    print(f"Bet 532 (BOX): Win={b2.is_winner}, Type={b2.winning_prize_type}, Amount={b2.winning_amount}")

if __name__ == '__main__':
    test_box_logic()
