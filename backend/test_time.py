import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'backend.settings')
django.setup()

from core.models import User, Game, UserGameTiming, Bet
from rest_framework.test import APIClient
from datetime import datetime, timedelta

client = APIClient()

# Create sub-dealer
try:
    subdealer, _ = User.objects.get_or_create(username='time_sub', role='SUB_DEALER', weekly_credit_limit=1000000)
    subdealer.set_password('1234')
    subdealer.save()
except Exception as e:
    pass

subdealer = User.objects.get(username='time_sub')
try:
    dealer, _ = User.objects.get_or_create(username='time_dealer', role='DEALER', weekly_credit_limit=1000000)
    subdealer.parent = dealer
    subdealer.save()
except Exception:
    pass
dealer = User.objects.get(username='time_dealer')

# Ensure game exists
game = Game.objects.first()

print(f"Current Time: {datetime.now().time()}")

# Clear timings
UserGameTiming.objects.filter(game=game).delete()

# Set dealer timing strictly to the past
past_start = (datetime.now() - timedelta(hours=2)).time()
past_end = (datetime.now() - timedelta(hours=1)).time()
t_dealer = UserGameTiming.objects.create(user=dealer, game=game, start_time=past_start, end_time=past_end)

print(f"Created Dealer limit: {t_dealer.start_time} - {t_dealer.end_time}")

# Login and test (should fail because subdealer's branch time is over)
client.force_authenticate(user=subdealer)

data1 = {
    "bets": [{"game": game.id, "type": "SUPER", "number": "123", "count": 1}]
}
res1 = client.post('/api/bets/bulk-create/', data1, format='json')
print("Bulk Create Bet under restricted dealer response:", res1.json())

res2 = client.post('/api/bets/', {"game": game.id, "type": "SUPER", "number": "123", "count": 1}, format='json')
print("Single Create Bet under restricted dealer response:", res2.json())

# Now Give Subdealer active time
now_start = (datetime.now() - timedelta(minutes=5)).time()
now_end = (datetime.now() + timedelta(hours=1)).time()
t_sub = UserGameTiming.objects.create(user=subdealer, game=game, start_time=now_start, end_time=now_end)
print(f"Created Subdealer explicit limit: {t_sub.start_time} - {t_sub.end_time}")

# Should succeed! Because closest ancestor (self) has an open window
res3 = client.post('/api/bets/bulk-create/', data1, format='json')
print("Bulk Create Bet under active subdealer response:", res3.json())
