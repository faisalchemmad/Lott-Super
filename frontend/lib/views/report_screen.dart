import 'forward_net_report_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'forward_winning_report_screen.dart';
import 'package:flutter/material.dart';
import '../utils/constants.dart';
import 'sales_report_screen.dart';
import 'count_report_screen.dart';
import 'daily_report_screen.dart';
import 'number_report_screen.dart';
import 'winning_report_filter_screen.dart';
import 'purchase_report_screen.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}


class _ReportScreenState extends State<ReportScreen> {
  String _userRole = '';

  @override
  void initState() {
    super.initState();
    _loadRole();
  }

  Future<void> _loadRole() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userRole = prefs.getString('role') ?? '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 180,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: AppColors.primary,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
              title: const Text(
                'Reports Center',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, Color(0xFFC0392B)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -50,
                      top: -50,
                      child: CircleAvatar(
                        radius: 100,
                        backgroundColor: Colors.white.withOpacity(0.05),
                      ),
                    ),
                    Positioned(
                      left: -20,
                      bottom: 20,
                      child: CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.white.withOpacity(0.03),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(top: 80, left: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Business Insights',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'View and analyze summaries',
                            style: TextStyle(
                              color: Colors.white60,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildReportCard(
                  title: 'Sales Report',
                  subtitle: 'Detailed breakdown of all tickets sold',
                  icon: Icons.analytics_rounded,
                  color: Colors.blueAccent,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const SalesReportScreen()),
                  ),
                ),
                const SizedBox(height: 12),
                _buildReportCard(
                  title: 'Winning Report',
                  subtitle: 'Track winners and prize distributions',
                  icon: Icons.emoji_events_rounded,
                  color: Colors.amber.shade700,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            const WinningReportFilterScreen()),
                  ),
                ),
                const SizedBox(height: 12),
                if (_userRole == 'SUPER_ADMIN' || _userRole == 'ADMIN') ...[
                  _buildReportCard(
                    title: 'Forward Winning Report',
                    subtitle: 'Track winners from forwarded bets',
                    icon: Icons.military_tech_rounded,
                    color: Colors.orange.shade700,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              const ForwardWinningReportScreen()),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildReportCard(
                    title: 'Forward Net Report',
                    subtitle: 'Summary of forwarded bets (Purchase - Win - Commi)',
                    icon: Icons.account_balance_wallet_rounded,
                    color: Colors.purple.shade600,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              const ForwardNetReportScreen()),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                _buildReportCard(
                  title: 'Number Report',
                  subtitle: 'Check total quantity for specific numbers',
                  icon: Icons.onetwothree_rounded,
                  color: Colors.tealAccent.shade700,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const NumberReportScreen()),
                  ),
                ),
                const SizedBox(height: 12),
                _buildReportCard(
                  title: 'Count Report',
                  subtitle: 'Summary of ticket counts by type',
                  icon: Icons.calculate_rounded,
                  color: Colors.indigoAccent,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const CountReportScreen()),
                  ),
                ),
                const SizedBox(height: 12),
                const SizedBox(height: 12),
                _buildReportCard(
                  title: 'Daily Report',
                  subtitle: 'Summary grouped by Date or Game name',
                  icon: Icons.calendar_today_rounded,
                  color: Colors.orangeAccent,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const DailyReportScreen()),
                  ),
                ),
                const SizedBox(height: 12),
                _buildReportCard(
                  title: 'Purchase Report',
                  subtitle: 'View forwarded numbers and total purchase amount',
                  icon: Icons.shopping_cart_checkout_rounded,
                  color: Colors.pinkAccent,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const PurchaseReportScreen()),
                  ),
                ),
                const SizedBox(height: 50),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color.withOpacity(0.15), color.withOpacity(0.05)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: Colors.grey.shade400,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
