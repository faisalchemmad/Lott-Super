import 'package:flutter/material.dart';
import '../models/game_model.dart';
import '../utils/constants.dart';
import 'global_count_limit_detail_screen.dart';

class GlobalLimitMenuScreen extends StatelessWidget {
  final GameModel game;
  const GlobalLimitMenuScreen({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text('${game.name} Global Settings',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            _buildSelectionCard(
              context,
              title: 'COUNT LIMIT',
              subtitle: 'Manage system-wide caps for all bet types',
              icon: Icons.settings_input_component_rounded,
              color: AppColors.primary,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => GlobalCountLimitDetailScreen(
                        game: game, initialTab: 0)),
              ),
            ),
            const SizedBox(height: 24),
            _buildSelectionCard(
              context,
              title: 'NUMBER COUNT',
              subtitle: 'Restrict specific numbers system-wide',
              icon: Icons.numbers_rounded,
              color: Colors.deepOrange,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => GlobalCountLimitDetailScreen(
                        game: game, initialTab: 1)),
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
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800])),
                      const SizedBox(height: 4),
                      Text(subtitle,
                          style:
                              TextStyle(fontSize: 14, color: Colors.grey[600])),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded,
                    color: Colors.grey[400], size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
