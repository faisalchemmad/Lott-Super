import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../models/game_model.dart';
import '../models/user_model.dart';
import '../utils/constants.dart';
import 'forward_purchase_report_screen.dart';

class GameTypeOption {
  final String key;
  final String label;
  final String? state;
  final String? type;
  final bool isHeader;

  const GameTypeOption({
    required this.key,
    required this.label,
    this.state,
    this.type,
    this.isHeader = false,
  });
}

class ForwardReportFilterScreen extends StatefulWidget {
  const ForwardReportFilterScreen({super.key});

  @override
  State<ForwardReportFilterScreen> createState() =>
      _ForwardReportFilterScreenState();
}

class _ForwardReportFilterScreenState extends State<ForwardReportFilterScreen> {
  DateTime _fromDate = DateTime.now();
  DateTime _toDate = DateTime.now();
  int? _selectedGameId;
  int? _selectedAdminId;
  String _selectedState = 'ALL';
  String _selectedGameType = 'ALL';
  String? _userRole;

  List<GameModel> _games = [];
  List<UserModel> _admins = [];
  bool _isLoadingFilters = true;
  bool _isGenerating = false;
  final TextEditingController _numberController = TextEditingController();

  List<GameTypeOption> get _availableGameTypeOptions {
    if (_selectedState == 'KL') {
      return const [
        GameTypeOption(key: 'ALL', label: 'ALL KL TYPES', state: 'KL', type: null),
        GameTypeOption(key: 'KL:SUPER', label: 'SUPER', state: 'KL', type: 'SUPER'),
        GameTypeOption(key: 'KL:BOX', label: 'BOX', state: 'KL', type: 'BOX'),
        GameTypeOption(key: 'KL:A', label: 'A', state: 'KL', type: 'A'),
        GameTypeOption(key: 'KL:B', label: 'B', state: 'KL', type: 'B'),
        GameTypeOption(key: 'KL:C', label: 'C', state: 'KL', type: 'C'),
        GameTypeOption(key: 'KL:AB', label: 'AB', state: 'KL', type: 'AB'),
        GameTypeOption(key: 'KL:BC', label: 'BC', state: 'KL', type: 'BC'),
        GameTypeOption(key: 'KL:AC', label: 'AC', state: 'KL', type: 'AC'),
      ];
    } else if (_selectedState == 'TN') {
      return const [
        GameTypeOption(key: 'ALL', label: 'ALL TN TYPES', state: 'TN', type: null),
        GameTypeOption(key: 'TN:A', label: 'A', state: 'TN', type: 'A'),
        GameTypeOption(key: 'TN:B', label: 'B', state: 'TN', type: 'B'),
        GameTypeOption(key: 'TN:C', label: 'C', state: 'TN', type: 'C'),
        GameTypeOption(key: 'TN:AB', label: 'AB', state: 'TN', type: 'AB'),
        GameTypeOption(key: 'TN:BC', label: 'BC', state: 'TN', type: 'BC'),
        GameTypeOption(key: 'TN:AC', label: 'AC', state: 'TN', type: 'AC'),
        GameTypeOption(key: 'TN:3D-10', label: '3D-10', state: 'TN', type: '3D-10'),
        GameTypeOption(key: 'TN:3D-25', label: '3D-25', state: 'TN', type: '3D-25'),
        GameTypeOption(key: 'TN:3D-30', label: '3D-30', state: 'TN', type: '3D-30'),
        GameTypeOption(key: 'TN:3D-60', label: '3D-60', state: 'TN', type: '3D-60'),
        GameTypeOption(key: 'TN:4D-110', label: '4D-110', state: 'TN', type: '4D-110'),
        GameTypeOption(key: 'TN:4D-55', label: '4D-55', state: 'TN', type: '4D-55'),
        GameTypeOption(key: 'TN:4D-20', label: '4D-20', state: 'TN', type: '4D-20'),
      ];
    } else {
      return const [
        GameTypeOption(key: 'ALL', label: 'ALL TYPES', state: 'ALL', type: null),
        GameTypeOption(key: 'HEADER_KL', label: '─── KERALA (KL) ───', isHeader: true),
        GameTypeOption(key: 'KL:ALL', label: 'ALL KL', state: 'KL', type: null),
        GameTypeOption(key: 'KL:SUPER', label: 'SUPER', state: 'KL', type: 'SUPER'),
        GameTypeOption(key: 'KL:BOX', label: 'BOX', state: 'KL', type: 'BOX'),
        GameTypeOption(key: 'KL:A', label: 'A', state: 'KL', type: 'A'),
        GameTypeOption(key: 'KL:B', label: 'B', state: 'KL', type: 'B'),
        GameTypeOption(key: 'KL:C', label: 'C', state: 'KL', type: 'C'),
        GameTypeOption(key: 'KL:AB', label: 'AB', state: 'KL', type: 'AB'),
        GameTypeOption(key: 'KL:BC', label: 'BC', state: 'KL', type: 'BC'),
        GameTypeOption(key: 'KL:AC', label: 'AC', state: 'KL', type: 'AC'),
        GameTypeOption(key: 'HEADER_TN', label: '─── TAMIL NADU (TN) ───', isHeader: true),
        GameTypeOption(key: 'TN:ALL', label: 'ALL TN', state: 'TN', type: null),
        GameTypeOption(key: 'TN:A', label: 'A', state: 'TN', type: 'A'),
        GameTypeOption(key: 'TN:B', label: 'B', state: 'TN', type: 'B'),
        GameTypeOption(key: 'TN:C', label: 'C', state: 'TN', type: 'C'),
        GameTypeOption(key: 'TN:AB', label: 'AB', state: 'TN', type: 'AB'),
        GameTypeOption(key: 'TN:BC', label: 'BC', state: 'TN', type: 'BC'),
        GameTypeOption(key: 'TN:AC', label: 'AC', state: 'TN', type: 'AC'),
        GameTypeOption(key: 'TN:3D-10', label: '3D-10', state: 'TN', type: '3D-10'),
        GameTypeOption(key: 'TN:3D-25', label: '3D-25', state: 'TN', type: '3D-25'),
        GameTypeOption(key: 'TN:3D-30', label: '3D-30', state: 'TN', type: '3D-30'),
        GameTypeOption(key: 'TN:3D-60', label: '3D-60', state: 'TN', type: '3D-60'),
        GameTypeOption(key: 'TN:4D-110', label: '4D-110', state: 'TN', type: '4D-110'),
        GameTypeOption(key: 'TN:4D-55', label: '4D-55', state: 'TN', type: '4D-55'),
        GameTypeOption(key: 'TN:4D-20', label: '4D-20', state: 'TN', type: '4D-20'),
      ];
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchFilterData();
  }

  @override
  void dispose() {
    _numberController.dispose();
    super.dispose();
  }

  Future<void> _fetchFilterData() async {
    setState(() => _isLoadingFilters = true);
    final apiService = Provider.of<ApiService>(context, listen: false);
    try {
      final games = await apiService.getGames();
      final users = await apiService.getUsers();
      final prefs = await SharedPreferences.getInstance();
      final role = prefs.getString('role');

      setState(() {
        _games = games;
        _admins = users.where((u) => u.role == 'ADMIN' && u.canForward).toList();
        _userRole = role;
        _isLoadingFilters = false;
      });
    } catch (e) {
      setState(() => _isLoadingFilters = false);
    }
  }

  Future<void> _selectDate(BuildContext context, bool isFrom) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isFrom ? _fromDate : _toDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        if (isFrom) {
          _fromDate = picked;
        } else {
          _toDate = picked;
        }
      });
    }
  }

  Future<void> _generateReport() async {
    setState(() => _isGenerating = true);
    final apiService = Provider.of<ApiService>(context, listen: false);

    String reqState = _selectedState;
    String? reqType;

    if (_selectedGameType.contains(':')) {
      final parts = _selectedGameType.split(':');
      reqState = parts[0];
      reqType = parts[1] == 'ALL' ? null : parts[1];
    } else if (_selectedGameType != 'ALL') {
      reqType = _selectedGameType;
    }

    try {
      final data = await apiService.getForwardPurchaseReport(
        fromDate: DateFormat('yyyy-MM-dd').format(_fromDate),
        toDate: DateFormat('yyyy-MM-dd').format(_toDate),
        gameId: _selectedGameId,
        userId: _selectedAdminId,
        number:
            _numberController.text.trim().isNotEmpty ? _numberController.text.trim() : null,
        betType: reqType,
        state: reqState,
      );

      setState(() => _isGenerating = false);

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ForwardPurchaseReportScreen(
              initialData: data,
              fromDate: _fromDate,
              toDate: _toDate,
              gameId: _selectedGameId,
              adminId: _selectedAdminId,
              searchNumber: _numberController.text.trim().isNotEmpty
                  ? _numberController.text.trim()
                  : null,
              selectedOptionKey: _selectedGameType,
              state: _selectedState,
            ),
          ),
        );
      }
    } catch (e) {
      setState(() => _isGenerating = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Filter Forward Report',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: AppColors.primary,
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoadingFilters
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 8, bottom: 20),
                    padding:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStateRadio('ALL'),
                        _buildStateRadio('KL'),
                        _buildStateRadio('TN'),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                          child: _buildDateTile('FROM', _fromDate, () async {
                        await _selectDate(context, true);
                      })),
                      const SizedBox(width: 12),
                      Expanded(
                          child: _buildDateTile('TO', _toDate, () async {
                        await _selectDate(context, false);
                      })),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildDropdownTile<int?>(
                    label: 'SELECT GAME',
                    value: _selectedGameId,
                    items: [
                      const DropdownMenuItem(
                          value: null, child: Text('ALL GAMES')),
                      ..._games.map((g) =>
                          DropdownMenuItem(value: g.id, child: Text(g.name))),
                    ],
                    onChanged: (val) => setState(() => _selectedGameId = val),
                    icon: Icons.games_rounded,
                  ),
                  const SizedBox(height: 16),
                  _buildDropdownTile<String>(
                    label: 'SELECT GAME TYPE',
                    value: _selectedGameType,
                    items: _availableGameTypeOptions.map((opt) {
                      if (opt.isHeader) {
                        return DropdownMenuItem<String>(
                          value: opt.key,
                          enabled: false,
                          child: Text(
                            opt.label,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: AppColors.primary,
                              letterSpacing: 0.5,
                            ),
                          ),
                        );
                      }
                      return DropdownMenuItem<String>(
                        value: opt.key,
                        child: Text(
                          opt.label,
                          style: TextStyle(
                            fontWeight: opt.key == 'ALL'
                                ? FontWeight.bold
                                : FontWeight.w600,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null && !val.startsWith('HEADER_')) {
                        setState(() => _selectedGameType = val);
                      }
                    },
                    icon: Icons.category_rounded,
                  ),
                  const SizedBox(height: 16),
                  if (_userRole == 'SUPER_ADMIN') ...[
                    _buildDropdownTile<int?>(
                      label: 'SELECT ADMIN',
                      value: _selectedAdminId,
                      items: [
                        const DropdownMenuItem(
                            value: null, child: Text('ALL FORWARDED ADMINS')),
                        ..._admins.map((a) => DropdownMenuItem(
                            value: a.id, child: Text(a.username))),
                      ],
                      onChanged: (val) =>
                          setState(() => _selectedAdminId = val),
                      icon: Icons.person_search_rounded,
                    ),
                    const SizedBox(height: 16),
                  ],
                  _buildTextFieldTile(
                    label: 'SEARCH NUMBER',
                    controller: _numberController,
                    hint: 'Enter 1, 2, 3 or 4 digits',
                    icon: Icons.numbers_rounded,
                  ),
                  const SizedBox(height: 48),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _isGenerating ? null : _generateReport,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6)),
                          elevation: 4),
                      child: _isGenerating
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('SHOW REPORT',
                              style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildStateRadio(String state) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Radio<String>(
          value: state,
          groupValue: _selectedState,
          activeColor: AppColors.primary,
          onChanged: (val) {
            setState(() {
              _selectedState = val!;
              _selectedGameType = 'ALL';
            });
          },
        ),
        Text(
          state,
          style: TextStyle(
            fontSize: 15,
            fontWeight:
                _selectedState == state ? FontWeight.bold : FontWeight.w500,
            color: _selectedState == state ? AppColors.primary : Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildDateTile(String label, DateTime date, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
        ),
        child: Text(
          DateFormat('dd/MM/yyyy').format(date),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ),
    );
  }

  Widget _buildDropdownTile<T>(
      {required String label,
      required T value,
      required List<DropdownMenuItem<T>> items,
      required ValueChanged<T?> onChanged,
      required IconData icon}) {
    return DropdownButtonFormField<T>(
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
        filled: true,
        fillColor: Colors.white,
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      value: value,
      items: items,
      onChanged: onChanged,
    );
  }

  Widget _buildTextFieldTile({
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
        filled: true,
        fillColor: Colors.white,
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
      ),
    );
  }
}
