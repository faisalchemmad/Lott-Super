import os
import django

# Set up Django environment
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'server.settings')
django.setup()

from core.models import User

def update_defaults():
    # Update all users whose prices are still at the old default of 1.0
    users = User.objects.all()
    count = 0
    for user in users:
        updated = False
        if float(user.price_abc) == 1.0:
            user.price_abc = 12.0
            updated = True
        if float(user.price_ab_bc_ac) == 1.0:
            user.price_ab_bc_ac = 10.0
            updated = True
        if float(user.price_super) == 1.0 or hasattr(user, 'price_super_box') and float(getattr(user, 'price_super_box', 1.0)) == 1.0:
            user.price_super = 10.0
            updated = True
        if float(user.price_box) == 1.0:
            user.price_box = 10.0
            updated = True
            
        if updated:
            user.save()
            count += 1
            print(f"Updated user: {user.username}")
    
    print(f"Total users updated: {count}")

if __name__ == "__main__":
    update_defaults()
