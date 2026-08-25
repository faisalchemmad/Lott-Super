from rest_framework import serializers
from .models import User, Game, Bet, GameResult, NumberLimit, GlobalNumberLimit, UserGameTiming, SystemSettings

class UserSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True, required=False)

    class Meta:
        model = User
        fields = [
            'id', 'username', 'password', 'role', 'parent',
            'weekly_credit_limit', 'remaining_credit',
            'count_a', 'count_b', 'count_c', 'count_ab', 'count_bc', 'count_ac', 'count_super', 'count_box',
            'tn_count_a', 'tn_count_b', 'tn_count_c', 'tn_count_ab', 'tn_count_bc', 'tn_count_ac',
            'tn_count_3d_10', 'tn_count_3d_25', 'tn_count_3d_30', 'tn_count_3d_60',
            'tn_count_4d_110', 'tn_count_4d_55', 'tn_count_4d_20',
            'price_abc', 'price_ab_bc_ac', 'price_super', 'price_box',
            'tn_price_abc', 'tn_price_ab_bc_ac', 
            'tn_price_3d_10', 'tn_price_3d_25', 'tn_price_3d_30', 'tn_price_3d_60',
            'tn_price_4d_110', 'tn_price_4d_55', 'tn_price_4d_20',
            'prize_super_1', 'comm_super_1', 'prize_super_2', 'comm_super_2',
            'prize_super_3', 'comm_super_3', 'prize_super_4', 'comm_super_4',
            'prize_super_5', 'comm_super_5', 'prize_6th', 'comm_6th',
            'prize_ab_bc_ac_1', 'comm_ab_bc_ac_1', 'prize_abc_1', 'comm_abc_1',
            'prize_box_3d_1', 'comm_box_3d_1', 'prize_box_3d_2', 'comm_box_3d_2',
            'prize_box_2s_1', 'comm_box_2s_1', 'prize_box_2s_2', 'comm_box_2s_2',
            'prize_box_3s_1', 'comm_box_3s_1',
                        'tn_prize_abc', 'tn_prize_ab_bc_ac', 
            'tn_prize_3d_10', 'tn_prize_3d_10_bc', 'tn_prize_3d_25', 'tn_prize_3d_25_bc',
            'tn_prize_3d_30', 'tn_prize_3d_30_bc', 'tn_prize_3d_30_c',
            'tn_prize_3d_60', 'tn_prize_3d_60_bc', 'tn_prize_3d_60_c',
            'tn_prize_4d_110_1', 'tn_prize_4d_110_2', 'tn_prize_4d_110_3', 'tn_prize_4d_110_4',
            'tn_prize_4d_55_1', 'tn_prize_4d_55_2', 'tn_prize_4d_55_3', 'tn_prize_4d_55_4',
            'tn_prize_4d_20_1',
'sales_comm_super', 'sales_comm_abc', 'sales_comm_ab_bc_ac', 'sales_comm_box',
            'tn_sales_comm_abc', 'tn_sales_comm_ab_bc_ac',
            'tn_sales_comm_3d_10', 'tn_sales_comm_3d_25', 'tn_sales_comm_3d_30', 'tn_sales_comm_3d_60',
            'tn_sales_comm_4d_110', 'tn_sales_comm_4d_55', 'tn_sales_comm_4d_20',
            'is_blocked', 'is_default', 'date_joined', 'allowed_games'
        ]

    remaining_credit = serializers.SerializerMethodField()

    def get_remaining_credit(self, obj):
        return float(obj.weekly_credit_limit) - float(obj.get_weekly_net_loss())

    def create(self, validated_data):
        password = validated_data.pop('password', None)
        user = super().create(validated_data)
        if password:
            user.set_password(password)
            user.save()
        return user

    def update(self, instance, validated_data):
        password = validated_data.pop('password', None)
        user = super().update(instance, validated_data)
        if password:
            user.set_password(password)
            user.save()
        return user

class GameSerializer(serializers.ModelSerializer):
    class Meta:
        model = Game
        fields = '__all__'

class BetSerializer(serializers.ModelSerializer):
    game_name = serializers.ReadOnlyField(source='game.name')
    user_username = serializers.ReadOnlyField(source='user.username')

    class Meta:
        model = Bet
        fields = '__all__'
        read_only_fields = ['user']

class GameResultSerializer(serializers.ModelSerializer):
    game_name = serializers.ReadOnlyField(source='game.name')

    class Meta:
        model = GameResult
        fields = '__all__'

class NumberLimitSerializer(serializers.ModelSerializer):
    game_name = serializers.ReadOnlyField(source='game.name')
    user_username = serializers.ReadOnlyField(source='user.username')

    class Meta:
        model = NumberLimit
        fields = '__all__'

class GlobalNumberLimitSerializer(serializers.ModelSerializer):
    game_name = serializers.ReadOnlyField(source='game.name')

    class Meta:
        model = GlobalNumberLimit
        fields = '__all__'

class UserGameTimingSerializer(serializers.ModelSerializer):
    game_name = serializers.ReadOnlyField(source='game.name')
    user_username = serializers.ReadOnlyField(source='user.username')

    class Meta:
        model = UserGameTiming
        fields = '__all__'

class SystemSettingsSerializer(serializers.ModelSerializer):
    class Meta:
        model = SystemSettings
        fields = '__all__'
