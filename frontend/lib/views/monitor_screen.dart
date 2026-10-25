import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../services/api_service.dart';
import '../models/game_model.dart';

class MonitorScreen extends StatefulWidget {
  const MonitorScreen({super.key});

  @override
  State<MonitorScreen> createState() => _MonitorScreenState();
}

class _MonitorScreenState extends State<MonitorScreen> {
  DateTime _selectedDate = DateTime.now();
  String _selectedState = 'KL'; // 'KL' or 'TN'
  List<GameModel> _allGames = [];
  List<GameModel> _filteredGames = [];
  GameModel? _selectedGame;

  // Filter tabs
  int _selectedFilterTab = 0; // 0: ALL, 1: 1D, 2: 2D, 3: 3D, 4: 4D
  String _selectedFilterType = 'ALL';
  bool _excessOnly = true; // Show only numbers with excess count by default
  final TextEditingController _searchController = TextEditingController();

  List<dynamic> _monitorData = [];
  Map<String, dynamic> _summary = {};
  Map<String, dynamic> _activeHoldLimits = {};
  bool _isLoading = false;

  static const Color headerNavy = Color(0xFF0F172A);
  static const Color primaryBlue = Color(0xFF1E40AF);
  static const Color accentGreen = Color(0xFF16A34A);
  static const Color alertRed = Color(0xFFDC2626);
  static const Color warningOrange = Color(0xFFEA580C);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    final apiService = Provider.of<ApiService>(context, listen: false);
    try {
      final profile = await apiService.getProfile();
      final games = await apiService.getGames();

      _allGames = games;

      if (profile != null) {
        if (profile.effectiveGameMode == 'TN') {
          _selectedState = 'TN';
        } else {
          _selectedState = 'KL';
        }
      }

      _updateGamesForState();
      await _fetchData();
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _updateGamesForState() {
    _filteredGames = _allGames.where((g) {
      final nameUpper = g.name.toUpperCase();
      if (_selectedState == 'TN') {
        return nameUpper.contains('TN') ||
            nameUpper.contains('TAMIL') ||
            nameUpper.contains('1:00') ||
            nameUpper.contains('6:00') ||
            nameUpper.contains('8:00');
      } else {
        return !nameUpper.contains('TN') && !nameUpper.contains('TAMIL');
      }
    }).toList();

    if (_filteredGames.isEmpty && _allGames.isNotEmpty) {
      _filteredGames = List.from(_allGames);
    }

    if (_filteredGames.isNotEmpty) {
      if (_selectedGame == null || !_filteredGames.any((g) => g.id == _selectedGame!.id)) {
        _selectedGame = _filteredGames.first;
      }
    } else {
      _selectedGame = null;
    }
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    final apiService = Provider.of<ApiService>(context, listen: false);
    try {
      final res = await apiService.getMonitorData(
        date: DateFormat('yyyy-MM-dd').format(_selectedDate),
        gameId: _selectedGame?.id,
        state: _selectedState,
        digits: _selectedFilterTab == 0 ? 'ALL' : '$_selectedFilterTab',
        type: _selectedFilterType == 'ALL' ? null : _selectedFilterType,
        number: _searchController.text.trim(),
        excessOnly: _excessOnly,
      );

      if (mounted) {
        setState(() {
          _monitorData = (res['data'] as List?) ?? [];
          _summary = (res['summary'] as Map<String, dynamic>?) ?? {};
          _activeHoldLimits = (res['active_hold_limits'] as Map<String, dynamic>?) ?? {};
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  List<String> _getSubTypesForTab(int tabIndex, bool isTn) {
    if (tabIndex == 1) {
      return ['ALL', 'A', 'B', 'C'];
    } else if (tabIndex == 2) {
      return ['ALL', 'AB', 'BC', 'AC'];
    } else if (tabIndex == 3) {
      if (isTn) {
        return ['ALL', '3D-10', '3D-25', '3D-30', '3D-60'];
      }
      return ['ALL', 'SUPER', 'BOX'];
    } else if (tabIndex == 4) {
      if (isTn) {
        return ['ALL', '4D-110', '4D-55', '4D-20'];
      }
      return ['ALL'];
    }
    return ['ALL'];
  }

  String _formatPassingText() {
    final gameTitle = _selectedGame?.name ?? 'ALL GAMES';
    final dateStr = DateFormat('dd-MM-yyyy').format(_selectedDate);

    final Map<String, List<Map<String, dynamic>>> grouped = {};
    int totalExcess = 0;

    for (var item in _monitorData) {
      final excess = int.tryParse(item['excess_count'].toString()) ?? 0;
      if (excess > 0) {
        final t = (item['type'] ?? '').toString().toUpperCase();
        if (!grouped.containsKey(t)) {
          grouped[t] = [];
        }
        grouped[t]!.add({
          'num': item['number'].toString(),
          'excess': excess,
        });
        totalExcess += excess;
      }
    }

    final sb = StringBuffer();
    sb.writeln("━━━━━━━━━━━━━━━━━━━━━");
    sb.writeln("🔥 *LOTT SUPER - PASSING LIST (പുറത്തേക്ക്)*");
    sb.writeln("🎮 Game: $gameTitle ($_selectedState)");
    sb.writeln("📅 Date: $dateStr");
    sb.writeln("━━━━━━━━━━━━━━━━━━━━━");

    if (grouped.isEmpty) {
      sb.writeln("No excess numbers to pass.");
    } else {
      grouped.forEach((type, list) {
        sb.writeln("\n[$type]");
        for (var n in list) {
          sb.writeln("${n['num']} - ${n['excess']}");
        }
      });
      sb.writeln("\n━━━━━━━━━━━━━━━━━━━━━");
      sb.writeln("📊 *TOTAL EXCESS COUNT: $totalExcess*");
      sb.writeln("━━━━━━━━━━━━━━━━━━━━━");
    }

    return sb.toString();
  }

  void _shareViaWhatsApp() {
    final text = _formatPassingText();
    final excessCount = _summary['total_excess_count'] ?? 0;
    if (excessCount == 0 && _monitorData.every((e) => (e['excess_count'] ?? 0) <= 0)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('പുറത്തേക്ക് നൽകാൻ അധികം കൗണ്ടുള്ള നമ്പറുകൾ ഒന്നും ഇല്ല!')),
      );
      return;
    }
    Share.share(text);
  }

  void _copyToClipboard() {
    final text = _formatPassingText();
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('പാസിംഗ് ലിസ്റ്റ് ക്ലിപ്പ്ബോർഡിലേക്ക് കോപ്പി ചെയ്തു!'),
        backgroundColor: accentGreen,
      ),
    );
  }

  void _showSetHoldLimitDialog() {
    final bool isTn = _selectedState == 'TN';
    final List<String> types = isTn
        ? ['A', 'B', 'C', 'AB', 'BC', 'AC', '3D-10', '3D-25', '3D-30', '3D-60', '4D-110', '4D-55', '4D-20']
        : ['A', 'B', 'C', 'AB', 'BC', 'AC', 'SUPER', 'BOX'];

    final Map<String, TextEditingController> controllers = {};
    for (var t in types) {
      final currentVal = _activeHoldLimits[t] ??
          (t.contains('4D')
              ? 10
              : (t.contains('3D') || t == 'SUPER' || t == 'BOX'
                  ? 25
                  : (t.length == 2 ? 50 : 100)));
      controllers[t] = TextEditingController(text: currentVal.toString());
    }

    bool applyToAllGames = false;
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.tune_rounded, color: primaryBlue),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'ഹോൾഡ് ലിമിറ്റ് സെറ്റ് ചെയ്യുക ($_selectedState)',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: primaryBlue.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'ഗെയിം: ${_selectedGame?.name ?? "All Games"}\nനമ്മുടെ കൈയിൽ വെക്കേണ്ട പരമാവധി കൗണ്ട് ഇവിടെ സെറ്റ് ചെയ്യാം. ഇതിൽ കൂടുതൽ വരുന്നവ പുറത്തേക്ക് ഷെയർ ചെയ്യാൻ ലിസ്റ്റ് ചെയ്യും.',
                      style: const TextStyle(fontSize: 12, color: primaryBlue, fontWeight: FontWeight.w500),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 12,
                    runSpacing: 10,
                    children: types.map((t) {
                      return SizedBox(
                        width: 130,
                        child: TextField(
                          controller: controllers[t],
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: t,
                            labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),
                  CheckboxListTile(
                    value: applyToAllGames,
                    onChanged: (val) => setDialogState(() => applyToAllGames = val ?? false),
                    title: Text(
                      'എല്ലാ $_selectedState ഗെയിമുകൾക്കും ഇത് ബാധകമാക്കുക',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCEL', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: isSaving
                  ? null
                  : () async {
                      if (_selectedGame == null && !applyToAllGames) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please select a game first')),
                        );
                        return;
                      }

                      setDialogState(() => isSaving = true);
                      final Map<String, int> limitsMap = {};
                      controllers.forEach((k, v) {
                        limitsMap[k] = int.tryParse(v.text.trim()) ?? 25;
                      });

                      final apiService = Provider.of<ApiService>(context, listen: false);
                      final ok = await apiService.setMonitoringHoldLimits(
                        gameId: _selectedGame?.id ?? 0,
                        state: _selectedState,
                        limits: limitsMap,
                        applyToAllGames: applyToAllGames,
                      );

                      if (context.mounted) {
                        Navigator.pop(context);
                        if (ok) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('ഹോൾഡ് ലിമിറ്റുകൾ വിജയകരമായി സേവ് ചെയ്തു!'),
                              backgroundColor: accentGreen,
                            ),
                          );
                          _fetchData();
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('ലിമിറ്റ് സേവ് ചെയ്യാൻ സാധിച്ചില്ല'),
                              backgroundColor: alertRed,
                            ),
                          );
                        }
                      }
                    },
              child: isSaving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('SAVE LIMITS'),
            ),
          ],
        ),
      ),
    );
  }

  void _showCustomNumberLimitDialog(Map<String, dynamic> item) {
    final num = item['number'].toString();
    final type = item['type'].toString();
    final currentHold = item['hold_limit'] ?? 25;
    final isCustom = item['is_custom_number_limit'] == true;

    final controller = TextEditingController(text: currentHold.toString());
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'നമ്പർ ലിമിറ്റ്: $num ($type)',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ഈ നമ്പറിന് മാത്രം പ്രത്യേകമായി കൈയിൽ വെക്കേണ്ട ലിമിറ്റ് ഇവിടെ മാറ്റാം:',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'കൈയിൽ വെക്കേണ്ട കൗണ്ട്',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
          actions: [
            if (isCustom)
              TextButton(
                onPressed: () async {
                  final apiService = Provider.of<ApiService>(context, listen: false);
                  await apiService.deleteMonitoringNumberLimit(
                    gameId: item['game_id'],
                    state: item['state'],
                    type: type,
                    number: num,
                  );
                  if (context.mounted) {
                    Navigator.pop(context);
                    _fetchData();
                  }
                },
                child: const Text('RESET TO DEFAULT', style: TextStyle(color: Colors.red)),
              ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCEL', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: primaryBlue, foregroundColor: Colors.white),
              onPressed: isSaving
                  ? null
                  : () async {
                      final val = int.tryParse(controller.text.trim()) ?? 0;
                      setDialogState(() => isSaving = true);
                      final apiService = Provider.of<ApiService>(context, listen: false);
                      final ok = await apiService.setMonitoringNumberLimit(
                        gameId: item['game_id'],
                        state: item['state'],
                        type: type,
                        number: num,
                        maxRetainedCount: val,
                      );
                      if (context.mounted) {
                        Navigator.pop(context);
                        if (ok) _fetchData();
                      }
                    },
              child: const Text('UPDATE'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isTn = _selectedState == 'TN';
    final subTypes = _getSubTypesForTab(_selectedFilterTab, isTn);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text(
          'റിസ്ക് മോണിറ്ററിംഗ് (Monitoring)',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Colors.white),
        ),
        backgroundColor: headerNavy,
        elevation: 0,
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            tooltip: 'Refresh',
            onPressed: _fetchData,
          ),
          IconButton(
            icon: const Icon(Icons.tune_rounded, color: Colors.white),
            tooltip: 'Set Hold Limits',
            onPressed: _showSetHoldLimitDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. Controls Header: State Toggle + Game Dropdown + Date Picker
          _buildTopControls(),

          // 2. Summary KPI Cards
          _buildSummaryCards(),

          // 3. Quick Action Buttons: Share WhatsApp + Copy List + Set Hold
          _buildActionButtonsRow(),

          // 4. Digit Filter Tabs (Compact Full Width)
          _buildDigitTabs(),

          // 5. Sub-Type Filter Chips
          if (_selectedFilterTab >= 1 && subTypes.length > 1) _buildSubTypesRow(subTypes),

          // 6. Search Bar & Excess-Only Toggle
          _buildSearchAndToggle(),

          // 7. Table Header
          _buildTableHeader(),

          // 8. Numbers Table / List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _monitorData.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inventory_2_outlined, size: 56, color: Colors.grey.shade400),
                            const SizedBox(height: 10),
                            Text(
                              _excessOnly
                                  ? 'പുറത്തേക്ക് നൽകേണ്ട അധികം നമ്പറുകൾ ഒന്നും ഇല്ല!'
                                  : 'ഈ ഗെയിമിൽ ബെറ്റുകൾ ഒന്നും ലഭ്യമല്ല',
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            if (_excessOnly)
                              TextButton(
                                onPressed: () {
                                  setState(() => _excessOnly = false);
                                  _fetchData();
                                },
                                child: const Text('എല്ലാ നമ്പറുകളും കാണുക'),
                              ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _fetchData,
                        child: ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: _monitorData.length,
                          itemBuilder: (context, index) {
                            return _buildDataRow(_monitorData[index], index);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  // ===================== TOP CONTROLS (KL/TN, GAME, DATE) =====================
  Widget _buildTopControls() {
    return Container(
      color: headerNavy,
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
      child: Column(
        children: [
          Row(
            children: [
              // KL / TN Pill Toggle
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white24),
                ),
                child: Row(
                  children: ['KL', 'TN'].map((st) {
                    final isSel = _selectedState == st;
                    return GestureDetector(
                      onTap: () {
                        if (_selectedState != st) {
                          setState(() {
                            _selectedState = st;
                            _selectedFilterTab = 0;
                            _selectedFilterType = 'ALL';
                            _updateGamesForState();
                          });
                          _fetchData();
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: isSel ? (st == 'TN' ? Colors.deepOrange : primaryBlue) : Colors.transparent,
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: Text(
                          st,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: isSel ? FontWeight.w900 : FontWeight.w600,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(width: 10),

              // Game Selector
              Expanded(
                child: Container(
                  height: 36,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: _selectedGame?.id,
                      dropdownColor: headerNavy,
                      icon: const Icon(Icons.arrow_drop_down, color: Colors.white70),
                      isExpanded: true,
                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                      items: _filteredGames.map((g) {
                        return DropdownMenuItem<int>(
                          value: g.id,
                          child: Text(
                            g.name,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedGame = _filteredGames.firstWhere((g) => g.id == val);
                          });
                          _fetchData();
                        }
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Date Picker Button
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2035),
                  );
                  if (picked != null) {
                    setState(() => _selectedDate = picked);
                    _fetchData();
                  }
                },
                child: Container(
                  height: 36,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded, size: 14, color: Colors.white70),
                      const SizedBox(width: 6),
                      Text(
                        DateFormat('dd/MM').format(_selectedDate),
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ===================== SUMMARY KPI CARDS =====================
  Widget _buildSummaryCards() {
    final totReceived = _summary['total_received_count'] ?? 0;
    final totHold = _summary['total_retained_count'] ?? 0;
    final totExcess = _summary['total_excess_count'] ?? 0;
    final excessNums = _summary['excess_numbers_count'] ?? 0;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
      child: Row(
        children: [
          _buildStatTile('ആകെ വന്നത്', '$totReceived', primaryBlue, Icons.input_rounded),
          const SizedBox(width: 6),
          _buildStatTile('കൈയിലുള്ളത്', '$totHold', accentGreen, Icons.lock_clock_rounded),
          const SizedBox(width: 6),
          _buildStatTile('പുറത്തേക്ക്', '$totExcess', alertRed, Icons.output_rounded, isAlert: totExcess > 0),
          const SizedBox(width: 6),
          _buildStatTile('അധികം നമ്പറുകൾ', '$excessNums', Colors.purple.shade700, Icons.numbers_rounded),
        ],
      ),
    );
  }

  Widget _buildStatTile(String label, String value, Color color, IconData icon, {bool isAlert = false}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 6),
        decoration: BoxDecoration(
          color: isAlert ? alertRed.withValues(alpha: 0.12) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isAlert ? alertRed : color.withValues(alpha: 0.2),
            width: isAlert ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 13, color: color),
                const SizedBox(width: 3),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 9.5, color: Colors.grey.shade700, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===================== ACTION BUTTONS ROW =====================
  Widget _buildActionButtonsRow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: Row(
        children: [
          // Set Hold Limit Button
          Expanded(
            flex: 3,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.tune_rounded, size: 15),
              label: const Text('ഹോൾഡ് ലിമിറ്റ്', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: headerNavy,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 9),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
                elevation: 0,
              ),
              onPressed: _showSetHoldLimitDialog,
            ),
          ),
          const SizedBox(width: 8),

          // Share WhatsApp Button
          Expanded(
            flex: 4,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.share_rounded, size: 15),
              label: const Text('പുറത്തേക്ക് ഷെയർ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: alertRed,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 9),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
                elevation: 0,
              ),
              onPressed: _shareViaWhatsApp,
            ),
          ),
          const SizedBox(width: 8),

          // Copy Button
          InkWell(
            onTap: _copyToClipboard,
            borderRadius: BorderRadius.circular(7),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(7),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: const Icon(Icons.copy_rounded, size: 17, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  // ===================== DIGIT TABS =====================
  Widget _buildDigitTabs() {
    final tabs = ['ALL', '1 DIGIT', '2 DIGIT', '3 DIGIT', '4 DIGIT'];

    return Container(
      margin: const EdgeInsets.fromLTRB(14, 6, 14, 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: List.generate(tabs.length, (index) {
          final isSelected = _selectedFilterTab == index;
          return Expanded(
            child: InkWell(
              onTap: () {
                setState(() {
                  _selectedFilterTab = index;
                  _selectedFilterType = 'ALL';
                });
                _fetchData();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 7),
                decoration: BoxDecoration(
                  color: isSelected ? primaryBlue : Colors.transparent,
                  borderRadius: BorderRadius.circular(7),
                ),
                alignment: Alignment.center,
                child: Text(
                  tabs[index],
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.w900 : FontWeight.bold,
                    color: isSelected ? Colors.white : Colors.grey.shade700,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ===================== SUB TYPES ROW =====================
  Widget _buildSubTypesRow(List<String> subTypes) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 2, 14, 4),
      child: Row(
        children: subTypes.map((t) {
          final isSelected = _selectedFilterType == t;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2.0),
              child: InkWell(
                borderRadius: BorderRadius.circular(6),
                onTap: () {
                  setState(() => _selectedFilterType = t);
                  _fetchData();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 4.5),
                  decoration: BoxDecoration(
                    color: isSelected ? primaryBlue : Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isSelected ? primaryBlue : Colors.grey.shade300,
                      width: 1,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    t,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: isSelected ? FontWeight.w900 : FontWeight.bold,
                      color: isSelected ? Colors.white : Colors.grey.shade800,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ===================== SEARCH & TOGGLE =====================
  Widget _buildSearchAndToggle() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: Row(
        children: [
          // Search Number Field
          Expanded(
            child: SizedBox(
              height: 34,
              child: TextField(
                controller: _searchController,
                keyboardType: TextInputType.number,
                onSubmitted: (_) => _fetchData(),
                decoration: InputDecoration(
                  hintText: 'നമ്പർ സെർച്ച്...',
                  hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  prefixIcon: const Icon(Icons.search, size: 16),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 15),
                          onPressed: () {
                            _searchController.clear();
                            _fetchData();
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: EdgeInsets.zero,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(7),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(7),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Excess Only Toggle Checkbox
          InkWell(
            onTap: () {
              setState(() => _excessOnly = !_excessOnly);
              _fetchData();
            },
            borderRadius: BorderRadius.circular(7),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: _excessOnly ? alertRed.withValues(alpha: 0.1) : Colors.white,
                borderRadius: BorderRadius.circular(7),
                border: Border.all(color: _excessOnly ? alertRed : Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  Icon(
                    _excessOnly ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                    size: 16,
                    color: _excessOnly ? alertRed : Colors.grey,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'അധികം ഉള്ളവ',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: _excessOnly ? alertRed : Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===================== TABLE HEADER =====================
  Widget _buildTableHeader() {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 6, 14, 0),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: const BoxDecoration(
        color: headerNavy,
        borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
      ),
      child: const Row(
        children: [
          Expanded(flex: 3, child: Text('NUMBER', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold))),
          Expanded(flex: 2, child: Text('TYPE', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold))),
          Expanded(flex: 2, child: Text('TOTAL', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold))),
          Expanded(flex: 2, child: Text('HOLD', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold))),
          Expanded(flex: 2, child: Text('EXCESS', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFFFCA5A5), fontSize: 11, fontWeight: FontWeight.w900))),
          SizedBox(width: 32, child: Text('EDIT', textAlign: TextAlign.center, style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  // ===================== DATA ROW =====================
  Widget _buildDataRow(dynamic item, int index) {
    final int excess = int.tryParse(item['excess_count'].toString()) ?? 0;
    final int total = int.tryParse(item['total_count'].toString()) ?? 0;
    final int hold = int.tryParse(item['hold_limit'].toString()) ?? 0;
    final String type = (item['type'] ?? '').toString().toUpperCase();
    final String num = (item['number'] ?? '').toString();
    final bool isCustomLimit = item['is_custom_number_limit'] == true;

    final Color rowBg = index % 2 == 0 ? Colors.white : const Color(0xFFF8FAFC);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: excess > 0 ? (index % 2 == 0 ? const Color(0xFFFEF2F2) : const Color(0xFFFEE2E2)) : rowBg,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200),
          left: BorderSide(color: excess > 0 ? alertRed : Colors.grey.shade300, width: excess > 0 ? 3 : 1),
          right: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      child: Row(
        children: [
          // Number
          Expanded(
            flex: 3,
            child: Text(
              num,
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Colors.black87),
            ),
          ),

          // Type Badge
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _getTypeColor(type).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: _getTypeColor(type).withValues(alpha: 0.3)),
                ),
                child: Text(
                  type,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: _getTypeColor(type),
                  ),
                ),
              ),
            ),
          ),

          // Total Count
          Expanded(
            flex: 2,
            child: Text(
              '$total',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
            ),
          ),

          // Hold Limit
          Expanded(
            flex: 2,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$hold',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: isCustomLimit ? Colors.deepPurple : Colors.grey.shade700,
                  ),
                ),
                if (isCustomLimit)
                  const Text(
                    '*',
                    style: TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.bold),
                  ),
              ],
            ),
          ),

          // Excess Count (Alert Badge if > 0)
          Expanded(
            flex: 2,
            child: excess > 0
                ? Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: alertRed,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '+$excess',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  )
                : const Text(
                    '-',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
          ),

          // Edit Specific Limit Action
          SizedBox(
            width: 32,
            child: IconButton(
              icon: const Icon(Icons.edit_outlined, size: 15, color: Colors.blueGrey),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              tooltip: 'Edit number hold limit',
              onPressed: () => _showCustomNumberLimitDialog(item),
            ),
          ),
        ],
      ),
    );
  }

  Color _getTypeColor(String type) {
    if (type == 'SUPER') return primaryBlue;
    if (type == 'BOX') return Colors.teal;
    if (['A', 'B', 'C'].contains(type)) return warningOrange;
    if (['AB', 'BC', 'AC'].contains(type)) return Colors.indigo;
    if (type.contains('3D')) return Colors.deepPurple;
    if (type.contains('4D')) return Colors.pink.shade700;
    return Colors.blueGrey;
  }
}
