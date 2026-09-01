from rest_framework import viewsets, permissions, status, views, serializers
from rest_framework.response import Response
from rest_framework.decorators import action
from rest_framework.authtoken.models import Token
from django.contrib.auth import authenticate
from django.db.models import Sum, Q, F, Count, Max, When, Case, Value, CharField
from .models import (
    ForwardLimit, ForwardedBet,
    User, Game, Bet, GameResult, NumberLimit,
    GlobalNumberLimit, ClearedExposure, UserGameTiming, SystemSettings
)
from .serializers import (
    UserSerializer, GameSerializer, BetSerializer,
    GameResultSerializer, NumberLimitSerializer, GlobalNumberLimitSerializer,
    UserGameTimingSerializer, SystemSettingsSerializer
)
from django.utils import timezone
from datetime import datetime
from decimal import Decimal
import random
import string

def get_user_type_count_limit(user, bet_type):
    if not user:
        return 0
    bt = str(bet_type).upper().replace('_', '-')
    mapping = {
        'A': getattr(user, 'count_a', 0),
        'B': getattr(user, 'count_b', 0),
        'C': getattr(user, 'count_c', 0),
        'AB': getattr(user, 'count_ab', 0),
        'BC': getattr(user, 'count_bc', 0),
        'AC': getattr(user, 'count_ac', 0),
        'SUPER': getattr(user, 'count_super', 0),
        'BOX': getattr(user, 'count_box', 0),
        'TN-A': getattr(user, 'tn_count_a', 0),
        'TN-B': getattr(user, 'tn_count_b', 0),
        'TN-C': getattr(user, 'tn_count_c', 0),
        'TN-AB': getattr(user, 'tn_count_ab', 0),
        'TN-BC': getattr(user, 'tn_count_bc', 0),
        'TN-AC': getattr(user, 'tn_count_ac', 0),
        '3D-10': getattr(user, 'tn_count_3d_10', 0),
        '3D-25': getattr(user, 'tn_count_3d_25', 0),
        '3D-30': getattr(user, 'tn_count_3d_30', 0),
        '3D-60': getattr(user, 'tn_count_3d_60', 0),
        '4D-110': getattr(user, 'tn_count_4d_110', 0),
        '4D-55': getattr(user, 'tn_count_4d_55', 0),
        '4D-20': getattr(user, 'tn_count_4d_20', 0),
    }
    return mapping.get(bt, 0)

def get_game_global_type_count_limit(game, bet_type):
    if not game:
        return 0
    bt = str(bet_type).upper().replace('_', '-')
    mapping = {
        'A': getattr(game, 'global_count_a', 0),
        'B': getattr(game, 'global_count_b', 0),
        'C': getattr(game, 'global_count_c', 0),
        'AB': getattr(game, 'global_count_ab', 0),
        'BC': getattr(game, 'global_count_bc', 0),
        'AC': getattr(game, 'global_count_ac', 0),
        'SUPER': getattr(game, 'global_count_super', 0),
        'BOX': getattr(game, 'global_count_box', 0),
        'TN-A': getattr(game, 'global_tn_count_a', 0),
        'TN-B': getattr(game, 'global_tn_count_b', 0),
        'TN-C': getattr(game, 'global_tn_count_c', 0),
        'TN-AB': getattr(game, 'global_tn_count_ab', 0),
        'TN-BC': getattr(game, 'global_tn_count_bc', 0),
        'TN-AC': getattr(game, 'global_tn_count_ac', 0),
        '3D-10': getattr(game, 'global_tn_count_3d_10', 0),
        '3D-25': getattr(game, 'global_tn_count_3d_25', 0),
        '3D-30': getattr(game, 'global_tn_count_3d_30', 0),
        '3D-60': getattr(game, 'global_tn_count_3d_60', 0),
        '4D-110': getattr(game, 'global_tn_count_4d_110', 0),
        '4D-55': getattr(game, 'global_tn_count_4d_55', 0),
        '4D-20': getattr(game, 'global_tn_count_4d_20', 0),
    }
    return mapping.get(bt, 0)

def get_excluded_forwarding_user_ids():
    """Returns set of all descendant IDs for Admins where can_forward=True."""
    excluded = set()
    for f_admin in User.objects.filter(role='ADMIN', can_forward=True):
        excluded.update(f_admin.get_descendant_ids())
    return excluded

class IsSuperAdmin(permissions.BasePermission):
    def has_permission(self, request, view):
        return request.user.is_authenticated and request.user.role == 'SUPER_ADMIN'

class IsAdminOrSuperAdmin(permissions.BasePermission):
    def has_permission(self, request, view):
        return request.user.is_authenticated and request.user.role in ['SUPER_ADMIN', 'ADMIN']

class UserViewSet(viewsets.ModelViewSet):
    serializer_class = UserSerializer

    def get_queryset(self):
        user = self.request.user
        if not user.is_authenticated:
            return User.objects.none()
        if user.role == 'SUPER_ADMIN':
            return User.objects.all()
        # Non-SuperAdmin sees only their entire branch (descendants + self)
        descendants = user.get_descendant_ids()
        qs = User.objects.filter(id__in=descendants)
        
        # Optional filter: Only show users DIRECTLY created by the current user
        if self.request.query_params.get('created_by_me') == 'true':
            qs = qs.filter(parent=user)
            
        return qs

    @action(detail=False, methods=['get'])
    def me(self, request):
        serializer = self.get_serializer(request.user)
        return Response(serializer.data)

    @action(detail=False, methods=['post'], url_path='change-password')
    def change_password(self, request):
        user = request.user
        old_password = request.data.get('old_password')
        new_password = request.data.get('new_password')
        
        if not user.check_password(old_password):
            return Response({'error': 'Incorrect current password'}, status=status.HTTP_400_BAD_REQUEST)
        
        user.set_password(new_password)
        user.save()
        return Response({'success': 'Password changed successfully'})

    def perform_create(self, serializer):
        from rest_framework import serializers as drf_serializers
        creator = self.request.user
        target_role = serializer.validated_data.get('role')
        
        # Role Hierarchy validation
        if creator.role != 'SUPER_ADMIN':
            if creator.role == 'ADMIN':
                if target_role not in ['AGENT', 'DEALER', 'SUB_DEALER']:
                     raise drf_serializers.ValidationError("You can only create users with the AGENT, DEALER, or SUB_DEALER role.")
            elif creator.role == 'AGENT':
                if target_role not in ['DEALER', 'SUB_DEALER']:
                     raise drf_serializers.ValidationError("You can only create users with the DEALER or SUB_DEALER role.")
            elif creator.role == 'DEALER':
                if target_role != 'SUB_DEALER':
                     raise drf_serializers.ValidationError("You can only create users with the SUB_DEALER role.")

        instance = serializer.save(parent=creator)
        if instance.is_default:
            # Reset others under same parent
            User.objects.filter(parent=creator, is_default=True).exclude(id=instance.id).update(is_default=False)

    def perform_update(self, serializer):
        instance = serializer.save()
        if instance.is_default and instance.parent:
            # Reset others under same parent
            User.objects.filter(parent=instance.parent, is_default=True).exclude(id=instance.id).update(is_default=False)

class LoginView(views.APIView):
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        username = request.data.get('username')
        password = request.data.get('password')
        
        if not username or not password:
            return Response({'error': 'Please provide both username and password'}, status=status.HTTP_400_BAD_REQUEST)
            
        user = authenticate(username=username, password=password)
        if user:
            if not user.is_active:
                return Response({'error': 'Account is disabled'}, status=status.HTTP_403_FORBIDDEN)
            if user.is_blocked or any(p.is_blocked for p in user.get_ancestors()):
                return Response({'error': 'Account Blocked'}, status=status.HTTP_403_FORBIDDEN)
                
            token, _ = Token.objects.get_or_create(user=user)
            return Response({
                'token': token.key,
                'user': UserSerializer(user).data
            })
        
        # Check if user exists but password matches (for better error msg)
        user_exists = User.objects.filter(username=username).exists()
        if user_exists:
            return Response({'error': 'Incorrect password'}, status=status.HTTP_400_BAD_REQUEST)
        return Response({'error': 'User not found'}, status=status.HTTP_400_BAD_REQUEST)

class SystemSettingsViewSet(viewsets.ModelViewSet):
    queryset = SystemSettings.objects.all()
    serializer_class = SystemSettingsSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        # Ensure at least one settings object exists
        if not SystemSettings.objects.exists():
            SystemSettings.objects.create()
        return SystemSettings.objects.all()
    
    def list(self, request, *args, **kwargs):
        # Return only the single settings object
        settings = self.get_queryset().first()
        serializer = self.get_serializer(settings)
        return Response(serializer.data)

    @action(detail=False, methods=['post'], url_path='update-settings')
    def update_settings(self, request):
        if request.user.role != 'SUPER_ADMIN':
            return Response({'error': 'Only Super Admin can update system settings'}, status=status.HTTP_403_FORBIDDEN)
        
        settings = self.get_queryset().first()
        serializer = self.get_serializer(settings, data=request.data, partial=True)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

class GameViewSet(viewsets.ModelViewSet):
    serializer_class = GameSerializer

    def get_queryset(self):
        qs = Game.objects.filter(is_active=True).order_by('time')
        user = self.request.user
        
        # Super Admins always see all active games
        if getattr(user, 'role', None) == 'SUPER_ADMIN':
            return qs
            
        # Other authenticated users see only games they have explicitly been allowed
        # (Default new users have all games assigned via creation script/logic)
        if user.is_authenticated:
            return qs.filter(id__in=user.allowed_games.values_list('id', flat=True))
        return Game.objects.none()

    def get_permissions(self):
        if self.action in ['create', 'update', 'partial_update', 'destroy']:
            return [IsAdminOrSuperAdmin()]
        return [permissions.IsAuthenticated()]

class BetViewSet(viewsets.ModelViewSet):
    queryset = Bet.objects.all()
    serializer_class = BetSerializer

    def get_queryset(self):
        user = self.request.user
        queryset = Bet.objects.all()
        
        # Filter by game if provided
        game_id = self.request.query_params.get('game')
        if game_id:
            queryset = queryset.filter(game_id=game_id)

        if user.role in ['SUPER_ADMIN', 'ADMIN']:
            descendants = user.get_descendant_ids()
            queryset = queryset.filter(user__id__in=descendants).order_by('-created_at')
        else:
            # For lower roles (Agent/Dealer/Sub-dealer), only show their own bets in the recent list for speed
            queryset = queryset.filter(user=user).order_by('-created_at')
            
        if self.action == 'list':
            return queryset[:100]
        return queryset

    def perform_create(self, serializer):
        from rest_framework import serializers as drf_serializers
        user = self.request.user
        if user.is_blocked or any(p.is_blocked for p in user.get_ancestors()):
            raise drf_serializers.ValidationError("Account Blocked")
        game = serializer.validated_data['game']
        bet_type = serializer.validated_data['type']
        
        # Prices per unit from consolidated groups
        price_map = {
            'A': user.price_abc,
            'B': user.price_abc,
            'C': user.price_abc,
            'AB': user.price_ab_bc_ac,
            'BC': user.price_ab_bc_ac,
            'AC': user.price_ab_bc_ac,
            'SUPER': user.price_super,
            'BOX': user.price_box,
        }
        amount = Decimal(str(price_map.get(bet_type, 1.0)))
        count = serializer.validated_data.get('count', 1)
        total_bet_amount = amount * count

        # 1. Check Betting Window (User-specific or Global)
        current_time = timezone.localtime().time()
        
        start_t = game.start_time
        end_t = game.end_time
        
        hierarchy = [user] + user.get_ancestors()
        
        # Check hierarchy for User-specific timing override (closest ancestor wins)
        for p in hierarchy:
            timing = UserGameTiming.objects.filter(user=p, game=game).first()
            if timing:
                start_t = timing.start_time
                end_t = timing.end_time
                break

        if current_time < start_t or current_time > end_t:
             raise drf_serializers.ValidationError(
                 f"Betting for {game.name} is only allowed between "
                 f"{start_t.strftime('%I:%M %p')} and {end_t.strftime('%I:%M %p')}."
             )

        # 1.5 Individual User-Specific Limits are now handled in the hierarchy check

        # 1.7 Hierarchical Branch Limits (Individual -> Dealer -> Agent -> Admin -> System)
        
        # Determine if bet-placing user has specific individual limit
        has_specific_limit = NumberLimit.objects.filter(user=user, game=game, number=number, type=bet_type).exists()

        for p in hierarchy:
            # A. Branch-wide/User-specific Number Limit - Override
            gnl_q = Q(admin=p) if p.role != 'SUPER_ADMIN' else Q(admin__isnull=True)
            relevant_glims = list(GlobalNumberLimit.objects.filter(gnl_q, game=game, number=number, type=bet_type))
            
            try:
                p_lim = NumberLimit.objects.get(user=p, game=game, number=number, type=bet_type)
                class AttrDict:
                    def __init__(self, c): self.max_count = c
                relevant_glims.append(AttrDict(p_lim.max_count))
            except NumberLimit.DoesNotExist:
                pass
            
            has_branch_specific = len(relevant_glims) > 0

            for glim in relevant_glims:
                d_ids = p.get_descendant_ids()
                b_tot = Bet.objects.filter(
                    user__id__in=d_ids, game=game, number=number, type=bet_type,
                    created_at__date=timezone.localtime().date()
                ).aggregate(t=Sum('count'))['t'] or 0
                b_clr = ClearedExposure.objects.filter(
                    user__id__in=d_ids, game=game, number=number, type=bet_type,
                    date=timezone.localtime().date()
                ).aggregate(t=Sum('count'))['t'] or 0
                
                if (b_tot - b_clr + count) > glim.max_count:
                    label = p.username if p.role != 'SUPER_ADMIN' else "System"
                    raise drf_serializers.ValidationError(f"Total Limit Reached. {max(0, glim.max_count - (b_tot - b_clr))} Only")

            # B. Branch Type Limit (User.count_a, etc.) - Only check if no specific limit exists for this branch
            if not has_branch_specific:
                # If the target user has a specific Individual Number Limit (1.5), 
                # we skip all general branch type caps for this specific number.
                # This makes the User-Wise Number Limit the "Master Capacity" for that user.
                if has_specific_limit:
                    continue

                t_limit = get_user_type_count_limit(p, bet_type)
                if t_limit > 0:
                    d_ids = p.get_descendant_ids()
                    type_tot = Bet.objects.filter(
                        user__id__in=d_ids, game=game, number=number, type=bet_type,
                        created_at__date=timezone.localtime().date()
                    ).aggregate(t=Sum('count'))['t'] or 0
                    type_clr = ClearedExposure.objects.filter(
                        user__id__in=d_ids, game=game, number=number, type=bet_type,
                        date=timezone.localtime().date()
                    ).aggregate(t=Sum('count'))['t'] or 0
                    
                    if (type_tot - type_clr + count) > t_limit:
                        label = p.username if p.role != 'SUPER_ADMIN' else "System"
                        raise drf_serializers.ValidationError(f"Total Limit Reached. {max(0, t_limit - (type_tot - type_clr))} Only")

        # 1.8 System-wide Global Type Limit (from Game model)
        # Only check if no system-wide GlobalNumberLimit exists for this number
        system_gnl_exists = GlobalNumberLimit.objects.filter(admin__isnull=True, game=game, number=number, type=bet_type).exists()
        
        if not system_gnl_exists:
            game_type_limit = get_game_global_type_count_limit(game, bet_type)
            if game_type_limit > 0:
                total_type_count = Bet.objects.filter(
                    game=game, type=bet_type, number=number,
                    created_at__date=timezone.localtime().date()
                ).aggregate(total=Sum('count'))['total'] or 0
                
                total_type_cleared = ClearedExposure.objects.filter(
                    game=game, type=bet_type, number=number, date=timezone.localtime().date()
                ).aggregate(total=Sum('count'))['total'] or 0
    
                if (total_type_count - total_type_cleared + count) > game_type_limit:
                     raise drf_serializers.ValidationError(f"Total Limit Reached. {max(0, game_type_limit - (total_type_count - total_type_cleared))} Only")

        # 3. Check Weekly Credit Limit Hierarchically
        for p in hierarchy:
            if p.role == 'SUPER_ADMIN':
                continue
                
            p_net_loss = p.get_weekly_net_loss()
            if (p_net_loss + total_bet_amount) > p.weekly_credit_limit:
                available = p.weekly_credit_limit - p_net_loss
                label = "Your" if p == user else f"{p.username}'s"
                raise drf_serializers.ValidationError(f"{label} Weekly credit limit exceeded. Available: ₹{max(0, available):.2f}")

        # Save the bet
        serializer.save(user=user, amount=amount)

    @action(detail=False, methods=['post'], url_path='bulk-create')
    def bulk_create(self, request):
        requested_user = request.user
        target_user_id = request.data.get('user_id')
        
        # Determine which user is actually placing the bet
        if target_user_id:
            try:
                target_user = User.objects.get(id=target_user_id)
                # Security check: Any management role (SuperAdmin/Admin/Agent/Dealer) 
                # can place bets for themselves or their entire downline branch.
                if requested_user.role != 'SUPER_ADMIN':
                    descendants = requested_user.get_descendant_ids()
                    if target_user.id not in descendants:
                        return Response({'error': 'Unauthorized to place bets for this user'}, status=status.HTTP_403_FORBIDDEN)
                user = target_user
            except User.DoesNotExist:
                return Response({'error': 'Target user not found'}, status=status.HTTP_404_NOT_FOUND)
        else:
            user = requested_user

        if requested_user.role == 'SUPER_ADMIN' or user.role == 'SUPER_ADMIN':
            return Response({'error': 'Super Admin cannot place bets'}, status=status.HTTP_400_BAD_REQUEST)

        if requested_user.is_blocked or any(p.is_blocked for p in requested_user.get_ancestors()):
            return Response({'error': 'Account Blocked'}, status=status.HTTP_403_FORBIDDEN)

        if user.is_blocked or any(p.is_blocked for p in user.get_ancestors()):
            return Response({'error': 'Account Blocked'}, status=status.HTTP_403_FORBIDDEN)

        bets_data = request.data.get('bets', [])
        customer_name = (request.data.get('customer_name') or '').strip()
        if not bets_data:
            return Response({'error': 'No bets provided'}, status=status.HTTP_400_BAD_REQUEST)
        
        # LOGGING
        print('BULK CREATE RECEIVED BETS:', bets_data)

        # Generate 8-digit Invoice ID (will only be used if we save at least one bet)
        invoice_id = ''.join(random.choices(string.digits, k=8))
        
        from rest_framework import serializers as drf_serializers
        

        
        # Calculate starting available credit for ALL hierarchy members
        hierarchy = [user] + user.get_ancestors()
        ancestor_credits = []
        for p in hierarchy:
            if p.role == 'SUPER_ADMIN':
                ancestor_credits.append((p, Decimal('999999999')))
            else:
                p_net_loss = p.get_weekly_net_loss()
                ancestor_credits.append((p, p.weekly_credit_limit - p_net_loss))

        created_bets_count = 0
        total_created_amount = Decimal('0.00')
        failed_bets = []
        
        # Track counts within THIS bulk request per LEVEL (User & Branches)
        session_branch_nos = {}
        session_branch_types = {}
        
        # Pre-fetch hierarchy info and descendant IDs once
        hierarchy_info = []
        for p in hierarchy:
            hierarchy_info.append({
                'user': p,
                'descendant_ids': p.get_descendant_ids(),
                'role': p.role,
                'id': p.id
            })
        
        today = timezone.localtime().date()
        
        for b_data in bets_data:
            try:
                game = Game.objects.get(id=b_data['game'])
            except Game.DoesNotExist:
                continue

            bet_type = b_data['type']
            count = b_data['count']
            number = b_data.get('number', '')
            state = b_data.get('state', 'KL')
            
            # FORCE TN STATE FOR TN TYPES
            if bet_type in ['3D-10', '3D-25', '3D-30', '3D-60', '4D-110', '4D-55', '4D-20']:
                state = 'TN'
            # For SUPER/BOX/A/B/C/AB/BC/AC, we trust the state provided by frontend.

            
            p_price_map = {
                'A': user.price_abc if state == 'KL' else getattr(user, 'tn_price_abc', 12.0),
                'B': user.price_abc if state == 'KL' else getattr(user, 'tn_price_abc', 12.0),
                'C': user.price_abc if state == 'KL' else getattr(user, 'tn_price_abc', 12.0),
                'AB': user.price_ab_bc_ac if state == 'KL' else getattr(user, 'tn_price_ab_bc_ac', 10.0),
                'BC': user.price_ab_bc_ac if state == 'KL' else getattr(user, 'tn_price_ab_bc_ac', 10.0),
                'AC': user.price_ab_bc_ac if state == 'KL' else getattr(user, 'tn_price_ab_bc_ac', 10.0),
                'SUPER': user.price_super,
                'BOX': user.price_box,
            }
            if state == 'TN':
                if bet_type == '3D-10': p_price_map['3D-10'] = getattr(user, 'tn_price_3d_10', 10.0)
                elif bet_type == '3D-25': p_price_map['3D-25'] = getattr(user, 'tn_price_3d_25', 25.0)
                elif bet_type == '3D-30': p_price_map['3D-30'] = getattr(user, 'tn_price_3d_30', 30.0)
                elif bet_type == '3D-60': p_price_map['3D-60'] = getattr(user, 'tn_price_3d_60', 60.0)
                elif bet_type == '4D-110': p_price_map['4D-110'] = getattr(user, 'tn_price_4d_110', 110.0)
                elif bet_type == '4D-55': p_price_map['4D-55'] = getattr(user, 'tn_price_4d_55', 55.0)
                elif bet_type == '4D-20': p_price_map['4D-20'] = getattr(user, 'tn_price_4d_20', 20.0)
                
            amount = Decimal(str(p_price_map.get(bet_type, 1.0)))
            
            # Skip if count is invalid
            if not isinstance(count, int) or count <= 0:
                continue

            # Helper to add to failed list
            def mark_failed(err_msg):
                failed_bets.append({
                    'game': game.name,
                    'number': number,
                    'type': bet_type,
                    'count': count,
                    'state': state,
                    'error': err_msg
                })

            # 1. Weekly Credit Limit Check (Hierarchical)
            limit_error = None
            bet_cost = Decimal(str(amount)) * Decimal(str(count))
            for p, avail in ancestor_credits:
                if (total_created_amount + bet_cost) > avail:
                    label = "Your" if p == user else f"{p.username}'s"
                    limit_error = f"{label} Credit limit exceeded (Avail: ₹{max(0, avail - total_created_amount):.2f})"
                    break
            
            if limit_error:
                mark_failed(limit_error)
                continue

            # 2. Check Betting Window
            current_time = timezone.localtime().time()
            start_t = game.start_time
            end_t = game.end_time
            
            for info in hierarchy_info:
                p = info['user']
                timing = UserGameTiming.objects.filter(user=p, game=game).first()
                if timing:
                    start_t = timing.start_time
                    end_t = timing.end_time
                    break

            if current_time < start_t or current_time > end_t:
                 mark_failed(f"Time: {start_t.strftime('%I:%M %p')} - {end_t.strftime('%I:%M %p')}")
                 continue
            
            # 3. Individual User-Specific Limit checks are now integrated into hierarchical Branch checks

            # 4. Hierarchical Branch Limits (includes individual user at index 0)
            limit_error = None
            
            # The user at index 0 has specific limit if their own NumberLimit exists
            has_specific_limit = NumberLimit.objects.filter(user=user, game=game, number=number, type=bet_type).exists()

            for info in hierarchy_info:
                p = info['user']
                d_ids = info['descendant_ids']
                
                # A. Branch-wide/User-specific Number Limits
                # Check GlobalNumberLimit (set by the admin themselves)
                gnl_q = Q(admin=p) if p.role != 'SUPER_ADMIN' else Q(admin__isnull=True)
                relevant_glims = list(GlobalNumberLimit.objects.filter(gnl_q, game=game, number=number, type=bet_type))
                
                # Check NumberLimit (set by their parent manager onto them)
                try:
                    p_lim = NumberLimit.objects.get(user=p, game=game, number=number, type=bet_type)
                    # Use a dummy object duck-typed like a glim
                    class AttrDict:
                        def __init__(self, c): self.max_count = c
                    relevant_glims.append(AttrDict(p_lim.max_count))
                except NumberLimit.DoesNotExist:
                    pass
                
                has_branch_specific = len(relevant_glims) > 0

                for glim in relevant_glims:
                    b_tot = Bet.objects.filter(user__id__in=d_ids, game=game, number=number, type=bet_type, created_at__date=today).aggregate(t=Sum('count'))['t'] or 0
                    b_clr = ClearedExposure.objects.filter(user__id__in=d_ids, game=game, number=number, type=bet_type, date=today).aggregate(t=Sum('count'))['t'] or 0
                    
                    # Add counts already processed in this branch hierarchy level in this session
                    current_session_n = session_branch_nos.get((p.id if p.role != 'SUPER_ADMIN' else None, number, bet_type, game.id), 0)
                    
                    if (b_tot - b_clr + current_session_n + count) > glim.max_count:
                        l = p.username if p.role != 'SUPER_ADMIN' else "System"
                        limit_error = f"Total Limit Reached. {max(0, glim.max_count - (b_tot - b_clr + current_session_n))} Only"
                        break
                if limit_error: break

                # B. Branch Type Limit (User.count_a, etc.) - Only if no specific limit exists for this branch
                if not has_branch_specific:
                    # If target user has a specific Individual Number Limit, skip hierarchical general branch type checks
                    if has_specific_limit:
                        continue

                    t_limit = get_user_type_count_limit(p, bet_type)
                    if t_limit > 0:
                        type_tot = Bet.objects.filter(user__id__in=d_ids, game=game, number=number, type=bet_type, created_at__date=today).aggregate(t=Sum('count'))['t'] or 0
                        type_clr = ClearedExposure.objects.filter(user__id__in=d_ids, game=game, number=number, type=bet_type, date=today).aggregate(t=Sum('count'))['t'] or 0
                        
                        # Add counts already processed in this branch hierarchy level in this session
                        current_session_n = session_branch_nos.get((p.id if p.role != 'SUPER_ADMIN' else None, number, bet_type, game.id), 0)
                        
                        if (type_tot - type_clr + current_session_n + count) > t_limit:
                            l = p.username if p.role != 'SUPER_ADMIN' else "System"
                            limit_error = f"Total Limit Reached. {max(0, t_limit - (type_tot - type_clr + current_session_n))} Only"
                            break
                if limit_error: break

            if limit_error:
                mark_failed(limit_error)
                continue

            # 5. System-wide Global Type Limit
            # Only check if no system-wide GlobalNumberLimit exists for this number
            system_gnl_exists = GlobalNumberLimit.objects.filter(admin__isnull=True, game=game, number=number, type=bet_type).exists()
            
            if not system_gnl_exists:
                game_type_limit = get_game_global_type_count_limit(game, bet_type)
                if game_type_limit > 0:
                    tot_type = Bet.objects.filter(game=game, type=bet_type, number=number, created_at__date=timezone.localtime().date()).aggregate(t=Sum('count'))['t'] or 0
                    t_clr = ClearedExposure.objects.filter(game=game, type=bet_type, number=number, date=timezone.localtime().date()).aggregate(t=Sum('count'))['t'] or 0
                    
                    # Global system tracking
                    current_session_n = session_branch_nos.get((None, number, bet_type, game.id), 0)
                    
                    if (tot_type - t_clr + current_session_n + count) > game_type_limit:
                        mark_failed(f"Total Limit Reached. {max(0, game_type_limit - (tot_type - t_clr + current_session_n))} Only")
                        continue

            # All checks passed!
            bet_obj = Bet.objects.create(
                user=user,
                game=game,
                number=number,
                type=bet_type,
                amount=amount,
                count=count,
                state=state,
                invoice_id=invoice_id,
                customer_name=customer_name or None
            )
            created_bets_count += 1
            total_created_amount += amount * count
            
            # Auto Forward Logic (Cut-out)
            # Evaluate after each bet creation
            try:
                from .models import ForwardLimit, ForwardedBet
                for info in hierarchy_info:
                    p = info['user']
                    if p.role != 'ADMIN' or not getattr(p, 'can_forward', False):
                        continue # Only Admins with can_forward=True can forward
                    
                    d_ids = info['descendant_ids']
                    
                    # 1. Fetch any applicable ForwardLimit (Specific Number or Generic Type)
                    fwd_limit = ForwardLimit.objects.filter(
                        admin=p, game=game, state=state, type=bet_type
                    ).filter(Q(number=number) | Q(number='') | Q(number__isnull=True)).order_by('-number').first()
                    
                    # 2. Calculate current total count for THIS number
                    tot_db = Bet.objects.filter(user__id__in=d_ids, game=game, state=state, type=bet_type, number=number, created_at__date=today).aggregate(t=Sum('count'))['t'] or 0
                    fwd_out = ForwardedBet.objects.filter(forwarded_by=p, game=game, state=state, type=bet_type, number=number, date=today).aggregate(t=Sum('count'))['t'] or 0
                    
                    if fwd_limit:
                        limit_val = fwd_limit.max_retained_count
                    else:
                        limit_val = 0
                        
                    retained = tot_db - fwd_out
                    
                    if retained > limit_val:
                        excess = retained - limit_val
                        forward_count = min(excess, count)
                        if forward_count > 0:
                        
                            forward_to = p.parent
                            if forward_to:
                                p_price_map = {
                                    'A': p.price_abc if state == 'KL' else getattr(p, 'tn_price_abc', 12.0),
                                    'B': p.price_abc if state == 'KL' else getattr(p, 'tn_price_abc', 12.0),
                                    'C': p.price_abc if state == 'KL' else getattr(p, 'tn_price_abc', 12.0),
                                    'AB': p.price_ab_bc_ac if state == 'KL' else getattr(p, 'tn_price_ab_bc_ac', 10.0),
                                    'BC': p.price_ab_bc_ac if state == 'KL' else getattr(p, 'tn_price_ab_bc_ac', 10.0),
                                    'AC': p.price_ab_bc_ac if state == 'KL' else getattr(p, 'tn_price_ab_bc_ac', 10.0),
                                    'SUPER': p.price_super,
                                    'BOX': p.price_box,
                                }
                                if state == 'TN':
                                    if bet_type == '3D-10': p_price_map['3D-10'] = getattr(p, 'tn_price_3d_10', 10.0)
                                    elif bet_type == '3D-25': p_price_map['3D-25'] = getattr(p, 'tn_price_3d_25', 25.0)
                                    elif bet_type == '3D-30': p_price_map['3D-30'] = getattr(p, 'tn_price_3d_30', 30.0)
                                    elif bet_type == '3D-60': p_price_map['3D-60'] = getattr(p, 'tn_price_3d_60', 60.0)
                                    elif bet_type == '4D-110': p_price_map['4D-110'] = getattr(p, 'tn_price_4d_110', 110.0)
                                    elif bet_type == '4D-55': p_price_map['4D-55'] = getattr(p, 'tn_price_4d_55', 55.0)
                                    elif bet_type == '4D-20': p_price_map['4D-20'] = getattr(p, 'tn_price_4d_20', 20.0)
                                
                                p_amount = Decimal(str(p_price_map.get(bet_type, 1.0)))
                            
                                ForwardedBet.objects.create(
                                    forwarded_by=p,
                                    forwarded_to=forward_to,
                                    game=game,
                                    state=state,
                                    type=bet_type,
                                    number=number,
                                        count=excess,
                                        price_per_count=p_amount,
                                        is_auto=True
                                    )
            except Exception as e:
                print("Auto Forward Error:", e)
                
            # Update session tracking for ALL levels in the hierarchy
            for p in hierarchy:
                key_n = (p.id if p.role != 'SUPER_ADMIN' else None, number, bet_type, game.id)
                key_t = (p.id if p.role != 'SUPER_ADMIN' else None, bet_type, game.id)
                session_branch_nos[key_n] = session_branch_nos.get(key_n, 0) + count
                session_branch_types[key_t] = session_branch_types.get(key_t, 0) + count
            
            # Also update the Master Global tracking if SuperAdmin wasn't in hierarchy
            if not any(p.role == 'SUPER_ADMIN' for p in hierarchy):
                key_n_global = (None, number, bet_type, game.id)
                key_t_global = (None, bet_type, game.id)
                session_branch_nos[key_n_global] = session_branch_nos.get(key_n_global, 0) + count
                session_branch_types[key_t_global] = session_branch_types.get(key_t_global, 0) + count
            
        return Response({
            'invoice_id': invoice_id if created_bets_count > 0 else None,
            'count': created_bets_count,
            'total_amount': total_created_amount,
            'failed_bets': failed_bets
        }, status=status.HTTP_201_CREATED)

    def check_edit_delete_permission(self, instance=None, invoice_id=None):
        if self.request.user.role == 'SUPER_ADMIN':
            return True
        
        # 1. Check Global Master Switch (optional but good for safety)
        sys_settings = SystemSettings.objects.first()
        if sys_settings and not sys_settings.can_edit_delete_invoice:
            return False

        # 2. Check Game-Specific Switch
        target_game = None
        if instance:
            target_game = instance.game
        elif invoice_id:
            first_bet = Bet.objects.filter(invoice_id=invoice_id).first()
            if first_bet:
                target_game = first_bet.game
        
        if target_game:
            if not target_game.can_edit_delete:
                return False
            
            current_time = timezone.localtime().time()
            if current_time > target_game.edit_delete_limit_time:
                return False
        
        return True

    @action(detail=False, methods=['delete'], url_path='delete-invoice/(?P<invoice_id>[^/.]+)')
    def delete_invoice(self, request, invoice_id=None):
        if not self.check_edit_delete_permission(invoice_id=invoice_id):
            return Response({'error': 'Edit/Delete is currently disabled by administrator or past the time limit.'}, status=status.HTTP_403_FORBIDDEN)
            
        bets = Bet.objects.filter(invoice_id=invoice_id)
        if not bets.exists():
            return Response({'error': 'Invoice not found'}, status=status.HTTP_404_NOT_FOUND)
        
        bets.delete()
        return Response({'message': 'Invoice deleted successfully'}, status=status.HTTP_200_OK)

    def perform_update(self, serializer):
        if not self.check_edit_delete_permission(serializer.instance):
             from rest_framework import serializers as drf_serializers
             raise drf_serializers.ValidationError("Edit/Delete is currently disabled by administrator or past the time limit.")
        serializer.save()

    def perform_destroy(self, instance):
        if not self.check_edit_delete_permission(instance):
             from rest_framework import serializers as drf_serializers
             raise drf_serializers.ValidationError("Edit/Delete is currently disabled by administrator or past the time limit.")
        instance.delete()

    @action(detail=False, methods=['get'], url_path='invoice-details/(?P<invoice_id>[^/.]+)')
    def invoice_details(self, request, invoice_id=None):
        bets = Bet.objects.filter(invoice_id=invoice_id).select_related('game', 'user')
        if not bets.exists():
            return Response([])
            
        user = request.user
        isAdmin = user.role in ['SUPER_ADMIN', 'ADMIN', 'AGENT', 'DEALER']
        use_admin_rate = request.query_params.get('admin_rate') != 'false' # Default true for backwards compat

        # We'll return a custom list instead of just serializer data
        from decimal import Decimal
        data = []
        # Pre-cache involved users to avoid N+1 queries during hierarchy traversal
        user_ids_in_invoice = set(bets.values_list('user_id', flat=True))
        user_objects = User.objects.filter(id__in=user_ids_in_invoice)
        user_cache = {u.id: u for u in user_objects}
        def get_user_recursive(uid):
            if uid in user_cache: return user_cache[uid]
            try:
                uobj = User.objects.get(id=uid)
                user_cache[uid] = uobj
                return uobj
            except User.DoesNotExist: return None

        for bet in bets:
            u = bet.user
            bet_sale = Decimal(str(bet.amount)) * Decimal(str(bet.count))
            
            # Default commission (Agent's own rate)
            comm_subject = u
            
            # If viewer is a manager, use their rates for net view
            if isAdmin:
                if use_admin_rate:
                    if user.role == 'SUPER_ADMIN':
                        # Super Admin sees the direct seller's net rate
                        comm_subject = u
                    else:
                        # Middle managers see their branch-head profit logic
                        curr = u
                        found_manager = None
                        while curr:
                            if curr.parent_id == user.id:
                                found_manager = curr
                                break
                            if not curr.parent_id:
                                break
                            curr = get_user_recursive(curr.parent_id)
                        comm_subject = found_manager or user
                elif user.role != 'SUPER_ADMIN':
                    # Agent Rate OFF: Non-SuperAdmin managers show their own cost rates
                    comm_subject = user

            # Calculate Commission
            c_rate = Decimal('0.00')
            btype = (bet.type or "").upper()
            
            if bet.state == 'TN':
                if btype in ['A', 'B', 'C']: c_rate = Decimal(str(comm_subject.tn_sales_comm_abc))
                elif btype in ['AB', 'BC', 'AC']: c_rate = Decimal(str(comm_subject.tn_sales_comm_ab_bc_ac))
                elif btype == '3D-10': c_rate = Decimal(str(comm_subject.tn_sales_comm_3d_10))
                elif btype == '3D-25': c_rate = Decimal(str(comm_subject.tn_sales_comm_3d_25))
                elif btype == '3D-30': c_rate = Decimal(str(comm_subject.tn_sales_comm_3d_30))
                elif btype == '3D-60': c_rate = Decimal(str(comm_subject.tn_sales_comm_3d_60))
                elif btype == '4D-110': c_rate = Decimal(str(comm_subject.tn_sales_comm_4d_110))
                elif btype == '4D-55': c_rate = Decimal(str(comm_subject.tn_sales_comm_4d_55))
                elif btype == '4D-20': c_rate = Decimal(str(comm_subject.tn_sales_comm_4d_20))
            else:
                if btype in ['A', 'B', 'C']:
                    c_rate = Decimal(str(comm_subject.sales_comm_abc))
                elif btype in ['AB', 'BC', 'AC']:
                    c_rate = Decimal(str(comm_subject.sales_comm_ab_bc_ac))
                elif btype == 'SUPER':
                    c_rate = Decimal(str(comm_subject.sales_comm_super))
                elif btype == 'BOX':
                    c_rate = Decimal(str(comm_subject.sales_comm_box))
            
            bet_comm = c_rate * Decimal(str(bet.count))
            
            data.append({
                'id': bet.id,
                'game_name': bet.game.name,
                'user_username': bet.user.username,
                'customer_name': bet.customer_name or '',
                'number': bet.number,
                'amount': float(bet.amount),
                'count': bet.count,
                'type': bet.type,
                'created_at': bet.created_at.isoformat(),
                'total_amount': float(bet_sale),
                'commission': float(bet_comm),
                'net_amount': float(bet_sale - bet_comm),
                'game_can_edit_delete': bet.game.can_edit_delete,
                'game_edit_delete_limit_time': bet.game.edit_delete_limit_time.strftime('%H:%M:%S')
            })
            
        return Response(data)




class ReportView(views.APIView):
    def get(self, request):
        user = request.user
        date_str = request.query_params.get('date', timezone.now().date().isoformat())
        date = datetime.strptime(date_str, '%Y-%m-%d').date()

        # Filters based on role (Simplified)
        bets = Bet.objects.filter(created_at__date=date)
        if user.role == 'SUPER_ADMIN':
            excluded_ids = get_excluded_forwarding_user_ids()
            if excluded_ids:
                bets = bets.exclude(user_id__in=excluded_ids)
        else:
            bets = bets.filter(user_id__in=user.get_descendant_ids())

        sales = bets.aggregate(total_sales=Sum(F('amount') * F('count')))['total_sales'] or 0
        winning = bets.filter(is_winner=True).aggregate(total_winning=Sum('winning_amount'))['total_winning'] or 0
        count = bets.aggregate(total_count=Sum('count'))['total_count'] or 0
        net = sales - winning

        return Response({
            'sales': sales,
            'winning': winning,
            'count': count,
            'net': net,
            'date': date_str
        })

class SalesReportView(views.APIView):
    def get(self, request):
        user = request.user
        from_date = request.query_params.get('from')
        to_date = request.query_params.get('to')
        game_id = request.query_params.get('game')
        agent_id = request.query_params.get('user')
        search_number = request.query_params.get('number')
        state_filter = request.query_params.get('state')

        bets = Bet.objects.all()
        
        if state_filter and state_filter.upper() != 'ALL':
            bets = bets.filter(state=state_filter.upper())
        
        if from_date:
            bets = bets.filter(created_at__date__gte=from_date)
        if to_date:
            bets = bets.filter(created_at__date__lte=to_date)
        if game_id:
            bets = bets.filter(game_id=game_id)
        if search_number:
            bets = bets.filter(number=search_number)
        if agent_id:
            try:
                target_user = User.objects.get(id=agent_id)
                # Security: Managers can only view their descendants
                if user.role == 'SUPER_ADMIN' or target_user.id in user.get_descendant_ids():
                    if int(agent_id) == user.id:
                        # SELF selected: Show only direct children + self
                        bets = bets.filter(Q(user=user) | Q(user__parent=user))
                    else:
                        # Other agent selected: Show their whole branch
                        bets = bets.filter(user_id__in=target_user.get_descendant_ids())
                else:
                    return Response({'error': 'Unauthorized'}, status=status.HTTP_403_FORBIDDEN)
            except User.DoesNotExist:
                bets = bets.filter(user_id=agent_id) # Fallback
        elif user.role == 'SUPER_ADMIN':
            excluded_ids = get_excluded_forwarding_user_ids()
            if excluded_ids:
                bets = bets.exclude(user_id__in=excluded_ids)
        elif user.role != 'SUPER_ADMIN':
            bets = bets.filter(user_id__in=user.get_descendant_ids())

        from django.db.models import Sum, F
        winning = bets.filter(is_winner=True).aggregate(total_winning=Sum('winning_amount'))['total_winning'] or 0
        total_count = bets.aggregate(total_count=Sum('count'))['total_count'] or 0
        all_bets = bets.select_related('user', 'game')

        # Cache all users to avoid N+1 queries during ancestor lookup
        user_cache = {u.id: u for u in User.objects.all()}
        
        from decimal import Decimal
        total_sales = Decimal('0.00')
        total_comm = Decimal('0.00')
        total_winning = Decimal(str(winning))
        
        invoice_map = {}
        full_view = request.query_params.get('full_view') == 'true'
        use_admin_rate = request.query_params.get('admin_rate') == 'true'
        isAdmin = user.role in ['SUPER_ADMIN', 'ADMIN', 'AGENT', 'DEALER']

        for bet in all_bets:
            u = bet.user
            bet_sale = Decimal(str(bet.amount)) * Decimal(str(bet.count))
            total_sales += bet_sale
            
            # Identify which user's commission rates to use
            comm_subject = u
            if isAdmin:
                if use_admin_rate:
                    if user.role == 'SUPER_ADMIN':
                        # Super Admin sees the direct seller's net rate
                        comm_subject = u
                    else:
                        # Middle managers see their branch-head profit logic
                        curr = u
                        found_manager = None
                        while curr:
                            if curr.parent_id == user.id:
                                found_manager = curr
                                break
                            if not curr.parent_id:
                                break
                            curr = user_cache.get(curr.parent_id)
                        comm_subject = found_manager or user
                elif user.role != 'SUPER_ADMIN':
                    # Agent Rate OFF: Non-SuperAdmin managers show their own cost rates
                    comm_subject = user

            # Calculate Commission
            c_rate = Decimal('0.00')
            btype = (bet.type or "").upper()
            
            if bet.state == 'TN':
                if btype in ['A', 'B', 'C']: c_rate = Decimal(str(comm_subject.tn_sales_comm_abc))
                elif btype in ['AB', 'BC', 'AC']: c_rate = Decimal(str(comm_subject.tn_sales_comm_ab_bc_ac))
                elif btype == '3D-10': c_rate = Decimal(str(comm_subject.tn_sales_comm_3d_10))
                elif btype == '3D-25': c_rate = Decimal(str(comm_subject.tn_sales_comm_3d_25))
                elif btype == '3D-30': c_rate = Decimal(str(comm_subject.tn_sales_comm_3d_30))
                elif btype == '3D-60': c_rate = Decimal(str(comm_subject.tn_sales_comm_3d_60))
                elif btype == '4D-110': c_rate = Decimal(str(comm_subject.tn_sales_comm_4d_110))
                elif btype == '4D-55': c_rate = Decimal(str(comm_subject.tn_sales_comm_4d_55))
                elif btype == '4D-20': c_rate = Decimal(str(comm_subject.tn_sales_comm_4d_20))
            else:
                if btype in ['A', 'B', 'C']:
                    c_rate = Decimal(str(comm_subject.sales_comm_abc))
                elif btype in ['AB', 'BC', 'AC']:
                    c_rate = Decimal(str(comm_subject.sales_comm_ab_bc_ac))
                elif btype == 'SUPER':
                    c_rate = Decimal(str(comm_subject.sales_comm_super))
                elif btype == 'BOX':
                    c_rate = Decimal(str(comm_subject.sales_comm_box))
            
            bet_comm = c_rate * Decimal(str(bet.count))
            total_comm += bet_comm
            
            # Map to Invoice
            inv_id = bet.invoice_id
            if inv_id not in invoice_map:
                invoice_map[inv_id] = {
                    'invoice_id': inv_id,
                    'user__username': u.username,
                    'customer_name': bet.customer_name or '',
                    'game__name': bet.game.name,
                    'game__time': bet.game.time,
                    'amount': Decimal('0.00'),
                    'count': 0,
                    'commission': Decimal('0.00'),
                    'net': Decimal('0.00'),
                    'created_at': bet.created_at,
                    'items': []
                }
            elif not invoice_map[inv_id].get('customer_name') and bet.customer_name:
                invoice_map[inv_id]['customer_name'] = bet.customer_name
            
            inv = invoice_map[inv_id]
            inv['amount'] += bet_sale
            inv['count'] += bet.count
            inv['commission'] += bet_comm
            inv['net'] += (bet_sale - bet_comm)
            
            # Key fix: Always include items if we're searching for a specific number,
            # so the frontend table view has data to display.
            if full_view or search_number:
                inv['items'].append({
                    'type': bet.type,
                    'number': bet.number,
                    'count': bet.count,
                    'amount': float(bet.amount),
                    'total': float(bet_sale),
                    'comm': float(bet_comm),
                    'net': float(bet_sale - bet_comm)
                })

            if bet.created_at > inv['created_at']:
                inv['created_at'] = bet.created_at

        # Format invoices for JSON
        sorted_invoices = []
        for inv in sorted(invoice_map.values(), key=lambda x: x['created_at'], reverse=True):
            inv['amount'] = float(inv['amount'])
            inv['commission'] = float(inv['commission'])
            inv['net'] = float(inv['net'])
            sorted_invoices.append(inv)
        
        return Response({
            'sales': float(total_sales),
            'winning': float(total_winning),
            'count': total_count,
            'commission': float(total_comm),
            'net': float(total_sales - total_comm),
            'invoices': sorted_invoices
        })

class NetReportView(views.APIView):
    def get(self, request):
        from django.db.models import Sum, F, Case, When, Value, CharField
        user = request.user
        from_date = request.query_params.get('from')
        to_date = request.query_params.get('to')
        game_id = request.query_params.get('game')
        
        # New: Target user ID for drill-down
        target_uid = request.query_params.get('user')
        if target_uid:
            try:
                # Security: Can only view descendants
                target_user = User.objects.get(id=target_uid)
                if target_user.id not in user.get_descendant_ids():
                    return Response({'error': 'Unauthorized'}, status=403)
            except User.DoesNotExist:
                return Response({'error': 'User not found'}, status=404)
        else:
            target_user = user

        # 1. Get all direct children of the target user
        direct_children = User.objects.filter(parent=target_user).order_by('username')
        if user.role == 'SUPER_ADMIN' and not target_uid:
            direct_children = direct_children.exclude(role='ADMIN', can_forward=True)
        
        display_subjects = []
        # 'Self' row for the target user (their own personal bets)
        if target_user.role != 'SUPER_ADMIN':
            display_subjects.append(('Self', [target_user.id], target_user, target_user.id))
        
        for child in direct_children:
            # We want to show the Child's name and their consolidated branch total
            display_subjects.append((child.username, child.get_descendant_ids(), child, child.id))

        data = []
        for idx, (label, branch_ids, comm_user, uid) in enumerate(display_subjects):
            branch_bets = Bet.objects.filter(user_id__in=branch_ids)
            if from_date:
                branch_bets = branch_bets.filter(created_at__date__gte=from_date)
            if to_date:
                branch_bets = branch_bets.filter(created_at__date__lte=to_date)
            if game_id:
                branch_bets = branch_bets.filter(game_id=game_id)
            
            type_stats = branch_bets.values('type', 'state').annotate(
                total_count=Sum('count'),
                total_sale_price=Sum(F('amount') * F('count')),
                total_winning=Sum('winning_amount')
            )
            
            total_sale_price = 0.0
            total_winning = 0.0
            total_comm = 0.0
            
            for stat in type_stats:
                btype = stat['type'].upper()
                state = stat['state']
                count = stat['total_count'] or 0
                total_sale_price += float(stat['total_sale_price'] or 0)
                total_winning += float(stat['total_winning'] or 0)
                
                c_rate = 0.0
                if state == 'TN':
                    if btype in ['A', 'B', 'C']: c_rate = float(comm_user.tn_sales_comm_abc)
                    elif btype in ['AB', 'BC', 'AC']: c_rate = float(comm_user.tn_sales_comm_ab_bc_ac)
                    elif btype == '3D-10': c_rate = float(comm_user.tn_sales_comm_3d_10)
                    elif btype == '3D-25': c_rate = float(comm_user.tn_sales_comm_3d_25)
                    elif btype == '3D-30': c_rate = float(comm_user.tn_sales_comm_3d_30)
                    elif btype == '3D-60': c_rate = float(comm_user.tn_sales_comm_3d_60)
                    elif btype == '4D-110': c_rate = float(comm_user.tn_sales_comm_4d_110)
                    elif btype == '4D-55': c_rate = float(comm_user.tn_sales_comm_4d_55)
                    elif btype == '4D-20': c_rate = float(comm_user.tn_sales_comm_4d_20)
                else:
                    if btype in ['A', 'B', 'C']:
                        c_rate = float(comm_user.sales_comm_abc)
                    elif btype in ['AB', 'BC', 'AC']:
                        c_rate = float(comm_user.sales_comm_ab_bc_ac)
                    elif btype == 'SUPER':
                        c_rate = float(comm_user.sales_comm_super)
                    elif btype == 'BOX':
                        c_rate = float(comm_user.sales_comm_box)
                
                total_comm += (c_rate * count)
            
            if total_sale_price == 0 and total_winning == 0:
                continue

            sale_net = total_sale_price - total_comm
            rate_pct = (total_comm / total_sale_price * 100) if total_sale_price > 0 else 0.0
            
            data.append({
                'logid': len(data) + 1,
                'user': label if label == 'Self' else label,
                'user_id': uid,
                'role': comm_user.role,
                'is_drillable': label != 'Self' and comm_user.role != 'SUB_DEALER',
                'rate': f"{rate_pct:.1f}%",
                'gross_sale': total_sale_price,
                'commission': total_comm,
                'all_sale': sale_net,
                'winning': total_winning,
                'win_co': total_winning + total_comm,
                'balance': sale_net - total_winning
            })

        # --- Inject Forwarding Calculations into Net Report ---
        if target_user.id == user.id:
            from .models import ForwardedBet
            
            fwd_sales = 0.0
            fwd_win = 0.0
            fwd_comm = 0.0

            if user.role != 'SUPER_ADMIN':
                fwd_out_qs = ForwardedBet.objects.filter(forwarded_by=user)
                if from_date: fwd_out_qs = fwd_out_qs.filter(date__gte=from_date)
                if to_date: fwd_out_qs = fwd_out_qs.filter(date__lte=to_date)
                if game_id: fwd_out_qs = fwd_out_qs.filter(game_id=game_id)
                
                for fb in fwd_out_qs:
                    fwd_sales += float(fb.price_per_count * fb.count)
                    if fb.is_winner:
                        fwd_win += float(fb.winning_amount)
                        
                if fwd_sales > 0 or fwd_win > 0:
                    data.append({
                        'logid': len(data) + 1,
                        'user': 'FORWARDED (OUT)',
                        'user_id': -1,
                        'role': 'FORWARD',
                        'is_drillable': False,
                        'rate': "N/A",
                        'gross_sale': -fwd_sales,
                        'commission': 0,
                        'all_sale': -fwd_sales,
                        'winning': -fwd_win,
                        'win_co': -fwd_win,
                        'balance': (-fwd_sales) - (-fwd_win)
                    })
            else:
                fwd_in_qs = ForwardedBet.objects.filter(forwarded_to=user)
                if from_date: fwd_in_qs = fwd_in_qs.filter(date__gte=from_date)
                if to_date: fwd_in_qs = fwd_in_qs.filter(date__lte=to_date)
                if game_id: fwd_in_qs = fwd_in_qs.filter(game_id=game_id)
                
                for fb in fwd_in_qs:
                    fwd_sales += float(fb.price_per_count * fb.count)
                    if fb.is_winner:
                        fwd_win += float(fb.winning_amount)
                
                if fwd_sales > 0 or fwd_win > 0:
                    data.append({
                        'logid': len(data) + 1,
                        'user': 'FORWARDED (IN)',
                        'user_id': -1,
                        'role': 'FORWARD',
                        'is_drillable': False,
                        'rate': "N/A",
                        'gross_sale': fwd_sales,
                        'commission': 0,
                        'all_sale': fwd_sales,
                        'winning': fwd_win,
                        'win_co': fwd_win,
                        'balance': fwd_sales - fwd_win
                    })

        return Response({
            'breadcrumb': {
                'id': target_user.id,
                'name': target_user.username,
                'role': target_user.role
            },
            'data': data
        })

class CountReportView(views.APIView):
    def get(self, request):
        user = request.user
        from_date = request.query_params.get('from')
        to_date = request.query_params.get('to')
        game_id = request.query_params.get('game')
        agent_id = request.query_params.get('user')

        state = request.query_params.get('state')
        bets = Bet.objects.all()
        
        if state and state.upper() in ['KL', 'TN']:
            bets = bets.filter(state=state.upper())
        if from_date:
            bets = bets.filter(created_at__date__gte=from_date)
        if to_date:
            bets = bets.filter(created_at__date__lte=to_date)
        if game_id:
            bets = bets.filter(game_id=game_id)

        if agent_id:
            try:
                target_id = int(agent_id)
                if target_id == user.id:
                    # SELF selected: Show self + direct subordinates
                    bets = bets.filter(Q(user=user) | Q(user__parent=user))
                else:
                    # Specific agent selected: Show their descendant tree
                    target_user = User.objects.get(id=target_id)
                    bets = bets.filter(user_id__in=target_user.get_descendant_ids())
            except (ValueError, User.DoesNotExist):
                bets = bets.filter(user_id=agent_id)
        elif user.role == 'SUPER_ADMIN':
            excluded_ids = get_excluded_forwarding_user_ids()
            if excluded_ids:
                bets = bets.exclude(user_id__in=excluded_ids)
        elif user.role != 'SUPER_ADMIN':
            bets = bets.filter(user_id__in=user.get_descendant_ids())

        # Normalize types for grouping
        bets = bets.annotate(
            report_type=Case(
                When(type__iexact='a', then=Value('A, B, C')),
                When(type__iexact='b', then=Value('A, B, C')),
                When(type__iexact='c', then=Value('A, B, C')),
                When(type__iexact='ab', then=Value('AB, BC, AC')),
                When(type__iexact='bc', then=Value('AB, BC, AC')),
                When(type__iexact='ac', then=Value('AB, BC, AC')),
                default=F('type'),
                output_field=CharField(),
            )
        )

        # Group by report_type
        counts_qs = bets.values('report_type').annotate(
            total_count=Sum('count'),
            total_cash=Sum(F('amount') * F('count')),
            rate=Max('amount') 
        ).order_by('report_type')

        isAdmin = user.role in ['SUPER_ADMIN', 'ADMIN', 'AGENT', 'DEALER']
        use_admin_rate = request.query_params.get('admin_rate') == 'true'
        
        from decimal import Decimal
        data = []
        global_total_cash = Decimal('0')

        # Fetch selected agent if any
        selected_agent = None
        if agent_id:
            try:
                selected_agent = User.objects.get(id=agent_id)
            except User.DoesNotExist:
                pass
        
        for item in counts_qs:
            r_type = item['report_type']
            t_count = item['total_count']
            t_cash = Decimal(str(item['total_cash']))
            rate = Decimal(str(item['rate']))
            
            # Default net is same as selling if viewer is SuperAdmin
            net_rate = rate
            net_cash = t_cash

            if isAdmin and user.role != 'SUPER_ADMIN':
                target_user = None
                # Case 1: Agent selected and Agent Rate ON -> Use selected agent's commission
                if use_admin_rate and selected_agent:
                    target_user = selected_agent
                # Case 2: Agent Rate OFF -> Use viewer's (admin's) own commission
                elif not use_admin_rate:
                    target_user = user
                
                if target_user:
                    # Identify commission rate for this type for the TARGET user
                    c_rate = Decimal('0.00')
                    if r_type == 'A, B, C':
                        c_rate = Decimal(str(target_user.sales_comm_abc))
                    elif r_type == 'AB, BC, AC':
                        c_rate = Decimal(str(target_user.sales_comm_ab_bc_ac))
                    elif r_type == 'SUPER':
                        c_rate = Decimal(str(target_user.sales_comm_super))
                    elif r_type == 'BOX':
                        c_rate = Decimal(str(target_user.sales_comm_box))
                    
                    net_rate = rate - c_rate
                    net_cash = t_cash - (c_rate * Decimal(str(t_count)))

            data.append({
                'type': r_type,
                'total_count': t_count,
                'total_cash': float(net_cash),
                'rate': float(net_rate),
                'selling_rate': float(rate),
                'selling_cash': float(t_cash)
            })
            global_total_cash += net_cash

        return Response({
            'data': data,
            'total_cash': float(global_total_cash),
            'total_count': bets.aggregate(total=Sum('count'))['total'] or 0,
        })


class DailyReportView(views.APIView):
    def get(self, request):
        user = request.user
        from_date = request.query_params.get('from')
        to_date = request.query_params.get('to')
        agent_id = request.query_params.get('user')
        game_ids = request.query_params.getlist('games') # Support multiple games
        
        state = request.query_params.get('state')
        day_detail = request.query_params.get('day_detail') == 'true'
        game_detail = request.query_params.get('game_detail') == 'true'
        user_detail = request.query_params.get('user_detail') == 'true'
        
        use_agent_rate = request.query_params.get('agent_rate') == 'true'

        # 1. Determine target_user for drilldown
        target_user = user
        if agent_id:
            try:
                t_id = int(agent_id)
                if t_id == user.id or t_id in user.get_descendant_ids():
                    target_user = User.objects.get(id=t_id)
                else:
                    return Response({'error': 'Unauthorized'}, status=403)
            except (ValueError, User.DoesNotExist):
                return Response({'error': 'User not found'}, status=404)

        bets = Bet.objects.filter(user_id__in=target_user.get_descendant_ids())
        if user.role == 'SUPER_ADMIN' and not agent_id:
            excluded_ids = get_excluded_forwarding_user_ids()
            if excluded_ids:
                bets = bets.exclude(user_id__in=excluded_ids)
        
        if state and state.upper() in ['KL', 'TN']:
            bets = bets.filter(state=state.upper())
        if from_date:
            bets = bets.filter(created_at__date__gte=from_date)
        if to_date:
            bets = bets.filter(created_at__date__lte=to_date)
        if game_ids:
            bets = bets.filter(game_id__in=game_ids)

        # Determine grouping
        group_fields = []
        if day_detail:
            bets = bets.annotate(date_only=F('created_at__date'))
            group_fields.append('date_only')
        if game_detail:
            group_fields.append('game__name')
            group_fields.append('game__color')
        if user_detail:
            group_fields.append('user__username')
            group_fields.append('user__id')

        # Check if this is the root request (flat list of Self + direct subordinates for all roles)
        is_root_view = False

        # ── Build direct-subordinate map under target_user ────────────────────
        direct_children = list(
            User.objects.filter(parent=target_user).only(
                'id', 'username', 'role', 'can_forward',
                'sales_comm_abc', 'sales_comm_ab_bc_ac', 'sales_comm_super', 'sales_comm_box',
                'tn_sales_comm_abc', 'tn_sales_comm_ab_bc_ac',
                'tn_sales_comm_3d_10', 'tn_sales_comm_3d_25', 'tn_sales_comm_3d_30', 'tn_sales_comm_3d_60',
                'tn_sales_comm_4d_110', 'tn_sales_comm_4d_55', 'tn_sales_comm_4d_20',
            )
        )
        if user.role == 'SUPER_ADMIN' and not agent_id:
            direct_children = [c for c in direct_children if not (c.role == 'ADMIN' and getattr(c, 'can_forward', False))]
        direct_child_ids = {c.id for c in direct_children}
        direct_child_obj = {c.id: c for c in direct_children}
        has_subordinates = len(direct_children) > 0

        involved_user_ids = set(bets.values_list('user_id', flat=True).distinct())
        involved_users_qs = User.objects.filter(id__in=involved_user_ids).select_related(
            'parent', 'parent__parent', 'parent__parent__parent', 'parent__parent__parent__parent'
        )
        involved_users = {u.id: u for u in involved_users_qs}

        # Map each user who placed a bet to either 'SELF' or the direct child object under target_user
        direct_sub_map = {}
        for uid in involved_user_ids:
            if uid == target_user.id:
                direct_sub_map[uid] = 'SELF'
                continue
            current = involved_users.get(uid)
            found = False
            while current:
                if current.id in direct_child_ids:
                    direct_sub_map[uid] = direct_child_obj[current.id]
                    found = True
                    break
                parent_id = current.parent_id
                if not parent_id or parent_id == target_user.id:
                    if current.id in direct_child_ids:
                        direct_sub_map[uid] = direct_child_obj[current.id]
                        found = True
                    break
                next_u = involved_users.get(parent_id)
                if next_u is None:
                    try:
                        next_u = User.objects.get(id=parent_id)
                        involved_users[parent_id] = next_u
                    except User.DoesNotExist:
                        break
                current = next_u
            if not found:
                direct_sub_map[uid] = 'SELF'

        # Annotate bets with bet_type_category
        bets = bets.annotate(
            bet_type_category=Case(
                When(type__iexact='a', then=Value('ABC')),
                When(type__iexact='b', then=Value('ABC')),
                When(type__iexact='c', then=Value('ABC')),
                When(type__iexact='ab', then=Value('AB_BC_AC')),
                When(type__iexact='bc', then=Value('AB_BC_AC')),
                When(type__iexact='ac', then=Value('AB_BC_AC')),
                default=F('type'),
                output_field=CharField(),
            )
        )

        def get_comm_rate(user_obj, bcat, st):
            if not user_obj or user_obj == 'SELF':
                user_obj = target_user
            if st == 'TN':
                if bcat == 'ABC': return Decimal(str(user_obj.tn_sales_comm_abc))
                elif bcat == 'AB_BC_AC': return Decimal(str(user_obj.tn_sales_comm_ab_bc_ac))
                elif bcat == '3D-10': return Decimal(str(user_obj.tn_sales_comm_3d_10))
                elif bcat == '3D-25': return Decimal(str(user_obj.tn_sales_comm_3d_25))
                elif bcat == '3D-30': return Decimal(str(user_obj.tn_sales_comm_3d_30))
                elif bcat == '3D-60': return Decimal(str(user_obj.tn_sales_comm_3d_60))
                elif bcat == '4D-110': return Decimal(str(user_obj.tn_sales_comm_4d_110))
                elif bcat == '4D-55': return Decimal(str(user_obj.tn_sales_comm_4d_55))
                elif bcat == '4D-20': return Decimal(str(user_obj.tn_sales_comm_4d_20))
            else:
                if bcat == 'ABC': return Decimal(str(user_obj.sales_comm_abc))
                elif bcat == 'AB_BC_AC': return Decimal(str(user_obj.sales_comm_ab_bc_ac))
                elif bcat == 'SUPER': return Decimal(str(user_obj.sales_comm_super))
                elif bcat == 'BOX': return Decimal(str(user_obj.sales_comm_box))
            return Decimal('0.00')

        # If no detail is requested, provide a summary
        if not group_fields:
            sub_groups = bets.values('user_id', 'bet_type_category', 'state').annotate(
                sub_sale=Sum(F('amount') * F('count')),
                sub_count=Sum('count'),
                sub_winning=Sum('winning_amount'),
                sub_winning_comm=Sum('winning_commission'),
            )
            total_net_sale = Decimal('0.00')
            total_winning = Decimal('0.00')
            total_winning_comm = Decimal('0.00')
            for sg in sub_groups:
                uid = sg['user_id']
                sub_user_obj = direct_sub_map.get(uid, target_user)
                bcat = sg['bet_type_category']
                st = sg.get('state', 'KL')

                if user.role != 'SUPER_ADMIN' and use_agent_rate:
                    effective_comm_user = user
                else:
                    effective_comm_user = sub_user_obj

                comm_rate = get_comm_rate(effective_comm_user, bcat, st)
                s = Decimal(str(sg['sub_sale'] or 0))
                cnt = Decimal(str(sg['sub_count'] or 0))
                w = Decimal(str(sg['sub_winning'] or 0))
                wc = Decimal(str(sg['sub_winning_comm'] or 0))
                total_net_sale += (s - (comm_rate * cnt))
                total_winning += w
                total_winning_comm += wc
            balance = total_net_sale - (total_winning + total_winning_comm)
            return Response({
                'data': [{
                    'label': 'Total Summary',
                    'sale': float(total_net_sale),
                    'commission': float(total_winning_comm),
                    'net_sale': float(total_net_sale),
                    'winning': float(total_winning),
                    'balance': float(balance),
                }],
                'breadcrumb': {
                    'id': target_user.id,
                    'name': target_user.username,
                    'role': target_user.role,
                }
            })

        if user_detail and direct_sub_map:
            from django.db.models import IntegerField as DjangoIntField
            whens_username = []
            whens_userid = []
            whens_role = []
            for uid, sub_user in direct_sub_map.items():
                if is_root_view:
                    whens_username.append(When(user_id=uid, then=Value(target_user.username)))
                    whens_userid.append(When(user_id=uid, then=Value(target_user.id)))
                    whens_role.append(When(user_id=uid, then=Value(target_user.role)))
                elif sub_user == 'SELF':
                    whens_username.append(When(user_id=uid, then=Value('Self')))
                    whens_userid.append(When(user_id=uid, then=Value(0)))
                    whens_role.append(When(user_id=uid, then=Value(target_user.role)))
                else:
                    whens_username.append(When(user_id=uid, then=Value(sub_user.username)))
                    whens_userid.append(When(user_id=uid, then=Value(sub_user.id)))
                    whens_role.append(When(user_id=uid, then=Value(sub_user.role)))

            bets = bets.annotate(
                direct_sub_username=Case(*whens_username, default=F('user__username'), output_field=CharField()),
                direct_sub_id=Case(*whens_userid, default=F('user_id'), output_field=DjangoIntField()),
                direct_sub_role=Case(*whens_role, default=F('user__role'), output_field=CharField()),
            )
            group_fields_for_query = [
                f for f in group_fields if f not in ('user__username', 'user__id')
            ]
            group_fields_for_query += ['direct_sub_username', 'direct_sub_id', 'direct_sub_role']
        else:
            group_fields_for_query = group_fields

        # Grouped aggregation
        grouped_bets = (
            bets.values(*group_fields_for_query, 'user_id', 'bet_type_category', 'state')
            .annotate(
                sub_total_sale=Sum(F('amount') * F('count')),
                sub_total_count=Sum('count'),
                sub_total_winning=Sum('winning_amount'),
                sub_total_winning_comm=Sum('winning_commission'),
            )
            .order_by(*group_fields_for_query, 'bet_type_category', 'state')
        )

        final_data = {}

        for r in grouped_bets:
            uid = r['user_id']
            sub_user_obj = direct_sub_map.get(uid, target_user)

            bcat = r.get('bet_type_category')
            state_code = r.get('state', 'KL')

            if user.role != 'SUPER_ADMIN' and use_agent_rate:
                effective_comm_user = user
            else:
                effective_comm_user = sub_user_obj

            comm_rate = get_comm_rate(effective_comm_user, bcat, state_code)

            sub_gross_sale = Decimal(str(r['sub_total_sale'] or 0))
            sub_count = Decimal(str(r['sub_total_count'] or 0))
            sub_winning = Decimal(str(r['sub_total_winning'] or 0))
            sub_winning_comm = Decimal(str(r['sub_total_winning_comm'] or 0))

            sales_discount = comm_rate * sub_count
            sub_net_sale = sub_gross_sale - sales_discount

            key_parts = []
            if day_detail:
                key_parts.append(str(r.get('date_only', '')))
            if game_detail:
                key_parts.append(r.get('game__name', 'ALL'))
            if user_detail:
                u_label = r.get('direct_sub_username') or r.get('user__username', 'ALL')
                key_parts.append(u_label)

            key = tuple(key_parts)

            if key not in final_data:
                date_obj = r.get('date_only')
                date_str = (
                    date_obj.strftime('%d/%m').lstrip('0').replace('/0', '/')
                    if date_obj else 'ALL'
                )
                u_label = (
                    r.get('direct_sub_username') or r.get('user__username', 'ALL')
                    if user_detail else 'ALL'
                )
                u_id = r.get('direct_sub_id') or r.get('user__id')
                u_role = r.get('direct_sub_role') or 'SUB_DEALER'

                if is_root_view:
                    is_drillable = has_subordinates
                elif u_label == 'Self' or u_id == 0:
                    is_drillable = False
                else:
                    is_drillable = bool(u_id and u_id != target_user.id and u_role != 'SUB_DEALER')

                final_data[key] = {
                    'date': date_str,
                    'game': r.get('game__name', 'ALL'),
                    'game_color': r.get('game__color'),
                    'user': u_label,
                    'user_id': u_id if u_id != 0 else None,
                    'role': u_role,
                    'is_drillable': is_drillable,
                    'sale': Decimal('0.00'),
                    'gross_sale': Decimal('0.00'),
                    'commission': Decimal('0.00'),
                    'net_sale': Decimal('0.00'),
                    'winning': Decimal('0.00'),
                    'balance': Decimal('0.00'),
                }

            final_data[key]['sale'] += sub_net_sale
            final_data[key]['gross_sale'] += sub_gross_sale
            final_data[key]['commission'] += sub_winning_comm
            final_data[key]['net_sale'] += sub_net_sale
            final_data[key]['winning'] += sub_winning
            final_data[key]['balance'] = (
                final_data[key]['sale'] - (final_data[key]['winning'] + final_data[key]['commission'])
            )

        output_data = []
        for key in sorted(final_data.keys()):
            item = final_data[key]
            if target_user.role == 'SUPER_ADMIN' and str(item['user']).upper() == 'SELF':
                continue
            output_data.append({
                'date': item['date'],
                'game': item['game'],
                'game_color': item.get('game_color'),
                'user': str(item['user']).upper(),
                'user_id': item.get('user_id'),
                'role': item.get('role'),
                'is_drillable': item.get('is_drillable', False),
                'sale': float(item['sale']),
                'gross_sale': float(item.get('gross_sale', item['sale'])),
                'commission': float(item['commission']),
                'net_sale': float(item['net_sale']),
                'winning': float(item['winning']),
                'balance': float(item['balance']),
            })

        return Response({
            'data': output_data,
            'breadcrumb': {
                'id': target_user.id,
                'name': target_user.username,
                'role': target_user.role,
            }
        })


class NumberReportView(views.APIView):
    def get(self, request):
        user = request.user
        from_date = request.query_params.get('from')
        to_date = request.query_params.get('to')
        game_id = request.query_params.get('game')
        agent_id = request.query_params.get('user')
        bet_type = request.query_params.get('type')
        search_number = request.query_params.get('number')
        state_filter = request.query_params.get('state')
        state = request.query_params.get('state')
        forwarded_only = request.query_params.get('forwarded_only') == 'true'

        if forwarded_only:
            from .models import ForwardedBet
            if user.role == 'SUPER_ADMIN':
                fwd_qs = ForwardedBet.objects.filter(forwarded_to=user)
                if agent_id:
                    fwd_qs = fwd_qs.filter(forwarded_by_id=agent_id)
            else:
                fwd_qs = ForwardedBet.objects.filter(forwarded_by=user)
            
            if state and state.upper() in ['KL', 'TN']:
                fwd_qs = fwd_qs.filter(state=state.upper())
            if from_date:
                fwd_qs = fwd_qs.filter(date__gte=from_date)
            if to_date:
                fwd_qs = fwd_qs.filter(date__lte=to_date)
            if game_id:
                fwd_qs = fwd_qs.filter(game_id=game_id)
            if search_number:
                fwd_qs = fwd_qs.filter(number=search_number)
            if bet_type:
                if bet_type in ['SUPER+BOX', 'SUPER BOX']:
                    fwd_qs = fwd_qs.filter(type__in=['SUPER', 'BOX', 'super', 'box'])
                else:
                    fwd_qs = fwd_qs.filter(type__iexact=bet_type)

            if user.role == 'SUPER_ADMIN':
                fwd_items = fwd_qs.values('game__name', 'type', 'number', 'forwarded_by__username').annotate(
                    total_qty=Sum('count')
                ).order_by('-total_qty', 'number')
                results = []
                for item in fwd_items:
                    results.append({
                        'game__name': item['game__name'],
                        'type': item['type'],
                        'number': item['number'],
                        'user__username': item['forwarded_by__username'],
                        'total_qty': item['total_qty'],
                        'forwarded_qty': item['total_qty'],
                    })
                return Response(results)
            else:
                fwd_items = fwd_qs.values('game__name', 'type', 'number').annotate(
                    total_qty=Sum('count')
                ).order_by('-total_qty', 'number')
                results = []
                for item in fwd_items:
                    results.append({
                        'game__name': item['game__name'],
                        'type': item['type'],
                        'number': item['number'],
                        'user__username': user.username,
                        'total_qty': item['total_qty'],
                        'forwarded_qty': item['total_qty'],
                    })
                return Response(results)

        # Regular Number Report: Only normal bets (Forwarded off Admins + downlines)
        bets = Bet.objects.all()
        
        if state_filter and state_filter.upper() != 'ALL':
            bets = bets.filter(state=state_filter.upper())
        
        if state and state.upper() in ['KL', 'TN']:
            bets = bets.filter(state=state.upper())
        if from_date:
            bets = bets.filter(created_at__date__gte=from_date)
        if to_date:
            bets = bets.filter(created_at__date__lte=to_date)
        if game_id:
            bets = bets.filter(game_id=game_id)
        if search_number:
            bets = bets.filter(number=search_number)
        if agent_id:
            bets = bets.filter(user_id=agent_id)
        elif user.role == 'SUPER_ADMIN':
            excluded_ids = get_excluded_forwarding_user_ids()
            if excluded_ids:
                bets = bets.exclude(user_id__in=excluded_ids)
        elif user.role != 'SUPER_ADMIN':
            # View my bets and all my descendants' bets
            bets = bets.filter(user_id__in=user.get_descendant_ids())
        
        if bet_type:
            # Handle possible space if not encoded correctly, although it's better to fix frontend
            if bet_type in ['SUPER+BOX', 'SUPER BOX']:
                # Filter for all cases
                bets = bets.filter(type__in=['SUPER', 'BOX', 'super', 'box'])
            else:
                bets = bets.filter(type__iexact=bet_type)

        results = bets.values('game__name', 'type', 'number', 'user__username').annotate(
            total_qty=Sum('count')
        ).order_by('-total_qty', 'number')

        results_list = list(results)
        
        # Attach Forwarded Quantities
        if user.role == 'ADMIN' and not agent_id:
            try:
                from .models import ForwardedBet
                fwd_qs = ForwardedBet.objects.filter(forwarded_by=user)
                if from_date: fwd_qs = fwd_qs.filter(date__gte=from_date)
                if to_date: fwd_qs = fwd_qs.filter(date__lte=to_date)
                if game_id: fwd_qs = fwd_qs.filter(game_id=game_id)
                if search_number: fwd_qs = fwd_qs.filter(number=search_number)
                if bet_type:
                    if bet_type in ['SUPER+BOX', 'SUPER BOX']:
                        fwd_qs = fwd_qs.filter(type__in=['SUPER', 'BOX', 'super', 'box'])
                    else:
                        fwd_qs = fwd_qs.filter(type__iexact=bet_type)

                fwd_grouped = fwd_qs.values('game__name', 'type', 'number').annotate(fwd_qty=Sum('count'))
                fwd_dict = {(item['game__name'], item['type'], item['number']): item['fwd_qty'] for item in fwd_grouped}
                for r in results_list:
                    key = (r['game__name'], r['type'], r['number'])
                    r['forwarded_qty'] = fwd_dict.get(key, 0)
            except Exception as e:
                print("Error attaching forwarded bets:", e)
                pass

        return Response(results_list)


def calculate_bet_win_prize_and_comm(bet, user, specific_prize_type=None):
    """Calculates prize and commission for a bet based on a specific user's settings."""
    count = float(bet.count)
    btype = bet.type.upper()
    
    # If a specific type is requested (for unfolding reports), use it.
    # Otherwise use the string stored in the bet.
    raw_prize_type = specific_prize_type or (bet.winning_prize_type or "")
    prize_types = [t.strip().upper() for t in raw_prize_type.split("|") if t.strip()]
    
    total_prize = 0.0
    total_comm = 0.0

    for pt in prize_types:
        p, c = 0.0, 0.0
        if btype == 'SUPER':
            if "1ST" in pt:
                p = count * float(user.prize_super_1)
                c = count * float(user.comm_super_1)
            elif "2ND" in pt:
                p = count * float(user.prize_super_2)
                c = count * float(user.comm_super_2)
            elif "3RD" in pt:
                p = count * float(user.prize_super_3)
                c = count * float(user.comm_super_3)
            elif "4TH" in pt:
                p = count * float(user.prize_super_4)
                c = count * float(user.comm_super_4)
            elif "5TH" in pt:
                p = count * float(user.prize_super_5)
                c = count * float(user.comm_super_5)
            elif "COMPLIMENT" in pt:
                p = count * float(user.prize_6th)
                c = count * float(user.comm_6th)
                
        elif btype == 'BOX':
            num_stripped = (bet.number or "").strip()
            distinct = len(set(num_stripped))
            upt = pt.upper()
            
            # EXACT = exact match against 1ST PRIZE → prize_box_*_1
            # BOX2 = permutation match → prize_box_*_2
            # The prize type string is stored as "BOX (1ST PRIZE) EXACT" or "BOX2 (1ND PRIZE)"
            box_level = 1 if 'EXACT' in upt else 2

            if distinct == 3:      # All-different digits (e.g. 325)
                p, c = (count * float(user.prize_box_3d_1), count * float(user.comm_box_3d_1)) if box_level == 1 else (count * float(user.prize_box_3d_2), count * float(user.comm_box_3d_2))
            elif distinct == 2:    # Two-same digits (e.g. 332)
                p, c = (count * float(user.prize_box_2s_1), count * float(user.comm_box_2s_1)) if box_level == 1 else (count * float(user.prize_box_2s_2), count * float(user.comm_box_2s_2))
            else:                  # Triple (e.g. 333) — only one prize level
                p, c = (count * float(user.prize_box_3s_1), count * float(user.comm_box_3s_1))
                    
        elif btype in ['TN-AB', 'TN-BC', 'TN-AC']:
            p = count * float(user.tn_prize_ab_bc_ac)
            c = 0.0  # No commission for TN
            
        elif btype in ['TN-A', 'TN-B', 'TN-C']:
            p = count * float(user.tn_prize_abc)
            c = 0.0  # No commission for TN

        elif btype in ['AB', 'BC', 'AC'] and bet.state == 'TN':
            p = count * float(user.tn_prize_ab_bc_ac)
            c = 0.0  # No commission for TN

        elif btype in ['A', 'B', 'C'] and bet.state == 'TN':
            p = count * float(user.tn_prize_abc)
            c = 0.0  # No commission for TN

        elif btype in ['AB', 'BC', 'AC']:
            p = count * float(user.prize_ab_bc_ac_1)
            c = count * float(user.comm_ab_bc_ac_1)
            
        elif btype in ['A', 'B', 'C']:
            p = count * float(user.prize_abc_1)
            c = count * float(user.comm_abc_1)

        elif btype in ['3D-10']:
            if 'BC' in pt:
                p = count * float(getattr(user, 'tn_prize_3d_10_bc', 0))
            else:
                p = count * float(getattr(user, 'tn_prize_3d_10', 0))
            c = 0.0
        elif btype in ['3D-25']:
            if 'BC' in pt:
                p = count * float(getattr(user, 'tn_prize_3d_25_bc', 0))
            else:
                p = count * float(getattr(user, 'tn_prize_3d_25', 0))
            c = 0.0
        elif btype in ['3D-30']:
            if 'BC' in pt:
                p = count * float(getattr(user, 'tn_prize_3d_30_bc', 0))
            elif 'C MATCH' in pt or pt.endswith(' C') or pt.endswith('(C)'):
                p = count * float(getattr(user, 'tn_prize_3d_30_c', 0))
            else:
                p = count * float(getattr(user, 'tn_prize_3d_30', 0))
            c = 0.0
        elif btype in ['3D-60']:
            if 'BC' in pt:
                p = count * float(getattr(user, 'tn_prize_3d_60_bc', 0))
            elif 'C MATCH' in pt or pt.endswith(' C') or pt.endswith('(C)'):
                p = count * float(getattr(user, 'tn_prize_3d_60_c', 0))
            else:
                p = count * float(getattr(user, 'tn_prize_3d_60', 0))
            c = 0.0
        elif btype in ['4D-110']:
            if '1ST' in pt: p = count * float(getattr(user, 'tn_prize_4d_110_1', 0))
            elif '2ND' in pt: p = count * float(getattr(user, 'tn_prize_4d_110_2', 0))
            elif '3RD' in pt: p = count * float(getattr(user, 'tn_prize_4d_110_3', 0))
            elif '4TH' in pt: p = count * float(getattr(user, 'tn_prize_4d_110_4', 0))
            c = 0.0
        elif btype in ['4D-55']:
            if '1ST' in pt: p = count * float(getattr(user, 'tn_prize_4d_55_1', 0))
            elif '2ND' in pt: p = count * float(getattr(user, 'tn_prize_4d_55_2', 0))
            elif '3RD' in pt: p = count * float(getattr(user, 'tn_prize_4d_55_3', 0))
            elif '4TH' in pt: p = count * float(getattr(user, 'tn_prize_4d_55_4', 0))
            c = 0.0
        elif btype in ['4D-20']:
            p = count * float(getattr(user, 'tn_prize_4d_20_1', 0))
            c = 0.0
        
        total_prize += p
        total_comm += c
        
    return total_prize, total_comm

class WinningReportView(views.APIView):
    def get(self, request):
        from_date = request.query_params.get('from')
        to_date = request.query_params.get('to')
        game_id = request.query_params.get('game')
        user_id = request.query_params.get('user')
        search_number = request.query_params.get('number')
        
        state = request.query_params.get('state')
        user = request.user
        forwarded_only = request.query_params.get('forwarded_only') == 'true'
        
        bets = Bet.objects.filter(is_winner=True).select_related('user', 'game').distinct()
        if forwarded_only:
            bets = Bet.objects.none()
        
        if from_date:
            bets = bets.filter(created_at__date__gte=from_date)
        if to_date:
            bets = bets.filter(created_at__date__lte=to_date)
        if game_id:
            bets = bets.filter(game_id=game_id)
        if state and state.upper() in ['KL', 'TN']:
            bets = bets.filter(state=state.upper())
        if search_number:
            bets = bets.filter(number=search_number)
        if user_id:
            try:
                target_id = int(user_id)
                if target_id == user.id:
                    # SELF selected: Show self + direct subordinates
                    bets = bets.filter(Q(user_id=user.id) | Q(user__parent_id=user.id))
                else:
                    # Specific agent selected: Show their entire branch (descendants)
                    target_user = User.objects.get(id=target_id)
                    bets = bets.filter(user_id__in=target_user.get_descendant_ids())
            except (ValueError, User.DoesNotExist):
                bets = bets.filter(user_id=user_id)
        elif user.role == 'SUPER_ADMIN':
            excluded_ids = get_excluded_forwarding_user_ids()
            if excluded_ids:
                bets = bets.exclude(user_id__in=excluded_ids)
        elif user.role != 'SUPER_ADMIN':
            # Admin/Agent sees their own and their descendants' winners
            bets = bets.filter(user_id__in=user.get_descendant_ids())

        # Define priority for sorting
        from django.db.models import Case, When, Value, IntegerField
        sorted_bets = bets.annotate(
            prize_priority=Case(
                When(winning_prize_type__icontains="1st", then=Value(1)),
                When(winning_prize_type__icontains="BOX (1ST PRIZE) EXACT", then=Value(1)),
                When(winning_prize_type__icontains="BOX2 (1ND PRIZE)", then=Value(2)),
                When(winning_prize_type__icontains="2nd", then=Value(3)),
                When(winning_prize_type__icontains="3rd", then=Value(4)),
                When(winning_prize_type__icontains="4th", then=Value(5)),
                When(winning_prize_type__icontains="5th", then=Value(6)),
                When(winning_prize_type__icontains="Compliment", then=Value(7)),
                default=Value(10),
                output_field=IntegerField(),
            )
        ).order_by('prize_priority', 'number')

        # User-wise Summary / Recalculation Loop
        use_agent_rate = request.query_params.get('admin_rate') == 'true'
        
        total_winning_amount = 0.0
        total_winning_commission = 0.0
        total_winning_count = bets.count()
        
        # Convert queryset to list for stable processing
        actual_bets = list(sorted_bets)
        serialized_bets = BetSerializer(actual_bets, many=True).data
        branch_summary = {} # key: (username, role) -> stats
        unfolded_results = []

        # Pre-load all users for efficient hierarchy climbing
        all_users = {u.id: u for u in User.objects.select_related('parent').all()}

        def get_branch_head(leaf_user_id, viewer_id):
            """Returns the direct child of viewer_id that is an ancestor of leaf_user_id."""
            if leaf_user_id == viewer_id:
                return all_users.get(leaf_user_id)

            path = []
            curr = all_users.get(leaf_user_id)
            visited = set()
            while curr is not None and curr.id not in visited:
                visited.add(curr.id)
                path.append(curr)
                if curr.parent_id is None: break
                curr = all_users.get(curr.parent_id)

            # Find the node in the path whose parent is the viewer
            for node in path:
                if node.parent_id == viewer_id:
                    return node
            
            # Fallback to the leaf user
            return all_users.get(leaf_user_id)

        for i, bet_obj in enumerate(actual_bets):
            raw_snapshot = serialized_bets[i]
            # Multi-win support: unfold bets with multiple prize types (separated by |)
            prize_tiers = [t.strip() for t in (bet_obj.winning_prize_type or "").split("|") if t.strip()]
            
            # Fallback if no tiers but marked as winner
            if not prize_tiers and bet_obj.is_winner:
                prize_tiers = [bet_obj.winning_prize_type or "WINNER"]

            for tier_idx, tier_name in enumerate(prize_tiers):
                p, c = 0.0, 0.0
                if use_agent_rate:
                    # Group by the direct child of the viewer (e.g. if Admin is viewing, group by Agent)
                    b_head = get_branch_head(bet_obj.user_id, user.id)
                    if not b_head:
                        b_head = bet_obj.user # Fallback
                    
                    u_key = (b_head.username, b_head.role)
                    
                    # Calculate prize ONLY for this specific tier
                    p, c = calculate_bet_win_prize_and_comm(bet_obj, b_head, specific_prize_type=tier_name)
                else:
                    # Group by the specific winning user
                    u_key = (bet_obj.user.username, bet_obj.user.role)
                    
                    # Calculate prize ONLY for this specific tier
                    p, c = calculate_bet_win_prize_and_comm(bet_obj, user, specific_prize_type=tier_name)
                
                # Create a "virtual" row for the report
                tier_entry = dict(raw_snapshot)
                tier_entry['id'] = f"{bet_obj.id}_{tier_name}_{tier_idx}" # Unique ID for frontend keys
                tier_entry['winning_prize_type'] = tier_name
                tier_entry['winning_amount'] = p
                tier_entry['winning_commission'] = c
                
                # Add per-unit rates for transparency
                tier_entry['prize_rate'] = p / float(bet_obj.count) if bet_obj.count > 0 else 0
                tier_entry['comm_rate'] = c / float(bet_obj.count) if bet_obj.count > 0 else 0
                
                unfolded_results.append(tier_entry)
                
                total_winning_amount += p
                total_winning_commission += c
                
                if u_key not in branch_summary:
                    branch_summary[u_key] = {'total_prize': 0.0, 'total_comm': 0.0, 'win_count': 0}
                
                branch_summary[u_key]['total_prize'] += p
                branch_summary[u_key]['total_comm'] += c
                branch_summary[u_key]['win_count'] += 1

        # Build final user_summary list
        results = unfolded_results
        total_winning_count = len(unfolded_results)
        user_summary = []
        for (uname, urole), val in branch_summary.items():
            user_summary.append({
                'user__username': uname,
                'user__role': urole,
                'total_prize': round(val['total_prize'], 2),
                'total_comm': round(val['total_comm'], 2),
                'win_count': val['win_count']
            })
        # --- INCLUDE FORWARDED BET WINNINGS ---
        from .models import ForwardedBet
        
        # Only include forwarded bets if specifically requested
        if forwarded_only:
            # Determine if we are viewing as SUPER_ADMIN or ADMIN
            if user.role == 'SUPER_ADMIN':
                fwd_qs = ForwardedBet.objects.filter(forwarded_to=user, is_winner=True)
                fwd_username = "FORWARDED (IN)"
            else:
                fwd_qs = ForwardedBet.objects.filter(forwarded_by=user, is_winner=True)
                fwd_username = "FORWARDED (OUT)"
                
            if from_date: fwd_qs = fwd_qs.filter(date__gte=from_date)
            if to_date: fwd_qs = fwd_qs.filter(date__lte=to_date)
            if game_id: fwd_qs = fwd_qs.filter(game_id=game_id)
            if search_number: fwd_qs = fwd_qs.filter(number=search_number)
        else:
            fwd_qs = ForwardedBet.objects.none()
            fwd_username = ""

            
        fwd_amount_total = 0.0
        fwd_count_total = 0

        for b in fwd_qs:
            fwd_amount_total += float(b.winning_amount)
            fwd_count_total += b.count
            
            prize_tiers = [t.strip() for t in (b.winning_prize_type or "WINNER").split("|") if t.strip()]
            pt_amount = float(b.winning_amount) / len(prize_tiers) if prize_tiers else float(b.winning_amount)
            
            for pt in prize_tiers:
                results.append({
                    'id': f"fwd_{b.id}",
                    'game': b.game.name,
                    'game_name': b.game.name,
                    'state': b.state,
                    'type': b.type,
                    'number': b.number,
                    'count': b.count,
                    'winning_prize_type': pt,
                    'winning_amount': pt_amount,
                    'winning_commission': 0.0,
                    'is_winner': True,
                    'user_username': fwd_username,
                    'created_at': b.created_at.isoformat() if hasattr(b.created_at, 'isoformat') else b.created_at,
                })

        if fwd_count_total > 0:
            total_winning_amount += fwd_amount_total
            total_winning_count += fwd_count_total
            user_summary.append({
                'user__username': fwd_username,
                'user__role': 'FORWARD',
                'total_prize': round(fwd_amount_total, 2),
                'total_comm': 0.0,
                'win_count': fwd_count_total
            })

        user_summary.sort(key=lambda x: x['user__username'])
        
        return Response({
            'total_winning_amount': float(total_winning_amount),
            'total_winning_commission': float(total_winning_commission),
            'total_winning_count': total_winning_count,
            'winners': results,
            'user_summary': user_summary
        })

class MonitorView(views.APIView):
    def get(self, request):
        date_str = request.query_params.get('date')
        game_id = request.query_params.get('game')
        search_num = request.query_params.get('number')
        digits = request.query_params.get('digits') # 1, 2, 3, ALL
        
        if not date_str:
            date = timezone.localtime().date()
        else:
            try:
                date = datetime.strptime(date_str, '%Y-%m-%d').date()
            except:
                date = timezone.localtime().date()
            
        bets = Bet.objects.filter(created_at__date=date).distinct()
        if game_id:
            bets = bets.filter(game_id=game_id)
        if search_num:
            bets = bets.filter(number__icontains=search_num)
        
        # Filter by digits length
        if digits == '1':
            bets = bets.filter(Q(type='A') | Q(type='B') | Q(type='C'))
        elif digits == '2':
            bets = bets.filter(Q(type='AB') | Q(type='BC') | Q(type='AC'))
        elif digits == '3':
            bets = bets.filter(Q(type='SUPER') | Q(type='BOX'))

        results = bets.values(
            'user__id', 'user__username', 
            'game__id', 'game__name', 
            'number', 'type'
        ).annotate(
            total_count=Sum('count')
        )
        
        data = []
        # Pre-fetch users for efficiency since we need their individual limits if NumberLimit doesn't exist
        user_ids = [res['user__id'] for res in results]
        users_map = {u.id: u for u in User.objects.filter(id__in=user_ids)}
        
        for res in results:
            u_id = res['user__id']
            g_id = res['game__id']
            num = res['number']
            b_type = res['type']
            t_cnt = res['total_count']
            
            # Get individual limit
            try:
                limit_obj = NumberLimit.objects.get(user_id=u_id, game_id=g_id, number=num, type=b_type)
                limit = limit_obj.max_count
            except NumberLimit.DoesNotExist:
                user = users_map.get(u_id)
                limit = get_user_type_count_limit(user, b_type)
                
            # Get cleared count
            try:
                cleared = ClearedExposure.objects.get(user_id=u_id, game_id=g_id, number=num, type=b_type, date=date).count
            except ClearedExposure.DoesNotExist:
                cleared = 0
                
            # Prepare base row
            base_row = {
                'name': res['user__username'],
                'ticket': f"{res['game__name']}-{b_type}",
                'no': num,
                'cnt': t_cnt,
                'clr': cleared,
                'lim': limit,
                'user_id': u_id,
                'game_id': g_id,
                'type': b_type,
                'is_winner': bool(res['is_winner']),
                'win_prize_total': float(res['win_amount'] or 0),
            }
            
            # Multi-win unfolding
            prize_type_str = res.get('win_prize_type') or ""
            tiers = [t.strip() for t in prize_type_str.split("|") if t.strip()]
            
            if not tiers and res.get('is_winner'):
                tiers = ["WINNER"]
            
            if not tiers:
                base_row['win_prize_type'] = ""
                data.append(base_row)
            else:
                for t in tiers:
                    unfolded = dict(base_row)
                    unfolded['win_prize_type'] = t
                    data.append(unfolded)
            
        return Response(data)

    def post(self, request):
        user_id = request.data.get('user_id')
        game_id = request.data.get('game_id')
        number = request.data.get('no')
        bet_type = request.data.get('type')
        date_str = request.data.get('date')
        amount = int(request.data.get('amount', 0))
        
        if not date_str:
            date = timezone.now().date()
        else:
            try:
                date = datetime.strptime(date_str, '%Y-%m-%d').date()
            except:
                date = timezone.now().date()
            
        cleared, created = ClearedExposure.objects.get_or_create(
            user_id=user_id, game_id=game_id, number=number, type=bet_type, date=date
        )
        if amount > 0:
            cleared.count += amount
        else:
            # If no amount provided, assume clearing the entire excess
            # or just default increment
            cleared.count += 1 
            
        cleared.save()
        return Response({'success': True, 'new_cleared': cleared.count})

class DashboardView(views.APIView):
    def get(self, request):
        user = request.user
        # Weekly Stats calculation according to local monday to sunday
        week_start = timezone.localtime().date() - timezone.timedelta(days=timezone.localtime().weekday())
        
        if user.role == 'SUPER_ADMIN':
            # Global daily stats for Super Admin cards
            today = timezone.localtime().date()
            global_daily_bets = Bet.objects.filter(created_at__date=today)
            excluded_ids = get_excluded_forwarding_user_ids()
            if excluded_ids:
                global_daily_bets = global_daily_bets.exclude(user_id__in=excluded_ids)
            stats = global_daily_bets.aggregate(
                sales=Sum(F('amount') * F('count')),
                wins=Sum('winning_amount')
            )
            sales = stats['sales'] or 0
            wins = stats['wins'] or 0
            data = {
                'username': user.username,
                'role': user.role,
                'global_daily_sales': sales,
                'global_daily_wins': wins,
                'global_daily_profit': float(sales) - float(wins),
                'active_games': Game.objects.filter(is_active=True).count()
            }
        else:
            # Stats for others (Branch-wide)
            descendant_ids = user.get_descendant_ids()
            weekly_bets = Bet.objects.filter(user_id__in=descendant_ids, created_at__date__gte=week_start)
            stats = weekly_bets.aggregate(
                sales=Sum(F('amount') * F('count')),
                wins=Sum('winning_amount')
            )
            sales = stats['sales'] or 0
            wins = stats['wins'] or 0
            
            # Remaining credit is now properly hierarchical
            net_loss = user.get_weekly_net_loss()
            remaining_credit = float(user.weekly_credit_limit) - float(net_loss)
            
            data = {
                'username': user.username,
                'role': user.role,
                'can_forward': getattr(user, 'can_forward', False),
                'weekly_credit_limit': user.weekly_credit_limit,
                'remaining_credit': remaining_credit,
                'weekly_sales': sales,
                'weekly_wins': wins,
                'total_sales': Bet.objects.filter(user_id__in=descendant_ids).aggregate(total=Sum(F('amount') * F('count')))['total'] or 0,
                'active_games': Game.objects.filter(is_active=True).count()
            }

        if user.role != 'SUB_DEALER':
            # Only show users directly created by the logged-in user
            recent_users = User.objects.filter(parent=user).order_by('-date_joined')[:50]
            data['users'] = UserSerializer(recent_users, many=True).data

        return Response(data)

class NumberLimitViewSet(viewsets.ModelViewSet):
    queryset = NumberLimit.objects.all()
    serializer_class = NumberLimitSerializer

    def get_queryset(self):
        game_id = self.request.query_params.get('game')
        user_id = self.request.query_params.get('user')
        qs = NumberLimit.objects.all()
        if game_id:
            qs = qs.filter(game_id=game_id)
        if user_id:
            qs = qs.filter(user_id=user_id)
        return qs

class GlobalNumberLimitViewSet(viewsets.ModelViewSet):
    queryset = GlobalNumberLimit.objects.all()
    serializer_class = GlobalNumberLimitSerializer

    def get_queryset(self):
        user = self.request.user
        game_id = self.request.query_params.get('game')
        
        # Super Admin sees everything
        if user.role == 'SUPER_ADMIN':
            qs = GlobalNumberLimit.objects.all()
        else:
            # Admins see their own limits and system-wide (None) limits
            qs = GlobalNumberLimit.objects.filter(Q(admin=user) | Q(admin__isnull=True))

        if game_id:
            qs = qs.filter(game_id=game_id)
        return qs

    def perform_create(self, serializer):
        # Assign current user as owner of the limit they are creating
        # Unless they are Super Admin, in which case null admin = System Global
        if self.request.user.role != 'SUPER_ADMIN':
            serializer.save(admin=self.request.user)
        else:
            serializer.save()

class UserGameTimingViewSet(viewsets.ModelViewSet):
    queryset = UserGameTiming.objects.all()
    serializer_class = UserGameTimingSerializer

    def get_queryset(self):
        user_id = self.request.query_params.get('user')
        if user_id:
            return UserGameTiming.objects.filter(user_id=user_id)
        return UserGameTiming.objects.all()

    def perform_create(self, serializer):
        # Allow superadmin or admin to set timings
        serializer.save()


class GameResultViewSet(viewsets.ModelViewSet):
    queryset = GameResult.objects.all()
    serializer_class = GameResultSerializer

    def get_queryset(self):
        queryset = GameResult.objects.all()
        date = self.request.query_params.get('date')
        game_id = self.request.query_params.get('game')
        if date:
            queryset = queryset.filter(date=date)
        if game_id:
            queryset = queryset.filter(game_id=game_id)
        return queryset.order_by('-date', '-created_at')

    def create(self, request, *args, **kwargs):
        game_id = request.data.get('game')
        date_str = request.data.get('date')
        
        if date_str:
            date = datetime.strptime(date_str, '%Y-%m-%d').date()
        else:
            date = timezone.now().date()
            
        # Check if result already exists for this game/date
        existing = GameResult.objects.filter(game_id=game_id, date=date).first()
        if existing:
            # Re-route to update
            serializer = self.get_serializer(existing, data=request.data, partial=True)
        else:
            # Standard create
            serializer = self.get_serializer(data=request.data)
            
        serializer.is_valid(raise_exception=True)
        self.perform_create(serializer)
        
        return Response(serializer.data, status=status.HTTP_201_CREATED if not existing else status.HTTP_200_OK)

    def perform_create(self, serializer):
        game_result = serializer.save()
        self._calculate_winners(game_result)

    def perform_destroy(self, instance):
        # Reset bets associated with this game/date
        game = instance.game
        date = instance.date
        Bet.objects.filter(game=game, created_at__date=date).update(
            is_winner=False,
            winning_amount=0,
            winning_commission=0,
            winning_prize_type=None
        )
        instance.delete()

    def _calculate_winners(self, game_result):
        game = game_result.game
        date = game_result.date
        
        # 1. Define all prize sources
        prizes = [
            ("1ST PRIZE", (game_result.winning_number or "").strip()),
            ("2ND PRIZE", (game_result.second_prize or "").strip()),
            ("3RD PRIZE", (game_result.third_prize or "").strip()),
            ("4TH PRIZE", (game_result.fourth_prize or "").strip()),
            ("5TH PRIZE", (game_result.fifth_prize or "").strip()),
        ]
        
        # Add compliments
        if game_result.complimentary_numbers:
            import re
            comps = re.split(r'[,\s\n]+', game_result.complimentary_numbers.strip())
            for c_num in comps:
                if c_num.strip():
                    prizes.append(("COMPLIMENT", c_num.strip()))

        # 2. Reset all bets for this game/date
        # Use a 2-day window: bets may have been placed on the result date or the day before
        from datetime import timedelta
        date_from = date - timedelta(days=1)
        all_bets_qs = Bet.objects.filter(game=game, created_at__date__gte=date_from, created_at__date__lte=date)
        all_bets_qs.update(is_winner=False, winning_amount=0, winning_commission=0, winning_prize_type=None)

        # 3. Find potential bets
        # We check all bets that aren't empty
        potential_winners = all_bets_qs.exclude(number="").select_related('user')

        def get_sorted_num(n):
            return "".join(sorted(n)) if n else None

        def evaluate_wins(u, b_num, b_type, state):
            wins = []
            for tier_name, win_num in prizes:
                if not win_num: continue
                match = False
                p, c = 0.0, 0.0
                
                # Check match based on type
                if b_type == 'SUPER':
                    if b_num == win_num:
                        match = True
                        if tier_name == "1ST PRIZE": p, c = u.prize_super_1, u.comm_super_1
                        elif tier_name == "2ND PRIZE": p, c = u.prize_super_2, u.comm_super_2
                        elif tier_name == "3RD PRIZE": p, c = u.prize_super_3, u.comm_super_3
                        elif tier_name == "4TH PRIZE": p, c = u.prize_super_4, u.comm_super_4
                        elif tier_name == "5TH PRIZE": p, c = u.prize_super_5, u.comm_super_5
                        else: p, c = u.prize_6th, u.comm_6th # COMPLIMENT
                
                elif b_type == 'BOX':
                    if tier_name != "1ST PRIZE":
                        continue
                    s_b = get_sorted_num(b_num)
                    s_w = get_sorted_num(win_num)
                    if s_b and s_w and s_b == s_w:
                        match = True
                        distinct = len(set(b_num))
                        is_exact = (b_num == win_num)
                        box_level = 1 if is_exact else 2
                        if distinct == 3:
                            p = float(u.prize_box_3d_1) if box_level == 1 else float(u.prize_box_3d_2)
                            c = float(u.comm_box_3d_1)  if box_level == 1 else float(u.comm_box_3d_2)
                        elif distinct == 2:
                            p = float(u.prize_box_2s_1) if box_level == 1 else float(u.prize_box_2s_2)
                            c = float(u.comm_box_2s_1)  if box_level == 1 else float(u.comm_box_2s_2)
                        else:
                            p = float(u.prize_box_3s_1)
                            c = float(u.comm_box_3s_1)

                elif b_type in ['AB', 'BC', 'AC', 'A', 'B', 'C', 'TN-AB', 'TN-BC', 'TN-AC', 'TN-A', 'TN-B', 'TN-C']:
                    if tier_name != "1ST PRIZE":
                        continue
                    
                    base_win = win_num[-3:] if len(win_num) >= 3 else win_num
                    target = ""
                    # Normalize type for matching (strip TN- prefix)
                    norm_type = b_type.replace('TN-', '')
                    is_tn_type = b_type.startswith('TN-')
                    if len(base_win) >= 3:
                        if norm_type == 'AB': target = base_win[0:2]
                        elif norm_type == 'BC': target = base_win[1:3]
                        elif norm_type == 'AC': target = base_win[0] + base_win[2]
                        elif norm_type == 'A': target = base_win[0]
                        elif norm_type == 'B': target = base_win[1]
                        elif norm_type == 'C': target = base_win[2]
                    elif len(base_win) == 2:
                        if norm_type == 'AB': target = base_win
                        elif norm_type == 'A': target = base_win[0]
                        elif norm_type == 'B': target = base_win[1]
                    elif len(base_win) == 1:
                        if norm_type == 'A': target = base_win
                    
                    if target and b_num == target:
                        match = True
                        if is_tn_type or state == 'TN':
                            if norm_type in ['AB', 'BC', 'AC']: p, c = float(u.tn_prize_ab_bc_ac), 0.0
                            else: p, c = float(u.tn_prize_abc), 0.0
                        else:
                            if norm_type in ['AB', 'BC', 'AC']: p, c = float(u.prize_ab_bc_ac_1), float(u.comm_ab_bc_ac_1)
                            else: p, c = float(u.prize_abc_1), float(u.comm_abc_1)

                elif b_type in ['3D-10', '3D-25', '3D-30', '3D-60']:
                    if tier_name != "2ND PRIZE":
                        continue
                    if not win_num or len(win_num) < 3:
                        continue
                    if b_num == win_num:
                        match = True
                        c = 0.0
                        if b_type == '3D-10': p = float(u.tn_prize_3d_10)
                        elif b_type == '3D-25': p = float(u.tn_prize_3d_25)
                        elif b_type == '3D-30': p = float(u.tn_prize_3d_30)
                        elif b_type == '3D-60': p = float(u.tn_prize_3d_60)
                    elif len(b_num) >= 2 and b_num[-2:] == win_num[-2:]:
                        match = True
                        c = 0.0
                        if b_type == '3D-10': p = float(u.tn_prize_3d_10_bc)
                        elif b_type == '3D-25': p = float(u.tn_prize_3d_25_bc)
                        elif b_type == '3D-30': p = float(u.tn_prize_3d_30_bc)
                        elif b_type == '3D-60': p = float(u.tn_prize_3d_60_bc)
                    elif len(b_num) >= 1 and b_num[-1:] == win_num[-1:] and b_type in ['3D-30', '3D-60']:
                        match = True
                        c = 0.0
                        if b_type == '3D-30': p = float(u.tn_prize_3d_30_c)
                        elif b_type == '3D-60': p = float(u.tn_prize_3d_60_c)

                elif b_type in ['4D-110', '4D-55', '4D-20']:
                    if tier_name != "1ST PRIZE":
                        continue
                    if not win_num or len(win_num) < 4:
                        continue
                    if b_num == win_num:
                        match = True
                        c = 0.0
                        if b_type == '4D-110': p = float(u.tn_prize_4d_110_1)
                        elif b_type == '4D-55': p = float(u.tn_prize_4d_55_1)
                        elif b_type == '4D-20': p = float(u.tn_prize_4d_20_1)
                    elif b_num[-3:] == win_num[-3:] and b_type in ['4D-110', '4D-55']:
                        match = True
                        c = 0.0
                        if b_type == '4D-110': p = float(u.tn_prize_4d_110_2)
                        elif b_type == '4D-55': p = float(u.tn_prize_4d_55_2)
                    elif b_num[-2:] == win_num[-2:] and b_type in ['4D-110', '4D-55']:
                        match = True
                        c = 0.0
                        if b_type == '4D-110': p = float(u.tn_prize_4d_110_3)
                        elif b_type == '4D-55': p = float(u.tn_prize_4d_55_3)
                    elif b_num[-1:] == win_num[-1:] and b_type in ['4D-110', '4D-55']:
                        match = True
                        c = 0.0
                        if b_type == '4D-110': p = float(u.tn_prize_4d_110_4)
                        elif b_type == '4D-55': p = float(u.tn_prize_4d_55_4)

                if match:
                    display_name = f"{tier_name} ({b_type})"
                    if b_type == 'SUPER':
                        display_name = tier_name
                    elif b_type == 'BOX':
                        is_exact_match = (b_num == win_num)
                        display_name = "BOX (1ST PRIZE) EXACT" if is_exact_match else "BOX2 (1ND PRIZE)"
                    elif b_type in ['3D-10', '3D-25', '3D-30', '3D-60']:
                        # Determine if they won exactly, BC, or C based on length of match?
                        # It's easier to determine from `win_num` vs `b_num`.
                        if b_num == win_num: display_name = f"{tier_name} ({b_type}) EXACT"
                        elif len(b_num) >= 2 and b_num[-2:] == win_num[-2:]: display_name = f"{tier_name} ({b_type}) BC MATCH"
                        elif len(b_num) >= 1 and b_num[-1:] == win_num[-1:]: display_name = f"{tier_name} ({b_type}) C MATCH"
                    elif b_type in ['4D-110', '4D-55']:
                        if b_num == win_num: display_name = f"1ST PRIZE ({b_type})"
                        elif b_num[-3:] == win_num[-3:]: display_name = f"2ND PRIZE ({b_type})"
                        elif b_num[-2:] == win_num[-2:]: display_name = f"3RD PRIZE ({b_type})"
                        elif b_num[-1:] == win_num[-1:]: display_name = f"4TH PRIZE ({b_type})"

                    wins.append((display_name, p, c))
                    break # Usually stop matching after finding highest tier for this type against the same prize structure! Wait, no, we iterate over prizes. 
                    # If it's a 3D/4D match, it matches one of the tiers. `match` means they won. But what if they match another prize?
                    # The `prizes` loop continues. So they could win multiple times? E.g., multiple exact matches?
                    # Actually, for 4D it only checks "1ST PRIZE" tier. So it breaks anyway.

            return wins

        for b in potential_winners:
            wins = evaluate_wins(b.user, b.number.strip(), b.type.upper(), b.state)
            if wins:
                b.is_winner = True
                b.winning_amount = sum(w[1] for w in wins) * b.count
                b.winning_commission = sum(w[2] for w in wins) * b.count
                b.winning_prize_type = "|".join(w[0] for w in wins)
                b.save()
                
        # 4. Update ForwardedBets
        from .models import ForwardedBet
        all_fwd_bets = ForwardedBet.objects.filter(game=game, date=date)
        all_fwd_bets.update(is_winner=False, winning_amount=0)
        
        potential_fwd_winners = all_fwd_bets.exclude(number="").select_related('forwarded_by')
        for fb in potential_fwd_winners:
            wins = evaluate_wins(fb.forwarded_by, fb.number.strip(), fb.type.upper(), fb.state)
            if wins:
                fb.is_winner = True
                fb.winning_amount = sum(w[1] for w in wins) * fb.count
                fb.save()

class NumberLimitViewSet(viewsets.ModelViewSet):
    queryset = NumberLimit.objects.all()
    serializer_class = NumberLimitSerializer

    def get_queryset(self):
        game_id = self.request.query_params.get('game')
        user_id = self.request.query_params.get('user')
        qs = NumberLimit.objects.all()
        if game_id:
            qs = qs.filter(game_id=game_id)
        if user_id:
            qs = qs.filter(user_id=user_id)
        return qs

class GlobalNumberLimitViewSet(viewsets.ModelViewSet):
    queryset = GlobalNumberLimit.objects.all()
    serializer_class = GlobalNumberLimitSerializer

    def get_queryset(self):
        user = self.request.user
        game_id = self.request.query_params.get('game')
        
        # Super Admin sees everything
        if user.role == 'SUPER_ADMIN':
            qs = GlobalNumberLimit.objects.all()
        else:
            # Admins see their own limits and system-wide (None) limits
            qs = GlobalNumberLimit.objects.filter(Q(admin=user) | Q(admin__isnull=True))

        if game_id:
            qs = qs.filter(game_id=game_id)
        return qs

    def perform_create(self, serializer):
        # Assign current user as owner of the limit they are creating
        # Unless they are Super Admin, in which case null admin = System Global
        if self.request.user.role != 'SUPER_ADMIN':
            serializer.save(admin=self.request.user)
        else:
            serializer.save()

class UserGameTimingViewSet(viewsets.ModelViewSet):
    queryset = UserGameTiming.objects.all()
    serializer_class = UserGameTimingSerializer

    def get_queryset(self):
        user_id = self.request.query_params.get('user')
        if user_id:
            return UserGameTiming.objects.filter(user_id=user_id)
        return UserGameTiming.objects.all()

    def perform_create(self, serializer):
        # Allow superadmin or admin to set timings
        serializer.save()


class GameResultViewSet(viewsets.ModelViewSet):
    queryset = GameResult.objects.all()
    serializer_class = GameResultSerializer

    def get_queryset(self):
        queryset = GameResult.objects.all()
        date = self.request.query_params.get('date')
        game_id = self.request.query_params.get('game')
        if date:
            queryset = queryset.filter(date=date)
        if game_id:
            queryset = queryset.filter(game_id=game_id)
        return queryset.order_by('-date', '-created_at')

    def create(self, request, *args, **kwargs):
        game_id = request.data.get('game')
        date_str = request.data.get('date')
        
        if date_str:
            date = datetime.strptime(date_str, '%Y-%m-%d').date()
        else:
            date = timezone.now().date()
            
        # Check if result already exists for this game/date
        existing = GameResult.objects.filter(game_id=game_id, date=date).first()
        if existing:
            # Re-route to update
            serializer = self.get_serializer(existing, data=request.data, partial=True)
        else:
            # Standard create
            serializer = self.get_serializer(data=request.data)
            
        serializer.is_valid(raise_exception=True)
        self.perform_create(serializer)
        
        return Response(serializer.data, status=status.HTTP_201_CREATED if not existing else status.HTTP_200_OK)

    def perform_create(self, serializer):
        game_result = serializer.save()
        self._calculate_winners(game_result)

    def perform_destroy(self, instance):
        # Reset bets associated with this game/date
        game = instance.game
        date = instance.date
        Bet.objects.filter(game=game, created_at__date=date).update(
            is_winner=False,
            winning_amount=0,
            winning_commission=0,
            winning_prize_type=None
        )
        instance.delete()

    def _calculate_winners(self, game_result):
        game = game_result.game
        date = game_result.date
        
        # 1. Define all prize sources
        prizes = [
            ("1ST PRIZE", (game_result.winning_number or "").strip()),
            ("2ND PRIZE", (game_result.second_prize or "").strip()),
            ("3RD PRIZE", (game_result.third_prize or "").strip()),
            ("4TH PRIZE", (game_result.fourth_prize or "").strip()),
            ("5TH PRIZE", (game_result.fifth_prize or "").strip()),
        ]
        
        # Add compliments
        if game_result.complimentary_numbers:
            import re
            comps = re.split(r'[,\s\n]+', game_result.complimentary_numbers.strip())
            for c_num in comps:
                if c_num.strip():
                    prizes.append(("COMPLIMENT", c_num.strip()))

        # 2. Reset all bets for this game/date
        # Use a 2-day window: bets may have been placed on the result date or the day before
        from datetime import timedelta
        date_from = date - timedelta(days=1)
        all_bets_qs = Bet.objects.filter(game=game, created_at__date__gte=date_from, created_at__date__lte=date)
        all_bets_qs.update(is_winner=False, winning_amount=0, winning_commission=0, winning_prize_type=None)

        # 3. Find potential bets
        # We check all bets that aren't empty
        potential_winners = all_bets_qs.exclude(number="").select_related('user')

        def get_sorted_num(n):
            return "".join(sorted(n)) if n else None

        for b in potential_winners:
            u = b.user
            b_num = b.number.strip()
            b_type = b.type.upper()
            wins = [] # List of (display_name, prize_amount, comm_amount)

            for tier_name, win_num in prizes:
                if not win_num: continue
                
                match = False
                p, c = 0.0, 0.0
                
                # Check match based on type
                if b_type == 'SUPER':
                    if b_num == win_num:
                        match = True
                        # SUPER has distinct prizes for 1-5
                        if tier_name == "1ST PRIZE": p, c = u.prize_super_1, u.comm_super_1
                        elif tier_name == "2ND PRIZE": p, c = u.prize_super_2, u.comm_super_2
                        elif tier_name == "3RD PRIZE": p, c = u.prize_super_3, u.comm_super_3
                        elif tier_name == "4TH PRIZE": p, c = u.prize_super_4, u.comm_super_4
                        elif tier_name == "5TH PRIZE": p, c = u.prize_super_5, u.comm_super_5
                        else: p, c = u.prize_6th, u.comm_6th # COMPLIMENT
                
                elif b_type == 'BOX':
                    # BOX only matches against the 1ST PRIZE number.
                    # No match against 2nd, 3rd, 4th, 5th, or Compliment prizes.
                    if tier_name != "1ST PRIZE":
                        continue  # Skip this tier entirely for BOX bets

                    s_b = get_sorted_num(b_num)
                    s_w = get_sorted_num(win_num)

                    if s_b and s_w and s_b == s_w:
                        match = True
                        distinct = len(set(b_num))

                        # BOX-1: Exact match (b_num == win_num) → 1st BOX prize & commission
                        # BOX-2: Permutation match (same digits, different order) → 2nd BOX prize & commission
                        is_exact = (b_num == win_num)
                        box_level = 1 if is_exact else 2

                        if distinct == 3:      # All digits different (e.g. 325)
                            p = float(u.prize_box_3d_1) if box_level == 1 else float(u.prize_box_3d_2)
                            c = float(u.comm_box_3d_1)  if box_level == 1 else float(u.comm_box_3d_2)
                        elif distinct == 2:    # Two same, one different (e.g. 332)
                            p = float(u.prize_box_2s_1) if box_level == 1 else float(u.prize_box_2s_2)
                            c = float(u.comm_box_2s_1)  if box_level == 1 else float(u.comm_box_2s_2)
                        else:                  # All same (e.g. 333) — triple, single prize level
                            p = float(u.prize_box_3s_1)
                            c = float(u.comm_box_3s_1)

                elif b_type in ['AB', 'BC', 'AC', 'A', 'B', 'C', 'TN-AB', 'TN-BC', 'TN-AC', 'TN-A', 'TN-B', 'TN-C']:
                    if tier_name != "1ST PRIZE":
                        continue

                    # Derived match logic
                    target = ""
                    base_win = win_num[-3:] if len(win_num) >= 3 else win_num
                    # Normalize type for matching (strip TN- prefix)
                    norm_type = b_type.replace('TN-', '')
                    is_tn_type = b_type.startswith('TN-')

                    if len(base_win) >= 3:
                        if norm_type == 'AB': target = base_win[0:2]
                        elif norm_type == 'BC': target = base_win[1:3]
                        elif norm_type == 'AC': target = base_win[0] + base_win[2]
                        elif norm_type == 'A': target = base_win[0]
                        elif norm_type == 'B': target = base_win[1]
                        elif norm_type == 'C': target = base_win[2]
                    elif len(base_win) == 2:
                        if norm_type == 'AB': target = base_win
                        elif norm_type == 'A': target = base_win[0]
                        elif norm_type == 'B': target = base_win[1]
                    elif len(base_win) == 1:
                        if norm_type == 'A': target = base_win

                    if target and b_num == target:
                        match = True
                        if is_tn_type or b.state == 'TN':
                            if norm_type in ['AB', 'BC', 'AC']:
                                p, c = float(u.tn_prize_ab_bc_ac), 0.0
                            else:
                                p, c = float(u.tn_prize_abc), 0.0
                        else:
                            if norm_type in ['AB', 'BC', 'AC']:
                                p, c = float(u.prize_ab_bc_ac_1), float(u.comm_ab_bc_ac_1)
                            else:
                                p, c = float(u.prize_abc_1), float(u.comm_abc_1)

                elif b_type in ['3D-10', '3D-25', '3D-30', '3D-60']:
                    # 3D games check against 2nd PRIZE (which in TN is the last 3 digits of 1st PRIZE)
                    if tier_name != "2ND PRIZE":
                        continue
                    if not win_num or len(win_num) < 3:
                        continue
                    
                    # Exact Match
                    if b_num == win_num:
                        match = True
                        c = 0.0
                        if b_type == '3D-10': p = u.tn_prize_3d_10
                        elif b_type == '3D-25': p = u.tn_prize_3d_25
                        elif b_type == '3D-30': p = u.tn_prize_3d_30
                        elif b_type == '3D-60': p = u.tn_prize_3d_60
                    # BC Match (last 2 digits)
                    elif len(b_num) >= 2 and b_num[-2:] == win_num[-2:]:
                        match = True
                        c = 0.0
                        if b_type == '3D-10': p = u.tn_prize_3d_10_bc
                        elif b_type == '3D-25': p = u.tn_prize_3d_25_bc
                        elif b_type == '3D-30': p = u.tn_prize_3d_30_bc
                        elif b_type == '3D-60': p = u.tn_prize_3d_60_bc
                    # C Match (last 1 digit)
                    elif len(b_num) >= 1 and b_num[-1:] == win_num[-1:] and b_type in ['3D-30', '3D-60']:
                        match = True
                        c = 0.0
                        if b_type == '3D-30': p = u.tn_prize_3d_30_c
                        elif b_type == '3D-60': p = u.tn_prize_3d_60_c

                elif b_type in ['4D-110', '4D-55', '4D-20']:
                    # 4D games match against 1ST PRIZE
                    if tier_name != "1ST PRIZE":
                        continue
                    if not win_num or len(win_num) < 4:
                        continue
                    
                    # Exact match (1st Prize)
                    if b_num == win_num:
                        match = True
                        c = 0.0
                        if b_type == '4D-110': p = u.tn_prize_4d_110_1
                        elif b_type == '4D-55': p = u.tn_prize_4d_55_1
                        elif b_type == '4D-20': p = u.tn_prize_4d_20_1
                    # 2nd Prize match (last 3 digits)
                    elif b_num[-3:] == win_num[-3:] and b_type in ['4D-110', '4D-55']:
                        match = True
                        c = 0.0
                        if b_type == '4D-110': p = u.tn_prize_4d_110_2
                        elif b_type == '4D-55': p = u.tn_prize_4d_55_2
                    # 3rd Prize match (last 2 digits)
                    elif b_num[-2:] == win_num[-2:] and b_type in ['4D-110', '4D-55']:
                        match = True
                        c = 0.0
                        if b_type == '4D-110': p = u.tn_prize_4d_110_3
                        elif b_type == '4D-55': p = u.tn_prize_4d_55_3
                    # 4th Prize match (last 1 digit)
                    elif b_num[-1:] == win_num[-1:] and b_type in ['4D-110', '4D-55']:
                        match = True
                        c = 0.0
                        if b_type == '4D-110': p = u.tn_prize_4d_110_4
                        elif b_type == '4D-55': p = u.tn_prize_4d_55_4

                if match:
                    if b_type == 'SUPER':
                        display_name = tier_name
                    elif b_type == 'BOX':
                        # Since BOX only reaches here for 1ST PRIZE tier,
                        # exact match → BOX (1ST PRIZE) EXACT
                        # permutation match → BOX2 (1ND PRIZE)
                        is_exact_match = (b_num == win_num)
                        display_name = "BOX (1ST PRIZE) EXACT" if is_exact_match else "BOX2 (1ND PRIZE)"
                    elif b_type in ['3D-10', '3D-25', '3D-30', '3D-60']:
                        if b_num == win_num:
                            display_name = f"2ND PRIZE ({b_type}) EXACT"
                        elif len(b_num) >= 2 and b_num[-2:] == win_num[-2:]:
                            display_name = f"2ND PRIZE ({b_type}) BC MATCH"
                        elif len(b_num) >= 1 and b_num[-1:] == win_num[-1:]:
                            display_name = f"2ND PRIZE ({b_type}) C MATCH"
                        else:
                            display_name = f"2ND PRIZE ({b_type})"
                    elif b_type in ['4D-110', '4D-55']:
                        if b_num == win_num:
                            display_name = f"1ST PRIZE ({b_type})"
                        elif b_num[-3:] == win_num[-3:]:
                            display_name = f"2ND PRIZE ({b_type})"
                        elif b_num[-2:] == win_num[-2:]:
                            display_name = f"3RD PRIZE ({b_type})"
                        elif b_num[-1:] == win_num[-1:]:
                            display_name = f"4TH PRIZE ({b_type})"
                        else:
                            display_name = f"1ST PRIZE ({b_type})"
                    else:
                        display_name = f"{tier_name} ({b_type})"
                    
                    wins.append((display_name, p, c))

            if wins:
                b.is_winner = True
                b.winning_amount = sum(w[1] for w in wins) * b.count
                b.winning_commission = sum(w[2] for w in wins) * b.count
                b.winning_prize_type = "|".join(w[0] for w in wins)
                b.save()
                
        # 4. Update ForwardedBets
        from .models import ForwardedBet
        all_fwd_bets = ForwardedBet.objects.filter(game=game, date=date)
        all_fwd_bets.update(is_winner=False, winning_amount=0)
        
        potential_fwd_winners = all_fwd_bets.exclude(number="").select_related('forwarded_by')
        for fb in potential_fwd_winners:
            u = fb.forwarded_by
            b_num = fb.number.strip()
            b_type = fb.type.upper()
            wins = []

            for tier_name, win_num in prizes:
                if not win_num: continue
                match = False
                p = 0.0
                
                if b_type == 'SUPER':
                    if b_num == win_num:
                        match = True
                        if tier_name == "1ST PRIZE": p = u.prize_super_1
                        elif tier_name == "2ND PRIZE": p = u.prize_super_2
                        elif tier_name == "3RD PRIZE": p = u.prize_super_3
                        elif tier_name == "4TH PRIZE": p = u.prize_super_4
                        elif tier_name == "5TH PRIZE": p = u.prize_super_5
                        else: p = u.prize_6th
                elif b_type == 'BOX':
                    if tier_name != "1ST PRIZE": continue
                    s_b = get_sorted_num(b_num)
                    s_w = get_sorted_num(win_num)
                    if s_b and s_w and s_b == s_w:
                        match = True
                        distinct = len(set(b_num))
                        is_exact = (b_num == win_num)
                        box_level = 1 if is_exact else 2
                        if distinct == 3:
                            p = float(u.prize_box_3d_1) if box_level == 1 else float(u.prize_box_3d_2)
                        elif distinct == 2:
                            p = float(u.prize_box_2s_1) if box_level == 1 else float(u.prize_box_2s_2)
                        else:
                            p = float(u.prize_box_3s_1)
                elif b_type in ['AB', 'BC', 'AC', 'A', 'B', 'C', 'TN-AB', 'TN-BC', 'TN-AC', 'TN-A', 'TN-B', 'TN-C']:
                    if tier_name != "1ST PRIZE": continue
                    target = ""
                    norm_type = b_type.replace('TN-', '')
                    is_tn_type = b_type.startswith('TN-')
                    base_win = win_num[-3:] if len(win_num) >= 3 else win_num
                    if len(base_win) >= 3:
                        if norm_type == 'AB': target = base_win[0:2]
                        elif norm_type == 'BC': target = base_win[1:3]
                        elif norm_type == 'AC': target = base_win[0] + base_win[2]
                        elif norm_type == 'A': target = base_win[0]
                        elif norm_type == 'B': target = base_win[1]
                        elif norm_type == 'C': target = base_win[2]
                    elif len(base_win) == 2:
                        if norm_type == 'AB': target = base_win
                        elif norm_type == 'A': target = base_win[0]
                        elif norm_type == 'B': target = base_win[1]
                    elif len(base_win) == 1:
                        if norm_type == 'A': target = base_win
                    if target and b_num == target:
                        match = True
                        if is_tn_type or b.state == 'TN':
                            if norm_type in ['AB', 'BC', 'AC']: p = float(u.tn_prize_ab_bc_ac)
                            else: p = float(u.tn_prize_abc)
                        else:
                            if norm_type in ['AB', 'BC', 'AC']: p = float(u.prize_ab_bc_ac_1)
                            else: p = float(u.prize_abc_1)

                if match:
                    if b_type == 'SUPER':
                        display_name = tier_name
                    elif b_type == 'BOX':
                        is_exact_match = (b_num == win_num)
                        display_name = "BOX (1ST PRIZE) EXACT" if is_exact_match else "BOX2 (1ND PRIZE)"
                    else:
                        display_name = f"{tier_name} ({b_type})"
                    wins.append((display_name, p))

            if wins:
                fb.is_winner = True
                fb.winning_amount = sum(w[1] for w in wins) * fb.count
                fb.winning_prize_type = "|".join(w[0] for w in wins)
                fb.save()


class ForwardLimitViewSet(viewsets.ModelViewSet):
    queryset = ForwardLimit.objects.all()
    serializer_class = type('ForwardLimitSerializer', (serializers.ModelSerializer,), {
        'Meta': type('Meta', (), {'model': ForwardLimit, 'fields': '__all__'})
    })
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        user = self.request.user
        if user.role == 'SUPER_ADMIN':
            return ForwardLimit.objects.all()
        return ForwardLimit.objects.filter(admin=user)

def get_forwarded_bet_net_rate(fwd_user, state, btype):
    from decimal import Decimal
    state = (state or 'KL').upper()
    btype = (btype or '').upper()
    
    # 1. Gross Price
    if state == 'TN':
        if btype in ['A', 'B', 'C']: gross = Decimal(str(getattr(fwd_user, 'tn_price_abc', 12.0) or 12.0))
        elif btype in ['AB', 'BC', 'AC']: gross = Decimal(str(getattr(fwd_user, 'tn_price_ab_bc_ac', 10.0) or 10.0))
        elif btype == '3D-10': gross = Decimal(str(getattr(fwd_user, 'tn_price_3d_10', 10.0) or 10.0))
        elif btype == '3D-25': gross = Decimal(str(getattr(fwd_user, 'tn_price_3d_25', 25.0) or 25.0))
        elif btype == '3D-30': gross = Decimal(str(getattr(fwd_user, 'tn_price_3d_30', 30.0) or 30.0))
        elif btype == '3D-60': gross = Decimal(str(getattr(fwd_user, 'tn_price_3d_60', 60.0) or 60.0))
        elif btype == '4D-110': gross = Decimal(str(getattr(fwd_user, 'tn_price_4d_110', 110.0) or 110.0))
        elif btype == '4D-55': gross = Decimal(str(getattr(fwd_user, 'tn_price_4d_55', 55.0) or 55.0))
        elif btype == '4D-20': gross = Decimal(str(getattr(fwd_user, 'tn_price_4d_20', 20.0) or 20.0))
        else: gross = Decimal('10.0')
    else:
        if btype in ['A', 'B', 'C']: gross = Decimal(str(fwd_user.price_abc or 12.0))
        elif btype in ['AB', 'BC', 'AC']: gross = Decimal(str(fwd_user.price_ab_bc_ac or 10.0))
        elif btype == 'SUPER': gross = Decimal(str(fwd_user.price_super or 40.0))
        elif btype == 'BOX': gross = Decimal(str(fwd_user.price_box or 40.0))
        else: gross = Decimal('10.0')

    # 2. Sales Commission Rate (What Super Admin gives to this Admin)
    if state == 'TN':
        if btype in ['A', 'B', 'C']: comm = Decimal(str(getattr(fwd_user, 'tn_sales_comm_abc', 0.0) or 0.0))
        elif btype in ['AB', 'BC', 'AC']: comm = Decimal(str(getattr(fwd_user, 'tn_sales_comm_ab_bc_ac', 0.0) or 0.0))
        elif btype == '3D-10': comm = Decimal(str(getattr(fwd_user, 'tn_sales_comm_3d_10', 0.0) or 0.0))
        elif btype == '3D-25': comm = Decimal(str(getattr(fwd_user, 'tn_sales_comm_3d_25', 0.0) or 0.0))
        elif btype == '3D-30': comm = Decimal(str(getattr(fwd_user, 'tn_sales_comm_3d_30', 0.0) or 0.0))
        elif btype == '3D-60': comm = Decimal(str(getattr(fwd_user, 'tn_sales_comm_3d_60', 0.0) or 0.0))
        elif btype == '4D-110': comm = Decimal(str(getattr(fwd_user, 'tn_sales_comm_4d_110', 0.0) or 0.0))
        elif btype == '4D-55': comm = Decimal(str(getattr(fwd_user, 'tn_sales_comm_4d_55', 0.0) or 0.0))
        elif btype == '4D-20': comm = Decimal(str(getattr(fwd_user, 'tn_sales_comm_4d_20', 0.0) or 0.0))
        else: comm = Decimal('0.0')
    else:
        if btype in ['A', 'B', 'C']: comm = Decimal(str(fwd_user.sales_comm_abc or 0.0))
        elif btype in ['AB', 'BC', 'AC']: comm = Decimal(str(fwd_user.sales_comm_ab_bc_ac or 0.0))
        elif btype == 'SUPER': comm = Decimal(str(fwd_user.sales_comm_super or 0.0))
        elif btype == 'BOX': comm = Decimal(str(fwd_user.sales_comm_box or 0.0))
        else: comm = Decimal('0.0')

    net_rate = gross - comm
    return net_rate, gross, comm

class ForwardedBetViewSet(viewsets.ModelViewSet):
    queryset = ForwardedBet.objects.all()
    serializer_class = type('ForwardedBetSerializer', (serializers.ModelSerializer,), {
        'Meta': type('Meta', (), {'model': ForwardedBet, 'fields': '__all__'})
    })
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        user = self.request.user
        if user.role == 'SUPER_ADMIN':
            return ForwardedBet.objects.all().order_by('-created_at')
        return ForwardedBet.objects.filter(Q(forwarded_by=user) | Q(forwarded_to=user)).order_by('-created_at')

    @action(detail=False, methods=['get'])
    def report(self, request):
        user = request.user
        from_date = request.query_params.get('from')
        to_date = request.query_params.get('to')
        game_id = request.query_params.get('game')
        search_number = request.query_params.get('number')
        user_id = request.query_params.get('user')
        state = request.query_params.get('state')
        bet_type = request.query_params.get('type') or request.query_params.get('bet_type')
        
        if user.role == 'SUPER_ADMIN':
            qs = ForwardedBet.objects.filter(forwarded_to=user)
            if user_id:
                qs = qs.filter(forwarded_by_id=user_id)
        else:
            qs = ForwardedBet.objects.filter(forwarded_by=user)

        if state and state.upper() in ['KL', 'TN']:
            qs = qs.filter(state=state.upper())
        if from_date: qs = qs.filter(date__gte=from_date)
        if to_date: qs = qs.filter(date__lte=to_date)
        if game_id: qs = qs.filter(game_id=game_id)
        if search_number: qs = qs.filter(number=search_number)
        if bet_type and bet_type != 'ALL': qs = qs.filter(type=bet_type)
        
        # Format with Net Rate & Net Amount (Gross Price - Sales Commission)
        from decimal import Decimal
        total_sales = Decimal('0.00')
        total_count = 0
        
        invoice_map = {}
        for bet in qs.select_related('forwarded_by', 'game'):
            net_rate, gross, comm = get_forwarded_bet_net_rate(bet.forwarded_by, bet.state, bet.type)
            bet_sale = net_rate * Decimal(str(bet.count))
            total_sales += bet_sale
            total_count += bet.count
            
            inv_key = f"{bet.date}_{bet.game.name}_{bet.forwarded_by.username}"
            if inv_key not in invoice_map:
                invoice_map[inv_key] = {
                    'invoice_id': f"{bet.id}",
                    'user__username': bet.forwarded_by.username,
                    'game__name': bet.game.name,
                    'amount': Decimal('0.00'),
                    'count': 0,
                    'created_at': bet.created_at,
                    'items': []
                }
            
            inv = invoice_map[inv_key]
            inv['amount'] += bet_sale
            inv['count'] += bet.count
            
            inv['items'].append({
                'id': bet.id,
                'type': bet.type,
                'number': bet.number,
                'count': bet.count,
                'amount': float(net_rate),
                'total': float(bet_sale),
            })

        sorted_invoices = []
        for inv in sorted(invoice_map.values(), key=lambda x: x['created_at'], reverse=True):
            inv['amount'] = float(inv['amount'])
            sorted_invoices.append(inv)
        
        return Response({
            'sales': float(total_sales),
            'count': total_count,
            'invoices': sorted_invoices
        })

    @action(detail=False, methods=['get'])
    def purchase_winning_report(self, request):
        user = request.user
        from_date = request.query_params.get('from')
        to_date = request.query_params.get('to')
        game_id = request.query_params.get('game')
        search_number = request.query_params.get('number')
        
        if user.role == 'SUPER_ADMIN':
            qs = ForwardedBet.objects.filter(forwarded_to=user, is_winner=True)
        else:
            qs = ForwardedBet.objects.filter(forwarded_by=user, is_winner=True)

        if from_date: qs = qs.filter(date__gte=from_date)
        if to_date: qs = qs.filter(date__lte=to_date)
        if game_id: qs = qs.filter(game_id=game_id)
        if search_number: qs = qs.filter(number=search_number)
        
        total_winning_amount = 0.0
        total_winning_count = qs.count()
        unfolded_results = []
        
        for b in qs:
            total_winning_amount += float(b.winning_amount)
            
            prize_tiers = [t.strip() for t in (b.winning_prize_type or "WINNER").split("|") if t.strip()]
            pt_amount = float(b.winning_amount) / len(prize_tiers) if prize_tiers else float(b.winning_amount)
            
            for pt in prize_tiers:
                unfolded_results.append({
                    'id': b.id,
                    'game': b.game.name,
                    'game_name': b.game.name,
                    'state': b.state,
                    'type': b.type,
                    'number': b.number,
                    'count': b.count,
                    'winning_prize_type': pt,
                    'winning_amount': pt_amount,
                    'winning_commission': 0,
                    'is_winner': True,
                    'user_username': b.forwarded_by.username,
                    'created_at': b.created_at,
                })
                
        return Response({
            'total_winning_amount': total_winning_amount,
            'total_winning_commission': 0,
            'total_winning_count': total_winning_count,
            'bets': unfolded_results,
            'user_summary': [{'username': 'FORWARDED', 'role': 'FORWARD', 'count': total_winning_count, 'winning_amount': total_winning_amount, 'winning_commission': 0}]
        })

    @action(detail=False, methods=['get'])
    def purchase_report(self, request):
        user = request.user
        from_date = request.query_params.get('from')
        to_date = request.query_params.get('to')
        game_id = request.query_params.get('game')
        
        # Admin is checking what THEY forwarded (purchased)
        qs = ForwardedBet.objects.filter(forwarded_by=user)
        if from_date: qs = qs.filter(date__gte=from_date)
        if to_date: qs = qs.filter(date__lte=to_date)
        if game_id: qs = qs.filter(game_id=game_id)
        
        from django.db.models import Sum, F, Case, When, Value, CharField
        from decimal import Decimal
        
        qs = qs.annotate(
            bet_type_category=Case(
                When(type__iexact='a', then=Value('ABC')),
                When(type__iexact='b', then=Value('ABC')),
                When(type__iexact='c', then=Value('ABC')),
                When(type__iexact='ab', then=Value('AB_BC_AC')),
                When(type__iexact='bc', then=Value('AB_BC_AC')),
                When(type__iexact='ac', then=Value('AB_BC_AC')),
                default=F('type'),
                output_field=CharField(),
            )
        )
        
        results = qs.values('game__name', 'type', 'number', 'price_per_count', 'state', 'bet_type_category').annotate(
            total_qty=Sum('count'),
            total_price=Sum(F('count') * F('price_per_count'))
        ).order_by('-total_qty', 'number')
        
        response_data = []
        for r in results:
            bcat = r['bet_type_category']
            state = r['state']
            comm_rate = Decimal('0.00')
            
            if state == 'KL':
                if bcat == 'ABC': comm_rate = Decimal(str(user.sales_comm_abc))
                elif bcat == 'AB_BC_AC': comm_rate = Decimal(str(user.sales_comm_ab_bc_ac))
                elif bcat == 'SUPER': comm_rate = Decimal(str(user.sales_comm_super))
                elif bcat == 'BOX': comm_rate = Decimal(str(user.sales_comm_box))
            elif state == 'TN':
                if bcat == 'ABC': comm_rate = Decimal(str(user.tn_sales_comm_abc))
                elif bcat == 'AB_BC_AC': comm_rate = Decimal(str(user.tn_sales_comm_ab_bc_ac))
                elif bcat == '3D-10': comm_rate = Decimal(str(user.tn_sales_comm_3d_10))
                elif bcat == '3D-25': comm_rate = Decimal(str(user.tn_sales_comm_3d_25))
                elif bcat == '3D-30': comm_rate = Decimal(str(user.tn_sales_comm_3d_30))
                elif bcat == '3D-60': comm_rate = Decimal(str(user.tn_sales_comm_3d_60))
                
            qty = Decimal(str(r['total_qty']))
            total_price = Decimal(str(r['total_price']))
            commission = comm_rate * qty
            net_amount = total_price - commission
            
            response_data.append({
                'game__name': r['game__name'],
                'type': r['type'],
                'number': r['number'],
                'price_per_count': r['price_per_count'],
                'comm_per_count': comm_rate,
                'total_qty': r['total_qty'],
                'total_price': total_price,
                'total_commission': commission,
                'net_amount': net_amount,
            })
            
        return Response(response_data)

    @action(detail=False, methods=['get'])
    def get_retained_numbers(self, request):
        user = request.user
        game_id = request.query_params.get('game')
        state = request.query_params.get('state', 'KL')
        bet_type = request.query_params.get('type')
        
        if not game_id:
            return Response({'error': 'game is required'}, status=400)
            
        today = timezone.localtime().date()
        descendants = user.get_descendant_ids()
        
        # 1. Total Bets Under Admin Branch
        bets_qs = Bet.objects.filter(
            user_id__in=descendants, 
            game_id=game_id, 
            state=state, 
            created_at__date=today
        )
        if bet_type:
            bets_qs = bets_qs.filter(type=bet_type)
            
        from django.db.models import Sum, F
        
        grouped_bets = bets_qs.values('type').annotate(total_count=Sum('count'))
        
        # 2. Already Forwarded (Out)
        fwd_out_qs = ForwardedBet.objects.filter(
            forwarded_by=user, 
            game_id=game_id, 
            state=state, 
            date=today
        )
        if bet_type:
            fwd_out_qs = fwd_out_qs.filter(type=bet_type)
            
        fwd_grouped = fwd_out_qs.values('type').annotate(fwd_count=Sum('count'))
        
        fwd_dict = {item['type']: item['fwd_count'] for item in fwd_grouped}
        
        results = []
        for item in grouped_bets:
            typ = item['type']
            tot = item['total_count']
            fwd = fwd_dict.get(typ, 0)
            retained = tot - fwd
            if retained > 0:
                results.append({
                    'number': '',  # No longer tracking specific numbers in UI
                    'type': typ,
                    'total_count': tot,
                    'forwarded_count': fwd,
                    'retained_count': retained
                })
                
        # Sort by retained descending
        results.sort(key=lambda x: x['retained_count'], reverse=True)
        return Response(results)

    @action(detail=False, methods=['post'])
    def manual_forward(self, request):
        user = request.user
        if not user.parent:
            return Response({'error': 'No parent to forward to'}, status=400)
            
        game_id = request.data.get('game')
        state = request.data.get('state', 'KL')
        items = request.data.get('items', []) # [{'number': '123', 'type': 'SUPER', 'count': 10}]
        
        if not game_id or not items:
            return Response({'error': 'Invalid data'}, status=400)
            
        try:
            game = Game.objects.get(id=game_id)
        except Game.DoesNotExist:
            return Response({'error': 'Game not found'}, status=404)
            
        forwarded_records = []
        
        p_price_map = {
            'A': user.price_abc if state == 'KL' else getattr(user, 'tn_price_abc', 12.0),
            'B': user.price_abc if state == 'KL' else getattr(user, 'tn_price_abc', 12.0),
            'C': user.price_abc if state == 'KL' else getattr(user, 'tn_price_abc', 12.0),
            'AB': user.price_ab_bc_ac if state == 'KL' else getattr(user, 'tn_price_ab_bc_ac', 10.0),
            'BC': user.price_ab_bc_ac if state == 'KL' else getattr(user, 'tn_price_ab_bc_ac', 10.0),
            'AC': user.price_ab_bc_ac if state == 'KL' else getattr(user, 'tn_price_ab_bc_ac', 10.0),
            'SUPER': user.price_super,
            'BOX': user.price_box,
        }
        
        for item in items:
            bet_type = item.get('type')
            if state == 'TN':
                if bet_type == '3D-10': p_price_map['3D-10'] = getattr(user, 'tn_price_3d_10', 10.0)
                elif bet_type == '3D-25': p_price_map['3D-25'] = getattr(user, 'tn_price_3d_25', 25.0)
                elif bet_type == '3D-30': p_price_map['3D-30'] = getattr(user, 'tn_price_3d_30', 30.0)
                elif bet_type == '3D-60': p_price_map['3D-60'] = getattr(user, 'tn_price_3d_60', 60.0)
                elif bet_type == '4D-110': p_price_map['4D-110'] = getattr(user, 'tn_price_4d_110', 110.0)
                elif bet_type == '4D-55': p_price_map['4D-55'] = getattr(user, 'tn_price_4d_55', 55.0)
                elif bet_type == '4D-20': p_price_map['4D-20'] = getattr(user, 'tn_price_4d_20', 20.0)

            p_amount = Decimal(str(p_price_map.get(bet_type, 1.0)))
            
            f = ForwardedBet.objects.create(
                forwarded_by=user,
                forwarded_to=user.parent,
                game=game,
                state=state,
                type=bet_type,
                number=item.get('number'),
                count=item.get('count'),
                price_per_count=p_amount,
                is_auto=False
            )
            forwarded_records.append(f.id)
            
        return Response({'message': 'Forwarded successfully', 'forwarded_ids': forwarded_records})

class ForwardNetReportView(views.APIView):
    def get(self, request):
        user = request.user
        from_date = request.query_params.get('from')
        to_date = request.query_params.get('to')
        game_id = request.query_params.get('game')
        state = request.query_params.get('state')
        user_id = request.query_params.get('user')
        
        from .models import ForwardedBet
        from decimal import Decimal
        
        # If Admin, they forward out. If Super Admin, they forward in.
        if user.role == 'SUPER_ADMIN':
            qs = ForwardedBet.objects.filter(forwarded_to=user)
            if user_id:
                qs = qs.filter(forwarded_by_id=user_id)
        else:
            qs = ForwardedBet.objects.filter(forwarded_by=user)
            
        if state and state.upper() in ['KL', 'TN']:
            qs = qs.filter(state=state.upper())
        if from_date:
            qs = qs.filter(date__gte=from_date)
        if to_date:
            qs = qs.filter(date__lte=to_date)
        if game_id:
            qs = qs.filter(game_id=game_id)
            
        daily_map = {}
        for bet in qs.select_related('forwarded_by', 'game'):
            d_str = bet.date.strftime('%Y-%m-%d')
            if d_str not in daily_map:
                daily_map[d_str] = {
                    'date': d_str,
                    'purchase': Decimal('0.00'),
                    'winning': Decimal('0.00'),
                }
            net_rate, gross, comm = get_forwarded_bet_net_rate(bet.forwarded_by, bet.state, bet.type)
            daily_map[d_str]['purchase'] += net_rate * Decimal(str(bet.count))
            daily_map[d_str]['winning'] += Decimal(str(bet.winning_amount or 0.0))
        
        data = []
        for idx, d_str in enumerate(sorted(daily_map.keys(), reverse=True)):
            stat = daily_map[d_str]
            purchase = float(stat['purchase'])
            win = float(stat['winning'])
            balance = purchase - win
            data.append({
                'logid': idx + 1,
                'date': stat['date'],
                'purchase': purchase,
                'fwd_winning_commi': win,
                'balance': balance,
                'raw_commission': 0,
                'raw_winning': win
            })
            
        return Response(data)
