import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../models/game_model.dart';
import '../models/user_model.dart';
import '../utils/constants.dart';
import 'forward_net_report_detail_screen.dart';

class ForwardNetReportScreen extends StatefulWidget {
  const ForwardNetReportScreen({super.key});

  @override
  State<ForwardNetReportScreen> createState() => _ForwardNetReportScreenState();
}

class _ForwardNetReportScreenState extends State<ForwardNetReportScreen> {
  String _selectedState = 'ALL';
  DateTime _fromDate = DateTime.now();
  DateTime _toDate = DateTime.now();
  int? _selectedGameId;
  int? _selectedAdminId;
  String? _userRole;

  List<GameModel> _games = [];
  List<UserModel> _admins = [];
  bool _isLoadingFilters = true;
  bool _isGenerating = false;

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
      final prefs = await SharedPreferences.getInstance();
      final role = prefs.getString('role');

      setState(() {
        _games = games;
        _admins =
            users.where((u) => u.role == 'ADMIN' && u.canForward).toList();
        _userRole = role;
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

    try {
      final data = await apiService.getForwardNetReport(
        fromDate: DateFormat('yyyy-MM-dd').format(_fromDate),
        toDate: DateFormat('yyyy-MM-dd').format(_toDate),
        gameId: _selectedGameId,
        userId: _selectedAdminId,
        state: _selectedState,
      );

      setState(() => _isGenerating = false);

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ForwardNetReportDetailScreen(
              initialReportData: data,
              fromDate: _fromDate,
              toDate: _toDate,
              gameId: _selectedGameId,
              adminId: _selectedAdminId,
              state: _selectedState,
            ),
          ),
        );
      }
    } catch (e) {
      setState(() => _isGenerating = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to load report: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Filter Forward Net Report',
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
                  // State selector
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

                  // Dates
                  Row(
                    children: [
                      Expanded(
                          child: _buildDateTile('FROM', _fromDate, () async {
                        await _selectDate(true);
                      })),
                      const SizedBox(width: 12),
                      Expanded(
                          child: _buildDateTile('TO', _toDate, () async {
                        await _selectDate(false);
                      })),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Game Dropdown
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

                  // Admin Dropdown (if Super Admin)
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

                  const SizedBox(height: 48),

                  // Generate Button
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
}
