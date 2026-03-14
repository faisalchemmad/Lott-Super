import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/game_model.dart';
import '../utils/constants.dart';
import 'manage_user_number_limits_screen.dart';
import 'manage_user_count_limits_screen.dart';

class UserGameLimitMenuScreen extends StatelessWidget {
  final UserModel user;
  final GameModel game;
  const UserGameLimitMenuScreen({super.key, required this.user, required this.game});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text('${game.name} Limits',
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            _buildSelectionCard(
              context,
              title: 'COUNT LIMIT',
              subtitle: 'Manage type caps (A, B, C, SUPER, etc.) for this user',
              icon: Icons.analytics_rounded,
              color: AppColors.primary,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => ManageUserCountLimitsScreen(
                        user: user)),
              ),
            ),
            const SizedBox(height: 24),
            _buildSelectionCard(
              context,
              title: 'NUMBER COUNT',
              subtitle: 'Restrict specific numbers for ${game.name}',
              icon: Icons.format_list_numbered_rounded,
              color: Colors.deepOrange,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => ManageUserNumberLimitsScreen(
                        user: user, game: game)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectionCard(BuildContext context,
      {required String title,
      required String subtitle,
      required IconData icon,
      required Color color,
      required VoidCallback onTap}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      color: color.withOpacity(0.1), shape: BoxShape.circle),
                  child: Icon(icon, color: color, size: 36),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800])),
                      const SizedBox(height: 4),
                      Text(subtitle,
                          style:
                              TextStyle(fontSize: 13, color: Colors.grey[600])),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded,
                    color: Colors.grey[400], size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
