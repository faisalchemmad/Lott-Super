import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../models/game_model.dart';
import '../utils/constants.dart';

class ManageGamesScreen extends StatefulWidget {
  const ManageGamesScreen({super.key});

  @override
  State<ManageGamesScreen> createState() => _ManageGamesScreenState();
}

class _ManageGamesScreenState extends State<ManageGamesScreen> {
  List<GameModel> _games = [];
  bool _isLoading = true;
  String? _userRole;

  @override
  void initState() {
    super.initState();
    _loadGames();
    _loadRole();
  }

  Future<void> _loadRole() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _userRole = prefs.getString('role'));
  }

  bool get _canManageGames => _userRole == 'SUPER_ADMIN';

  Future<void> _loadGames() async {
    setState(() => _isLoading = true);
    final apiService = Provider.of<ApiService>(context, listen: false);
    final games = await apiService.getGames();
    setState(() {
      _games = games;
      _isLoading = false;
    });
  }

  void _showGameDialog([GameModel? game]) async {
    final nameController = TextEditingController(text: game?.name ?? '');

    TimeOfDay drawTime = const TimeOfDay(hour: 0, minute: 0);
    TimeOfDay startTime = const TimeOfDay(hour: 0, minute: 0);
    TimeOfDay endTime = const TimeOfDay(hour: 23, minute: 59);
    TimeOfDay deadlineTime = const TimeOfDay(hour: 23, minute: 59);
    bool canEditDelete = game?.canEditDelete ?? true;
    String selectedColor = game?.color ?? '#2C3E50';
    String selectedBgColor = game?.optionsBgColor ?? '#FFFFFF';

    if (game != null) {
      try {
        final dParts = game.time.split(':');
        drawTime =
            TimeOfDay(hour: int.parse(dParts[0]), minute: int.parse(dParts[1]));

        final sParts = game.startTime.split(':');
        startTime =
            TimeOfDay(hour: int.parse(sParts[0]), minute: int.parse(sParts[1]));

        final eParts = game.endTime.split(':');
        endTime =
            TimeOfDay(hour: int.parse(eParts[0]), minute: int.parse(eParts[1]));

        final dlParts = game.editDeleteLimitTime.split(':');
        deadlineTime = TimeOfDay(
            hour: int.parse(dlParts[0]), minute: int.parse(dlParts[1]));
      } catch (_) {}
    }

    String formatTime(TimeOfDay t) =>
        "${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:00";

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          title: Text(game == null ? 'Add Game' : 'Edit Game',
              style: const TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Game Name (e.g. 1PM DRAW)',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6)),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                      side: BorderSide(color: Colors.grey.shade200)),
                  title: const Text('Draw Time',
                      style:
                          TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  subtitle: Text(drawTime.format(context),
                      style: const TextStyle(fontSize: 12)),
                  trailing: const Icon(Icons.access_time,
                      size: 18, color: AppColors.primary),
                  onTap: () async {
                    final picked = await showTimePicker(
                        context: context, initialTime: drawTime);
                    if (picked != null) setDialogState(() => drawTime = picked);
                  },
                ),
                const SizedBox(height: 8),
                ListTile(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                      side: BorderSide(color: Colors.grey.shade200)),
                  title: const Text('Betting Start',
                      style:
                          TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  subtitle: Text(startTime.format(context),
                      style: const TextStyle(fontSize: 12)),
                  trailing: const Icon(Icons.access_time,
                      size: 18, color: AppColors.primary),
                  onTap: () async {
                    final picked = await showTimePicker(
                        context: context, initialTime: startTime);
                    if (picked != null) {
                      setDialogState(() => startTime = picked);
                    }
                  },
                ),
                const SizedBox(height: 8),
                ListTile(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                      side: BorderSide(color: Colors.grey.shade200)),
                  title: const Text('Betting End',
                      style:
                          TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  subtitle: Text(endTime.format(context),
                      style: const TextStyle(fontSize: 12)),
                  trailing: const Icon(Icons.access_time,
                      size: 18, color: AppColors.primary),
                  onTap: () async {
                    final picked = await showTimePicker(
                        context: context, initialTime: endTime);
                    if (picked != null) setDialogState(() => endTime = picked);
                  },
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                      side: BorderSide(color: Colors.grey.shade200)),
                  title: const Text('Allow Edit/Delete',
                      style:
                          TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  subtitle: const Text('Enable invoice changes for this game',
                      style: TextStyle(fontSize: 11)),
                  value: canEditDelete,
                  onChanged: (val) => setDialogState(() => canEditDelete = val),
                ),
                const SizedBox(height: 8),
                ListTile(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                      side: BorderSide(color: Colors.grey.shade200)),
                  title: const Text('Edit/Delete Deadline',
                      style:
                          TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  subtitle: Text(deadlineTime.format(context),
                      style: const TextStyle(fontSize: 12)),
                  trailing: const Icon(Icons.timer_outlined,
                      size: 18, color: AppColors.primary),
                  onTap: () async {
                    final picked = await showTimePicker(
                        context: context, initialTime: deadlineTime);
                    if (picked != null) {
                      setDialogState(() => deadlineTime = picked);
                    }
                  },
                ),
                const SizedBox(height: 14),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Betting Screen Color',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    '#9C212C',
                    '#2E7D32',
                    '#1565C0',
                    '#F9A825',
                    '#6A1B9A',
                    '#2C3E50',
                    '#E91E63'
                  ]
                      .map((c) => GestureDetector(
                            onTap: () =>
                                setDialogState(() => selectedColor = c),
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: Color(
                                    int.parse(c.replaceFirst('#', '0xFF'))),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: selectedColor == c
                                      ? Colors.black
                                      : Colors.grey.shade300,
                                  width: selectedColor == c ? 2 : 1,
                                ),
                              ),
                              child: selectedColor == c
                                  ? const Icon(Icons.check,
                                      color: Colors.white, size: 18)
                                  : null,
                            ),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 14),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Options Background Color',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    '#FFFFFF',
                    '#F5F5F5',
                    '#E3F2FD',
                    '#E8F5E9',
                    '#FFF3E0',
                    '#FCE4EC',
                    '#F3E5F5',
                  ]
                      .map((c) => GestureDetector(
                            onTap: () =>
                                setDialogState(() => selectedBgColor = c),
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: Color(
                                    int.parse(c.replaceFirst('#', '0xFF'))),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: selectedBgColor == c
                                      ? Colors.black
                                      : Colors.grey.shade400,
                                  width: selectedBgColor == c ? 2 : 1,
                                ),
                              ),
                              child: selectedBgColor == c
                                  ? const Icon(Icons.check,
                                      color: Colors.black, size: 18)
                                  : null,
                            ),
                          ))
                      .toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6)),
              ),
              onPressed: () async {
                final apiService =
                    Provider.of<ApiService>(context, listen: false);

                bool success;
                if (game == null) {
                  success = await apiService.createGame(
                    nameController.text,
                    formatTime(drawTime),
                    startTime: formatTime(startTime),
                    endTime: formatTime(endTime),
                    color: selectedColor,
                    canEditDelete: canEditDelete,
                    deadlineTime: formatTime(deadlineTime),
                  );
                } else {
                  try {
                    await apiService.updateGame(game.id, {
                      'name': nameController.text,
                      'time': formatTime(drawTime),
                      'start_time': formatTime(startTime),
                      'end_time': formatTime(endTime),
                      'color': selectedColor,
                      'options_bg_color': selectedBgColor,
                      'can_edit_delete': canEditDelete,
                      'edit_delete_limit_time': formatTime(deadlineTime),
                    });
                    success = true;
                  } catch (e) {
                    success = false;
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e')),
                      );
                    }
                  }
                }

                if (success) {
                  Navigator.pop(context);
                  _loadGames();
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(GameModel game) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        title: const Text('Delete Game',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to delete ${game.name}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6))),
            onPressed: () async {
              final apiService =
                  Provider.of<ApiService>(context, listen: false);
              final success = await apiService.deleteGame(game.id);
              if (success) {
                if (mounted) {
                  Navigator.pop(context);
                  _loadGames();
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Game deleted')));
                }
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Manage Games',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: AppColors.primary,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _games.length,
              itemBuilder: (context, index) {
                final game = _games[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                  child: Row(
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: Color(
                              int.parse(game.color.replaceFirst('#', '0xFF'))),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.black12),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              game.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Colors.black87),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Draw: ${game.time} | Window: ${game.startTime} - ${game.endTime}',
                              style: TextStyle(
                                  fontSize: 11, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                      if (_canManageGames) ...[
                        IconButton(
                          icon: const Icon(Icons.edit,
                              color: AppColors.primary, size: 20),
                          onPressed: () => _showGameDialog(game),
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints:
                              const BoxConstraints(minWidth: 32, minHeight: 32),
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          icon: const Icon(Icons.delete,
                              color: Colors.red, size: 20),
                          onPressed: () => _confirmDelete(game),
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints:
                              const BoxConstraints(minWidth: 32, minHeight: 32),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: _canManageGames
          ? FloatingActionButton(
              onPressed: () => _showGameDialog(),
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6)),
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }
}
