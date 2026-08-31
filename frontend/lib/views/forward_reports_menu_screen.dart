import 'package:flutter/material.dart';
import '../utils/constants.dart';
import 'forward_report_filter_screen.dart';
import 'forward_winning_report_screen.dart';
import 'forward_net_report_screen.dart';
import 'number_report_screen.dart';

class ForwardReportsMenuScreen extends StatelessWidget {
  const ForwardReportsMenuScreen({super.key});

  Widget _buildReportCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
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
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.grey[400],
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Fwd Reports',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.primary,
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          children: [
            _buildReportCard(
              context: context,
              title: 'Forward Report',
              subtitle: 'View and delete forwarded bets',
              icon: Icons.list_alt_rounded,
              color: Colors.blue.shade700,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const ForwardReportFilterScreen()),
              ),
            ),
            const SizedBox(height: 8),
            _buildReportCard(
              context: context,
              title: 'Forward Winning Report',
              subtitle: 'Track winners from forwarded bets',
              icon: Icons.military_tech_rounded,
              color: Colors.orange.shade700,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const ForwardWinningReportScreen()),
              ),
            ),
            const SizedBox(height: 8),
            _buildReportCard(
              context: context,
              title: 'Forward Net Report',
              subtitle: 'Summary of forwarded bets (Purchase - Win - Commi)',
              icon: Icons.account_balance_wallet_rounded,
              color: Colors.purple.shade600,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const ForwardNetReportScreen()),
              ),
            ),
            const SizedBox(height: 8),
            _buildReportCard(
              context: context,
              title: 'Forward Number Report',
              subtitle: 'Check total quantities of forwarded numbers',
              icon: Icons.format_list_numbered_rounded,
              color: Colors.cyan.shade700,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        const NumberReportScreen(isForwardedOnly: true)),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
