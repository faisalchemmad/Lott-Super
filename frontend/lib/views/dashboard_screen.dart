import 'forward_winning_report_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
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
import 'manage_forward_limits_screen.dart';
import 'manual_forwarding_screen.dart';

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
    bool isDesktop = defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.macOS;

    return Scaffold(
      appBar: isDesktop
          ? null
          : AppBar(
              title: const Text('Dashboard'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh),
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
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          _buildGridActions(),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationRail() {
    return NavigationRail(
      extended: MediaQuery.of(context).size.width > 900,
      backgroundColor: AppColors.primary.withOpacity(0.05),
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

  Widget _buildSuperAdminStats() {
    final double sales =
        double.tryParse(_stats?['global_daily_sales']?.toString() ?? '0') ?? 0;
    final double wins =
        double.tryParse(_stats?['global_daily_wins']?.toString() ?? '0') ?? 0;
    final double profit =
        double.tryParse(_stats?['global_daily_profit']?.toString() ?? '0') ?? 0;

    return Row(
      children: [
        _buildStatCard('Total Sales', '₹${sales.toStringAsFixed(0)}',
            Colors.blue, Icons.trending_up),
        const SizedBox(width: 8),
        _buildStatCard('Total Win', '₹${wins.toStringAsFixed(0)}',
            Colors.orange, Icons.emoji_events),
        const SizedBox(width: 8),
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
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                  color: color, fontSize: 13, fontWeight: FontWeight.w900),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: TextStyle(
                  color: color.withOpacity(0.85),
                  fontSize: 10,
                  fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.25),
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
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Icon(Icons.person_outline_rounded,
                        color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _stats?['username'] ?? 'User',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold),
                      ),
                      Text(
                        _stats?['role']?.replaceAll('_', ' ') ?? 'ROLE',
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 11,
                            fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Limit: ₹${_stats?['weekly_credit_limit'] ?? '0.00'}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600),
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
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.75),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '₹${_stats?['remaining_credit'] ?? '0.00'}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900),
                  ),
                ],
              ),
              Text(
                'Sale: ₹${_stats?['weekly_sales'] ?? '0'} | Win: ₹${_stats?['weekly_wins'] ?? '0'}',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 11,
                    fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
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
        if (isAdmin && (_stats?['can_forward'] == true))
          _buildActionCard(
            'Auto Forward',
            Icons.forward_to_inbox,
            Colors.blueGrey,
            () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const ManageForwardLimitsScreen())),
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.09),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(icon, size: 22, color: color),
                ),
                const SizedBox(height: 6),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C3E50),
                  ),
                ),
              ],
            ),
          ),
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
