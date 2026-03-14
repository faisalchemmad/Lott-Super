import os
import django
import sys

# Add the project directory to sys.path
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'server.settings')
django.setup()

from core.models import User, Game
from django.utils import timezone
from datetime import time

def seed():
    # Create Super Admin if not exists
    if not User.objects.filter(username='admin').exists():
        User.objects.create_superuser('admin', 'admin@example.com', 'admin123', role='SUPER_ADMIN', weekly_credit_limit=1000000)
        print("Super Admin created: admin / admin123")

    # Create Sample Games
    games = [
        ('1:00 PM DRAW', time(13, 0)),
        ('3:00 PM DRAW', time(15, 0)),
        ('6:00 PM DRAW', time(18, 0)),
        ('8:00 PM DRAW', time(20, 0)),
    ]

    for name, g_time in games:
        Game.objects.get_or_create(name=name, time=g_time)
        print(f"Game created: {name} at {g_time}")

if __name__ == '__main__':
    seed()
