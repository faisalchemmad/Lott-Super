from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import (
    LoginView, GameViewSet, BetViewSet, ReportView, SalesReportView, 
    CountReportView, DailyReportView, NumberReportView, WinningReportView, DashboardView, UserViewSet, 
    NumberLimitViewSet, GlobalNumberLimitViewSet, GameResultViewSet,
    MonitorView, UserGameTimingViewSet, NetReportView, SystemSettingsViewSet
)

router = DefaultRouter()
router.register(r'games', GameViewSet, basename='games')
router.register(r'system-settings', SystemSettingsViewSet)
router.register(r'bets', BetViewSet)
router.register(r'users', UserViewSet, basename='users')
router.register(r'number-limits', NumberLimitViewSet)
router.register(r'global-number-limits', GlobalNumberLimitViewSet)
router.register(r'game-results', GameResultViewSet)
router.register(r'user-game-timings', UserGameTimingViewSet)

urlpatterns = [
    path('login/', LoginView.as_view(), name='login'),
    path('report/sales/', SalesReportView.as_view(), name='sales_report'),
    path('report/count/', CountReportView.as_view(), name='count_report'),
    path('report/daily/', DailyReportView.as_view(), name='daily_report'),
    path('report/number/', NumberReportView.as_view(), name='number_report'),
    path('report/winning/', WinningReportView.as_view(), name='winning_report'),
    path('report/net/', NetReportView.as_view(), name='net_report'),
    path('dashboard/', DashboardView.as_view(), name='dashboard'),
    path('monitor/', MonitorView.as_view(), name='monitor'),
    path('monitor/clear/', MonitorView.as_view(), name='monitor_clear'),
    path('', include(router.urls)),
]
