import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:screenshot/screenshot.dart';
import '../services/api_service.dart';
import '../models/game_model.dart';
import '../utils/constants.dart';
import 'publish_result_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ResultViewScreen extends StatefulWidget {
  const ResultViewScreen({super.key});

  @override
  State<ResultViewScreen> createState() => _ResultViewScreenState();
}

class _ResultViewScreenState extends State<ResultViewScreen> {
  DateTime _selectedDate = DateTime.now();
  int? _selectedGameId;
  List<GameModel> _games = [];
  List<dynamic> _results = [];
  bool _isLoading = true;
  bool _isLoadingGames = true;
  bool _isAdmin = false;
  final ScreenshotController _screenshotController = ScreenshotController();

  @override
  void initState() {
    super.initState();
    _checkAdmin();
    _fetchGames();
    _fetchResults();
  }

  Future<void> _checkAdmin() async {
    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString('role');
    setState(() {
      _isAdmin = role == 'ADMIN' || role == 'SUPER_ADMIN';
    });
  }

  Future<void> _fetchGames() async {
    final apiService = Provider.of<ApiService>(context, listen: false);
    final games = await apiService.getGames();
    setState(() {
      _games = games;
      if (_games.isNotEmpty && _selectedGameId == null) {
        _selectedGameId = _games[0].id; // Default to first game
      }
      _isLoadingGames = false;
    });
    _fetchResults();
  }

  Future<void> _fetchResults() async {
    setState(() => _isLoading = true);
    final apiService = Provider.of<ApiService>(context, listen: false);
    try {
      final results = await apiService.getGameResults(
        date: DateFormat('yyyy-MM-dd').format(_selectedDate),
        gameId: _selectedGameId,
      );
      setState(() {
        _results = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
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
      _fetchResults();
    }
  }

  void _shareAsText(Map<String, dynamic> res) {
    String formattedDate = DateFormat('dd-MM-yyyy').format(_selectedDate);
    String text = "LOTT SUPER - RESULT REPORT\n";
    text += "Date: $formattedDate\n";
    text += "Game: ${res['game_name']}\n\n";
    text += "1st Prize : ${res['winning_number']}\n";
    text += "2nd Prize : ${res['second_prize'] ?? '---'}\n";
    text += "3rd Prize : ${res['third_prize'] ?? '---'}\n";
    text += "4th Prize : ${res['fourth_prize'] ?? '---'}\n";
    text += "5th Prize : ${res['fifth_prize'] ?? '---'}\n\n";
    text += "COMPLIMENTS:\n${res['complimentary_numbers'] ?? 'None'}";

    Share.share(text);
  }

  Future<void> _shareAsImage() async {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Image sharing is currently disabled.')),
      );
    }
  }

  Future<void> _deleteResult(int resultId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Result?'),
        content: const Text(
            'Are you sure you want to delete this result? All winners for this game/date will be reset.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      final apiService = Provider.of<ApiService>(context, listen: false);
      try {
        final success = await apiService.deleteGameResult(resultId);
        if (success) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Result deleted successfully')),
            );
          }
          _fetchResults();
        } else {
          throw Exception('Failed to delete result');
        }
      } catch (e) {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Result Report',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: AppColors.primary,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (_results.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.share_rounded, color: Colors.white),
              onPressed: () => _shareAsText(_results[0]),
              tooltip: "Share as Text",
            ),
          if (_results.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.image_rounded, color: Colors.white),
              onPressed: _shareAsImage,
              tooltip: "Share as Image",
            ),
          if (_results.isNotEmpty && _isAdmin) ...[
            IconButton(
              icon: const Icon(Icons.edit_rounded, color: Colors.white),
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        PublishResultScreen(resultData: _results[0]),
                  ),
                );
                _fetchResults(); // Refresh after edit
              },
              tooltip: "Edit Result",
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded,
                  color: Colors.white),
              onPressed: () => _deleteResult(_results[0]['id']),
              tooltip: "Delete Result",
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          _buildFilterHeader(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _results.isEmpty
                    ? _buildNoResults()
                    : Screenshot(
                        controller: _screenshotController,
                        child: Container(
                          color: Colors.white,
                          child: ListView.builder(
                            padding: EdgeInsets.zero,
                            itemCount: _results.length,
                            itemBuilder: (context, index) =>
                                _buildStyledResultBlock(_results[index]),
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 3,
            child: Text(
              DateFormat('dd-MM-yyyy').format(_selectedDate),
              style: const TextStyle(
                color: Color(0xFFE67E22), // More orange-brown
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (_games.isNotEmpty)
            Expanded(
              flex: 3,
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int?>(
                  value: _selectedGameId,
                  isExpanded: true,
                  icon: const Icon(Icons.arrow_drop_down, color: Colors.blueAccent),
                  items: _games
                      .map((g) =>
                          DropdownMenuItem(value: g.id, child: Text(g.name, overflow: TextOverflow.ellipsis)))
                      .toList(),
                  onChanged: (val) {
                    setState(() => _selectedGameId = val);
                    _fetchResults();
                  },
                  style: const TextStyle(
                      color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black12),
                borderRadius: BorderRadius.circular(4),
              ),
              child: InkWell(
                onTap: _selectDate,
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: Text(
                    'CHANGE DATE',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResults() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_busy_rounded, size: 60, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text('No results found',
              style: TextStyle(color: Colors.grey, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildStyledResultBlock(Map<String, dynamic> res) {
    return Column(
      children: [
        _buildPrizeRow("1", res['winning_number'], const Color(0xFF1D8740)),
        _buildPrizeRow("2", res['second_prize'], const Color(0xFF0E799F)),
        _buildPrizeRow("3", res['third_prize'], const Color(0xFFDE8D0C)),
        _buildPrizeRow("4", res['fourth_prize'], const Color(0xFF6E378E)),
        _buildPrizeRow("5", res['fifth_prize'], const Color(0xFF104282)),
        const SizedBox(height: 24),
        const Text(
          "COMPLIMENTS",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w400,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        const Divider(height: 1, thickness: 1),
        _buildComplimentsGrid(res['complimentary_numbers']),
        if (_isAdmin)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              PublishResultScreen(resultData: res),
                        ),
                      );
                      _fetchResults();
                    },
                    icon: const Icon(Icons.edit_rounded, size: 18),
                    label: const Text('EDIT RESULT DETAILS',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: AppColors.primary.withOpacity(0.05),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextButton.icon(
                    onPressed: () => _deleteResult(res['id']),
                    icon: const Icon(Icons.delete_outline_rounded, size: 18),
                    label: const Text('DELETE RESULT',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: Colors.red.withOpacity(0.05),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 48),
      ],
    );
  }

  Widget _buildPrizeRow(String label, String? value, Color bgColor) {
    return Container(
      width: double.infinity,
      color: bgColor,
      padding: const EdgeInsets.symmetric(vertical: 6),
      margin: const EdgeInsets.only(bottom: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 40,
            child: Text(
              label,
              style: const TextStyle(fontSize: 24, color: Colors.white70),
              textAlign: TextAlign.center,
            ),
          ),
          const Text(
            ":",
            style: TextStyle(fontSize: 24, color: Colors.white70),
          ),
          const SizedBox(width: 16),
          Text(
            value ?? "---",
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComplimentsGrid(String? complimentsStr) {
    if (complimentsStr == null || complimentsStr.isEmpty)
      return const SizedBox();

    List<String> nums = complimentsStr
        .split(RegExp(r'[,\s\n]+'))
        .where((e) => e.isNotEmpty)
        .toList();

    int columns = 3;
    int rows = (nums.length / columns).ceil();

    return Table(
      border: const TableBorder(
        verticalInside: BorderSide(color: Colors.black12, width: 1),
      ),
      children: List.generate(rows, (rowIndex) {
        return TableRow(
          children: List.generate(columns, (colIndex) {
            // Distribute numbers in columns like the image
            int index = rowIndex + (colIndex * rows);
            String text = index < nums.length ? nums[index] : "";
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
              child: Center(
                child: Text(
                  text,
                  style: const TextStyle(
                    fontSize: 20,
                    color: Colors.black87,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            );
          }),
        );
      }),
    );
  }
}
