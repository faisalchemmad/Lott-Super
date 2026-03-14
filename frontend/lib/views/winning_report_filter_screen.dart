import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../models/game_model.dart';
import '../models/user_model.dart';
import '../utils/constants.dart';
import 'winning_report_screen.dart';

class WinningReportFilterScreen extends StatefulWidget {
  const WinningReportFilterScreen({super.key});

  @override
  State<WinningReportFilterScreen> createState() =>
      _WinningReportFilterScreenState();
}

class _WinningReportFilterScreenState extends State<WinningReportFilterScreen> {
  DateTime _fromDate = DateTime.now();
  DateTime _toDate = DateTime.now();
  int? _selectedGameId;
  int? _selectedAgentId;
  final TextEditingController _numberController = TextEditingController();

  List<GameModel> _games = [];
  List<UserModel> _agents = [];
  UserModel? _currentUser;
  String? _userRole;
  bool _agentRate = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFilters();
  }

  Future<void> _loadFilters() async {
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

        if (role == 'SUB_DEALER' && profile != null) {
          _selectedAgentId = profile.id;
        }

        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Filter Winning Report',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: AppColors.primary,
        centerTitle: true,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('Date Range'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildDatePicker(
                          'From Date',
                          _fromDate,
                          (d) => setState(() => _fromDate = d),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildDatePicker(
                          'To Date',
                          _toDate,
                          (d) => setState(() => _toDate = d),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Game & Agent'),
                  const SizedBox(height: 12),
                  _buildDropdown<int?>(
                    label: 'Select Game',
                    value: _selectedGameId,
                    items: [
                      const DropdownMenuItem(
                          value: null, child: Text('All Games')),
                      ..._games.map((g) =>
                          DropdownMenuItem(value: g.id, child: Text(g.name))),
                    ],
                    onChanged: (v) => setState(() => _selectedGameId = v),
                    icon: Icons.sports_esports_rounded,
                  ),
                  const SizedBox(height: 16),
                  if (_userRole != 'SUB_DEALER')
                    _buildDropdown<int?>(
                      label: 'Select Agent',
                      value: _selectedAgentId,
                      items: [
                        const DropdownMenuItem(
                            value: null, child: Text('All Agents')),
                        if (_currentUser != null)
                          DropdownMenuItem(
                              value: _currentUser!.id,
                              child: const Text('SELF')),
                        ..._agents
                            .where((a) =>
                                a.id != _currentUser?.id &&
                                ['SUB_DEALER', 'DEALER', 'AGENT']
                                    .contains(a.role))
                            .map((u) => DropdownMenuItem(
                                value: u.id, child: Text(u.username))),
                      ],
                      onChanged: (v) => setState(() => _selectedAgentId = v),
                      icon: Icons.person_search_rounded,
                    ),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Specific Number (Optional)'),
                  TextField(
                    controller: _numberController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'Search number...',
                      prefixIcon: const Icon(Icons.search_rounded,
                          color: AppColors.primary),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (_userRole != 'SUB_DEALER')
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border:
                            Border.all(color: Colors.black.withOpacity(0.05)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.percent_rounded,
                                  color: AppColors.primary, size: 20),
                              const SizedBox(width: 12),
                              const Text(
                                'AGENT RATE',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey),
                              ),
                            ],
                          ),
                          Switch(
                            value: _agentRate,
                            onChanged: (val) =>
                                setState(() => _agentRate = val),
                            activeColor: AppColors.primary,
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 48),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => WinningReportScreen(
                              initialFromDate: _fromDate,
                              initialToDate: _toDate,
                              initialGameId: _selectedGameId,
                              initialAgentId: _selectedAgentId,
                              initialAgentRate: _agentRate,
                              initialNumber: _numberController.text.isNotEmpty
                                  ? _numberController.text
                                  : null,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        elevation: 4,
                        shadowColor: AppColors.primary.withOpacity(0.4),
                      ),
                      child: const Text('GENERATE REPORT',
                          style: TextStyle(
                              fontWeight: FontWeight.w900, letterSpacing: 1.2)),
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

  Widget _buildDatePicker(
      String label, DateTime date, Function(DateTime) onPicked) {
    return InkWell(
      onTap: () async {
        final d = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime(2020),
          lastDate: DateTime(2101),
        );
        if (d != null) onPicked(d);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black.withOpacity(0.05)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(color: Colors.grey[500], fontSize: 10)),
            const SizedBox(height: 4),
            Text(DateFormat('dd/MM/yy').format(date),
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButtonFormField<T>(
          value: value,
          items: items,
          onChanged: onChanged,
          decoration: InputDecoration(
            labelText: label,
            labelStyle: TextStyle(color: Colors.grey[500], fontSize: 12),
            prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
            border: InputBorder.none,
          ),
        ),
      ),
    );
  }
}
