import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:screenshot/screenshot.dart';
import 'package:path_provider/path_provider.dart';
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

class _ResultViewScreenState extends State<ResultViewScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _selectedDate = DateTime.now();
  int? _selectedGameId;
  List<GameModel> _games = [];
  List<dynamic> _results = [];
  bool _isLoading = true;
  bool _isAdmin = false;
  final ScreenshotController _screenshotController = ScreenshotController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
    _checkAdmin();
    _fetchGames();
    _fetchResults();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
      if (_games.isNotEmpty &&
          (_selectedGameId == null ||
              !_games.any((g) => g.id == _selectedGameId))) {
        _selectedGameId = _games.first.id;
      }
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

  List<dynamic> get _klResults => _results.where((res) {
        final state = (res['state'] ?? '').toString().toUpperCase();
        if (state == 'KL') return true;
        if (state == 'TN') return false;
        final compStr = (res['complimentary_numbers'] ?? '').toString().trim();
        final fifthPrize = (res['fifth_prize'] ?? '').toString().trim();
        final gameName = (res['game_name'] ?? '').toString().toUpperCase();
        if (compStr.isNotEmpty || fifthPrize.isNotEmpty || gameName.startsWith('KL')) {
          return true;
        }
        final winNum = (res['winning_number'] ?? '').toString().trim();
        return winNum.length != 4;
      }).toList();

  List<dynamic> get _tnResults => _results.where((res) {
        final state = (res['state'] ?? '').toString().toUpperCase();
        if (state == 'TN') return true;
        if (state == 'KL') return false;
        final compStr = (res['complimentary_numbers'] ?? '').toString().trim();
        final fifthPrize = (res['fifth_prize'] ?? '').toString().trim();
        final gameName = (res['game_name'] ?? '').toString().toUpperCase();
        if (compStr.isNotEmpty || fifthPrize.isNotEmpty || gameName.startsWith('KL')) {
          return false;
        }
        final winNum = (res['winning_number'] ?? '').toString().trim();
        return winNum.length == 4;
      }).toList();

  List<dynamic> get _currentTabResults =>
      _tabController.index == 0 ? _klResults : _tnResults;

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

  void _shareAsText(Map<String, dynamic> res, {required bool isTN}) {
    String formattedDate = DateFormat('dd-MM-yyyy').format(_selectedDate);
    String stateTag = isTN ? "TN" : "KL";
    String text = "Mango - $stateTag RESULT REPORT\n";
    text += "Date: $formattedDate\n";
    text += "Game: ${res['game_name']}\n\n";

    if (isTN) {
      if (res['winning_number'] != null &&
          res['winning_number'].toString().trim().isNotEmpty) {
        text += "${res['winning_number']}\n";
      }
      if (res['second_prize'] != null &&
          res['second_prize'].toString().trim().isNotEmpty) {
        text += "${res['second_prize']}\n";
      }
      if (res['third_prize'] != null &&
          res['third_prize'].toString().trim().isNotEmpty) {
        text += "${res['third_prize']}\n";
      }
      if (res['fourth_prize'] != null &&
          res['fourth_prize'].toString().trim().isNotEmpty) {
        text += "${res['fourth_prize']}\n";
      }
    } else {
      if (res['winning_number'] != null &&
          res['winning_number'].toString().trim().isNotEmpty) {
        text += "${res['winning_number']}\n";
      }
      if (res['second_prize'] != null &&
          res['second_prize'].toString().trim().isNotEmpty) {
        text += "${res['second_prize']}\n";
      }
      if (res['third_prize'] != null &&
          res['third_prize'].toString().trim().isNotEmpty) {
        text += "${res['third_prize']}\n";
      }
      if (res['fourth_prize'] != null &&
          res['fourth_prize'].toString().trim().isNotEmpty) {
        text += "${res['fourth_prize']}\n";
      }
      if (res['fifth_prize'] != null &&
          res['fifth_prize'].toString().trim().isNotEmpty) {
        text += "${res['fifth_prize']}\n";
      }

      if (res['complimentary_numbers'] != null &&
          res['complimentary_numbers'].toString().trim().isNotEmpty) {
        List<String> compList = res['complimentary_numbers']
            .toString()
            .split(RegExp(r'[,\s\n]+'))
            .where((e) => e.trim().isNotEmpty)
            .map((e) => e.trim())
            .toList();

        if (compList.isNotEmpty) {
          text += "\n";
          List<String> compLines = [];
          for (int i = 0; i < compList.length; i += 6) {
            int end = (i + 6 < compList.length) ? i + 6 : compList.length;
            compLines.add(compList.sublist(i, end).join(' '));
          }
          text += compLines.join('\n');
        }
      }
    }

    Share.share(text.trim());
  }

  Future<void> _shareAsImage() async {
    final currentResults = _currentTabResults;
    if (currentResults.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No results to share.')),
        );
      }
      return;
    }

    final isTNTab = _tabController.index == 1;
    final res = currentResults[0];

    try {
      final imageBytes = await _screenshotController.captureFromWidget(
        Material(
          color: Colors.white,
          child: Container(
            width: 380,
            color: Colors.white,
            padding: const EdgeInsets.only(bottom: 16),
            child:
                _buildStyledResultBlock(res, isTN: isTNTab, isForShare: true),
          ),
        ),
        delay: const Duration(milliseconds: 50),
        pixelRatio: 2.5,
      );

      final directory = await getTemporaryDirectory();
      final imagePath =
          '${directory.path}/result_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.png';
      final imageFile = File(imagePath);
      await imageFile.writeAsBytes(imageBytes);

      await Share.shareXFiles(
        [XFile(imagePath)],
        text:
            'Mango - ${isTNTab ? "TN" : "KL"} RESULT REPORT (${DateFormat('dd-MM-yyyy').format(_selectedDate)})',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sharing image: $e')),
        );
      }
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
    final currentResults = _currentTabResults;
    final isTNTab = _tabController.index == 1;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Container(
          height: 36,
          width: 170,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.18),
            borderRadius: BorderRadius.circular(20),
          ),
          child: TabBar(
            controller: _tabController,
            indicator: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            labelColor: AppColors.primary,
            unselectedLabelColor: Colors.white,
            labelStyle:
                const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            unselectedLabelStyle:
                const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            tabs: const [
              Tab(text: 'KL'),
              Tab(text: 'TN'),
            ],
          ),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (currentResults.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.share_rounded,
                  color: Colors.white, size: 20),
              onPressed: () => _shareAsText(currentResults[0], isTN: isTNTab),
              tooltip: "Share as Text",
            ),
          if (currentResults.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.image_rounded,
                  color: Colors.white, size: 20),
              onPressed: _shareAsImage,
              tooltip: "Share as Image",
            ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterHeader(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildResultList(_klResults, isTN: false),
                      _buildResultList(_tnResults, isTN: true),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 3,
            child: Text(
              DateFormat('dd-MM-yyyy').format(_selectedDate),
              style: const TextStyle(
                color: Color(0xFFE67E22),
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (_games.isNotEmpty)
            Expanded(
              flex: 4,
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: _games.any((g) => g.id == _selectedGameId)
                      ? _selectedGameId
                      : _games.first.id,
                  isExpanded: true,
                  isDense: true,
                  icon: const Icon(Icons.arrow_drop_down,
                      color: Colors.blueAccent, size: 20),
                  items: _games
                      .map((g) => DropdownMenuItem<int>(
                          value: g.id,
                          child: Text(g.name,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 13))))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedGameId = val);
                      _fetchResults();
                    }
                  },
                  style: const TextStyle(
                      color: Colors.blueAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 13),
                ),
              ),
            ),
          const SizedBox(width: 6),
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
                  padding: EdgeInsets.symmetric(horizontal: 4, vertical: 5),
                  child: Text(
                    'CHANGE DATE',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
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

  Widget _buildResultList(List<dynamic> results, {required bool isTN}) {
    if (results.isEmpty) {
      return _buildNoResults(isTN: isTN);
    }

    return Screenshot(
      controller: _screenshotController,
      child: Container(
        color: Colors.white,
        child: ListView.builder(
          padding: EdgeInsets.zero,
          itemCount: results.length,
          itemBuilder: (context, index) =>
              _buildStyledResultBlock(results[index], isTN: isTN),
        ),
      ),
    );
  }

  Widget _buildNoResults({required bool isTN}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_busy_rounded, size: 60, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text('No ${isTN ? 'TN' : 'KL'} results found for this date',
              style: TextStyle(color: Colors.grey[600], fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildStyledResultBlock(Map<String, dynamic> res,
      {required bool isTN, bool isForShare = false}) {
    return Column(
      children: [
        // Game Name Banner
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            border: Border(
              bottom: BorderSide(color: Colors.grey.shade300, width: 0.5),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isTN ? Colors.orange[800] : AppColors.primary,
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text(
                      isTN ? 'TN' : 'KL',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 10.5),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    res['game_name'] ?? 'GAME',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              Text(
                DateFormat('dd-MM-yyyy').format(_selectedDate),
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),

        // Prize Rows (Compact and cleanly fitted)
        _buildPrizeRow("1", res['winning_number'], const Color(0xFF1D8740)),
        _buildPrizeRow("2", res['second_prize'], const Color(0xFF0E799F)),
        _buildPrizeRow("3", res['third_prize'], const Color(0xFFDE8D0C)),
        _buildPrizeRow("4", res['fourth_prize'], const Color(0xFF6E378E)),
        if (!isTN)
          _buildPrizeRow("5", res['fifth_prize'], const Color(0xFF104282)),

        // Compliments for KL
        if (!isTN &&
            res['complimentary_numbers'] != null &&
            res['complimentary_numbers'].toString().trim().isNotEmpty) ...[
          const SizedBox(height: 8),
          const Text(
            "COMPLIMENTS",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 4),
          const Divider(height: 1, thickness: 0.5),
          _buildComplimentsGrid(res['complimentary_numbers']),
        ],

        // Admin Action Buttons
        if (_isAdmin && !isForShare)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                    icon: const Icon(Icons.edit_rounded, size: 15),
                    label: const Text('EDIT RESULT',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 12)),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      backgroundColor: AppColors.primary.withOpacity(0.08),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextButton.icon(
                    onPressed: () => _deleteResult(res['id']),
                    icon: const Icon(Icons.delete_outline_rounded, size: 15),
                    label: const Text('DELETE',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 12)),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      backgroundColor: Colors.red.withOpacity(0.08),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildPrizeRow(String label, String? value, Color bgColor) {
    return Container(
      width: double.infinity,
      color: bgColor,
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      margin: const EdgeInsets.only(bottom: 1.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 28,
            child: Text(
              label,
              style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                  fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
          const Text(
            ":",
            style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 12),
          Text(
            value ?? "---",
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComplimentsGrid(String? complimentsStr) {
    if (complimentsStr == null || complimentsStr.isEmpty) {
      return const SizedBox();
    }

    List<String> nums = complimentsStr
        .split(RegExp(r'[,\s\n]+'))
        .where((e) => e.isNotEmpty)
        .toList();

    int columns = 3;
    int rows = (nums.length / columns).ceil();

    return Table(
      border: const TableBorder(
        verticalInside: BorderSide(color: Colors.black12, width: 0.5),
      ),
      children: List.generate(rows, (rowIndex) {
        return TableRow(
          children: List.generate(columns, (colIndex) {
            int index = rowIndex + (colIndex * rows);
            String text = index < nums.length ? nums[index] : "";
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
              child: Center(
                child: Text(
                  text,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
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
