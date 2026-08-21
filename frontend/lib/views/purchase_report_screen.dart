import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../models/game_model.dart';
import '../models/user_model.dart';
import '../utils/constants.dart';
import 'purchase_report_detail_screen.dart';

class PurchaseReportScreen extends StatefulWidget {
  const PurchaseReportScreen({super.key});

  @override
  State<PurchaseReportScreen> createState() => _PurchaseReportScreenState();
}

class _PurchaseReportScreenState extends State<PurchaseReportScreen> {
  DateTime _fromDate = DateTime.now();
  DateTime _toDate = DateTime.now();
  int? _selectedGameId;
  int? _selectedAgentId;
  String? _selectedType;
  UserModel? _currentUser;
  String? _userRole;

  List<GameModel> _games = [];
  List<UserModel> _agents = [];
  bool _isLoadingFilters = true;
  bool _isGenerating = false;

  final List<String> _types = [
    'A',
    'B',
    'C',
    'AB',
    'BC',
    'AC',
    'SUPER',
    'BOX',
    'SUPER+BOX'
  ];

  @override
  void initState() {
    super.initState();
    _fetchFilters();
  }

  Future<void> _fetchFilters() async {
    final apiService = Provider.of<ApiService>(context, listen: false);
    try {
      final games = await apiService.getGames();
      final users = await apiService.getUsers();
      final profile = await apiService.getProfile();
      final prefs = await SharedPreferences.getInstance();
      final role = prefs.getString('role');

      setState(() {
        _games = games;
        _agents = users;
        _currentUser = profile;
        _userRole = role;

        if (role == 'SUB_DEALER' && profile != null) {
          _selectedAgentId = profile.id;
        }

        _isLoadingFilters = false;
      });
    } catch (e) {
      setState(() => _isLoadingFilters = false);
    }
  }

  Future<void> _selectDate(bool isFrom) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isFrom ? _fromDate : _toDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        if (isFrom)
          _fromDate = picked;
        else
          _toDate = picked;
      });
    }
  }

  Future<void> _generateReport() async {
    setState(() => _isGenerating = true);
    final apiService = Provider.of<ApiService>(context, listen: false);
    try {
      final data = await apiService.getPurchaseReport(
        fromDate: DateFormat('yyyy-MM-dd').format(_fromDate),
        toDate: DateFormat('yyyy-MM-dd').format(_toDate),
        gameId: _selectedGameId,
      );

      String? gameName = _selectedGameId != null
          ? _games.firstWhere((g) => g.id == _selectedGameId).name
          : null;

      setState(() => _isGenerating = false);

      if (mounted) {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => PurchaseReportDetailScreen(
                      reportData: data,
                      fromDate: _fromDate,
                      toDate: _toDate,
                      gameName: gameName,
                      typeName: _selectedType,
                    )));
      }
    } catch (e) {
      setState(() => _isGenerating = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Filter Purchase Report',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: AppColors.primary,
        centerTitle: true,
        elevation: 0,
      ),
      body: _isLoadingFilters
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  
                  Row(
                    children: [
                      Expanded(
                          child: _buildDateTile(
                              'FROM', _fromDate, () => _selectDate(true))),
                      const SizedBox(width: 12),
                      Expanded(
                          child: _buildDateTile(
                              'TO', _toDate, () => _selectDate(false))),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
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
                  _buildDropdownTile<String?>(
                    label: 'SELECT TYPE',
                    value: _selectedType,
                    items: [
                      const DropdownMenuItem(
                          value: null, child: Text('ALL TYPES')),
                      ..._types.map(
                          (t) => DropdownMenuItem(value: t, child: Text(t))),
                    ],
                    onChanged: (val) => setState(() => _selectedType = val),
                    icon: Icons.category_rounded,
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

  

  Widget _buildDateTile(String label, DateTime date, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
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
          // ignore: undefined_function
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
      value: value,
      items: items,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
        filled: true,
        fillColor: Colors.white,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
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
