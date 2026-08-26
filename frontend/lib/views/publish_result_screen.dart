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
  String _resultType = 'KL';
  List<GameModel> _games = [];
  bool _isLoadingGames = true;
  bool _isSubmitting = false;
  DateTime _selectedDate = DateTime.now();

  final TextEditingController _p1Controller = TextEditingController();
  final TextEditingController _p2Controller = TextEditingController();
  final TextEditingController _p3Controller = TextEditingController();
  final TextEditingController _p4Controller = TextEditingController();
  final TextEditingController _p5Controller = TextEditingController();
  final List<TextEditingController> _compControllers =
      List.generate(30, (_) => TextEditingController());

  final FocusNode _p1Focus = FocusNode();
  final FocusNode _p2Focus = FocusNode();
  final FocusNode _p3Focus = FocusNode();
  final FocusNode _p4Focus = FocusNode();
  final FocusNode _p5Focus = FocusNode();
  final List<FocusNode> _compFocusNodes = List.generate(30, (_) => FocusNode());

  @override
  void initState() {
    super.initState();
    if (widget.resultData != null) {
      _selectedGameId = widget.resultData!['game'];
      String winNum = widget.resultData!['winning_number'] ?? '';
      if (winNum.length == 4) {
        _resultType = 'TN';
      }
      _selectedDate = DateTime.parse(widget.resultData!['date']);
      _p1Controller.text = widget.resultData!['winning_number'] ?? '';
      _p2Controller.text = widget.resultData!['second_prize'] ?? '';
      _p3Controller.text = widget.resultData!['third_prize'] ?? '';
      _p4Controller.text = widget.resultData!['fourth_prize'] ?? '';
      _p5Controller.text = widget.resultData!['fifth_prize'] ?? '';

      String compStr = widget.resultData!['complimentary_numbers'] ?? '';
      List<String> compParts = compStr
          .split(RegExp(r'[,\s\n]+'))
          .where((e) => e.trim().isNotEmpty)
          .toList();
      for (int i = 0; i < 30 && i < compParts.length; i++) {
        _compControllers[i].text = compParts[i].trim();
      }
    }
    _fetchGames();
  }

  @override
  void dispose() {
    _p1Controller.dispose();
    _p2Controller.dispose();
    _p3Controller.dispose();
    _p4Controller.dispose();
    _p5Controller.dispose();
    for (var c in _compControllers) {
      c.dispose();
    }
    _p1Focus.dispose();
    _p2Focus.dispose();
    _p3Focus.dispose();
    _p4Focus.dispose();
    _p5Focus.dispose();
    for (var f in _compFocusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  Future<void> _fetchGames() async {
    final apiService = Provider.of<ApiService>(context, listen: false);
    final games = await apiService.getGames();
    setState(() {
      _games = games;
      _isLoadingGames = false;
    });
  }

  void _handleClearAll() {
    setState(() {
      _p1Controller.clear();
      _p2Controller.clear();
      _p3Controller.clear();
      _p4Controller.clear();
      _p5Controller.clear();
      for (var c in _compControllers) {
        c.clear();
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('All fields cleared')),
    );
  }

  void _handlePasteAll() async {
    ClipboardData? data = await Clipboard.getData('text/plain');
    if (data != null && data.text != null) {
      String text = data.text!.trim();
      List<String> parts =
          text.split(RegExp(r'[,\s\n]+')).where((e) => e.length == 3).toList();

      if (parts.isNotEmpty) {
        setState(() {
          if (parts.isNotEmpty) _p1Controller.text = parts[0];
          if (parts.length >= 2) _p2Controller.text = parts[1];
          if (parts.length >= 3) _p3Controller.text = parts[2];
          if (parts.length >= 4) _p4Controller.text = parts[3];
          if (parts.length >= 5) _p5Controller.text = parts[4];

          List<String> compParts = parts.skip(5).toList();
          for (int i = 0; i < 30; i++) {
            _compControllers[i].text = i < compParts.length ? compParts[i] : '';
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
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      String compNumbers = _compControllers
          .map((c) => c.text.trim())
          .where((t) => t.isNotEmpty)
          .join(', ');

      final response = await apiService.publishResult({
        'game': _selectedGameId,
        'date': DateFormat('yyyy-MM-dd').format(_selectedDate),
        'winning_number': _p1Controller.text,
        'second_prize': _p2Controller.text,
        'third_prize': _p3Controller.text,
        'fourth_prize': _p4Controller.text,
        'fifth_prize': _p5Controller.text,
        'complimentary_numbers': compNumbers,
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
            icon: const Icon(Icons.delete_sweep_outlined, color: Colors.white),
            tooltip: 'Clear All',
            onPressed: _handleClearAll,
          ),
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
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Column(
                children: [
                  _buildSelectionHeader(),
                  const SizedBox(height: 10),
                  _buildCombinedResultsSection(),
                  const SizedBox(height: 10),
                  _buildSubmitButton(),
                  const SizedBox(height: 10),
                ],
              ),
            ),
    );
  }

  Widget _buildSelectionHeader() {
    return Container(
      padding: const EdgeInsets.all(10),
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
        children: [
          Row(
            children: [
              Expanded(flex: 5, child: _buildGameDropdown()),
              const SizedBox(width: 8),
              Expanded(flex: 3, child: _buildDigitToggle()),
            ],
          ),
          const SizedBox(height: 8),
          _buildDateSelector(),
        ],
      ),
    );
  }

  Widget _buildDigitToggle() {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: 'TYPE',
        labelStyle: const TextStyle(
            color: AppColors.primary,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.3),
        floatingLabelBehavior: FloatingLabelBehavior.always,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildDigitOption('KL'),
          _buildDigitOption('TN'),
        ],
      ),
    );
  }

  Widget _buildDigitOption(String type) {
    bool isSelected = _resultType == type;
    return GestureDetector(
      onTap: () {
        setState(() {
          _resultType = type;
          _p1Controller.clear();
          _p2Controller.clear();
          _p3Controller.clear();
          _p4Controller.clear();
          _p5Controller.clear();
          for (var c in _compControllers) {
            c.clear();
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
        ),
        alignment: Alignment.center,
        child: Text(
          type,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[700],
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildGameDropdown() {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: 'SELECT GAME',
        labelStyle: const TextStyle(
            color: AppColors.primary,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.3),
        floatingLabelBehavior: FloatingLabelBehavior.always,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: _selectedGameId,
          hint: const Text('Select Game',
              style: TextStyle(color: Colors.grey, fontSize: 13)),
          isExpanded: true,
          isDense: true,
          dropdownColor: Colors.white,
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              color: Colors.grey, size: 18),
          style: const TextStyle(
              color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 13),
          items: _games
              .map((g) => DropdownMenuItem(value: g.id, child: Text(g.name)))
              .toList(),
          onChanged: (val) => setState(() => _selectedGameId = val),
        ),
      ),
    );
  }

  Widget _buildDateSelector() {
    return InkWell(
      onTap: _selectDate,
      borderRadius: BorderRadius.circular(6),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'SELECT DATE',
          labelStyle: const TextStyle(
              color: AppColors.primary,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.3),
          floatingLabelBehavior: FloatingLabelBehavior.always,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          suffixIcon: const Icon(Icons.calendar_today_rounded,
              color: AppColors.primary, size: 15),
          suffixIconConstraints:
              const BoxConstraints(minWidth: 30, minHeight: 20),
        ),
        child: Text(
          DateFormat('dd MMMM yyyy').format(_selectedDate),
          style: const TextStyle(
              color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 13),
        ),
      ),
    );
  }

  Widget _buildCombinedResultsSection() {
    return Container(
      padding: const EdgeInsets.all(12),
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
              const Icon(Icons.military_tech_rounded,
                  color: AppColors.primary, size: 18),
              const SizedBox(width: 6),
              const Text(
                'PRIZE NUMBERS',
                style: TextStyle(
                  color: Color(0xFF2C3E50),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // 1st and 2nd Prize Row
          Row(
            children: [
              Expanded(
                flex: 3,
                child: _buildPrizeBox(
                  '1ST PRIZE',
                  _p1Controller,
                  _p1Focus,
                  AppColors.primary,
                  true,
                  _resultType == 'TN' ? 4 : 3,
                  (val) {
                    if (_resultType == 'TN') {
                      _p2Controller.text =
                          val.length >= 3 ? val.substring(val.length - 3) : val;
                      _p3Controller.text =
                          val.length >= 2 ? val.substring(val.length - 2) : val;
                      _p4Controller.text =
                          val.length >= 1 ? val.substring(val.length - 1) : val;
                    }
                  },
                  _p2Focus,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: _buildPrizeBox(
                  '2ND PRIZE',
                  _p2Controller,
                  _p2Focus,
                  Colors.grey.shade700,
                  false,
                  3,
                  null,
                  _p3Focus,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // 3rd, 4th, 5th Prize Row
          if (_resultType == 'KL') ...[
            Row(
              children: [
                Expanded(
                  child: _buildPrizeBox(
                    '3RD PRIZE',
                    _p3Controller,
                    _p3Focus,
                    Colors.grey.shade700,
                    false,
                    3,
                    null,
                    _p4Focus,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _buildPrizeBox(
                    '4TH PRIZE',
                    _p4Controller,
                    _p4Focus,
                    Colors.grey.shade700,
                    false,
                    3,
                    null,
                    _p5Focus,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _buildPrizeBox(
                    '5TH PRIZE',
                    _p5Controller,
                    _p5Focus,
                    Colors.grey.shade700,
                    false,
                    3,
                    null,
                    _compFocusNodes.isNotEmpty ? _compFocusNodes[0] : null,
                  ),
                ),
              ],
            ),
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: _buildPrizeBox(
                    '3RD PRIZE',
                    _p3Controller,
                    _p3Focus,
                    Colors.grey.shade700,
                    false,
                    2,
                    null,
                    _p4Focus,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildPrizeBox(
                    '4TH PRIZE',
                    _p4Controller,
                    _p4Focus,
                    Colors.grey.shade700,
                    false,
                    1,
                    null,
                    null,
                  ),
                ),
              ],
            ),
          ],

          // Complimentary 30 nos inside the same border
          if (_resultType == 'KL') ...[
            const SizedBox(height: 10),
            const Divider(height: 1, color: Colors.black12),
            const SizedBox(height: 8),
            const Text(
              'COMPLIMENTARY (30 NOS)',
              style: TextStyle(
                color: Color(0xFF2C3E50),
                fontWeight: FontWeight.bold,
                fontSize: 11,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 6),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 6,
                crossAxisSpacing: 4,
                mainAxisSpacing: 4,
                childAspectRatio: 1.8,
              ),
              itemCount: 30,
              itemBuilder: (context, index) {
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  alignment: Alignment.center,
                  child: TextField(
                    controller: _compControllers[index],
                    focusNode: _compFocusNodes[index],
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    maxLength: 3,
                    onChanged: (val) {
                      if (val.length >= 3) {
                        if (index < 29) {
                          _compFocusNodes[index + 1].requestFocus();
                        } else {
                          _compFocusNodes[index].unfocus();
                        }
                      }
                    },
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                    decoration: InputDecoration(
                      counterText: "",
                      hintText: "${index + 1}",
                      hintStyle: TextStyle(
                        color: Colors.grey.shade300,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPrizeBox(String label, TextEditingController controller,
      FocusNode focusNode, Color activeColor,
      [bool isFirst = false,
      int maxLength = 3,
      void Function(String)? onChanged,
      FocusNode? nextFocusNode]) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      onChanged: (val) {
        if (onChanged != null) onChanged(val);
        if (val.length >= maxLength) {
          if (nextFocusNode != null) {
            nextFocusNode.requestFocus();
          } else {
            focusNode.unfocus();
          }
        }
      },
      maxLength: maxLength,
      keyboardType: TextInputType.number,
      textAlign: TextAlign.center,
      style: TextStyle(
        color: isFirst ? AppColors.primary : Colors.black87,
        fontSize: isFirst ? 16 : 14,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.5,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: isFirst ? AppColors.primary : Colors.grey.shade700,
          fontSize: 9,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.3,
        ),
        floatingLabelBehavior: FloatingLabelBehavior.always,
        counterText: "",
        hintText: "000",
        hintStyle: TextStyle(color: Colors.grey.shade300, fontSize: 13),
        filled: true,
        fillColor: isFirst ? AppColors.primary.withOpacity(0.04) : Colors.white,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(
              color: isFirst
                  ? AppColors.primary.withOpacity(0.5)
                  : Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(
              color: isFirst
                  ? AppColors.primary.withOpacity(0.5)
                  : Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(
              color: isFirst ? AppColors.primary : Colors.blue, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 42,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitResult,
        style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 3,
            shadowColor: AppColors.primary.withOpacity(0.3),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(6))),
        child: _isSubmitting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2))
            : Text(
                widget.resultData != null ? 'UPDATE RESULT' : 'PUBLISH RESULT',
                style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    letterSpacing: 1)),
      ),
    );
  }
}
