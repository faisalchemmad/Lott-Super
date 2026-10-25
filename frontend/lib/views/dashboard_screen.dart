import 'cut_report_screen.dart';
import 'monitor_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';
import 'report_screen.dart';
import 'manage_admins_screen.dart';
import 'manage_games_screen.dart';
import 'select_game_screen.dart';
import 'publish_result_screen.dart';
import 'result_view_screen.dart';
import 'price_setting_screen.dart';
import 'admin_net_rate_screen.dart';
import 'global_count_limit_screen.dart';
import 'manage_prize_commission_screen.dart';
import 'user_options_screen.dart';
import 'settings_screen.dart';
import 'system_settings_screen.dart';
import 'create_admin_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic>? _stats;
  bool _isLoading = true;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    final apiService = Provider.of<ApiService>(context, listen: false);
    final data = await apiService.getDashboard();
    if (mounted) {
      setState(() {
        _stats = data;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDesktop = defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.macOS;
    bool isSuperAdmin = _stats?['role'] == 'SUPER_ADMIN';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: isDesktop
          ? null
          : AppBar(
              title: Text(isSuperAdmin ? 'Super Admin Platform' : 'Dashboard'),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh_rounded),
                  onPressed: _loadDashboard,
                ),
              ],
            ),
      drawer: isDesktop ? null : _buildDrawer(),
      body: Row(
        children: [
          if (isDesktop) _buildNavigationRail(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadDashboard,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16.0),
                      child: isSuperAdmin
                          ? _buildSuperAdminDashboard()
                          : _buildStandardDashboard(),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // ===================== SUPER ADMIN SAAS DASHBOARD =====================
  Widget _buildSuperAdminDashboard() {
    final totalAdmins = _stats?['total_admins'] ?? 0;
    final activeAdmins = _stats?['active_admins'] ?? 0;
    final expiredAdmins = _stats?['expired_admins'] ?? 0;
    final expiringSoon = _stats?['expiring_soon'] ?? 0;
    final List admins = (_stats?['admins'] as List?) ?? [];

    final filteredAdmins = admins.where((a) {
      final name = (a['username'] ?? '').toString().toLowerCase();
      return name.contains(_searchQuery.toLowerCase());
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // KPI Cards Row
        Row(
          children: [
            _buildStatCard(
              'Total Admins',
              totalAdmins.toString(),
              Colors.indigo,
              Icons.admin_panel_settings_rounded,
            ),
            const SizedBox(width: 8),
            _buildStatCard(
              'Active Subscriptions',
              activeAdmins.toString(),
              Colors.green.shade700,
              Icons.check_circle_rounded,
            ),
            const SizedBox(width: 8),
            _buildStatCard(
              'Expired',
              expiredAdmins.toString(),
              Colors.red.shade700,
              Icons.cancel_rounded,
            ),
            const SizedBox(width: 8),
            _buildStatCard(
              'Expiring Soon',
              expiringSoon.toString(),
              Colors.amber.shade800,
              Icons.warning_amber_rounded,
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Action Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Admin Subscriptions (അഡ്മിൻ മാനേജ്‌മെന്റ്)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.add, size: 18),
              label: const Text('CREATE ADMIN'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
              onPressed: () async {
                final res = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CreateAdminScreen()),
                );
                if (res == true) _loadDashboard();
              },
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Search Bar
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search admin by username...',
            prefixIcon: const Icon(Icons.search, color: Colors.grey),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                  )
                : null,
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
          ),
          onChanged: (val) => setState(() => _searchQuery = val.trim()),
        ),
        const SizedBox(height: 16),

        // Admin Subscription Cards List
        if (filteredAdmins.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                Icon(Icons.people_outline_rounded, size: 48, color: Colors.grey.shade400),
                const SizedBox(height: 12),
                Text(
                  _searchQuery.isEmpty ? 'No admins created yet.' : 'No admins found matching "$_searchQuery".',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                ),
              ],
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filteredAdmins.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final admin = filteredAdmins[index];
              return _buildAdminSubscriptionCard(admin);
            },
          ),
      ],
    );
  }

  Widget _buildAdminSubscriptionCard(Map<String, dynamic> admin) {
    final status = admin['subscription_status'] ?? 'ACTIVE';
    final daysLeft = admin['subscription_days_left'] ?? 0;
    final isExpired = status == 'EXPIRED' || daysLeft < 0;
    final isExpiringSoon = !isExpired && daysLeft <= 3;
    final endDateStr = admin['subscription_end_date'] ?? 'N/A';
    final maxGames = admin['max_allowed_games'] ?? 4;
    final createdGames = admin['created_games_count'] ?? 0;

    Color badgeColor;
    String badgeText;
    if (isExpired) {
      badgeColor = Colors.red.shade700;
      badgeText = 'Expired (${daysLeft.abs()}d ago)';
    } else if (isExpiringSoon) {
      badgeColor = Colors.amber.shade800;
      badgeText = 'Expires in $daysLeft day${daysLeft == 1 ? "" : "s"}';
    } else {
      badgeColor = Colors.green.shade700;
      badgeText = 'Active ($daysLeft days left)';
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isExpired
              ? Colors.red.shade300
              : (isExpiringSoon ? Colors.amber.shade300 : Colors.grey.shade200),
          width: isExpired || isExpiringSoon ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                child: Text(
                  (admin['username'] ?? 'A')[0].toUpperCase(),
                  style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          admin['username'] ?? 'Admin',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.deepOrange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '$createdGames / $maxGames Games',
                            style: const TextStyle(
                              color: Colors.deepOrange,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Plan: ${admin["subscription_plan"]?.replaceAll("_", " ")?.toUpperCase() ?? "30 DAYS"} • Valid Till: $endDateStr',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: badgeColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: badgeColor.withValues(alpha: 0.4)),
                    ),
                    child: Text(
                      badgeText,
                      style: TextStyle(
                        color: badgeColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Builder(builder: (context) {
                    final mode = (admin['game_mode'] ?? 'KL').toString().toUpperCase();
                    final modeLabel = mode == 'TN' ? 'TN' : (mode == 'KL' ? 'KL' : 'KL & TN');
                    final modeColor = mode == 'TN' ? Colors.deepOrange : (mode == 'KL' ? Colors.teal : Colors.indigo);
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: modeColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: modeColor.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        modeLabel,
                        style: TextStyle(
                          color: modeColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton.icon(
                icon: const Icon(Icons.settings_outlined, size: 16),
                label: const Text('MANAGE'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.blueGrey.shade800,
                  side: BorderSide(color: Colors.grey.shade400),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                onPressed: () async {
                  final apiService = Provider.of<ApiService>(context, listen: false);
                  final user = await apiService.getUser(admin['id']);
                  if (user != null && mounted) {
                    final res = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => UserOptionsScreen(user: user)),
                    );
                    if (res == true) _loadDashboard();
                  }
                },
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                icon: const Icon(Icons.autorenew_rounded, size: 16),
                label: const Text('RENEW / EXTEND'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isExpired ? Colors.red.shade700 : AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                onPressed: () => _showRenewSubscriptionDialog(admin),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showRenewSubscriptionDialog(Map<String, dynamic> admin) {
    String selectedPlan = admin['subscription_plan'] ?? '30_days';
    int maxGames = admin['max_allowed_games'] ?? 4;
    String selectedMode = (admin['game_mode'] ?? 'KL').toString().toUpperCase();
    if (!['KL', 'TN', 'BOTH'].contains(selectedMode)) selectedMode = 'KL';
    bool isSubmitting = false;

    final planDaysMap = {
      '7_days': 7,
      '30_days': 30,
      '90_days': 90,
      '180_days': 180,
      '365_days': 365,
    };

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.autorenew_rounded, color: AppColors.primary),
              const SizedBox(width: 8),
              Text('Renew: ${admin["username"]}'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select Subscription Plan (കാലാവധി):',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: selectedPlan,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  items: const [
                    DropdownMenuItem(value: '7_days', child: Text('7 Days (1 Week)')),
                    DropdownMenuItem(value: '30_days', child: Text('30 Days (1 Month)')),
                    DropdownMenuItem(value: '90_days', child: Text('90 Days (3 Months)')),
                    DropdownMenuItem(value: '180_days', child: Text('180 Days (6 Months)')),
                    DropdownMenuItem(value: '365_days', child: Text('365 Days (1 Year)')),
                  ],
                  onChanged: (val) {
                    if (val != null) setDialogState(() => selectedPlan = val);
                  },
                ),
                const SizedBox(height: 16),
                const Text(
                  'Max Allowed Games (അനുവദിച്ച ഗെയിമുകൾ):',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<int>(
                  value: maxGames,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  items: const [
                    DropdownMenuItem(value: 4, child: Text('4 Games Limit')),
                    DropdownMenuItem(value: 8, child: Text('8 Games Limit')),
                    DropdownMenuItem(value: 12, child: Text('12 Games Limit')),
                    DropdownMenuItem(value: 16, child: Text('16 Games Limit')),
                    DropdownMenuItem(value: 24, child: Text('24 Games Limit')),
                    DropdownMenuItem(value: 999, child: Text('Unlimited Games')),
                  ],
                  onChanged: (val) {
                    if (val != null) setDialogState(() => maxGames = val);
                  },
                ),
                const SizedBox(height: 16),
                const Text(
                  'Game Model (ഏത് മോഡൽ വേണം?):',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: selectedMode,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'KL', child: Text('KL (Kerala Only)')),
                    DropdownMenuItem(value: 'TN', child: Text('TN (Tamil Nadu Only)')),
                    DropdownMenuItem(value: 'BOTH', child: Text('Both (KL & TN)')),
                  ],
                  onChanged: (val) {
                    if (val != null) setDialogState(() => selectedMode = val);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCEL', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
              onPressed: isSubmitting
                  ? null
                  : () async {
                      setDialogState(() => isSubmitting = true);
                      final apiService = Provider.of<ApiService>(context, listen: false);
                      final days = planDaysMap[selectedPlan] ?? 30;
                      final ok = await apiService.renewSubscription(
                        admin['id'],
                        plan: selectedPlan,
                        days: days,
                        maxAllowedGames: maxGames,
                        gameMode: selectedMode,
                      );
                      if (context.mounted) {
                        Navigator.pop(context);
                        if (ok) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Subscription renewed successfully!'), backgroundColor: Colors.green),
                          );
                          _loadDashboard();
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Failed to renew subscription'), backgroundColor: Colors.red),
                          );
                        }
                      }
                    },
              child: isSubmitting
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('RENEW NOW'),
            ),
          ],
        ),
      ),
    );
  }

  // ===================== STANDARD (ADMIN / AGENT / DEALER) DASHBOARD =====================
  Widget _buildStandardDashboard() {
    bool isAdmin = _stats?['role'] == 'ADMIN';
    final daysLeft = _stats?['subscription_days_left'] ?? 9999;
    final bool showExpiryAlert = isAdmin && daysLeft <= 5;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showExpiryAlert) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.amber.shade100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amber.shade700),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.amber.shade900),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    daysLeft <= 0
                        ? 'നിങ്ങളുടെ സബ്സ്ക്രിപ്ഷൻ കാലാവധി കഴിഞ്ഞു! ദയവായി സൂപ്പർ അഡ്മിനുമായി ബന്ധപ്പെടുക.'
                        : 'നിങ്ങളുടെ സബ്സ്ക്രിപ്ഷൻ കാലാവധി കഴിയാൻ $daysLeft ദിവസം മാത്രം ബാക്കി! സൂപ്പർ അഡ്മിനുമായി ബന്ധപ്പെട്ട് റിന്യൂ ചെയ്യുക.',
                    style: TextStyle(color: Colors.amber.shade900, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        _buildProfileCard(),
        const SizedBox(height: 24),
        const Text(
          'Quick Actions',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        _buildGridActions(),
      ],
    );
  }

  Widget _buildNavigationRail() {
    return NavigationRail(
      extended: MediaQuery.of(context).size.width > 900,
      backgroundColor: AppColors.primary.withValues(alpha: 0.05),
      unselectedIconTheme: const IconThemeData(color: Colors.grey),
      selectedIconTheme: const IconThemeData(color: AppColors.primary),
      destinations: const [
        NavigationRailDestination(
          icon: Icon(Icons.dashboard),
          label: Text('Dashboard'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.settings),
          label: Text('Settings'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.logout, color: Colors.red),
          label: Text('Logout'),
        ),
      ],
      selectedIndex: 0,
      onDestinationSelected: (index) {
        if (index == 1) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SettingsScreen()),
          );
        } else if (index == 2) {
          Navigator.pushReplacementNamed(context, '/');
        }
      },
      leading: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: CircleAvatar(
          backgroundColor: AppColors.primary,
          child: Text(
            _stats?['username']?[0].toUpperCase() ?? 'U',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.w900),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: TextStyle(color: color.withValues(alpha: 0.85), fontSize: 10, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard() {
    bool isAdmin = _stats?['role'] == 'ADMIN';
    final activeGames = _stats?['active_games'] ?? 0;
    final maxGames = _stats?['max_allowed_games'] ?? 4;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Icon(Icons.person_outline_rounded, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _stats?['username'] ?? 'User',
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        _stats?['role']?.replaceAll('_', ' ') ?? 'ROLE',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 11, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ],
              ),
              if (isAdmin)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Games: $activeGames / $maxGames Allowed',
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Limit: ₹${_stats?['weekly_credit_limit'] ?? '0.00'}',
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Colors.white24),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'REMAINING CREDIT',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '₹${_stats?['remaining_credit'] ?? '0.00'}',
                    style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900),
                  ),
                ],
              ),
              Text(
                'Sale: ₹${_stats?['weekly_sales'] ?? '0'} | Win: ₹${_stats?['weekly_wins'] ?? '0'}',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 11, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGridActions() {
    bool isAdmin = _stats?['role'] == 'ADMIN';
    bool isAgent = _stats?['role'] == 'AGENT';
    bool isDealer = _stats?['role'] == 'DEALER';
    bool canManage = isAdmin || isAgent || isDealer;

    double screenWidth = MediaQuery.of(context).size.width;
    int crossAxisCount = screenWidth > 1200 ? 6 : (screenWidth > 800 ? 4 : 3);

    return GridView.count(
      crossAxisCount: crossAxisCount,
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      childAspectRatio: 1.05,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildActionCard(
          'Place Bet',
          Icons.add_shopping_cart,
          Colors.blue,
          () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SelectGameScreen())),
        ),
        _buildActionCard(
          'Reports',
          Icons.bar_chart,
          Colors.orange,
          () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ReportScreen())),
        ),
        if (isAdmin)
          _buildActionCard(
            'Monitoring',
            Icons.remove_red_eye_rounded,
            Colors.deepOrange,
            () => Navigator.push(context, MaterialPageRoute(builder: (context) => const MonitorScreen())),
          ),
        if (isAdmin)
          _buildActionCard(
            'Cut Report',
            Icons.content_cut_rounded,
            Colors.teal,
            () => Navigator.push(context, MaterialPageRoute(builder: (context) => const CutReportScreen())),
          ),
        if (canManage)
          _buildActionCard(
            isAdmin ? 'Manage Agents' : 'Manage Team',
            Icons.supervisor_account,
            Colors.purple,
            () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ManageAdminsScreen())),
          ),
        if (isAdmin)
          _buildActionCard(
            'Manage Games',
            Icons.sports_esports_rounded,
            Colors.green.shade700,
            () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ManageGamesScreen())),
          )
        else if (_stats?['role'] != 'SUB_DEALER')
          _buildActionCard(
            'Game Times',
            Icons.timer,
            Colors.green,
            () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ManageGamesScreen())),
          ),
        _buildActionCard(
          'View Results',
          Icons.remove_red_eye,
          Colors.cyan,
          () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ResultViewScreen())),
        ),
        if (isAdmin)
          _buildActionCard(
            'Publish Result',
            Icons.publish_rounded,
            Colors.red,
            () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PublishResultScreen())),
          ),
        if (isAdmin)
          _buildActionCard(
            'Price Setting',
            Icons.currency_rupee_rounded,
            Colors.indigo,
            () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PriceSettingScreen())),
          ),
        if (isAdmin)
          _buildActionCard(
            'Net Rate',
            Icons.tune_rounded,
            Colors.teal.shade800,
            () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminNetRateScreen())),
          ),
        if (isAdmin)
          _buildActionCard(
            'Global Limit',
            Icons.public_rounded,
            Colors.deepOrange,
            () => Navigator.push(context, MaterialPageRoute(builder: (context) => const GlobalCountLimitScreen())),
          ),
        _buildActionCard(
          'Prize&Comm',
          Icons.emoji_events_rounded,
          Colors.teal.shade700,
          () async {
            final apiService = Provider.of<ApiService>(context, listen: false);
            final user = await apiService.getProfile();
            if (user != null && context.mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ManagePrizeCommissionScreen(user: user, isReadOnly: !isAdmin),
                ),
              );
            }
          },
        ),
        if (isAdmin)
          _buildActionCard(
            'Settings',
            Icons.settings,
            Colors.blueGrey,
            () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SystemSettingsScreen())),
          ),
      ],
    );
  }

  Widget _buildActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.15)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    bool isSuperAdmin = _stats?['role'] == 'SUPER_ADMIN';
    bool isAdmin = _stats?['role'] == 'ADMIN';
    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(_stats?['username'] ?? 'User'),
            accountEmail: Text(_stats?['role']?.replaceAll('_', ' ') ?? 'ROLE'),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                _stats?['username']?[0].toUpperCase() ?? 'U',
                style: const TextStyle(fontSize: 24, color: AppColors.primary, fontWeight: FontWeight.bold),
              ),
            ),
            decoration: const BoxDecoration(color: AppColors.primary),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard_rounded),
            title: const Text('Dashboard'),
            onTap: () => Navigator.pop(context),
          ),
          if (isAdmin)
            ListTile(
              leading: const Icon(Icons.remove_red_eye_rounded, color: Colors.deepOrange),
              title: const Text('Monitoring'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => const MonitorScreen()));
              },
            ),
          if (isSuperAdmin)
            ListTile(
              leading: const Icon(Icons.person_add_rounded, color: AppColors.primary),
              title: const Text('Create Admin'),
              onTap: () async {
                Navigator.pop(context);
                final res = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CreateAdminScreen()),
                );
                if (res == true) _loadDashboard();
              },
            ),
          ListTile(
            leading: const Icon(Icons.settings_rounded),
            title: const Text('Settings'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()));
            },
          ),
          const Spacer(),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout_rounded, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            onTap: () async {
              final apiService = Provider.of<ApiService>(context, listen: false);
              await apiService.logout();
              if (mounted) {
                Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
              }
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
