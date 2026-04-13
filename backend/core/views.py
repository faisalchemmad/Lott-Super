from rest_framework import viewsets, permissions, status, views
from rest_framework.response import Response
from rest_framework.decorators import action
from rest_framework.authtoken.models import Token
from django.contrib.auth import authenticate
from django.db.models import Sum, Q, F, Count, Max, When, Case, Value, CharField
from .models import (
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

        if user.role == 'SUPER_ADMIN':
            return queryset.order_by('-created_at')[:100]
            
        # For non-superadmins, only show their own bets in the recent list for speed
        return queryset.filter(user=user).order_by('-created_at')[:100]

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
        amount = price_map.get(bet_type, 1.0)
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

                t_limit = getattr(p, f'count_{bet_type.lower()}', 0)
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
            game_type_limit = getattr(game, f'global_count_{bet_type.lower()}', 0)
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

        if requested_user.is_blocked or any(p.is_blocked for p in requested_user.get_ancestors()):
            return Response({'error': 'Account Blocked'}, status=status.HTTP_403_FORBIDDEN)

        if user.is_blocked or any(p.is_blocked for p in user.get_ancestors()):
            return Response({'error': 'Account Blocked'}, status=status.HTTP_403_FORBIDDEN)

        bets_data = request.data.get('bets', [])
        if not bets_data:
            return Response({'error': 'No bets provided'}, status=status.HTTP_400_BAD_REQUEST)

        # Generate 8-digit Invoice ID (will only be used if we save at least one bet)
        invoice_id = ''.join(random.choices(string.digits, k=8))
        
        from rest_framework import serializers as drf_serializers
        
        # Use target user's price map
        price_map = {
            'A': user.price_abc, 'B': user.price_abc, 'C': user.price_abc,
            'AB': user.price_ab_bc_ac, 'BC': user.price_ab_bc_ac, 'AC': user.price_ab_bc_ac,
            'SUPER': user.price_super, 'BOX': user.price_box,
        }
        
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
            amount = price_map.get(bet_type, 0)
            count = b_data['count']
            number = b_data.get('number', '')
            
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

                    t_limit = getattr(p, f'count_{bet_type.lower()}', 0)
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
                game_type_limit = getattr(game, f'global_count_{bet_type.lower()}', 0)
                if game_type_limit > 0:
                    tot_type = Bet.objects.filter(game=game, type=bet_type, number=number, created_at__date=timezone.localtime().date()).aggregate(t=Sum('count'))['t'] or 0
                    t_clr = ClearedExposure.objects.filter(game=game, type=bet_type, number=number, date=timezone.localtime().date()).aggregate(t=Sum('count'))['t'] or 0
                    
                    # Global system tracking
                    current_session_n = session_branch_nos.get((None, number, bet_type, game.id), 0)
                    
                    if (tot_type - t_clr + current_session_n + count) > game_type_limit:
                        mark_failed(f"Total Limit Reached. {max(0, game_type_limit - (tot_type - t_clr + current_session_n))} Only")
                        continue

            # All checks passed!
            Bet.objects.create(
                user=user,
                game=game,
                number=number,
                type=bet_type,
                amount=amount,
                count=count,
                invoice_id=invoice_id
            )
            created_bets_count += 1
            total_created_amount += amount * count
            
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
        if user.role != 'SUPER_ADMIN':
            bets = bets.filter(user=user)

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

        bets = Bet.objects.all()
        
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
                    'game__name': bet.game.name,
                    'game__time': bet.game.time,
                    'amount': Decimal('0.00'),
                    'count': 0,
                    'commission': Decimal('0.00'),
                    'net': Decimal('0.00'),
                    'created_at': bet.created_at,
                    'items': []
                }
            
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
        
        display_subjects = []
        # 'Self' row for the target user (their own personal bets)
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
            
            type_stats = branch_bets.values('type').annotate(
                total_count=Sum('count'),
                total_sale_price=Sum(F('amount') * F('count')),
                total_winning=Sum('winning_amount')
            )
            
            total_sale_price = 0.0
            total_winning = 0.0
            total_comm = 0.0
            
            for stat in type_stats:
                btype = stat['type'].upper()
                count = stat['total_count'] or 0
                total_sale_price += float(stat['total_sale_price'] or 0)
                total_winning += float(stat['total_winning'] or 0)
                
                c_rate = 0.0
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

        bets = Bet.objects.all()
        
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
        
        day_detail = request.query_params.get('day_detail') == 'true'
        game_detail = request.query_params.get('game_detail') == 'true'
        user_detail = request.query_params.get('user_detail') == 'true'
        
        use_agent_rate = request.query_params.get('agent_rate') == 'true'

        bets = Bet.objects.all()
        
        if from_date:
            bets = bets.filter(created_at__date__gte=from_date)
        if to_date:
            bets = bets.filter(created_at__date__lte=to_date)
        if game_ids:
            bets = bets.filter(game_id__in=game_ids)
        
        # Filter bets based on the user hierarchy
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
                # If agent_id is invalid, filter for no bets or handle as needed
                bets = bets.none() # No bets if user not found
        elif user.role != 'SUPER_ADMIN':
            bets = bets.filter(user_id__in=user.get_descendant_ids())

        # Determine grouping
        group_fields = []
        if day_detail:
            bets = bets.annotate(date_only=F('created_at__date'))
            group_fields.append('date_only')
        if game_detail:
            group_fields.append('game__name')
        if user_detail:
            group_fields.append('user__username')
            group_fields.append('user__id') # Include user ID for fetching commission rates

        # If no detail is requested, provide a summary
        if not group_fields:
            # We compute commission based on viewer's (admin) rates for summary
            bets_annotated = bets.annotate(
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
            sub_groups = bets_annotated.values('bet_type_category').annotate(
                sub_sale=Sum(F('amount') * F('count')),
                sub_count_total=Sum('count'),
                sub_winning=Sum('winning_amount'),
            )
            total_sale = Decimal('0')
            total_commission = Decimal('0')
            total_winning = Decimal('0')
            for sg in sub_groups:
                s = Decimal(str(sg['sub_sale'] or 0))
                cnt = Decimal(str(sg['sub_count_total'] or 0))
                w = Decimal(str(sg['sub_winning'] or 0))
                # Admin rate: always use viewer's commission for summary
                comm_rate = Decimal('0')
                if use_agent_rate:
                    # For summary with agent_rate ON but no user grouping,
                    # use viewer's commission as fallback
                    pass  # No specific agent, use 0 commission
                else:
                    # Admin rate: viewer's own commission
                    bcat = sg['bet_type_category']
                    if bcat == 'ABC':
                        comm_rate = Decimal(str(user.sales_comm_abc))
                    elif bcat == 'AB_BC_AC':
                        comm_rate = Decimal(str(user.sales_comm_ab_bc_ac))
                    elif bcat == 'SUPER':
                        comm_rate = Decimal(str(user.sales_comm_super))
                    elif bcat == 'BOX':
                        comm_rate = Decimal(str(user.sales_comm_box))
                comm = comm_rate * cnt
                total_sale += s
                total_commission += comm
                total_winning += w
            net_sale = total_sale - total_commission
            balance = net_sale - total_winning
            return Response([{
                'label': 'Total Summary',
                'sale': float(total_sale),
                'commission': float(total_commission),
                'net_sale': float(net_sale),
                'winning': float(total_winning),
                'balance': float(balance),
            }])

        # Annotate bets with their type categories for commission calculation
        bets = bets.annotate(
            bet_type_category=Case(
                When(type__iexact='a', then=Value('ABC')),
                When(type__iexact='b', then=Value('ABC')),
                When(type__iexact='c', then=Value('ABC')),
                When(type__iexact='ab', then=Value('AB_BC_AC')),
                When(type__iexact='bc', then=Value('AB_BC_AC')),
                When(type__iexact='ac', then=Value('AB_BC_AC')),
                default=F('type'), # SUPER, BOX
                output_field=CharField(),
            )
        )

        # ── Build direct-subordinate map (Agent Rate mode) ────────────────────
        # When agent_rate=ON, commission is charged at the level of the viewer's
        # DIRECT SUBORDINATE — not the leaf bet-placer.  E.g.:
        #   Viewer(Admin) → Agent1 → Dealer1 → Sub-dealer1 (places bet)
        # The commission used = Agent1's rates, and the row is labelled "Agent1".
        # This gives the Admin a summary of how much each of their direct agents earns.
        direct_sub_commission_map = {}  # bet_user_id  -> User object (direct subordinate)

        if use_agent_rate:
            # All direct children of the viewer
            direct_children = list(
                User.objects.filter(parent=user).only(
                    'id', 'username', 'sales_comm_abc', 'sales_comm_ab_bc_ac',
                    'sales_comm_super', 'sales_comm_box'
                )
            )
            direct_child_ids = {c.id for c in direct_children}
            direct_child_obj = {c.id: c for c in direct_children}

            # Collect all user_ids that appear in filtered bets
            involved_user_ids = set(
                bets.values_list('user_id', flat=True).distinct()
            )

            # Fetch all involved users with 4-level parent chain for hierarchy walk
            involved_users_qs = User.objects.filter(
                id__in=involved_user_ids
            ).select_related(
                'parent',
                'parent__parent',
                'parent__parent__parent',
                'parent__parent__parent__parent',
            ).only(
                'id', 'username', 'parent_id',
                'sales_comm_abc', 'sales_comm_ab_bc_ac',
                'sales_comm_super', 'sales_comm_box',
            )
            involved_users = {u.id: u for u in involved_users_qs}

            for uid in involved_user_ids:
                current = involved_users.get(uid)
                found = False
                while current:
                    if current.id in direct_child_ids:
                        # Found the direct-subordinate ancestor
                        direct_sub_commission_map[uid] = direct_child_obj[current.id]
                        found = True
                        break
                    parent_id = current.parent_id
                    if not parent_id:
                        # Reached root with no direct-sub ancestor found
                        # Could be the viewer's own bet — skip
                        break
                    next_user = involved_users.get(parent_id)
                    if next_user is None:
                        # Parent not in involved_users — fetch from DB once
                        try:
                            next_user = User.objects.only(
                                'id', 'username', 'parent_id',
                                'sales_comm_abc', 'sales_comm_ab_bc_ac',
                                'sales_comm_super', 'sales_comm_box',
                            ).get(id=parent_id)
                            # Cache it for future iterations
                            involved_users[parent_id] = next_user
                        except User.DoesNotExist:
                            break
                    current = next_user

        # ── Determine report grouping fields ──────────────────────────────────
        # Group by the determined fields and bet type category.
        # When agent_rate=ON, if user_detail is enabled, we group by the
        # DIRECT SUBORDINATE username (not the leaf bet-placer).
        # We achieve this by annotating each bet with its direct-sub username.

        if use_agent_rate and user_detail and direct_sub_commission_map:
            # Build a mapping list for annotation via Case/When on user_id
            from django.db.models import IntegerField as DjangoIntField
            whens_username = []
            whens_userid = []
            for uid, sub_user in direct_sub_commission_map.items():
                whens_username.append(
                    When(user_id=uid, then=Value(sub_user.username))
                )
                whens_userid.append(
                    When(user_id=uid, then=Value(sub_user.id))
                )
            bets = bets.annotate(
                direct_sub_username=Case(
                    *whens_username,
                    default=F('user__username'),
                    output_field=CharField(),
                ),
                direct_sub_id=Case(
                    *whens_userid,
                    default=F('user_id'),
                    output_field=DjangoIntField(),
                ),
            )
            # Replace user group fields with the direct-sub annotation
            group_fields_for_query = [
                f for f in group_fields if f not in ('user__username', 'user__id')
            ]
            group_fields_for_query += ['direct_sub_username', 'direct_sub_id']
        else:
            group_fields_for_query = group_fields

        # ── Execute grouped aggregation ───────────────────────────────────────
        grouped_bets = (
            bets.values(*group_fields_for_query, 'bet_type_category')
            .annotate(
                sub_total_sale=Sum(F('amount') * F('count')),
                sub_total_count=Sum('count'),
                sub_total_winning=Sum('winning_amount'),
            )
            .order_by(*group_fields_for_query, 'bet_type_category')
        )

        # Pre-fetch direct-sub User objects for commission lookup (agent_rate=ON)
        # When agent_rate=OFF, we just use the viewer
        direct_sub_by_id = {}
        if use_agent_rate and direct_sub_commission_map:
            seen_ids = {u.id for u in direct_sub_commission_map.values()}
            direct_sub_by_id = {
                u.id: u
                for u in User.objects.filter(id__in=seen_ids).only(
                    'id', 'sales_comm_abc', 'sales_comm_ab_bc_ac',
                    'sales_comm_super', 'sales_comm_box',
                )
            }

        final_data = {}  # key → aggregated row dict

        for r in grouped_bets:
            # ── Determine commission source user ──────────────────────────────
            if use_agent_rate:
                # When using direct-sub grouping, the sub_id is in direct_sub_id
                sub_id = r.get('direct_sub_id') or r.get('user__id')
                target_user_for_comm = direct_sub_by_id.get(sub_id)
                if target_user_for_comm is None:
                    # fallback: the direct_sub_commission_map might resolve it
                    uid = r.get('user__id')
                    target_user_for_comm = direct_sub_commission_map.get(uid)
            else:
                # Admin Rate — always the viewer's own commission
                target_user_for_comm = user

            # ── Compute commission rate for this bet-type bucket ──────────────
            commission_rate = Decimal('0.00')
            if target_user_for_comm:
                bcat = r['bet_type_category']
                if bcat == 'ABC':
                    commission_rate = Decimal(str(target_user_for_comm.sales_comm_abc))
                elif bcat == 'AB_BC_AC':
                    commission_rate = Decimal(str(target_user_for_comm.sales_comm_ab_bc_ac))
                elif bcat == 'SUPER':
                    commission_rate = Decimal(str(target_user_for_comm.sales_comm_super))
                elif bcat == 'BOX':
                    commission_rate = Decimal(str(target_user_for_comm.sales_comm_box))

            sub_sale    = Decimal(str(r['sub_total_sale'] or 0))
            sub_count   = Decimal(str(r['sub_total_count'] or 0))
            sub_winning = Decimal(str(r['sub_total_winning'] or 0))

            commission = commission_rate * sub_count
            net_sale   = sub_sale - commission

            # ── Build grouping key ────────────────────────────────────────────
            key_parts = []
            if day_detail:
                key_parts.append(str(r.get('date_only', '')))
            if game_detail:
                key_parts.append(r.get('game__name', 'ALL'))
            if user_detail:
                # Use direct-sub username when agent_rate=ON, else normal username
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
                final_data[key] = {
                    'date': date_str,
                    'game': r.get('game__name', 'ALL'),
                    'user': u_label,
                    'sale': Decimal('0.00'),
                    'commission': Decimal('0.00'),
                    'net_sale': Decimal('0.00'),
                    'winning': Decimal('0.00'),
                    'balance': Decimal('0.00'),
                }

            final_data[key]['sale']       += sub_sale
            final_data[key]['commission'] += commission
            final_data[key]['net_sale']   += net_sale
            final_data[key]['winning']    += sub_winning
            final_data[key]['balance']    = (
                final_data[key]['net_sale'] - final_data[key]['winning']
            )

        # ── Serialize ─────────────────────────────────────────────────────────
        output_data = []
        for key in sorted(final_data.keys()):
            item = final_data[key]
            output_data.append({
                'date':       item['date'],
                'game':       item['game'],
                'user':       item['user'],
                'sale':       float(item['sale']),
                'commission': float(item['commission']),
                'net_sale':   float(item['net_sale']),
                'winning':    float(item['winning']),
                'balance':    float(item['balance']),
            })

        return Response(output_data)


class NumberReportView(views.APIView):
    def get(self, request):
        user = request.user
        from_date = request.query_params.get('from')
        to_date = request.query_params.get('to')
        game_id = request.query_params.get('game')
        agent_id = request.query_params.get('user')
        bet_type = request.query_params.get('type')
        search_number = request.query_params.get('number')

        bets = Bet.objects.all()
        
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

        if agent_id:
            results = bets.values('game__name', 'type', 'number', 'user__username').annotate(
                total_qty=Sum('count')
            ).order_by('-total_qty', 'number')
        else:
            results = bets.values('game__name', 'type', 'number').annotate(
                total_qty=Sum('count')
            ).order_by('-total_qty', 'number')

        return Response(list(results))


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
                    
        elif btype in ['AB', 'BC', 'AC']:
            p = count * float(user.prize_ab_bc_ac_1)
            c = count * float(user.comm_ab_bc_ac_1)
            
        elif btype in ['A', 'B', 'C']:
            p = count * float(user.prize_abc_1)
            c = count * float(user.comm_abc_1)
        
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
        
        user = request.user
        bets = Bet.objects.filter(is_winner=True).select_related('user', 'game').distinct()
        
        if user.role != 'SUPER_ADMIN':
            # Admin/Agent sees their own and their descendants' winners
            bets = bets.filter(user_id__in=user.get_descendant_ids())
            
        if from_date:
            bets = bets.filter(created_at__date__gte=from_date)
        if to_date:
            bets = bets.filter(created_at__date__lte=to_date)
        if game_id:
            bets = bets.filter(game_id=game_id)
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
                limit_map = {
                    'A': user.count_a if user else 0,
                    'B': user.count_b if user else 0,
                    'C': user.count_c if user else 0,
                    'AB': user.count_ab if user else 0,
                    'BC': user.count_bc if user else 0,
                    'AC': user.count_ac if user else 0,
                    'SUPER': user.count_super if user else 0,
                    'BOX': user.count_box if user else 0
                }
                limit = limit_map.get(b_type, 0)
                
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
        all_bets_qs = Bet.objects.filter(game=game, created_at__date=date)
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

                elif b_type in ['AB', 'BC', 'AC', 'A', 'B', 'C']:
                    if tier_name != "1ST PRIZE":
                        continue

                    # Derived match logic
                    target = ""
                    if len(win_num) >= 3:
                        if b_type == 'AB': target = win_num[0:2]
                        elif b_type == 'BC': target = win_num[1:3]
                        elif b_type == 'AC': target = win_num[0] + win_num[2]
                        elif b_type == 'A': target = win_num[0]
                        elif b_type == 'B': target = win_num[1]
                        elif b_type == 'C': target = win_num[2]
                    elif len(win_num) == 2:
                        if b_type == 'AB': target = win_num
                        elif b_type == 'A': target = win_num[0]
                        elif b_type == 'B': target = win_num[1]
                    elif len(win_num) == 1:
                        if b_type == 'A': target = win_num
                    
                    if target and b_num == target:
                        match = True
                        if b_type in ['AB', 'BC', 'AC']: p, c = u.prize_ab_bc_ac_1, u.comm_ab_bc_ac_1
                        else: p, c = u.prize_abc_1, u.comm_abc_1

                if match:
                    if b_type == 'SUPER':
                        display_name = tier_name
                    elif b_type == 'BOX':
                        # Since BOX only reaches here for 1ST PRIZE tier,
                        # exact match → BOX (1ST PRIZE) EXACT
                        # permutation match → BOX2 (1ND PRIZE)
                        is_exact_match = (b_num == win_num)
                        display_name = "BOX (1ST PRIZE) EXACT" if is_exact_match else "BOX2 (1ND PRIZE)"
                    else:
                        display_name = f"{tier_name} ({b_type})"
                    
                    wins.append((display_name, p, c))

            if wins:
                b.is_winner = True
                b.winning_amount = sum(w[1] for w in wins) * b.count
                b.winning_commission = sum(w[2] for w in wins) * b.count
                b.winning_prize_type = "|".join(w[0] for w in wins)
                b.save()
