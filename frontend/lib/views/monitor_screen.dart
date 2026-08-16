import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../models/game_model.dart';
import '../utils/constants.dart';

class MonitorScreen extends StatefulWidget {
  const MonitorScreen({super.key});

  @override
  State<MonitorScreen> createState() => _MonitorScreenState();
}

class _MonitorScreenState extends State<MonitorScreen> {
  DateTime _selectedDate = DateTime.now();
  List<GameModel> _games = [];
  GameModel? _selectedGame;
  String _digits = 'ALL';
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _monitorData = [];
  bool _isLoading = false;
  bool _sortCustomer = false;
  bool _hideZeroCount = false;

  @override
  void initState() {
    super.initState();
    _loadGames();
    _fetchData();
  }

  Future<void> _loadGames() async {
    final apiService = Provider.of<ApiService>(context, listen: false);
    final games = await apiService.getGames();
    setState(() {
      _games = games;
    });
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    final apiService = Provider.of<ApiService>(context, listen: false);
    try {
      final data = await apiService.getMonitorData(
        date: DateFormat('yyyy-MM-dd').format(_selectedDate),
        gameId: _selectedGame?.id,
        number:
            _searchController.text.isNotEmpty ? _searchController.text : null,
        digits: _digits,
      );
      setState(() {
        _monitorData = data;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  void _clearAllFilters() {
    setState(() {
      _selectedDate = DateTime.now();
      _selectedGame = null;
      _digits = 'ALL';
      _searchController.clear();
      _sortCustomer = false;
      _hideZeroCount = false;
    });
    _fetchData();
  }

  Future<void> _clearEntry(dynamic entry) async {
    final apiService = Provider.of<ApiService>(context, listen: false);
    try {
      final success = await apiService.clearMonitorEntry({
        'user_id': entry['user_id'],
        'game_id': entry['game_id'],
        'no': entry['no'],
        'type': entry['type'],
        'date': DateFormat('yyyy-MM-dd').format(_selectedDate),
        'amount': 1, // Default to increment by 1
      });
      if (success) {
        _fetchData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to clear: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDesktop = defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.macOS;

    List<dynamic> displayData = List.from(_monitorData);
    if (_hideZeroCount) {
      displayData = displayData.where((e) => e['cnt'] > 0).toList();
    }
    if (_sortCustomer) {
      displayData
          .sort((a, b) => a['name'].toString().compareTo(b['name'].toString()));
    }

    Widget content = Column(
      children: [
        if (!isDesktop) _buildFilters(),
        _buildSearchAndOptions(isDesktop),
        _buildTableHeader(isDesktop),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : displayData.isEmpty
                  ? const Center(child: Text('No monitoring data found'))
                  : ListView.builder(
                      itemCount: displayData.length,
                      itemBuilder: (context, index) {
                        return _buildDataRow(displayData[index], isDesktop);
                      },
                    ),
        ),
      ],
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Monitor',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        centerTitle: !isDesktop,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              child: const Text('Set Monitor'),
            ),
          ),
        ],
      ),
      body: isDesktop
          ? Row(
              children: [
                SizedBox(
                  width: 300,
                  child: SingleChildScrollView(child: _buildFilters()),
                ),
                const VerticalDivider(width: 1),
                Expanded(child: content),
              ],
            )
          : content,
    );
  }

  Widget _buildSearchAndOptions(bool isDesktop) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                flex: isDesktop ? 4 : 2,
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) => _fetchData(),
                  decoration: InputDecoration(
                    hintText: 'Search Number...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (!isDesktop) ...[
                Expanded(
                  child: ElevatedButton(
                    onPressed: _fetchData,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                    ),
                    child: const Text('Search'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _clearAllFilters,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                    ),
                    child: const Text('Clear All'),
                  ),
                ),
              ] else ...[
                ElevatedButton.icon(
                  onPressed: _fetchData,
                  icon: const Icon(Icons.search),
                  label: const Text('Search'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _clearAllFilters,
                  icon: const Icon(Icons.clear_all),
                  label: const Text('Clear All'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Checkbox(
                value: _sortCustomer,
                onChanged: (v) => setState(() => _sortCustomer = v!),
              ),
              const Text('Sort Customer'),
              const SizedBox(width: 24),
              Checkbox(
                value: _hideZeroCount,
                onChanged: (v) => setState(() => _hideZeroCount = v!),
              ),
              const Text('Hide Zero Count'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader(bool isDesktop) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      color: const Color(0xFFFBC02D),
      child: Row(
        children: [
          Expanded(
              flex: isDesktop ? 4 : 2,
              child: const Text('Name', style: TextStyle(fontWeight: FontWeight.bold))),
          Expanded(
              flex: isDesktop ? 6 : 3,
              child: const Text('Ticket',
                  style: TextStyle(fontWeight: FontWeight.bold))),
          const Expanded(
              flex: 1,
              child: Text('No', style: TextStyle(fontWeight: FontWeight.bold))),
          const Expanded(
              flex: 1,
              child: Text('Cnt', style: TextStyle(fontWeight: FontWeight.bold))),
          const Expanded(
              flex: 1,
              child: Text('Clr', style: TextStyle(fontWeight: FontWeight.bold))),
          const Expanded(
              flex: 1,
              child: Text('Lim', style: TextStyle(fontWeight: FontWeight.bold))),
          Expanded(
              flex: isDesktop ? 1 : 2,
              child: const Text('Action',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  Widget _buildDataRow(dynamic entry, bool isDesktop) {
    bool overLimit = entry['cnt'] > entry['lim'];
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
      ),
      child: Row(
        children: [
          Expanded(
              flex: isDesktop ? 4 : 2,
              child: Text(entry['name'] ?? '',
                  style: const TextStyle(fontWeight: FontWeight.w600))),
          Expanded(
              flex: isDesktop ? 6 : 3,
              child: Text(entry['ticket'] ?? '',
                  style: TextStyle(fontSize: 12, color: Colors.grey[700]))),
          Expanded(
              flex: 1,
              child: Text(entry['no'] ?? '',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.blue))),
          Expanded(
              flex: 1,
              child: Text('${entry['cnt']}',
                  style: const TextStyle(fontWeight: FontWeight.w500))),
          Expanded(
              flex: 1,
              child: Text('${entry['clr']}',
                  style: const TextStyle(fontWeight: FontWeight.w500))),
          Expanded(
              flex: 1,
              child: Text('${entry['lim']}',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: overLimit ? Colors.red : Colors.green))),
          Expanded(
            flex: isDesktop ? 1 : 2,
            child: Align(
              alignment: Alignment.center,
              child: SizedBox(
                height: 35,
                child: ElevatedButton(
                  onPressed: () => _clearEntry(entry),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF263238),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4)),
                  ),
                  child: const Text('CLR', style: TextStyle(fontSize: 11)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget columnField({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Transform.translate(
          offset: const Offset(10, 8),
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(label,
                style: const TextStyle(fontSize: 12, color: Colors.deepPurple)),
          ),
        ),
        child,
      ],
    );
  }
}
