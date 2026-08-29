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
        to_check = [self.id]
        visited = {self.id}
        while to_check:
            # Fetch next level of children
            children = User.objects.filter(parent_id__in=to_check).values_list('id', flat=True)
            # Filter out already visited to prevent infinite loops
            new_children = [c for c in children if c not in visited]
            if not new_children:
                break
            descendants.extend(new_children)
            visited.update(new_children)
            to_check = new_children
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

    # TN Granular Count Limits
    tn_count_a = models.IntegerField(default=0)
    tn_count_b = models.IntegerField(default=0)
    tn_count_c = models.IntegerField(default=0)
    tn_count_ab = models.IntegerField(default=0)
    tn_count_bc = models.IntegerField(default=0)
    tn_count_ac = models.IntegerField(default=0)
    tn_count_3d_10 = models.IntegerField(default=0)
    tn_count_3d_25 = models.IntegerField(default=0)
    tn_count_3d_30 = models.IntegerField(default=0)
    tn_count_3d_60 = models.IntegerField(default=0)
    tn_count_4d_110 = models.IntegerField(default=0)
    tn_count_4d_55 = models.IntegerField(default=0)
    tn_count_4d_20 = models.IntegerField(default=0)
    # Consolidated prices per unit
    price_abc = models.DecimalField(max_digits=10, decimal_places=2, default=12.00)
    price_ab_bc_ac = models.DecimalField(max_digits=10, decimal_places=2, default=10.00)
    price_super = models.DecimalField(max_digits=10, decimal_places=2, default=10.00)
    price_box = models.DecimalField(max_digits=10, decimal_places=2, default=10.00)

    # TN Consolidated prices per unit
    tn_price_abc = models.DecimalField(max_digits=10, decimal_places=2, default=12.00)
    tn_price_ab_bc_ac = models.DecimalField(max_digits=10, decimal_places=2, default=10.00)
    tn_price_3d_10 = models.DecimalField(max_digits=10, decimal_places=2, default=10.00)
    tn_price_3d_25 = models.DecimalField(max_digits=10, decimal_places=2, default=25.00)
    tn_price_3d_30 = models.DecimalField(max_digits=10, decimal_places=2, default=30.00)
    tn_price_3d_60 = models.DecimalField(max_digits=10, decimal_places=2, default=60.00)
    tn_price_4d_110 = models.DecimalField(max_digits=10, decimal_places=2, default=110.00)
    tn_price_4d_55 = models.DecimalField(max_digits=10, decimal_places=2, default=55.00)
    tn_price_4d_20 = models.DecimalField(max_digits=10, decimal_places=2, default=20.00)

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

    # TN Sales Commission Settings
    tn_sales_comm_abc = models.DecimalField(max_digits=10, decimal_places=2, default=0.00)
    tn_sales_comm_ab_bc_ac = models.DecimalField(max_digits=10, decimal_places=2, default=0.00)
    tn_sales_comm_3d_10 = models.DecimalField(max_digits=10, decimal_places=2, default=0.00)
    tn_sales_comm_3d_25 = models.DecimalField(max_digits=10, decimal_places=2, default=0.00)
    tn_sales_comm_3d_30 = models.DecimalField(max_digits=10, decimal_places=2, default=0.00)
    tn_sales_comm_3d_60 = models.DecimalField(max_digits=10, decimal_places=2, default=0.00)
    tn_sales_comm_4d_110 = models.DecimalField(max_digits=10, decimal_places=2, default=0.00)
    tn_sales_comm_4d_55 = models.DecimalField(max_digits=10, decimal_places=2, default=0.00)
    tn_sales_comm_4d_20 = models.DecimalField(max_digits=10, decimal_places=2, default=0.00)

    # TN Prize Settings
    tn_prize_abc = models.DecimalField(max_digits=10, decimal_places=2, default=1000.0)
    tn_prize_ab_bc_ac = models.DecimalField(max_digits=10, decimal_places=2, default=1000.0)
    tn_prize_3d_10 = models.DecimalField(max_digits=10, decimal_places=2, default=5000.0)
    tn_prize_3d_10_bc = models.DecimalField(max_digits=10, decimal_places=2, default=100.0)
    tn_prize_3d_25 = models.DecimalField(max_digits=10, decimal_places=2, default=10000.0)
    tn_prize_3d_25_bc = models.DecimalField(max_digits=10, decimal_places=2, default=1000.0)
    tn_prize_3d_30 = models.DecimalField(max_digits=10, decimal_places=2, default=15000.0)
    tn_prize_3d_30_bc = models.DecimalField(max_digits=10, decimal_places=2, default=500.0)
    tn_prize_3d_30_c = models.DecimalField(max_digits=10, decimal_places=2, default=50.0)
    tn_prize_3d_60 = models.DecimalField(max_digits=10, decimal_places=2, default=30000.0)
    tn_prize_3d_60_bc = models.DecimalField(max_digits=10, decimal_places=2, default=1000.0)
    tn_prize_3d_60_c = models.DecimalField(max_digits=10, decimal_places=2, default=100.0)
    tn_prize_4d_110_1 = models.DecimalField(max_digits=10, decimal_places=2, default=450000.0)
    tn_prize_4d_110_2 = models.DecimalField(max_digits=10, decimal_places=2, default=10000.0)
    tn_prize_4d_110_3 = models.DecimalField(max_digits=10, decimal_places=2, default=1000.0)
    tn_prize_4d_110_4 = models.DecimalField(max_digits=10, decimal_places=2, default=100.0)
    tn_prize_4d_55_1 = models.DecimalField(max_digits=10, decimal_places=2, default=225000.0)
    tn_prize_4d_55_2 = models.DecimalField(max_digits=10, decimal_places=2, default=5000.0)
    tn_prize_4d_55_3 = models.DecimalField(max_digits=10, decimal_places=2, default=500.0)
    tn_prize_4d_55_4 = models.DecimalField(max_digits=10, decimal_places=2, default=50.0)
    tn_prize_4d_20_1 = models.DecimalField(max_digits=10, decimal_places=2, default=100000.0)

    def __str__(self):
        return f"{self.username} ({self.role})"

class Game(models.Model):
    name = models.CharField(max_length=100)
    time = models.TimeField()
    start_time = models.TimeField(default='00:00:00')
    end_time = models.TimeField(default='23:59:59')
    color = models.CharField(max_length=20, default='#2C3E50')
    options_bg_color = models.CharField(max_length=20, default='#FFFFFF')
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

    # TN Global Count Limits
    global_tn_count_a = models.IntegerField(default=0)
    global_tn_count_b = models.IntegerField(default=0)
    global_tn_count_c = models.IntegerField(default=0)
    global_tn_count_ab = models.IntegerField(default=0)
    global_tn_count_bc = models.IntegerField(default=0)
    global_tn_count_ac = models.IntegerField(default=0)
    global_tn_count_3d_10 = models.IntegerField(default=0)
    global_tn_count_3d_25 = models.IntegerField(default=0)
    global_tn_count_3d_30 = models.IntegerField(default=0)
    global_tn_count_3d_60 = models.IntegerField(default=0)
    global_tn_count_4d_110 = models.IntegerField(default=0)
    global_tn_count_4d_55 = models.IntegerField(default=0)
    global_tn_count_4d_20 = models.IntegerField(default=0)

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
        ('TN-A', 'TN-A'),
        ('TN-B', 'TN-B'),
        ('TN-C', 'TN-C'),
        ('TN-AB', 'TN-AB'),
        ('TN-BC', 'TN-BC'),
        ('TN-AC', 'TN-AC'),
        ('3D-10', '3D-10'),
        ('3D-25', '3D-25'),
        ('3D-30', '3D-30'),
        ('3D-60', '3D-60'),
        ('4D-110', '4D-110'),
        ('4D-55', '4D-55'),
        ('4D-20', '4D-20'),
        ('SUPER', 'SUPER'),
        ('BOX', 'BOX'),
    )
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='bets')
    game = models.ForeignKey(Game, on_delete=models.CASCADE, related_name='bets')
    number = models.CharField(max_length=10)
    amount = models.DecimalField(max_digits=10, decimal_places=2) # Price per count
    count = models.IntegerField(default=1)
    type = models.CharField(max_length=10, choices=TYPE_CHOICES)
    state = models.CharField(max_length=5, default='KL')
    invoice_id = models.CharField(max_length=8, blank=True, null=True)
    customer_name = models.CharField(max_length=100, blank=True, null=True)
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
    winning_number = models.CharField(max_length=10, help_text="1st Prize")
    second_prize = models.CharField(max_length=10, blank=True, null=True)
    third_prize = models.CharField(max_length=10, blank=True, null=True)
    fourth_prize = models.CharField(max_length=10, blank=True, null=True)
    fifth_prize = models.CharField(max_length=10, blank=True, null=True)
    complimentary_numbers = models.TextField(blank=True, null=True, help_text="Paste 30 complimentary numbers here")
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ('game', 'date')

    def __str__(self):
        return f"{self.game.name} - {self.date} - {self.winning_number}"

class NumberLimit(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='number_limits', default=1)
    game = models.ForeignKey(Game, on_delete=models.CASCADE, related_name='number_limits')
    number = models.CharField(max_length=10)
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
    number = models.CharField(max_length=10)
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
    number = models.CharField(max_length=10)
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


class ForwardLimit(models.Model):
    # This limit is set BY an admin FOR their branch
    admin = models.ForeignKey(User, on_delete=models.CASCADE, related_name='forward_limits')
    game = models.ForeignKey(Game, on_delete=models.CASCADE)
    type = models.CharField(max_length=10, choices=Bet.TYPE_CHOICES)
    number = models.CharField(max_length=10, blank=True, null=True, help_text="Optional: If blank, applies to all numbers of this type")
    max_retained_count = models.IntegerField(default=100) # Amount kept by admin, excess is forwarded
    state = models.CharField(max_length=5, default='KL')
    
    class Meta:
        unique_together = ('admin', 'game', 'type', 'state', 'number')

    def __str__(self):
        num_str = f" | Num: {self.number}" if self.number else " | All Nums"
        return f"{self.admin.username} | {self.game.name} | {self.state} {self.type}{num_str} | Retain: {self.max_retained_count}"

class ForwardedBet(models.Model):
    # Who is forwarding to whom
    forwarded_by = models.ForeignKey(User, related_name='forwarded_out', on_delete=models.CASCADE)
    forwarded_to = models.ForeignKey(User, related_name='forwarded_in', on_delete=models.CASCADE)
    
    # Details of the forwarded count
    game = models.ForeignKey(Game, on_delete=models.CASCADE)
    state = models.CharField(max_length=5, default='KL')
    type = models.CharField(max_length=10, choices=Bet.TYPE_CHOICES)
    number = models.CharField(max_length=10)
    count = models.IntegerField()
    
    # Financials (At what price/commission was it forwarded?)
    # When Admin forwards to Super Admin, Super Admin "sells" it to Admin at Admin's wholesale price.
    # Therefore, Admin receives commission on this forwarded bet just like a normal sale to a subordinate.
    # We store the total sales value (price_per_count * count) and total commission (comm_per_count * count)
    price_per_count = models.DecimalField(max_digits=10, decimal_places=2, default=0.00)
    comm_per_count = models.DecimalField(max_digits=10, decimal_places=2, default=0.00)
    
    created_at = models.DateTimeField(auto_now_add=True)
    date = models.DateField(default=timezone.now)
    is_auto = models.BooleanField(default=False)
    
    is_winner = models.BooleanField(null=True, blank=True)
    winning_amount = models.DecimalField(max_digits=12, decimal_places=2, default=0.00)
    winning_prize_type = models.CharField(max_length=200, null=True, blank=True)

    def __str__(self):
        auto_str = "AUTO" if self.is_auto else "MANUAL"
        return f"[{auto_str}] {self.forwarded_by.username} -> {self.forwarded_to.username} | {self.number} ({self.count})"
