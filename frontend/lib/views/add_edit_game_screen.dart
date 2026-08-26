import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../models/game_model.dart';
import '../utils/constants.dart';

class AddEditGameScreen extends StatefulWidget {
  final GameModel? game;
  const AddEditGameScreen({super.key, this.game});

  @override
  State<AddEditGameScreen> createState() => _AddEditGameScreenState();
}

class _AddEditGameScreenState extends State<AddEditGameScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;

  TimeOfDay _drawTime = const TimeOfDay(hour: 0, minute: 0);
  TimeOfDay _startTime = const TimeOfDay(hour: 0, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 23, minute: 59);
  TimeOfDay _deadlineTime = const TimeOfDay(hour: 23, minute: 59);
  bool _canEditDelete = true;
  String _selectedColor = '#2C3E50';
  String _selectedBgColor = '#FFFFFF';
  bool _isSaving = false;

  final List<String> _colors = [
    '#9C212C', // Crimson Maroon
    '#C0392B', // Alizarin Red
    '#D32F2F', // Deep Red
    '#E64A19', // Deep Orange
    '#D35400', // Rust Orange
    '#E67E22', // Carrot Orange
    '#F57C00', // Bright Orange
    '#F39C12', // Golden Orange
    '#F9A825', // Amber Gold
    '#FBC02D', // Bright Yellow
    '#2E7D32', // Forest Green
    '#27AE60', // Emerald Green
    '#388E3C', // Kelly Green
    '#16A085', // Green Sea
    '#00897B', // Teal
    '#0097A7', // Dark Cyan
    '#00ACC1', // Cyan
    '#1976D2', // Blue
    '#1565C0', // Royal Blue
    '#2980B9', // Belize Blue
    '#0D47A1', // Deep Navy
    '#2C3E50', // Midnight Navy
    '#34495E', // Wet Asphalt
    '#6A1B9A', // Deep Purple
    '#8E44AD', // Wisteria Violet
    '#7B1FA2', // Purple
    '#C2185B', // Dark Pink
    '#E91E63', // Hot Pink
    '#880E4F', // Wine Burgundy
    '#4E342E', // Espresso Brown
    '#5D4037', // Saddle Brown
    '#455A64', // Blue Grey Dark
    '#37474F', // Slate Grey
    '#212121', // Charcoal Black
  ];

  final List<String> _bgColors = [
    '#FFFFFF', // Pure White
    '#FAFAFA', // Snow White
    '#F5F5F5', // Light Grey
    '#EEEEEE', // Soft Platinum
    '#ECEFF1', // Blue Grey Tint
    '#E3F2FD', // Soft Sky Blue
    '#E1F5FE', // Light Ice Blue
    '#E0F7FA', // Soft Cyan
    '#E0F2F1', // Soft Teal
    '#E8F5E9', // Soft Mint Green
    '#F1F8E9', // Soft Lime
    '#F9FBE7', // Soft Pale Yellow
    '#FFFDE7', // Soft Cream Yellow
    '#FFF8E1', // Soft Amber Ivory
    '#FFF3E0', // Soft Peach Orange
    '#FBE9E7', // Soft Coral
    '#FFEBEE', // Soft Rose Blush
    '#FCE4EC', // Soft Pink
    '#F3E5F5', // Soft Lavender
    '#EDE7F6', // Soft Deep Purple
    '#EFEBE9', // Soft Warm Beige
    '#F0F4C3', // Soft Honeydew
    '#D7CCC8', // Soft Sandstone
    '#CFD8DC', // Soft Slate
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.game?.name ?? '');

    if (widget.game != null) {
      _canEditDelete = widget.game!.canEditDelete;
      _selectedColor = widget.game!.color;
      _selectedBgColor = widget.game!.optionsBgColor;

      if (!_colors.contains(_selectedColor)) {
        _colors.insert(0, _selectedColor);
      }
      if (!_bgColors.contains(_selectedBgColor)) {
        _bgColors.insert(0, _selectedBgColor);
      }

      try {
        final dParts = widget.game!.time.split(':');
        _drawTime =
            TimeOfDay(hour: int.parse(dParts[0]), minute: int.parse(dParts[1]));

        final sParts = widget.game!.startTime.split(':');
        _startTime =
            TimeOfDay(hour: int.parse(sParts[0]), minute: int.parse(sParts[1]));

        final eParts = widget.game!.endTime.split(':');
        _endTime =
            TimeOfDay(hour: int.parse(eParts[0]), minute: int.parse(eParts[1]));

        final dlParts = widget.game!.editDeleteLimitTime.split(':');
        _deadlineTime = TimeOfDay(
            hour: int.parse(dlParts[0]), minute: int.parse(dlParts[1]));
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  String _formatTime(TimeOfDay t) =>
      "${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:00";

  Future<void> _saveGame() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final apiService = Provider.of<ApiService>(context, listen: false);

    bool success = false;
    if (widget.game == null) {
      success = await apiService.createGame(
        _nameController.text.trim(),
        _formatTime(_drawTime),
        startTime: _formatTime(_startTime),
        endTime: _formatTime(_endTime),
        color: _selectedColor,
        canEditDelete: _canEditDelete,
        deadlineTime: _formatTime(_deadlineTime),
      );
    } else {
      try {
        await apiService.updateGame(widget.game!.id, {
          'name': _nameController.text.trim(),
          'time': _formatTime(_drawTime),
          'start_time': _formatTime(_startTime),
          'end_time': _formatTime(_endTime),
          'color': _selectedColor,
          'options_bg_color': _selectedBgColor,
          'can_edit_delete': _canEditDelete,
          'edit_delete_limit_time': _formatTime(_deadlineTime),
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

    setState(() => _isSaving = false);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(widget.game == null
                ? 'Game created successfully'
                : 'Game updated successfully')),
      );
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isEditing = widget.game != null;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Game' : 'Add New Game',
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: AppColors.primary,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCard(
                title: 'GAME INFO',
                icon: Icons.sports_esports_rounded,
                children: [
                  TextFormField(
                    controller: _nameController,
                    validator: (val) => val == null || val.trim().isEmpty
                        ? 'Please enter game name'
                        : null,
                    decoration: InputDecoration(
                      labelText: 'Game Name (e.g. 1PM DRAW)',
                      labelStyle: const TextStyle(fontSize: 12),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text('Betting Screen Color',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _colors
                        .map((c) => GestureDetector(
                              onTap: () => setState(() => _selectedColor = c),
                              child: Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: Color(
                                      int.parse(c.replaceFirst('#', '0xFF'))),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: _selectedColor == c
                                        ? Colors.black
                                        : Colors.grey.shade300,
                                    width: _selectedColor == c ? 2.5 : 1,
                                  ),
                                ),
                                child: _selectedColor == c
                                    ? const Icon(Icons.check,
                                        color: Colors.white, size: 20)
                                    : null,
                              ),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 14),
                  const Text('Options Background Color',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _bgColors
                        .map((c) => GestureDetector(
                              onTap: () => setState(() => _selectedBgColor = c),
                              child: Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: Color(
                                      int.parse(c.replaceFirst('#', '0xFF'))),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: _selectedBgColor == c
                                        ? Colors.black
                                        : Colors.grey.shade300,
                                    width: _selectedBgColor == c ? 2.5 : 1,
                                  ),
                                ),
                                child: _selectedBgColor == c
                                    ? const Icon(Icons.check,
                                        color: Colors.black, size: 20)
                                    : null,
                              ),
                            ))
                        .toList(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildCard(
                title: 'TIMINGS',
                icon: Icons.access_time_rounded,
                children: [
                  _buildTimeSelector(
                    label: 'Draw Time',
                    time: _drawTime,
                    onPicked: (t) => setState(() => _drawTime = t),
                  ),
                  const SizedBox(height: 8),
                  _buildTimeSelector(
                    label: 'Betting Start Time',
                    time: _startTime,
                    onPicked: (t) => setState(() => _startTime = t),
                  ),
                  const SizedBox(height: 8),
                  _buildTimeSelector(
                    label: 'Betting End Time',
                    time: _endTime,
                    onPicked: (t) => setState(() => _endTime = t),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildCard(
                title: 'EDIT / DELETE PERMISSION',
                icon: Icons.security_rounded,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: SwitchListTile(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6)),
                      title: const Text('Allow Edit/Delete',
                          style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.bold)),
                      subtitle: const Text(
                          'Enable invoice edits/cancellations for this game',
                          style: TextStyle(fontSize: 11, color: Colors.grey)),
                      value: _canEditDelete,
                      activeColor: AppColors.primary,
                      onChanged: (val) => setState(() => _canEditDelete = val),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildTimeSelector(
                    label: 'Edit/Delete Deadline',
                    time: _deadlineTime,
                    icon: Icons.timer_outlined,
                    onPicked: (t) => setState(() => _deadlineTime = t),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveGame,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6)),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : Text(
                          isEditing ? 'UPDATE GAME' : 'CREATE GAME',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              letterSpacing: 0.5),
                        ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard(
      {required String title,
      required IconData icon,
      required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 16),
              const SizedBox(width: 6),
              Text(
                title,
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF2C3E50),
                    letterSpacing: 0.5),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTimeSelector({
    required String label,
    required TimeOfDay time,
    required void Function(TimeOfDay) onPicked,
    IconData icon = Icons.access_time_rounded,
  }) {
    return InkWell(
      onTap: () async {
        final picked =
            await showTimePicker(context: context, initialTime: time);
        if (picked != null) onPicked(picked);
      },
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text(time.format(context),
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text('CHANGE',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary)),
            ),
          ],
        ),
      ),
    );
  }
}
