import os
import django
import sys

# Add the project directory to sys.path
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'server.settings')
django.setup()

from core.models import User

def check_users():
    print("Listing all users and their roles:")
    for user in User.objects.all():
        print(f"ID: {user.id} | Username: {user.username} | Role: {user.role} | Superuser: {user.is_superuser}")
        if user.username == 'admin':
            user.set_password('admin123')
            user.save()
            print("Successfully reset password for user 'admin' to 'admin123'")

if __name__ == '__main__':
    check_users()
