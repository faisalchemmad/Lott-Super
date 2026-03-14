import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../models/game_model.dart';
import '../utils/constants.dart';
import 'package:flutter/services.dart';

class PublishResultScreen extends StatefulWidget {
  final Map<String, dynamic>? resultData;
  const PublishResultScreen({super.key, this.resultData});

  @override
  State<PublishResultScreen> createState() => _PublishResultScreenState();
}

class _PublishResultScreenState extends State<PublishResultScreen> {
  int? _selectedGameId;
  List<GameModel> _games = [];
  bool _isLoadingGames = true;
  bool _isSubmitting = false;
  DateTime _selectedDate = DateTime.now();

  final TextEditingController _p1Controller = TextEditingController();
  final TextEditingController _p2Controller = TextEditingController();
  final TextEditingController _p3Controller = TextEditingController();
  final TextEditingController _p4Controller = TextEditingController();
  final TextEditingController _p5Controller = TextEditingController();
  final TextEditingController _compController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.resultData != null) {
      _selectedGameId = widget.resultData!['game'];
      _selectedDate = DateTime.parse(widget.resultData!['date']);
      _p1Controller.text = widget.resultData!['winning_number'] ?? '';
      _p2Controller.text = widget.resultData!['second_prize'] ?? '';
      _p3Controller.text = widget.resultData!['third_prize'] ?? '';
      _p4Controller.text = widget.resultData!['fourth_prize'] ?? '';
      _p5Controller.text = widget.resultData!['fifth_prize'] ?? '';
      _compController.text = widget.resultData!['complimentary_numbers'] ?? '';
    }
    _fetchGames();
  }

  Future<void> _fetchGames() async {
    final apiService = Provider.of<ApiService>(context, listen: false);
    final games = await apiService.getGames();
    setState(() {
      _games = games;
      _isLoadingGames = false;
    });
  }

  void _handlePaste() async {
    ClipboardData? data = await Clipboard.getData('text/plain');
    if (data != null && data.text != null) {
      String text = data.text!.trim();
      // Split by comma, space or newline and take first 30 numbers of 3 digits
      List<String> parts =
          text.split(RegExp(r'[,\s\n]+')).where((e) => e.length == 3).toList();

      if (parts.length >= 30) {
        _compController.text = parts.take(30).join(', ');
      } else {
        _compController.text = parts.join(', ');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Found only ${parts.length} 3-digit numbers.')));
      }
    }
  }

  void _handlePasteAll() async {
    ClipboardData? data = await Clipboard.getData('text/plain');
    if (data != null && data.text != null) {
      String text = data.text!.trim();
      List<String> parts =
          text.split(RegExp(r'[,\s\n]+')).where((e) => e.length == 3).toList();

      if (parts.isNotEmpty) {
        setState(() {
          if (parts.length >= 1) _p1Controller.text = parts[0];
          if (parts.length >= 2) _p2Controller.text = parts[1];
          if (parts.length >= 3) _p3Controller.text = parts[2];
          if (parts.length >= 4) _p4Controller.text = parts[3];
          if (parts.length >= 5) _p5Controller.text = parts[4];

          if (parts.length > 5) {
            _compController.text = parts.skip(5).take(30).join(', ');
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                'Auto-filled ${parts.length > 35 ? 35 : parts.length} numbers.')));
      }
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _submitResult() async {
    if (_selectedGameId == null || _p1Controller.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please select game and enter 1st prize')));
      return;
    }

    setState(() => _isSubmitting = true);
    // Note: We need to implement createGameResult in ApiService
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      // Constructing payload manually for now or use Map
      final response = await apiService.publishResult({
        'game': _selectedGameId,
        'date': DateFormat('yyyy-MM-dd').format(_selectedDate),
        'winning_number': _p1Controller.text,
        'second_prize': _p2Controller.text,
        'third_prize': _p3Controller.text,
        'fourth_prize': _p4Controller.text,
        'fifth_prize': _p5Controller.text,
        'complimentary_numbers': _compController.text,
      });

      if (response && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Result published successfully')));
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isEditing = widget.resultData != null;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Result' : 'Publish Result',
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: AppColors.primary,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy_all_rounded, color: Colors.white),
            tooltip: 'Paste All (35 Nos)',
            onPressed: _handlePasteAll,
          ),
        ],
      ),
      body: _isLoadingGames
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildSelectionHeader(),
                  const SizedBox(height: 24),
                  _buildPrizeFields(),
                  const SizedBox(height: 24),
                  _buildCompField(),
                  const SizedBox(height: 32),
                  _buildSubmitButton(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildSelectionHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildGameDropdown(),
          const SizedBox(height: 16),
          _buildDateSelector(),
        ],
      ),
    );
  }

  Widget _buildGameDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('SELECT GAME',
            style: TextStyle(
                color: Colors.grey[600],
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.black.withOpacity(0.05))),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: _selectedGameId,
              hint: const Text('Select Game',
                  style: TextStyle(color: Colors.grey, fontSize: 14)),
              isExpanded: true,
              dropdownColor: Colors.white,
              icon: const Icon(Icons.keyboard_arrow_down_rounded,
                  color: Colors.grey),
              style: const TextStyle(
                  color: Colors.black87, fontWeight: FontWeight.bold),
              items: _games
                  .map(
                      (g) => DropdownMenuItem(value: g.id, child: Text(g.name)))
                  .toList(),
              onChanged: (val) => setState(() => _selectedGameId = val),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('SELECT DATE',
            style: TextStyle(
                color: Colors.grey[600],
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5)),
        const SizedBox(height: 8),
        InkWell(
          onTap: _selectDate,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.black.withOpacity(0.05))),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_rounded,
                    color: AppColors.primary, size: 18),
                const SizedBox(width: 12),
                Text(
                  DateFormat('dd MMMM yyyy').format(_selectedDate),
                  style: const TextStyle(
                      color: Colors.black87, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Text('CHANGE',
                    style: TextStyle(
                        color: AppColors.primary.withOpacity(0.6),
                        fontSize: 11,
                        fontWeight: FontWeight.w900)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPrizeFields() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.military_tech_rounded,
                    color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              const Text('PRIZE NUMBERS',
                  style: TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                      letterSpacing: 0.5)),
            ],
          ),
          const SizedBox(height: 24),
          _buildPrizeInput('1st Prize', _p1Controller, AppColors.primary, true),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(color: Colors.black12),
          ),
          _buildPrizeInput('2nd Prize', _p2Controller, Colors.grey[700]!),
          _buildPrizeInput('3rd Prize', _p3Controller, Colors.grey[700]!),
          _buildPrizeInput('4th Prize', _p4Controller, Colors.grey[700]!),
          _buildPrizeInput('5th Prize', _p5Controller, Colors.grey[700]!),
        ],
      ),
    );
  }

  Widget _buildPrizeInput(
      String label, TextEditingController controller, Color color,
      [bool isFirst = false]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
              width: 90,
              child: Text(label,
                  style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5))),
          const SizedBox(width: 16),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isFirst ? color.withOpacity(0.05) : AppColors.background,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: isFirst
                        ? color.withOpacity(0.2)
                        : Colors.black.withOpacity(0.03)),
              ),
              child: TextField(
                controller: controller,
                style: TextStyle(
                    color: Colors.black87,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2),
                maxLength: 3,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  counterText: "",
                  hintText: "000",
                  hintStyle: TextStyle(color: Colors.grey[300]),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('COMPLIMENTARY (30 NOS)',
                  style: TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                      letterSpacing: 0.5)),
              InkWell(
                onTap: _handlePaste,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.paste_rounded,
                          color: Colors.blue, size: 14),
                      const SizedBox(width: 6),
                      const Text('PASTE',
                          style: TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.w900,
                              fontSize: 10)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.black.withOpacity(0.03)),
            ),
            child: TextField(
              controller: _compController,
              maxLines: 4,
              style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2),
              decoration: InputDecoration(
                hintText: "Paste comma separated 3-digit numbers...",
                hintStyle: TextStyle(
                    color: Colors.grey[400], fontWeight: FontWeight.normal),
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitResult,
        style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 8,
            shadowColor: AppColors.primary.withOpacity(0.4),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18))),
        child: _isSubmitting
            ? const CircularProgressIndicator(color: Colors.white)
            : Text(
                widget.resultData != null ? 'UPDATE RESULT' : 'PUBLISH RESULT',
                style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    letterSpacing: 1)),
      ),
    );
  }
}
