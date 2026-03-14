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
    extends State<ManageUserNumberLimitsScreen> {
  bool _isLoading = true;
  List<NumberLimitModel> _limits = [];
  List<GameModel> _games = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final apiService = Provider.of<ApiService>(context, listen: false);

    try {
      final allLimits = await apiService.getNumberLimits(widget.game?.id);
      final userLimits =
          allLimits.where((l) => l.userUsername == widget.user.username).toList();

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

  void _showAddNumberLimitDialog({NumberLimitModel? limit}) {
    final bool isEditing = limit != null;
    final numController =
        TextEditingController(text: isEditing ? limit.number : '');
    final countController = TextEditingController(
        text: isEditing ? limit.maxCount.toString() : '');
    String selectedType = isEditing ? limit.type : 'SUPER';
    final types = ['A', 'B', 'C', 'AB', 'BC', 'AC', 'SUPER', 'BOX'];
    bool allGame = false;
    int? selectedGameId = widget.game?.id ?? (_games.isNotEmpty ? _games.first.id : null);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
              isEditing
                  ? 'Edit User Number Limit'
                  : 'Add User Number Limit',
              style: const TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedType,
                  decoration: const InputDecoration(labelText: 'Bet Type'),
                  items: types
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (val) => setDialogState(() => selectedType = val!),
                ),
                TextField(
                  controller: numController,
                  decoration:
                      const InputDecoration(labelText: 'Number (1-3 digits)'),
                  keyboardType: TextInputType.number,
                  enabled: !isEditing,
                ),
                TextField(
                  controller: countController,
                  decoration:
                      const InputDecoration(labelText: 'Max Count'),
                  keyboardType: TextInputType.number,
                ),
                if (!isEditing && _games.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Checkbox(
                        value: allGame,
                        onChanged: (val) => setDialogState(() => allGame = val!),
                      ),
                      const Text('ALL Game'),
                    ],
                  ),
                  if (!allGame)
                    DropdownButtonFormField<int>(
                      value: selectedGameId,
                      decoration: const InputDecoration(labelText: 'Select Game'),
                      items: _games
                          .map((g) => DropdownMenuItem(value: g.id, child: Text(g.name)))
                          .toList(),
                      onChanged: (val) => setDialogState(() => selectedGameId = val!),
                    ),
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
                if (numController.text.isEmpty || countController.text.isEmpty)
                  return;

                int reqDigits = 0;
                if (['A', 'B', 'C'].contains(selectedType)) {
                  reqDigits = 1;
                } else if (['AB', 'BC', 'AC'].contains(selectedType)) {
                  reqDigits = 2;
                } else if (['SUPER', 'BOX'].contains(selectedType)) {
                  reqDigits = 3;
                }

                if (numController.text.length != reqDigits) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Number must be $reqDigits digits')),
                  );
                  return;
                }

                final apiService = Provider.of<ApiService>(context, listen: false);
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
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: Text(isEditing ? 'UPDATE' : 'ADD',
                  style: const TextStyle(color: Colors.white)),
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
        content: const Text('Are you sure you want to remove this number limit?'),
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
    String title = widget.isReadOnly ? 'My Number Limits' : 'Number Count Limit';
    if (widget.game != null) {
      title += ' (${widget.game!.name})';
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          _buildInfoCard('Set specific limits for numbers and bet types for ${widget.user.username}${widget.game != null ? " in ${widget.game!.name}" : ""}.'),
          if (!widget.isReadOnly)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Custom Limits',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary)),
                  ElevatedButton.icon(
                    onPressed: () => _showAddNumberLimitDialog(),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('ADD LIMIT'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _limits.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _limits.length,
                        itemBuilder: (context, index) {
                          final limit = _limits[index];
                          return _buildNumberLimitCard(limit);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildNumberLimitCard(NumberLimitModel limit) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          _buildTypeBadge(limit.type),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Number: ${limit.number}',
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C3E50)),
                ),
                Text(
                  'Max: ${limit.maxCount} | Game: ${limit.gameName}',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          if (!widget.isReadOnly) ...[
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: Colors.blue),
              onPressed: () => _showAddNumberLimitDialog(limit: limit),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
              onPressed: () => _confirmDelete(limit.id),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypeBadge(String type) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        type,
        style: const TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
            fontSize: 12),
      ),
    );
  }

  Widget _buildInfoCard(String text) {
    return Container(
      width: double.infinity,
      color: AppColors.primary,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: Colors.white, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style:
                  TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.numbers_outlined, size: 60, color: Colors.grey[300]),
          const SizedBox(height: 12),
          const Text('No Number Limits Set',
              style: TextStyle(color: Colors.grey, fontSize: 16)),
        ],
      ),
    );
  }
}
