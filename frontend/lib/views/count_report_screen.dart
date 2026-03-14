import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../models/game_model.dart';
import '../models/user_model.dart';
import '../utils/constants.dart';
import 'count_report_detail_screen.dart';

class CountReportScreen extends StatefulWidget {
  const CountReportScreen({super.key});

  @override
  State<CountReportScreen> createState() => _CountReportScreenState();
}

class _CountReportScreenState extends State<CountReportScreen> {
  DateTime _fromDate = DateTime.now();
  DateTime _toDate = DateTime.now();
  bool _agentRate = false;
  int? _selectedGameId;
  int? _selectedAgentId;
  UserModel? _currentUser;
  String? _userRole;
  final TextEditingController _numberController = TextEditingController();

  List<GameModel> _games = [];
  List<UserModel> _agents = [];
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
      final users = await apiService.getUsers(createdByMe: true);
      final profile = await apiService.getProfile();
      final prefs = await SharedPreferences.getInstance();
      final role = prefs.getString('role');

      setState(() {
        _games = games;
        _agents = users;
        _currentUser = profile;
        _userRole = role;

        // New logic for _agentRate based on role
        if (role == 'SUPER_ADMIN' ||
            role == 'ADMIN' ||
            role == 'AGENT' ||
            role == 'DEALER') {
          _agentRate = false; // Default to OFF for Self Net view
        }

        // If SUB_DEALER, default agent to SELF
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
      final data = await apiService.getCountReport(
        fromDate: DateFormat('yyyy-MM-dd').format(_fromDate),
        toDate: DateFormat('yyyy-MM-dd').format(_toDate),
        gameId: _selectedGameId,
        userId: _selectedAgentId,
        number:
            _numberController.text.isNotEmpty ? _numberController.text : null,
        adminRate: _agentRate,
      );
      setState(() => _isGenerating = false);
      if (mounted) {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => CountReportDetailScreen(
                    reportData: data, agentRate: _agentRate)));
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
        title: const Text('Filter Count Report',
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
                  _buildSectionTitle('DATE RANGE'),
                  const SizedBox(height: 12),
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
                  const SizedBox(height: 24),
                  _buildSectionTitle('GAME & AGENT'),
                  const SizedBox(height: 12),
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
                  if (_userRole != 'SUB_DEALER')
                    _buildDropdownTile<int?>(
                      label: 'SELECT AGENT',
                      value: _selectedAgentId,
                      items: [
                        const DropdownMenuItem(
                            value: null, child: Text('ANY AGENT')),
                        if (_currentUser != null)
                          DropdownMenuItem(
                              value: _currentUser!.id,
                              child: const Text('SELF')),
                        ..._agents
                            .where((a) =>
                                a.id != _currentUser?.id &&
                                ['SUB_DEALER', 'DEALER', 'AGENT']
                                    .contains(a.role))
                            .map((a) => DropdownMenuItem(
                                value: a.id, child: Text(a.username))),
                      ],
                      onChanged: (val) =>
                          setState(() => _selectedAgentId = val),
                      icon: Icons.person_search_rounded,
                    ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text('AGENT RATE',
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.bold)),
                      Switch(
                          value: _agentRate,
                          onChanged: (v) => setState(() => _agentRate = v),
                          activeColor: AppColors.primary),
                    ],
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
                              borderRadius: BorderRadius.circular(16)),
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

  Widget _buildSectionTitle(String title) {
    return Text(title,
        style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: Colors.grey[600],
            letterSpacing: 1));
  }

  Widget _buildDateTile(String label, DateTime date, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.black.withOpacity(0.05))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 10)),
          const SizedBox(height: 4),
          Text(DateFormat('dd/MM/yy').format(date),
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        ]),
      ),
    );
  }

  Widget _buildDropdownTile<T>(
      {required String label,
      required T value,
      required List<DropdownMenuItem<T>> items,
      required ValueChanged<T?> onChanged,
      required IconData icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black.withOpacity(0.05))),
      child: DropdownButtonHideUnderline(
        child: DropdownButtonFormField<T>(
            value: value,
            items: items,
            onChanged: onChanged,
            decoration: InputDecoration(
                labelText: label,
                prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
                border: InputBorder.none)),
      ),
    );
  }
}
