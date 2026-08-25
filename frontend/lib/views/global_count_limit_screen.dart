import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../models/game_model.dart';
import '../utils/constants.dart';
import 'global_count_limit_detail_screen.dart';

class GlobalCountLimitScreen extends StatefulWidget {
  const GlobalCountLimitScreen({super.key});

  @override
  State<GlobalCountLimitScreen> createState() => _GlobalCountLimitScreenState();
}

class _GlobalCountLimitScreenState extends State<GlobalCountLimitScreen> {
  List<GameModel> _games = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGames();
  }

  Future<void> _loadGames() async {
    final apiService = Provider.of<ApiService>(context, listen: false);
    final games = await apiService.getGames();
    setState(() {
      _games = games;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Global Count Limit',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        centerTitle: true,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _games.isEmpty
              ? _buildEmptyState()
              : GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 2.3,
                  ),
                  itemCount: _games.length,
                  itemBuilder: (context, index) {
                    final game = _games[index];
                    return _buildGameCard(game);
                  },
                ),
    );
  }

  Widget _buildGameCard(GameModel game) {
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
          onTap: () => _showGameOptions(game),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.videogame_asset_rounded,
                      color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        game.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        game.time,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.keyboard_arrow_down_rounded,
                    color: Colors.grey[400], size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showGameOptions(GameModel game) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(Icons.videogame_asset_rounded,
                          color: AppColors.primary, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${game.name} Global Limits',
                      style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 8),
                ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.analytics_rounded,
                        color: AppColors.primary, size: 20),
                  ),
                  title: const Text('COUNT LIMIT',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  subtitle: const Text(
                      'Manage global type caps (A, B, C, SUPER, etc.)',
                      style: TextStyle(fontSize: 12, color: Colors.grey)),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded,
                      size: 14, color: Colors.grey),
                  onTap: () async {
                    Navigator.pop(context);
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => GlobalCountLimitDetailScreen(
                            game: game, initialTab: 0),
                      ),
                    );
                    if (result == true) _loadGames();
                  },
                ),
                ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.deepOrange.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.format_list_numbered_rounded,
                        color: Colors.deepOrange, size: 20),
                  ),
                  title: const Text('NUMBER COUNT',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  subtitle: Text(
                      'Restrict specific numbers globally for ${game.name}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded,
                      size: 14, color: Colors.grey),
                  onTap: () async {
                    Navigator.pop(context);
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => GlobalCountLimitDetailScreen(
                            game: game, initialTab: 1),
                      ),
                    );
                    if (result == true) _loadGames();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.gamepad_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'No Games Available',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
