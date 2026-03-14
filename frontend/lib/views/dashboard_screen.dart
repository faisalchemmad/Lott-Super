import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';
import 'report_screen.dart';
import 'manage_admins_screen.dart';
import 'manage_games_screen.dart';
import 'select_game_screen.dart';
import 'publish_result_screen.dart';
import 'result_view_screen.dart';
import 'price_setting_screen.dart';
import 'global_count_limit_screen.dart';
import 'manage_prize_commission_screen.dart';
import '../models/user_model.dart';
import 'user_options_screen.dart';
import 'settings_screen.dart';
import 'system_settings_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic>? _stats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    final apiService = Provider.of<ApiService>(context, listen: false);
    final data = await apiService.getDashboard();
    setState(() {
      _stats = data;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboard,
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDashboard,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_stats?['role'] != 'SUPER_ADMIN') ...[
                      _buildProfileCard(),
                      const SizedBox(height: 24),
                    ] else ...[
                      _buildSuperAdminStats(),
                      const SizedBox(height: 24),
                    ],
                    const Text(
                      'Quick Actions',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    _buildGridActions(),

                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSuperAdminStats() {
    final double sales =
        double.tryParse(_stats?['global_daily_sales']?.toString() ?? '0') ?? 0;
    final double wins =
        double.tryParse(_stats?['global_daily_wins']?.toString() ?? '0') ?? 0;
    final double profit =
        double.tryParse(_stats?['global_daily_profit']?.toString() ?? '0') ??
            0;

    return Row(
      children: [
        _buildStatCard('Total Sales', '₹${sales.toStringAsFixed(0)}',
            Colors.blue, Icons.trending_up),
        const SizedBox(width: 12),
        _buildStatCard('Total Win', '₹${wins.toStringAsFixed(0)}',
            Colors.orange, Icons.emoji_events),
        const SizedBox(width: 12),
        _buildStatCard(
            'Profit/Loss',
            '₹${profit.toStringAsFixed(0)}',
            profit >= 0 ? Colors.green : Colors.red,
            profit >= 0 ? Icons.account_balance_wallet : Icons.trending_down),
      ],
    );
  }

  Widget _buildStatCard(
      String title, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                  color: color, fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(color: color.withOpacity(0.8), fontSize: 10),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primary, AppColors.secondary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _stats?['username'] ?? 'User',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold),
                    ),
                    Text(
                      _stats?['role']?.replaceAll('_', ' ') ?? 'ROLE',
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                  ],
                ),
                const Icon(Icons.account_balance,
                    color: Colors.white, size: 40),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Flexible(
                  child: Text(
                    'Remaining Credit',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Flexible(
                  child: Text(
                    'Limit: ₹${_stats?['weekly_credit_limit'] ?? '0.00'}',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                    textAlign: TextAlign.right,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            Text(
              '₹${_stats?['remaining_credit'] ?? '0.00'}',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              'Weekly Sale: ₹${_stats?['weekly_sales'] ?? '0.00'} | Win: ₹${_stats?['weekly_wins'] ?? '0.00'}',
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridActions() {
    bool isSuperAdmin = _stats?['role'] == 'SUPER_ADMIN';
    bool isAdmin = _stats?['role'] == 'ADMIN';
    bool isAgent = _stats?['role'] == 'AGENT';
    bool isDealer = _stats?['role'] == 'DEALER';

    // Anyone who is not a SUB_DEALER can manage others
    bool canManage = isSuperAdmin || isAdmin || isAgent || isDealer;

    print("User Role: ${_stats?['role']}");
    int crossAxisCount = 2;

    return GridView.count(
      crossAxisCount: crossAxisCount,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildActionCard(
          'Place Bet',
          Icons.add_shopping_cart,
          Colors.blue,
          () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const SelectGameScreen())),
        ),
        _buildActionCard(
          'Reports',
          Icons.bar_chart,
          Colors.orange,
          () => Navigator.push(context,
              MaterialPageRoute(builder: (context) => const ReportScreen())),
        ),
        if (canManage)
          _buildActionCard(
            isSuperAdmin
                ? 'Admins'
                : (isAdmin ? 'Manage Agents' : 'Manage Team'),
            Icons.supervisor_account,
            Colors.purple,
            () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const ManageAdminsScreen())),
          ),
        if (_stats?['role'] != 'SUB_DEALER')
          _buildActionCard(
            'Game Times',
            Icons.timer,
            Colors.green,
            () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const ManageGamesScreen())),
          ),
        _buildActionCard(
          'View Results',
          Icons.remove_red_eye,
          Colors.cyan,
          () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const ResultViewScreen())),
        ),
        if (isSuperAdmin)
          _buildActionCard(
            'Price Setting',
            Icons.currency_rupee_rounded,
            Colors.indigo,
            () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const PriceSettingScreen())),
          ),
        if (isSuperAdmin)
          _buildActionCard(
            'Global Limit',
            Icons.public_rounded,
            Colors.deepOrange,
            () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const GlobalCountLimitScreen())),
          ),
        if (isSuperAdmin)
          _buildActionCard(
            'Publish',
            Icons.publish,
            Colors.red,
            () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const PublishResultScreen())),
          ),
        _buildActionCard(
          'Prize&Comm',
          Icons.currency_rupee_rounded,
          Colors.teal,
          () async {
            final apiService = Provider.of<ApiService>(context, listen: false);
            final user = await apiService.getProfile();
            if (user != null && context.mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      ManagePrizeCommissionScreen(user: user, isReadOnly: true),
                ),
              );
            }
          },
        ),
        if (isSuperAdmin)
          _buildActionCard(
            'Settings',
            Icons.settings_suggest_rounded,
            Colors.blueGrey,
            () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const SystemSettingsScreen())),
          ),
      ],
    );
  }

  Widget _buildUserList() {
    List users = _stats?['users'] ?? [];
    if (users.isEmpty) return const Center(child: Text('No users found'));

    return Column(
      children: users.map<Widget>((u) {
        String dateStr = u['date_joined'] ?? '';
        String formattedDate = '';
        try {
          if (dateStr.isNotEmpty) {
            DateTime dt = DateTime.parse(dateStr).toLocal();
            formattedDate = DateFormat('dd MMM yyyy, hh:mm a').format(dt);
          }
        } catch (_) {}

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          elevation: 1,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: ListTile(
            onTap: () {
              UserModel userModel = UserModel.fromJson(u);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => UserOptionsScreen(user: userModel),
                ),
              );
            },
            leading: CircleAvatar(
              backgroundColor: AppColors.primary.withOpacity(0.1),
              child: const Icon(Icons.person, color: AppColors.primary),
            ),
            title: Text(
              u['username'] ?? 'Unknown',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              u['role']?.replaceAll('_', ' ') ?? '',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
            trailing: Text(
              formattedDate,
              style: const TextStyle(fontSize: 11, color: Colors.blueGrey),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildActionCard(
      String title, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: AppColors.primary),
            accountName: Text(_stats?['username'] ?? 'User'),
            accountEmail: Text(_stats?['role'] ?? 'Role'),
            currentAccountPicture: const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.person, color: AppColors.primary, size: 40),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text('Dashboard'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout'),
            onTap: () {
              Navigator.pushReplacementNamed(context, '/');
            },
          ),
        ],
      ),
    );
  }
}
