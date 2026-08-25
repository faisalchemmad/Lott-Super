import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../models/user_model.dart';
import '../models/game_model.dart';
import '../models/number_limit_model.dart';
import '../utils/constants.dart';

class ManageUserNumberLimitsScreen extends StatefulWidget {
  final UserModel user;
  final GameModel? game; // Optional game for filtering
  final bool isReadOnly;
  const ManageUserNumberLimitsScreen(
      {super.key, required this.user, this.game, this.isReadOnly = false});

  @override
  State<ManageUserNumberLimitsScreen> createState() =>
      _ManageUserNumberLimitsScreenState();
}

class _ManageUserNumberLimitsScreenState
    extends State<ManageUserNumberLimitsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<NumberLimitModel> _limits = [];
  List<GameModel> _games = [];

  static const Set<String> _klTypes = {
    'A',
    'B',
    'C',
    'AB',
    'BC',
    'AC',
    'SUPER',
    'BOX'
  };
  static const Set<String> _tnTypes = {
    'TN-A',
    'TN-B',
    'TN-C',
    'TN-AB',
    'TN-BC',
    'TN-AC',
    '3D-10',
    '3D-25',
    '3D-30',
    '3D-60',
    '4D-110',
    '4D-55',
    '4D-20'
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final apiService = Provider.of<ApiService>(context, listen: false);

    try {
      final allLimits = await apiService.getNumberLimits(widget.game?.id);
      final userLimits = allLimits
          .where((l) => l.userUsername == widget.user.username)
          .toList();

      final games = await apiService.getGames();

      setState(() {
        _limits = userLimits;
        _games = games;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _showAddNumberLimitDialog({NumberLimitModel? limit, bool isTn = false}) {
    final bool isEditing = limit != null;
    final bool isTnLimit = isEditing ? _tnTypes.contains(limit.type) : isTn;
    final types = isTnLimit ? _tnTypes.toList() : _klTypes.toList();

    final numController =
        TextEditingController(text: isEditing ? limit.number : '');
    final countController =
        TextEditingController(text: isEditing ? limit.maxCount.toString() : '');
    String selectedType =
        isEditing ? limit.type : (isTnLimit ? '3D-10' : 'SUPER');
    bool allGame = false;
    int? selectedGameId =
        widget.game?.id ?? (_games.isNotEmpty ? _games.first.id : null);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isTnLimit ? Colors.deepOrange : AppColors.primary,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  isTnLimit ? 'TN' : 'KL',
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                isEditing ? 'Edit Number Limit' : 'Add Number Limit',
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Bet Type',
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  ),
                  items: types
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (val) => setDialogState(() => selectedType = val!),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: numController,
                  decoration: const InputDecoration(
                    labelText: 'Number',
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  ),
                  keyboardType: TextInputType.number,
                  enabled: !isEditing,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: countController,
                  decoration: const InputDecoration(
                    labelText: 'Max Count',
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  ),
                  keyboardType: TextInputType.number,
                ),
                if (!isEditing && _games.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Checkbox(
                        value: allGame,
                        onChanged: (val) =>
                            setDialogState(() => allGame = val!),
                      ),
                      const Text('ALL Games'),
                    ],
                  ),
                  if (!allGame) ...[
                    const SizedBox(height: 8),
                    DropdownButtonFormField<int>(
                      value: selectedGameId,
                      decoration: const InputDecoration(
                        labelText: 'Select Game',
                        border: OutlineInputBorder(),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      ),
                      items: _games
                          .map((g) => DropdownMenuItem(
                              value: g.id, child: Text(g.name)))
                          .toList(),
                      onChanged: (val) =>
                          setDialogState(() => selectedGameId = val!),
                    ),
                  ],
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('CANCEL')),
            ElevatedButton(
              onPressed: () async {
                if (numController.text.isEmpty ||
                    countController.text.isEmpty) {
                  return;
                }

                int reqDigits = 0;
                if (['A', 'B', 'C', 'TN-A', 'TN-B', 'TN-C']
                    .contains(selectedType)) {
                  reqDigits = 1;
                } else if (['AB', 'BC', 'AC', 'TN-AB', 'TN-BC', 'TN-AC']
                    .contains(selectedType)) {
                  reqDigits = 2;
                } else if (['SUPER', 'BOX', '3D-10', '3D-25', '3D-30', '3D-60']
                    .contains(selectedType)) {
                  reqDigits = 3;
                } else if (['4D-110', '4D-55', '4D-20']
                    .contains(selectedType)) {
                  reqDigits = 4;
                }

                if (reqDigits > 0 && numController.text.length != reqDigits) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Number must be $reqDigits digits')),
                  );
                  return;
                }

                final apiService =
                    Provider.of<ApiService>(context, listen: false);
                try {
                  if (isEditing) {
                    await apiService.updateNumberLimit(limit.id, {
                      'type': selectedType,
                      'max_count': int.parse(countController.text),
                    });
                  } else {
                    List<GameModel> targetGames = allGame
                        ? _games
                        : [_games.firstWhere((g) => g.id == selectedGameId)];
                    for (var game in targetGames) {
                      await apiService.createNumberLimit(
                        game.id,
                        widget.user.id,
                        numController.text,
                        selectedType,
                        int.parse(countController.text),
                      );
                    }
                  }
                  Navigator.pop(context);
                  _loadData();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    isTnLimit ? Colors.deepOrange : AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6)),
              ),
              child: Text(isEditing ? 'UPDATE' : 'ADD',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Limit?'),
        content:
            const Text('Are you sure you want to remove this number limit?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('CANCEL')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('DELETE', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true) {
      final apiService = Provider.of<ApiService>(context, listen: false);
      if (await apiService.deleteNumberLimit(id)) {
        _loadData();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    String title =
        widget.isReadOnly ? 'My Number Limits' : 'Number Count Limit';
    if (widget.game != null) {
      title += ' (${widget.game!.name})';
    }

    final klLimits = _limits.where((l) => _klTypes.contains(l.type)).toList();
    final tnLimits = _limits.where((l) => _tnTypes.contains(l.type)).toList();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(title,
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(text: 'KL LIMITS (${klLimits.length})'),
            Tab(text: 'TN LIMITS (${tnLimits.length})'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildLimitsListTab(
                    limits: klLimits,
                    isTn: false,
                    badgeColor: AppColors.primary),
                _buildLimitsListTab(
                    limits: tnLimits,
                    isTn: true,
                    badgeColor: Colors.deepOrange),
              ],
            ),
    );
  }

  Widget _buildLimitsListTab(
      {required List<NumberLimitModel> limits,
      required bool isTn,
      required Color badgeColor}) {
    return Column(
      children: [
        if (!widget.isReadOnly)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isTn ? 'Tamil Nadu Number Limits' : 'Kerala Number Limits',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: badgeColor),
                ),
                ElevatedButton.icon(
                  onPressed: () => _showAddNumberLimitDialog(isTn: isTn),
                  icon: const Icon(Icons.add, size: 16),
                  label: Text('ADD ${isTn ? "TN" : "KL"} LIMIT'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: badgeColor,
                    foregroundColor: Colors.white,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6)),
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: limits.isEmpty
              ? _buildEmptyState(
                  isTn ? 'No TN Number Limits Set' : 'No KL Number Limits Set')
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: limits.length,
                  itemBuilder: (context, index) {
                    final limit = limits[index];
                    return _buildNumberLimitCard(limit, badgeColor);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildNumberLimitCard(NumberLimitModel limit, Color badgeColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 4,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          _buildTypeBadge(limit.type, badgeColor),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Number: ${limit.number}',
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C3E50)),
                ),
                const SizedBox(height: 2),
                Text(
                  'Max: ${limit.maxCount} | Game: ${limit.gameName}',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          if (!widget.isReadOnly) ...[
            IconButton(
              icon:
                  const Icon(Icons.edit_outlined, color: Colors.blue, size: 20),
              onPressed: () => _showAddNumberLimitDialog(limit: limit),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded,
                  color: Colors.red, size: 20),
              onPressed: () => _confirmDelete(limit.id),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypeBadge(String type, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        type,
        style:
            TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }

  Widget _buildEmptyState(String msg) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.numbers_outlined, size: 60, color: Colors.grey[300]),
          const SizedBox(height: 12),
          Text(msg, style: const TextStyle(color: Colors.grey, fontSize: 16)),
        ],
      ),
    );
  }
}
