import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../models/game_model.dart';
import '../models/user_model.dart';
import '../utils/constants.dart';
import 'daily_report_detail_screen.dart';

class DailyReportScreen extends StatefulWidget {
  const DailyReportScreen({super.key});

  @override
  State<DailyReportScreen> createState() => _DailyReportScreenState();
}

class _DailyReportScreenState extends State<DailyReportScreen> {
  String _selectedState = 'ALL';
  DateTime _fromDate = DateTime.now();
  DateTime _toDate = DateTime.now();
  int? _selectedAgentId;
  int? _selectedGameId;
  bool _dayDetail = true;
  bool _gameDetail = false;
  bool _userWise = true;
  bool _agentRate = false;
  UserModel? _currentUser;
  String? _userRole;

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
      final data = await apiService.getDailyReport(
        state: _selectedState,
        fromDate: DateFormat('yyyy-MM-dd').format(_fromDate),
        toDate: DateFormat('yyyy-MM-dd').format(_toDate),
        userId: _selectedAgentId,
        gameIds: _selectedGameId != null ? [_selectedGameId!] : null,
        dayDetail: _dayDetail,
        gameDetail: _gameDetail,
        userDetail: _userWise,
        agentRate: _agentRate,
      );

      setState(() => _isGenerating = false);

      if (mounted) {
        String agentName = 'ANY AGENT';
        if (_selectedAgentId != null) {
          if (_currentUser != null && _selectedAgentId == _currentUser!.id) {
            agentName = 'SELF (${_currentUser!.username})';
          } else {
            final agent = _agents.firstWhere((a) => a.id == _selectedAgentId,
                orElse: () => UserModel(id: -1, username: 'Unknown', role: ''));
            if (agent.id != -1) agentName = agent.username;
          }
        }

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DailyReportDetailScreen(
              initialReportData: data,
              fromDate: _fromDate,
              toDate: _toDate,
              agentId: _selectedAgentId,
              selectedGameId: _selectedGameId,
              dayDetail: _dayDetail,
              gameDetail: _gameDetail,
              userWise: _userWise,
              agentRate: _agentRate,
              agentName: agentName,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Filter Daily Report',
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
                  Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 24),
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
                        ..._agents.where((a) => a.id != _currentUser?.id).map(
                            (a) => DropdownMenuItem(
                                value: a.id, child: Text(a.username))),
                      ],
                      onChanged: (val) =>
                          setState(() => _selectedAgentId = val),
                      icon: Icons.person_search_rounded,
                    ),
                  const SizedBox(height: 8),
                  _buildToggle('DAY DETAIL', _dayDetail,
                      (v) => setState(() => _dayDetail = v)),
                  _buildToggle('GAME DETAIL', _gameDetail,
                      (v) => setState(() => _gameDetail = v)),
                  _buildToggle('AGENT RATE', _agentRate,
                      (v) => setState(() => _agentRate = v)),
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
                        elevation: 4,
                      ),
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

  Widget _buildToggle(String label, bool value, ValueChanged<bool> onChanged) {
    return Row(
      children: [
        Text(label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        Switch(
            value: value, onChanged: onChanged, activeColor: AppColors.primary),
      ],
    );
  }
}
