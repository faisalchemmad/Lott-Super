import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../models/user_model.dart';
import '../models/game_model.dart';
import '../utils/constants.dart';

class ManageUserGameTimingsScreen extends StatefulWidget {
  final UserModel user;
  const ManageUserGameTimingsScreen({super.key, required this.user});

  @override
  State<ManageUserGameTimingsScreen> createState() =>
      _ManageUserGameTimingsScreenState();
}

class _ManageUserGameTimingsScreenState
    extends State<ManageUserGameTimingsScreen> {
  List<GameModel> _games = [];
  Map<int, dynamic> _overrides = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    final apiService = Provider.of<ApiService>(context, listen: false);
    try {
      final games = await apiService.getGames();
      final overridesList = await apiService.getUserGameTimings(widget.user.id);

      Map<int, dynamic> overrideMap = {};
      for (var o in overridesList) {
        overrideMap[o['game']] = o;
      }

      if (mounted) {
        setState(() {
          _games = games;
          _overrides = overrideMap;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickTime(int gameId, bool isStart) async {
    final existing = _overrides[gameId];
    TimeOfDay initial;

    if (existing != null) {
      final timeStr = isStart ? existing['start_time'] : existing['end_time'];
      final parts = timeStr.split(':');
      initial =
          TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    } else {
      initial = TimeOfDay.now();
    }

    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked != null) {
      TimeOfDay start = isStart
          ? picked
          : (existing != null
              ? _parseTime(existing['start_time'])
              : const TimeOfDay(hour: 0, minute: 0));
      TimeOfDay end = !isStart
          ? picked
          : (existing != null
              ? _parseTime(existing['end_time'])
              : const TimeOfDay(hour: 23, minute: 59));

      _saveTiming(gameId, start, end);
    }
  }

  TimeOfDay _parseTime(String timeStr) {
    final parts = timeStr.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  void _saveTiming(int gameId, TimeOfDay start, TimeOfDay end) async {
    final apiService = Provider.of<ApiService>(context, listen: false);

    String startStr =
        "${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}:00";
    String endStr =
        "${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}:00";

    Map<String, dynamic> data = {
      'user': widget.user.id,
      'game': gameId,
      'start_time': startStr,
      'end_time': endStr,
    };

    try {
      bool success;
      if (_overrides.containsKey(gameId)) {
        success = await apiService.updateUserGameTiming(
            _overrides[gameId]['id'], data);
      } else {
        success = await apiService.createUserGameTiming(data);
      }

      if (success) {
        _fetchData();
        if (mounted)
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('Timing updated')));
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _deleteTiming(int id) async {
    final apiService = Provider.of<ApiService>(context, listen: false);
    try {
      if (await apiService.deleteUserGameTiming(id)) {
        _fetchData();
        if (mounted)
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('Override removed')));
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('${widget.user.username} Game Windows'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _games.length,
              itemBuilder: (context, index) {
                final game = _games[index];
                final override = _overrides[game.id];

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(game.name,
                                style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary)),
                            if (override != null)
                              IconButton(
                                icon: const Icon(Icons.delete_outline,
                                    color: Colors.red),
                                onPressed: () => _deleteTiming(override['id']),
                              ),
                          ],
                        ),
                        const Divider(),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _buildTimeTile(
                                label: 'Start Time',
                                time: override != null
                                    ? override['start_time']
                                    : game.startTime,
                                isOverride: override != null,
                                onTap: () => _pickTime(game.id, true),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildTimeTile(
                                label: 'End Time',
                                time: override != null
                                    ? override['end_time']
                                    : game.endTime,
                                isOverride: override != null,
                                onTap: () => _pickTime(game.id, false),
                              ),
                            ),
                          ],
                        ),
                        if (override == null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text('Using global game settings',
                                style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey[500],
                                    fontStyle: FontStyle.italic)),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildTimeTile(
      {required String label,
      required String time,
      required bool isOverride,
      required VoidCallback onTap}) {
    // Format HH:mm:ss to HH:mm AM/PM
    String displayTime = time;
    try {
      final parts = time.split(':');
      final tod =
          TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      final h = tod.hourOfPeriod == 0 ? 12 : tod.hourOfPeriod;
      final m = tod.minute.toString().padLeft(2, '0');
      final p = tod.period == DayPeriod.am ? 'AM' : 'PM';
      displayTime = "$h:$m $p";
    } catch (_) {}

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isOverride
              ? AppColors.primary.withOpacity(0.05)
              : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: isOverride
                  ? AppColors.primary.withOpacity(0.3)
                  : Colors.transparent),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            const SizedBox(height: 4),
            Text(displayTime,
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isOverride ? AppColors.primary : Colors.black87)),
          ],
        ),
      ),
    );
  }
}
