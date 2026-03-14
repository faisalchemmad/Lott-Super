import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'backend.settings')
django.setup()

from core.models import User, Game, NumberLimit, Bet
from rest_framework.test import APIClient

client = APIClient()

# Create sub-dealer
try:
    subdealer, _ = User.objects.get_or_create(username='subtest', role='SUB_DEALER', weekly_credit_limit=1000000)
    subdealer.set_password('1234')
    subdealer.save()
except Exception as e:
    pass

subdealer = User.objects.get(username='subtest')

# Ensure game exists
game = Game.objects.first()
if not game:
    game = Game.objects.create(name='Lott Test', start_time='00:00:00', end_time='23:59:59', time="12:00 PM")

# Create a User Specific Limit: User=subtest, game=Lott Test, number=999, type=SUPER, count=10
NumberLimit.objects.filter(user=subdealer).delete()
limit = NumberLimit.objects.create(user=subdealer, game=game, number='999', type='SUPER', max_count=10)

print("Created user limit:", limit)

# Login and test
client.force_authenticate(user=subdealer)

# 1. Bet 5 -> should succeed
data1 = {
    "bets": [{"game": game.id, "type": "SUPER", "number": "999", "count": 5}]
}
res1 = client.post('/api/bets/bulk-create/', data1, format='json')
print("Bet 5 response:", res1.json())

# 2. Bet 6 -> should fail
data2 = {
    "bets": [{"game": game.id, "type": "SUPER", "number": "999", "count": 6}]
}
res2 = client.post('/api/bets/bulk-create/', data2, format='json')
print("Bet 6 response:", res2.json())

# 3. Bet 10 + 1 -> test session override
data3 = {
    "bets": [
        {"game": game.id, "type": "SUPER", "number": "888", "count": 10},
        {"game": game.id, "type": "SUPER", "number": "888", "count": 1}
    ]
}
limit2 = NumberLimit.objects.create(user=subdealer, game=game, number='888', type='SUPER', max_count=10)
res3 = client.post('/api/bets/bulk-create/', data3, format='json')
print("Bet 10+1 session response:", res3.json())
