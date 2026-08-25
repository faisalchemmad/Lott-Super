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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isTn ? 'Tamil Nadu Number Limits' : 'Kerala Number Limits',
                  style: TextStyle(
                      fontSize: 14,
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
        if (limits.isNotEmpty) _buildTableHeader(badgeColor),
        Expanded(
          child: limits.isEmpty
              ? _buildEmptyState(
                  isTn ? 'No TN Number Limits Set' : 'No KL Number Limits Set')
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
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

  Widget _buildTableHeader(Color color) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: const Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              'TYPE',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                  letterSpacing: 0.5),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              'NUMBER',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                  letterSpacing: 0.5),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'CNT',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                  letterSpacing: 0.5),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'ACTION',
              textAlign: TextAlign.right,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                  letterSpacing: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNumberLimitCard(NumberLimitModel limit, Color badgeColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 3,
              offset: const Offset(0, 1)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: _buildTypeBadge(limit.type, badgeColor),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              limit.number,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50)),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '${limit.maxCount}',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w900, color: badgeColor),
            ),
          ),
          Expanded(
            flex: 2,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (!widget.isReadOnly) ...[
                  InkWell(
                    onTap: () => _showAddNumberLimitDialog(limit: limit),
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(Icons.edit_outlined,
                          color: Colors.blue, size: 18),
                    ),
                  ),
                  const SizedBox(width: 4),
                  InkWell(
                    onTap: () => _confirmDelete(limit.id),
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(Icons.delete_outline_rounded,
                          color: Colors.red, size: 18),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeBadge(String type, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        type,
        style:
            TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11),
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
