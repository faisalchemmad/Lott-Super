import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../models/user_model.dart';
import '../models/game_model.dart';
import '../models/number_limit_model.dart';
import '../utils/constants.dart';

class ManageUserNumberLimitsScreen extends StatefulWidget {
  final UserModel user;
  final GameModel? game; // Optional game for filtering
  final bool isReadOnly;
  const ManageUserNumberLimitsScreen(
      {super.key, required this.user, this.game, this.isReadOnly = false});

  @override
  State<ManageUserNumberLimitsScreen> createState() =>
      _ManageUserNumberLimitsScreenState();
}

class _ManageUserNumberLimitsScreenState
    extends State<ManageUserNumberLimitsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<NumberLimitModel> _limits = [];
  List<GameModel> _games = [];

  static const Set<String> _klTypes = {
    'A',
    'B',
    'C',
    'AB',
    'BC',
    'AC',
    'SUPER',
    'BOX'
  };
  static const Set<String> _tnTypes = {
    'TN-A',
    'TN-B',
    'TN-C',
    'TN-AB',
    'TN-BC',
    'TN-AC',
    '3D-10',
    '3D-25',
    '3D-30',
    '3D-60',
    '4D-110',
    '4D-55',
    '4D-20'
  };

  // Betting-Screen style Quick Number Limit Add
  int _selectedDigitTab = 2; // 0: 1-Digit, 1: 2-Digit, 2: 3-Digit, 3: 4-Digit
  final TextEditingController _quickNumberController = TextEditingController();
  final TextEditingController _quickCountController = TextEditingController();
  final FocusNode _quickNumberFocusNode = FocusNode();
  final FocusNode _quickCountFocusNode = FocusNode();
  bool _isQuickSubmitting = false;
  bool _quickAllGames = false;
  int? _quickSelectedGameId;

  void _autoJumpQuickNumber() {
    int reqDigits = _selectedDigitTab + 1;
    if (_quickNumberController.text.length == reqDigits) {
      _quickCountFocusNode.requestFocus();
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    if (widget.game != null) {
      _quickSelectedGameId = widget.game!.id;
    }
    _quickNumberController.addListener(_autoJumpQuickNumber);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _quickNumberController.dispose();
    _quickCountController.dispose();
    _quickNumberFocusNode.dispose();
    _quickCountFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final apiService = Provider.of<ApiService>(context, listen: false);

    try {
      final allLimits = await apiService.getNumberLimits(widget.game?.id);
      final userLimits = allLimits
          .where((l) => l.userUsername == widget.user.username)
          .toList();

      final games = await apiService.getGames();

      setState(() {
        _limits = userLimits;
        _games = games;
        if (_quickSelectedGameId == null && games.isNotEmpty) {
          _quickSelectedGameId = widget.game?.id ?? games.first.id;
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _showAddNumberLimitDialog({NumberLimitModel? limit, bool isTn = false}) {
    final bool isEditing = limit != null;
    final bool isTnLimit = isEditing ? _tnTypes.contains(limit.type) : isTn;
    final types = isTnLimit ? _tnTypes.toList() : _klTypes.toList();

    final numController =
        TextEditingController(text: isEditing ? limit.number : '');
    final countController =
        TextEditingController(text: isEditing ? limit.maxCount.toString() : '');
    String selectedType =
        isEditing ? limit.type : (isTnLimit ? '3D-10' : 'SUPER');
    bool allGame = false;
    int? selectedGameId =
        widget.game?.id ?? (_games.isNotEmpty ? _games.first.id : null);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isTnLimit ? Colors.deepOrange : AppColors.primary,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  isTnLimit ? 'TN' : 'KL',
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                isEditing ? 'Edit Number Limit' : 'Add Number Limit',
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Bet Type',
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  ),
                  items: types
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (val) => setDialogState(() => selectedType = val!),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: numController,
                  decoration: const InputDecoration(
                    labelText: 'Number',
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  ),
                  keyboardType: TextInputType.number,
                  enabled: !isEditing,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: countController,
                  decoration: const InputDecoration(
                    labelText: 'Max Count',
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  ),
                  keyboardType: TextInputType.number,
                ),
                if (!isEditing && _games.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Checkbox(
                        value: allGame,
                        onChanged: (val) =>
                            setDialogState(() => allGame = val!),
                      ),
                      const Text('ALL Games'),
                    ],
                  ),
                  if (!allGame) ...[
                    const SizedBox(height: 8),
                    DropdownButtonFormField<int>(
                      value: selectedGameId,
                      decoration: const InputDecoration(
                        labelText: 'Select Game',
                        border: OutlineInputBorder(),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      ),
                      items: _games
                          .map((g) => DropdownMenuItem(
                              value: g.id, child: Text(g.name)))
                          .toList(),
                      onChanged: (val) =>
                          setDialogState(() => selectedGameId = val!),
                    ),
                  ],
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('CANCEL')),
            ElevatedButton(
              onPressed: () async {
                if (numController.text.isEmpty ||
                    countController.text.isEmpty) {
                  return;
                }

                int reqDigits = 0;
                if (['A', 'B', 'C', 'TN-A', 'TN-B', 'TN-C']
                    .contains(selectedType)) {
                  reqDigits = 1;
                } else if (['AB', 'BC', 'AC', 'TN-AB', 'TN-BC', 'TN-AC']
                    .contains(selectedType)) {
                  reqDigits = 2;
                } else if (['SUPER', 'BOX', '3D-10', '3D-25', '3D-30', '3D-60']
                    .contains(selectedType)) {
                  reqDigits = 3;
                } else if (['4D-110', '4D-55', '4D-20']
                    .contains(selectedType)) {
                  reqDigits = 4;
                }

                if (reqDigits > 0 && numController.text.length != reqDigits) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Number must be $reqDigits digits')),
                  );
                  return;
                }

                final apiService =
                    Provider.of<ApiService>(context, listen: false);
                try {
                  if (isEditing) {
                    await apiService.updateNumberLimit(limit.id, {
                      'type': selectedType,
                      'max_count': int.parse(countController.text),
                    });
                  } else {
                    List<GameModel> targetGames = allGame
                        ? _games
                        : [_games.firstWhere((g) => g.id == selectedGameId)];
                    for (var game in targetGames) {
                      await apiService.createNumberLimit(
                        game.id,
                        widget.user.id,
                        numController.text,
                        selectedType,
                        int.parse(countController.text),
                      );
                    }
                  }
                  Navigator.pop(context);
                  _loadData();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    isTnLimit ? Colors.deepOrange : AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6)),
              ),
              child: Text(isEditing ? 'UPDATE' : 'ADD',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Limit?'),
        content:
            const Text('Are you sure you want to remove this number limit?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('CANCEL')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('DELETE', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true) {
      final apiService = Provider.of<ApiService>(context, listen: false);
      if (await apiService.deleteNumberLimit(id)) {
        _loadData();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    String title =
        widget.isReadOnly ? 'My Number Limits' : 'Number Count Limit';
    if (widget.game != null) {
      title += ' (${widget.game!.name})';
    }

    final klLimits = _limits.where((l) => _klTypes.contains(l.type)).toList();
    final tnLimits = _limits.where((l) => _tnTypes.contains(l.type)).toList();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(title,
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: widget.user.isBothEnabled
            ? TabBar(
                controller: _tabController,
                indicatorColor: Colors.white,
                indicatorWeight: 3,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                tabs: [
                  Tab(text: 'KL LIMITS (${klLimits.length})'),
                  Tab(text: 'TN LIMITS (${tnLimits.length})'),
                ],
              )
            : null,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : widget.user.isBothEnabled
              ? TabBarView(
                  controller: _tabController,
                  children: [
                    _buildLimitsListTab(
                        limits: klLimits,
                        isTn: false,
                        badgeColor: AppColors.primary),
                    _buildLimitsListTab(
                        limits: tnLimits,
                        isTn: true,
                        badgeColor: Colors.deepOrange),
                  ],
                )
              : (widget.user.effectiveGameMode == 'TN'
                  ? _buildLimitsListTab(
                      limits: tnLimits,
                      isTn: true,
                      badgeColor: Colors.deepOrange)
                  : _buildLimitsListTab(
                      limits: klLimits,
                      isTn: false,
                      badgeColor: AppColors.primary)),
    );
  }

  Widget _buildLimitsListTab(
      {required List<NumberLimitModel> limits,
      required bool isTn,
      required Color badgeColor}) {
    return Column(
      children: [
        if (!widget.isReadOnly) ...[
          _buildQuickInputSection(isTn, badgeColor),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isTn ? 'Active Tamil Nadu Number Limits (${limits.length})' : 'Active Kerala Number Limits (${limits.length})',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: badgeColor),
                ),
              ],
            ),
          ),
        ],
        if (limits.isNotEmpty) _buildTableHeader(badgeColor),
        Expanded(
          child: limits.isEmpty
              ? _buildEmptyState(
                  isTn ? 'No TN Number Limits Set' : 'No KL Number Limits Set')
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  itemCount: limits.length,
                  itemBuilder: (context, index) {
                    final limit = limits[index];
                    return _buildNumberLimitCard(limit, badgeColor);
                  },
                ),
        ),
      ],
    );
  }

  List<String> _getQuickButtonsForTab(int tabIndex, bool isTn) {
    if (tabIndex == 0) {
      return ['A', 'B', 'C', 'ALL'];
    } else if (tabIndex == 1) {
      return ['AB', 'BC', 'AC', 'ALL'];
    } else if (tabIndex == 2) {
      return isTn ? ['3D-10', '3D-25', '3D-30', '3D-60'] : ['SUPER', 'BOX'];
    } else {
      return ['4D-110', '4D-55', '4D-20'];
    }
  }

  Widget _buildQuickInputSection(bool isTn, Color activeColor) {
    int maxTabs = isTn ? 4 : 3;
    if (_selectedDigitTab >= maxTabs) {
      _selectedDigitTab = maxTabs - 1;
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: activeColor.withValues(alpha: 0.35), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Optional Game Selector if not pre-locked
          if (widget.game == null && _games.isNotEmpty) ...[
            Row(
              children: [
                SizedBox(
                  height: 24,
                  width: 24,
                  child: Checkbox(
                    value: _quickAllGames,
                    activeColor: activeColor,
                    onChanged: (val) => setState(() => _quickAllGames = val ?? false),
                  ),
                ),
                const SizedBox(width: 6),
                const Text('ALL GAMES', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                if (!_quickAllGames) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: _quickSelectedGameId ?? (_games.isNotEmpty ? _games.first.id : null),
                          isDense: true,
                          items: _games
                              .map((g) => DropdownMenuItem(
                                    value: g.id,
                                    child: Text(g.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                  ))
                              .toList(),
                          onChanged: (val) => setState(() => _quickSelectedGameId = val),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 10),
          ],

          // 1. Digit Selector Tabs
          Row(
            children: List.generate(maxTabs, (index) {
              final isSelected = _selectedDigitTab == index;
              final labels = ['1 DIGIT', '2 DIGIT', '3 DIGIT', '4 DIGIT'];
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: index < maxTabs - 1 ? 6.0 : 0.0),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(6),
                    onTap: () {
                      setState(() {
                        _selectedDigitTab = index;
                        _quickNumberController.clear();
                      });
                      _quickNumberFocusNode.requestFocus();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 7),
                      decoration: BoxDecoration(
                        color: isSelected ? activeColor : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isSelected ? activeColor : Colors.grey.shade300,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        labels[index],
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w900,
                          color: isSelected ? Colors.white : Colors.grey.shade700,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 10),

          // 2. Number & Count Inputs Row
          Row(
            children: [
              Expanded(
                flex: 5,
                child: TextField(
                  controller: _quickNumberController,
                  focusNode: _quickNumberFocusNode,
                  keyboardType: TextInputType.number,
                  maxLength: _selectedDigitTab + 1,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 2),
                  decoration: InputDecoration(
                    labelText: 'NUMBER',
                    labelStyle: TextStyle(color: activeColor, fontSize: 11, fontWeight: FontWeight.bold),
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                    counterText: '',
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide(color: activeColor, width: 1.5),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 5,
                child: TextField(
                  controller: _quickCountController,
                  focusNode: _quickCountFocusNode,
                  keyboardType: TextInputType.number,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: activeColor),
                  decoration: InputDecoration(
                    labelText: 'LIMIT COUNT',
                    labelStyle: TextStyle(color: activeColor, fontSize: 11, fontWeight: FontWeight.bold),
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide(color: activeColor, width: 1.5),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // 3. Quick Action / Type Buttons Row
          if (_isQuickSubmitting)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)),
              ),
            )
          else
            Row(
              children: _getQuickButtonsForTab(_selectedDigitTab, isTn).map((btn) {
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3.0),
                    child: ElevatedButton(
                      onPressed: () => _handleQuickAdd(btn, isTn),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: btn == 'ALL' ? Colors.black87 : activeColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                      child: Text(
                        btn,
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Future<void> _handleQuickAdd(String btn, bool isTn) async {
    final number = _quickNumberController.text.trim();
    final countStr = _quickCountController.text.trim();
    final reqDigits = _selectedDigitTab + 1;

    if (number.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter number'), duration: Duration(milliseconds: 1000)),
      );
      _quickNumberFocusNode.requestFocus();
      return;
    }

    if (number.length != reqDigits || int.tryParse(number) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Number must be $reqDigits digits'), duration: const Duration(milliseconds: 1000)),
      );
      _quickNumberFocusNode.requestFocus();
      return;
    }

    if (countStr.isEmpty || int.tryParse(countStr) == null || int.parse(countStr) <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid count'), duration: Duration(milliseconds: 1000)),
      );
      _quickCountFocusNode.requestFocus();
      return;
    }

    final count = int.parse(countStr);
    setState(() => _isQuickSubmitting = true);

    final apiService = Provider.of<ApiService>(context, listen: false);

    try {
      List<String> targetTypes = [];
      if (btn == 'ALL') {
        if (reqDigits == 1) {
          targetTypes = isTn ? ['TN-A', 'TN-B', 'TN-C'] : ['A', 'B', 'C'];
        } else if (reqDigits == 2) {
          targetTypes = isTn ? ['TN-AB', 'TN-BC', 'TN-AC'] : ['AB', 'BC', 'AC'];
        }
      } else {
        String realType = btn;
        if (isTn && ['A', 'B', 'C', 'AB', 'BC', 'AC'].contains(btn)) {
          realType = 'TN-$btn';
        }
        targetTypes = [realType];
      }

      List<GameModel> targetGames;
      if (widget.game != null) {
        targetGames = [widget.game!];
      } else if (_quickAllGames) {
        targetGames = _games;
      } else {
        targetGames = [_games.firstWhere((g) => g.id == _quickSelectedGameId, orElse: () => _games.first)];
      }

      for (var g in targetGames) {
        for (var t in targetTypes) {
          await apiService.createNumberLimit(g.id, widget.user.id, number, t, count);
        }
      }

      await _loadData();
      _quickNumberController.clear();
      _quickNumberFocusNode.requestFocus();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('User limit added: $number [$btn] -> $count'),
            backgroundColor: Colors.green,
            duration: const Duration(milliseconds: 1000),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding limit: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isQuickSubmitting = false);
    }
  }

  Widget _buildTableHeader(Color color) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: const Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              'TYPE',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                  letterSpacing: 0.5),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              'NUMBER',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                  letterSpacing: 0.5),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'CNT',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                  letterSpacing: 0.5),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'ACTION',
              textAlign: TextAlign.right,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                  letterSpacing: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNumberLimitCard(NumberLimitModel limit, Color badgeColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 3,
              offset: const Offset(0, 1)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: _buildTypeBadge(limit.type, badgeColor),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              limit.number,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50)),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '${limit.maxCount}',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w900, color: badgeColor),
            ),
          ),
          Expanded(
            flex: 2,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (!widget.isReadOnly) ...[
                  InkWell(
                    onTap: () => _showAddNumberLimitDialog(limit: limit),
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(Icons.edit_outlined,
                          color: Colors.blue, size: 18),
                    ),
                  ),
                  const SizedBox(width: 4),
                  InkWell(
                    onTap: () => _confirmDelete(limit.id),
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(Icons.delete_outline_rounded,
                          color: Colors.red, size: 18),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeBadge(String type, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        type,
        style:
            TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11),
      ),
    );
  }

  Widget _buildEmptyState(String msg) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.numbers_outlined, size: 60, color: Colors.grey[300]),
          const SizedBox(height: 12),
          Text(msg, style: const TextStyle(color: Colors.grey, fontSize: 16)),
        ],
      ),
    );
  }
}
