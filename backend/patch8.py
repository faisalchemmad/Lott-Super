import sys

p = r'd:\Gemini\Android\Lott_super\backend\core\views.py'
with open(p, 'r', encoding='utf-8') as f:
    c = f.read()

old_code = '''    def get_queryset(self):
        user = self.request.user
        queryset = Bet.objects.all()
        
        # Filter by game if provided
        game_id = self.request.query_params.get('game')
        if game_id:
            queryset = queryset.filter(game_id=game_id)

        if user.role in ['SUPER_ADMIN', 'ADMIN']:
            descendants = user.get_descendant_ids()
            return queryset.filter(user__id__in=descendants).order_by('-created_at')[:100]
            
        # For lower roles (Agent/Dealer/Sub-dealer), only show their own bets in the recent list for speed
        return queryset.filter(user=user).order_by('-created_at')[:100]'''

new_code = '''    def get_queryset(self):
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
        return queryset'''

if old_code in c:
    c = c.replace(old_code, new_code)
    with open(p, 'w', encoding='utf-8') as f:
        f.write(c)
    print("Patched successfully!")
else:
    print("Could not find code to replace!")
