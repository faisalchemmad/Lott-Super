from django.contrib import admin
from .models import User, Game, Bet, GameResult, NumberLimit, GlobalNumberLimit, ClearedExposure, UserGameTiming, SystemSettings

admin.site.register(User)
admin.site.register(Game)
admin.site.register(Bet)
admin.site.register(GameResult)
admin.site.register(NumberLimit)
admin.site.register(GlobalNumberLimit)
admin.site.register(ClearedExposure)
admin.site.register(UserGameTiming)
admin.site.register(SystemSettings)
