from django.db import models
from django.contrib.auth.models import AbstractUser
from django.utils import timezone
from decimal import Decimal

class User(AbstractUser):
    ROLE_CHOICES = (
        ('SUPER_ADMIN', 'Super Admin'),
        ('ADMIN', 'Admin'),
        ('AGENT', 'Agent'),
        ('DEALER', 'Dealer'),
        ('SUB_DEALER', 'Sub Dealer'),
    )
    role = models.CharField(max_length=20, choices=ROLE_CHOICES, default='SUB_DEALER')
    parent = models.ForeignKey('self', on_delete=models.SET_NULL, null=True, blank=True, related_name='subordinates')
    weekly_credit_limit = models.DecimalField(max_digits=12, decimal_places=2, default=0.00)
    is_blocked = models.BooleanField(default=False)
    is_default = models.BooleanField(default=False)
    allowed_games = models.ManyToManyField('Game', blank=True, related_name='allowed_users')

    def get_descendant_ids(self):
        """Returns a list of IDs for all descendants (children, grandchildren, etc.) including self."""
        descendants = [self.id]
        for child in self.subordinates.all():
            descendants.extend(child.get_descendant_ids())
        return descendants

    def get_weekly_net_loss(self):
        """Calculates the net loss (sales - wins) for this user and all their descendants for the current week."""
        from .models import Bet
        from django.db.models import Sum, F
        
        # Calculate used credit for the current week (local monday to sunday)
        now = timezone.localtime()
        start_of_week = now.date() - timezone.timedelta(days=now.weekday())
        
        descendant_ids = self.get_descendant_ids()
        stats = Bet.objects.filter(
            user_id__in=descendant_ids,
            created_at__date__gte=start_of_week
        ).aggregate(
            sales=Sum(F('amount') * F('count')),
            wins=Sum('winning_amount')
        )
        sales = stats['sales'] or Decimal('0.00')
        wins = stats['wins'] or Decimal('0.00')
        return sales - wins

    def get_ancestors(self):
        """Returns a list of all ancestor User objects up to the root."""
        ancestors = []
        curr = self.parent
        while curr:
            ancestors.append(curr)
            curr = curr.parent
        return ancestors

    # Granular Count Limits (per game)
    count_a = models.IntegerField(default=0)
    count_b = models.IntegerField(default=0)
    count_c = models.IntegerField(default=0)
    count_ab = models.IntegerField(default=0)
    count_bc = models.IntegerField(default=0)
    count_ac = models.IntegerField(default=0)
    count_super = models.IntegerField(default=0)
    count_box = models.IntegerField(default=0)
    # Consolidated prices per unit
    price_abc = models.DecimalField(max_digits=10, decimal_places=2, default=12.00)
    price_ab_bc_ac = models.DecimalField(max_digits=10, decimal_places=2, default=10.00)
    price_super = models.DecimalField(max_digits=10, decimal_places=2, default=10.00)
    price_box = models.DecimalField(max_digits=10, decimal_places=2, default=10.00)

    # Prize and Commission Settings
    # LSK SUPER
    prize_super_1 = models.DecimalField(max_digits=10, decimal_places=2, default=5000.0)
    comm_super_1 = models.DecimalField(max_digits=10, decimal_places=2, default=400.0)
    prize_super_2 = models.DecimalField(max_digits=10, decimal_places=2, default=500.0)
    comm_super_2 = models.DecimalField(max_digits=10, decimal_places=2, default=50.0)
    prize_super_3 = models.DecimalField(max_digits=10, decimal_places=2, default=250.0)
    comm_super_3 = models.DecimalField(max_digits=10, decimal_places=2, default=20.0)
    prize_super_4 = models.DecimalField(max_digits=10, decimal_places=2, default=100.0)
    comm_super_4 = models.DecimalField(max_digits=10, decimal_places=2, default=20.0)
    prize_super_5 = models.DecimalField(max_digits=10, decimal_places=2, default=50.0)
    comm_super_5 = models.DecimalField(max_digits=10, decimal_places=2, default=20.0)
    
    # COMPLIMENTS (6th Prize)
    prize_6th = models.DecimalField(max_digits=10, decimal_places=2, default=20.0)
    comm_6th = models.DecimalField(max_digits=10, decimal_places=2, default=10.0)
    
    # AB/BC/AC
    prize_ab_bc_ac_1 = models.DecimalField(max_digits=10, decimal_places=2, default=700.0)
    comm_ab_bc_ac_1 = models.DecimalField(max_digits=10, decimal_places=2, default=30.0)
    
    # A/B/C
    prize_abc_1 = models.DecimalField(max_digits=10, decimal_places=2, default=100.0)
    comm_abc_1 = models.DecimalField(max_digits=10, decimal_places=2, default=0.0)
    
    # BOX
    prize_box_3d_1 = models.DecimalField(max_digits=10, decimal_places=2, default=3000.0)
    comm_box_3d_1 = models.DecimalField(max_digits=10, decimal_places=2, default=300.0)
    prize_box_3d_2 = models.DecimalField(max_digits=10, decimal_places=2, default=800.0)
    comm_box_3d_2 = models.DecimalField(max_digits=10, decimal_places=2, default=30.0)
    
    prize_box_2s_1 = models.DecimalField(max_digits=10, decimal_places=2, default=3800.0)
    comm_box_2s_1 = models.DecimalField(max_digits=10, decimal_places=2, default=330.0)
    prize_box_2s_2 = models.DecimalField(max_digits=10, decimal_places=2, default=1600.0)
    comm_box_2s_2 = models.DecimalField(max_digits=10, decimal_places=2, default=60.0)
    
    prize_box_3s_1 = models.DecimalField(max_digits=10, decimal_places=2, default=7000.0)
    comm_box_3s_1 = models.DecimalField(max_digits=10, decimal_places=2, default=450.0)

    # Sales Commission Settings
    sales_comm_super = models.DecimalField(max_digits=10, decimal_places=2, default=0.00)
    sales_comm_abc = models.DecimalField(max_digits=10, decimal_places=2, default=0.00)
    sales_comm_ab_bc_ac = models.DecimalField(max_digits=10, decimal_places=2, default=0.00)
    sales_comm_box = models.DecimalField(max_digits=10, decimal_places=2, default=0.00)

    def __str__(self):
        return f"{self.username} ({self.role})"

class Game(models.Model):
    name = models.CharField(max_length=100)
    time = models.TimeField()
    start_time = models.TimeField(default='00:00:00')
    end_time = models.TimeField(default='23:59:59')
    color = models.CharField(max_length=20, default='#2C3E50')
    is_active = models.BooleanField(default=True)
    can_edit_delete = models.BooleanField(default=True)
    edit_delete_limit_time = models.TimeField(default='23:59:59')
    created_at = models.DateTimeField(auto_now_add=True)

    # Global Count Limits (per type)
    global_count_a = models.IntegerField(default=0)
    global_count_b = models.IntegerField(default=0)
    global_count_c = models.IntegerField(default=0)
    global_count_ab = models.IntegerField(default=0)
    global_count_bc = models.IntegerField(default=0)
    global_count_ac = models.IntegerField(default=0)
    global_count_super = models.IntegerField(default=0)
    global_count_box = models.IntegerField(default=0)

    def __str__(self):
        return f"{self.name} - {self.time}"

class Bet(models.Model):
    TYPE_CHOICES = (
        ('A', 'A'),
        ('B', 'B'),
        ('C', 'C'),
        ('AB', 'AB'),
        ('BC', 'BC'),
        ('AC', 'AC'),
        ('SUPER', 'SUPER'),
        ('BOX', 'BOX'),
    )
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='bets')
    game = models.ForeignKey(Game, on_delete=models.CASCADE, related_name='bets')
    number = models.CharField(max_length=3)
    amount = models.DecimalField(max_digits=10, decimal_places=2) # Price per count
    count = models.IntegerField(default=1) 
    type = models.CharField(max_length=10, choices=TYPE_CHOICES)
    invoice_id = models.CharField(max_length=8, blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)
    is_winner = models.BooleanField(null=True, blank=True)
    winning_amount = models.DecimalField(max_digits=12, decimal_places=2, default=0.00)
    winning_commission = models.DecimalField(max_digits=12, decimal_places=2, default=0.00)
    winning_prize_type = models.CharField(max_length=200, blank=True, null=True)

    def __str__(self):
        return f"{self.user.username} - {self.number} - {self.amount}"

class GameResult(models.Model):
    game = models.ForeignKey(Game, on_delete=models.CASCADE, related_name='results')
    date = models.DateField(default=timezone.now)
    winning_number = models.CharField(max_length=3, help_text="1st Prize")
    second_prize = models.CharField(max_length=3, blank=True, null=True)
    third_prize = models.CharField(max_length=3, blank=True, null=True)
    fourth_prize = models.CharField(max_length=3, blank=True, null=True)
    fifth_prize = models.CharField(max_length=3, blank=True, null=True)
    complimentary_numbers = models.TextField(blank=True, null=True, help_text="Paste 30 complimentary numbers here")
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ('game', 'date')

    def __str__(self):
        return f"{self.game.name} - {self.date} - {self.winning_number}"

class NumberLimit(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='number_limits', default=1)
    game = models.ForeignKey(Game, on_delete=models.CASCADE, related_name='number_limits')
    number = models.CharField(max_length=3)
    type = models.CharField(max_length=10, choices=Bet.TYPE_CHOICES)
    max_count = models.IntegerField(default=50) # Max allowed bets for this specific number

    class Meta:
        unique_together = ('user', 'game', 'number', 'type')

    def __str__(self):
        return f"{self.user.username} | {self.game.name} | {self.type} | {self.number} | Limit: {self.max_count}"

class GlobalNumberLimit(models.Model):
    # Null admin means system-wide global limit (Super Admin)
    admin = models.ForeignKey(User, on_delete=models.CASCADE, related_name='global_number_limits', null=True, blank=True)
    game = models.ForeignKey(Game, on_delete=models.CASCADE, related_name='global_number_limits')
    number = models.CharField(max_length=3)
    type = models.CharField(max_length=10, choices=Bet.TYPE_CHOICES)
    max_count = models.IntegerField(default=50)

    class Meta:
        unique_together = ('admin', 'game', 'number', 'type')

    def __str__(self):
        owner = self.admin.username if self.admin else "GLOBAL"
        return f"{owner} | {self.game.name} | {self.type} | {self.number} | Limit: {self.max_count}"

class ClearedExposure(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='cleared_exposures')
    game = models.ForeignKey(Game, on_delete=models.CASCADE, related_name='cleared_exposures')
    number = models.CharField(max_length=3)
    type = models.CharField(max_length=10, choices=Bet.TYPE_CHOICES)
    date = models.DateField(default=timezone.now)
    count = models.IntegerField(default=0)

    class Meta:
        unique_together = ('user', 'game', 'number', 'type', 'date')

    def __str__(self):
        return f"{self.user.username} | {self.game.name} | {self.number} | {self.date} | Cleared: {self.count}"
class UserGameTiming(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='game_timings')
    game = models.ForeignKey(Game, on_delete=models.CASCADE, related_name='user_timings')
    start_time = models.TimeField()
    end_time = models.TimeField()

    class Meta:
        unique_together = ('user', 'game')

    def __str__(self):
        return f"{self.user.username} | {self.game.name} | {self.start_time} - {self.end_time}"
class SystemSettings(models.Model):
    can_edit_delete_invoice = models.BooleanField(default=True)
    edit_delete_limit_time = models.TimeField(default='23:59:59')
    
    def __str__(self):
        return "System Settings"
