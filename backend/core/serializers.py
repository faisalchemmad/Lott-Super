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
            'price_abc', 'price_ab_bc_ac', 'price_super', 'price_box',
            'prize_super_1', 'comm_super_1', 'prize_super_2', 'comm_super_2',
            'prize_super_3', 'comm_super_3', 'prize_super_4', 'comm_super_4',
            'prize_super_5', 'comm_super_5', 'prize_6th', 'comm_6th',
            'prize_ab_bc_ac_1', 'comm_ab_bc_ac_1', 'prize_abc_1', 'comm_abc_1',
            'prize_box_3d_1', 'comm_box_3d_1', 'prize_box_3d_2', 'comm_box_3d_2',
            'prize_box_2s_1', 'comm_box_2s_1', 'prize_box_2s_2', 'comm_box_2s_2',
            'prize_box_3s_1', 'comm_box_3s_1',
            'sales_comm_super', 'sales_comm_abc', 'sales_comm_ab_bc_ac', 'sales_comm_box',
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
