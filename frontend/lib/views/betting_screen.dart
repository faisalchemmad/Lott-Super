import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../models/game_model.dart';
import '../models/user_model.dart';
import '../models/bet_model.dart';
import '../utils/constants.dart';
import 'failed_bets_screen.dart';

class BettingScreen extends StatefulWidget {
  final GameModel game;
  const BettingScreen({super.key, required this.game});

  @override
  State<BettingScreen> createState() => _BettingScreenState();
}

class _BettingScreenState extends State<BettingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  UserModel? _user;
  String? _selectedType;
  final TextEditingController _numberController = TextEditingController();
  final TextEditingController _countController =
      TextEditingController(text: '');
  final TextEditingController _boxCountController =
      TextEditingController(text: '');
  final TextEditingController _customerController = TextEditingController();
  final TextEditingController _userController = TextEditingController();
  List<UserModel> _users = [];
  bool _isLoading = true;
  bool _isSubmitting = false;
  List<BetModel> _recentBets = [];
  List<Map<String, dynamic>> _draftBets = [];
  bool _isRangeEnabled = false;
  final TextEditingController _startController = TextEditingController();
  final TextEditingController _endController = TextEditingController();
  final TextEditingController _stepController =
      TextEditingController(text: '1');
  final FocusNode _numberFocusNode = FocusNode();
  final FocusNode _countFocusNode = FocusNode();

  final Map<String, int> _typeDigitMap = {
    'A': 1,
    'B': 1,
    'C': 1,
    'AB': 2,
    'BC': 2,
    'AC': 2,
    'SUPER': 3,
    'BOX': 3,
    'ALL': 0, // Placeholder, will be handled dynamically
    'SET': 3,
    'BOTH': 3,
  };

  final Map<int, List<String>> _tabsMap = {
    0: ['A', 'B', 'C', 'ALL'],
    1: ['AB', 'BC', 'AC', 'ALL'],
    2: ['SUPER', 'BOX', 'SET', 'BOTH'],
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: 2);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      // Set default selected type for each tab when switched
      setState(() {
        _selectedType = _tabsMap[_tabController.index]![0];
        _numberController.clear();
        _numberFocusNode.requestFocus();
      });
    });
    _numberController.addListener(_autoJumpToCount);
    _loadData();
  }

  void _autoJumpToCount() {
    if (_numberController.text.isNotEmpty) {
      int requiredDigits = 0;
      if (_selectedType == 'ALL') {
        requiredDigits = (_tabController.index == 0
            ? 1
            : (_tabController.index == 1 ? 2 : 3));
      } else if (_selectedType != null) {
        requiredDigits = _typeDigitMap[_selectedType] ?? 0;
      }

      if (requiredDigits > 0 &&
          _numberController.text.length == requiredDigits) {
        if (!_countFocusNode.hasFocus) {
          _countFocusNode.requestFocus();
        }
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _numberFocusNode.dispose();
    _countFocusNode.dispose();
    _numberController.removeListener(_autoJumpToCount);
    super.dispose();
  }

  Future<void> _loadData() async {
    final apiService = Provider.of<ApiService>(context, listen: false);
    final user = await apiService.getProfile();
    final bets = await apiService.getBets(gameId: widget.game.id);

    final users = await apiService.getUsers(createdByMe: true);

    setState(() {
      _user = user;
      _users = users;
      if (user != null) {
        // Find the designated 'Default' sub-dealer first
        final defaultUser = users.firstWhere((u) => u.isDefault,
            orElse: () => users.firstWhere((u) => u.role == 'SUB_DEALER',
                orElse: () => UserModel(id: -1, username: '', role: '')));
        _userController.text = defaultUser.username;
      }
      _recentBets = bets;
      _selectedType = 'SUPER';
      _isLoading = false;
      // Focus number field after UI is ready
      _numberFocusNode.requestFocus();
    });
  }

  List<String> _getPermutations(String s) {
    if (s.length <= 1) return [s];
    List<String> perms = [];
    for (int i = 0; i < s.length; i++) {
      String char = s[i];
      String remaining = s.substring(0, i) + s.substring(i + 1);
      for (String p in _getPermutations(remaining)) {
        perms.add(char + p);
      }
    }
    return perms.toSet().toList();
  }

  void _triggerAddToDraft(String type) {
    if (_isRangeEnabled &&
        (_tabController.index == 1 || _tabController.index == 2)) {
      if (_startController.text.isEmpty ||
          _endController.text.isEmpty ||
          _countController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please enter Start, End and Count')));
        return;
      }
      int start = int.tryParse(_startController.text) ?? 0;
      int end = int.tryParse(_endController.text) ?? 0;
      int step = int.tryParse(_stepController.text) ?? 1;
      if (step <= 0) step = 1;

      List<String> rangeNumbers = [];
      int padWidth = _tabController.index == 1 ? 2 : 3;
      for (int i = start; i <= end; i += step) {
        rangeNumbers.add(i.toString().padLeft(padWidth, '0'));
      }

      if (rangeNumbers.isEmpty) return;

      if (type == 'SET' && _tabController.index == 2) {
        setState(() {
          UserModel? selectedUser;
          try {
            selectedUser =
                _users.firstWhere((u) => u.username == _userController.text);
          } catch (_) {
            selectedUser = _user;
          }

          for (String baseNum in rangeNumbers) {
            // Get permutations once for the base number
            List<String> perms = _getPermutations(baseNum);

            // 1. All SUPER permutations
            for (String perm in perms) {
              double unitPrice = selectedUser?.priceSuper ?? 10.0;
              double commRate = selectedUser?.salesCommSuper ?? 0.0;
              int count = int.parse(_countController.text);
              _draftBets.insert(0, {
                'number': perm,
                'count': count,
                'type': 'SUPER',
                'price': unitPrice * count,
                'net_price': (unitPrice - commRate) * count,
              });
            }

            // 2. All BOX permutations
            int boxCount = int.tryParse(_boxCountController.text) ?? 0;
            if (boxCount > 0) {
              for (String perm in perms) {
                double unitPrice = selectedUser?.priceBox ?? 10.0;
                double commRate = selectedUser?.salesCommBox ?? 0.0;
                _draftBets.insert(0, {
                  'number': perm,
                  'count': boxCount,
                  'type': 'BOX',
                  'price': unitPrice * boxCount,
                  'net_price': (unitPrice - commRate) * boxCount,
                });
              }
            }
          }
          _startController.clear();
          _endController.clear();
          _countController.text = '';
          _boxCountController.text = '';
          // Auto-focus back to number field
          _numberFocusNode.requestFocus();
        });
        return;
      }

      List<String> entryTypes = [];

      if (_tabController.index == 1) {
        if (type == 'ALL') {
          entryTypes = ['AB', 'BC', 'AC'];
        } else {
          entryTypes = [type];
        }
      } else {
        // 3 DIGITS (other than SET)
        if (type == 'BOTH') {
          entryTypes = ['SUPER', 'BOX'];
        } else {
          entryTypes = [type];
        }
      }

      setState(() {
        for (String num in rangeNumbers) {
          for (String t in entryTypes) {
            double unitPrice = 10.0;
            UserModel? selectedUser;
            try {
              selectedUser =
                  _users.firstWhere((u) => u.username == _userController.text);
            } catch (_) {
              selectedUser = _user;
            }

            double commRate = 0;
            if (selectedUser != null) {
              if (['AB', 'BC', 'AC'].contains(t)) {
                unitPrice = selectedUser.priceAbBcAc;
                commRate = selectedUser.salesCommAbBcAc;
              } else if (t == 'SUPER') {
                unitPrice = selectedUser.priceSuper;
                commRate = selectedUser.salesCommSuper;
              } else if (t == 'BOX') {
                unitPrice = selectedUser.priceBox;
                commRate = selectedUser.salesCommBox;
              }
            }
            int count = int.parse(_countController.text);
            if (t == 'BOX') {
              count = int.tryParse(_boxCountController.text) ?? count;
            }
            _draftBets.insert(0, {
              'number': num,
              'count': count,
              'type': t,
              'price': unitPrice * count,
              'net_price': (unitPrice - commRate) * count,
            });
          }
        }
        _startController.clear();
        _endController.clear();
        _countController.text = '';
        _boxCountController.text = '';
        // Auto-focus back to number field
        _numberFocusNode.requestFocus();
      });
      return;
    }

    if (_numberController.text.isEmpty || _countController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter number and count first')));
      return;
    }

    int requiredDigits = type == 'ALL'
        ? (_tabController.index == 0 ? 1 : 2)
        : _typeDigitMap[type]!;

    if (_numberController.text.length != requiredDigits) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Digits mismatch! Required: $requiredDigits')));
      return;
    }

    if (type == 'SET') {
      final String originalNum = _numberController.text;
      final List<String> perms = _getPermutations(originalNum);

      setState(() {
        UserModel? selectedUser;
        try {
          selectedUser =
              _users.firstWhere((u) => u.username == _userController.text);
        } catch (_) {
          selectedUser = _user;
        }

        // 1. Add all SUPER permutations
        for (String num in perms) {
          double unitPrice = selectedUser?.priceSuper ?? 10.0;
          double commRate = selectedUser?.salesCommSuper ?? 0.0;
          int count = int.parse(_countController.text);

          _draftBets.insert(0, {
            'number': num,
            'count': count,
            'type': 'SUPER',
            'price': unitPrice * count,
            'net_price': (unitPrice - commRate) * count,
          });
        }

        // 2. Add all BOX permutations
        int boxCount = int.tryParse(_boxCountController.text) ?? 0;
        if (boxCount > 0) {
          for (String num in perms) {
            double unitPrice = selectedUser?.priceBox ?? 10.0;
            double commRate = selectedUser?.salesCommBox ?? 0.0;
            _draftBets.insert(0, {
              'number': num,
              'count': boxCount,
              'type': 'BOX',
              'price': unitPrice * boxCount,
              'net_price': (unitPrice - commRate) * boxCount,
            });
          }
        }

        _numberController.clear();
        _countController.text = '';
        _boxCountController.text = '';
        _startController.clear();
        _endController.clear();
        // Auto-focus back to number field
        _numberFocusNode.requestFocus();
      });
      return;
    }

    List<String> entriesToAdd = [];
    List<String> entryTypes = [];

    if (type == 'BOTH') {
      entriesToAdd = [_numberController.text];
      entryTypes = ['SUPER', 'BOX'];
    } else if (type == 'ALL') {
      entriesToAdd = [_numberController.text];
      entryTypes =
          _tabController.index == 0 ? ['A', 'B', 'C'] : ['AB', 'BC', 'AC'];
    } else {
      entriesToAdd = [_numberController.text];
      entryTypes = [type];
    }

    setState(() {
      for (String num in entriesToAdd) {
        for (String t in entryTypes) {
          double unitPrice = ['A', 'B', 'C'].contains(t) ? 12.0 : 10.0;
          UserModel? selectedUser;
          try {
            selectedUser =
                _users.firstWhere((u) => u.username == _userController.text);
          } catch (_) {
            selectedUser = _user;
          }

          double commRate = 0;
          if (selectedUser != null) {
            if (['A', 'B', 'C'].contains(t)) {
              unitPrice = selectedUser.priceAbc;
              commRate = selectedUser.salesCommAbc;
            } else if (['AB', 'BC', 'AC'].contains(t)) {
              unitPrice = selectedUser.priceAbBcAc;
              commRate = selectedUser.salesCommAbBcAc;
            } else if (t == 'SUPER') {
              unitPrice = selectedUser.priceSuper;
              commRate = selectedUser.salesCommSuper;
            } else if (t == 'BOX') {
              unitPrice = selectedUser.priceBox;
              commRate = selectedUser.salesCommBox;
            }
          }
          int count = int.parse(_countController.text);
          if (t == 'BOX') {
            count = int.tryParse(_boxCountController.text) ?? count;
          }

          _draftBets.insert(0, {
            'number': num,
            'count': count,
            'type': t,
            'price': unitPrice * count,
            'net_price': (unitPrice - commRate) * count,
          });
        }
      }
      _numberController.clear();
      _countController.text = '';
      _boxCountController.text = '';
      _startController.clear();
      _endController.clear();
      // Auto-focus back to number field
      _numberFocusNode.requestFocus();
    });
  }

  void _submitDraftedBets() async {
    if (_draftBets.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('No bets to save')));
      return;
    }

    setState(() => _isSubmitting = true);
    final apiService = Provider.of<ApiService>(context, listen: false);

    try {
      // Find the selected user's ID
      int? targetUserId;
      try {
        targetUserId =
            _users.firstWhere((u) => u.username == _userController.text).id;
      } catch (_) {}

      final result = await apiService.placeBulkBets(widget.game.id, _draftBets,
          userId: targetUserId);
      final invoiceId = result['invoice_id'];
      final failedBets = result['failed_bets'] ?? [];

      final currentDraft = List<Map<String, dynamic>>.from(_draftBets);

      setState(() {
        _isSubmitting = false;
        _draftBets.clear();
      });

      if (mounted) {
        final gameColor =
            Color(int.parse(widget.game.color.replaceFirst('#', '0xFF')));

        if (failedBets.isNotEmpty) {
          // Nav to Not Booked screen
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FailedBetsScreen(
                invoiceId: invoiceId,
                failedBets: failedBets,
                themeColor: gameColor,
              ),
            ),
          );
          return;
        }

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            titlePadding: EdgeInsets.zero,
            title: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: gameColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white, size: 28),
                  SizedBox(width: 12),
                  Text('SUCCESS',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1)),
                ],
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                const Text('Invoice created successfully!',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: gameColor.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: gameColor.withOpacity(0.2)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('INVOICE ID:',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: Colors.grey)),
                      Text(invoiceId,
                          style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: gameColor,
                              letterSpacing: 2)),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  final now = DateTime.now();
                  final dateStr = DateFormat('dd/MM/yyyy').format(now);
                  final timeStr = DateFormat('HH:mm:ss').format(now);
                  final customer = _userController.text.isNotEmpty
                      ? _userController.text
                      : 'Kukku'; // Fallback to provided example if empty

                  // Calculate totals for text report (GROSS TOTAL)
                  double totalInvoiceAmount = 0;
                  int totalCount = 0;
                  String itemsText = "GAME   TYPE   NUM   QTY   TOT\n";

                  for (var b in currentDraft) {
                    final qty = (b['count'] ?? 0);
                    final countInt = (qty is int) ? qty : (qty as num).toInt();
                    // draft fields are 'price' (gross) and 'net_price'
                    final subtotal = (b['price'] ?? 0.0) as double;

                    totalInvoiceAmount += subtotal;
                    totalCount += countInt;

                    itemsText +=
                        "${widget.game.name.padRight(6).substring(0, 6)} ${(b['type'] ?? '').toString().padRight(6)} ${b['number']?.toString().padRight(5)} ${countInt.toString().padRight(5)} ${subtotal.toStringAsFixed(0).padLeft(5)}\n";
                  }

                  String shareText = "INV No : $invoiceId\n"
                      "Date : $dateStr\n"
                      "Customer : $customer\n"
                      "Sales Time : $timeStr\n"
                      "Total Amount : ${totalInvoiceAmount.toStringAsFixed(0)}\n"
                      "Total Count : $totalCount\n\n"
                      "$itemsText";

                  Share.share(shareText);
                },
                style: TextButton.styleFrom(
                  foregroundColor: Colors.green,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.share, size: 18),
                    SizedBox(width: 8),
                    Text('SHARE WHATSAPP',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  foregroundColor: gameColor,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: const Text('DONE',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
        _loadData(); // Refresh history
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showPasteDialog() {
    final TextEditingController textController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('PASTE BET LIST',
            style: TextStyle(
                fontWeight: FontWeight.w900, color: AppColors.primary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Format examples: 123-10, 123*10, 11#20#AB, A,B 1 10, ABC-1-5, ALL-10-10\nWorks with Symbols (* . # , - + / : ; x X)',
              style: TextStyle(fontSize: 10, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: textController,
              maxLines: 10,
              decoration: InputDecoration(
                hintText: 'Paste your list here...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                fillColor: Colors.grey[50],
                filled: true,
              ),
              style: const TextStyle(fontSize: 13, fontFamily: 'monospace'),
            ),
          ],
        ),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('CANCEL')),
              const SizedBox(width: 8),

              ElevatedButton(
                onPressed: () {
                  _processPasteText(textController.text, isRemoval: false);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary, elevation: 2),
                child: const Text('ADD TO DRAFT',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _processPasteText(String text, {bool isRemoval = false}) {
    if (text.trim().isEmpty) return;

    final lines = text.split('\n');
    int processedCount = 0;

    UserModel? selectedUser;
    try {
      selectedUser =
          _users.firstWhere((u) => u.username == _userController.text);
    } catch (_) {
      selectedUser = _user;
    }

    setState(() {
      for (var line in lines) {
        String originalLine = line.trim();
        if (originalLine.isEmpty) continue;

        // 1. Normalize line: treat common symbols as separators and split stuck tokens
        String cleanLine = originalLine.replaceAll(
            RegExp(r'[\*\.\#\,\-\+\/\:\;xX\s\=\%\!]+'), ' ');
        cleanLine = cleanLine.toUpperCase();
        cleanLine = cleanLine.replaceAllMapped(
            RegExp(r'(\d+)([A-Z]+)'), (m) => '${m[1]} ${m[2]}');
        cleanLine = cleanLine.replaceAllMapped(
            RegExp(r'([A-Z]+)(\d+)'), (m) => '${m[1]} ${m[2]}');

        List<String> tokens =
            cleanLine.trim().split(' ').where((t) => t.isNotEmpty).toList();

        if (tokens.isEmpty) continue;

        // --- Helper to handle either add or remove ---
        void handleProcessed(String num, String type, int count) {
          if (isRemoval) {
            int idx = _draftBets.indexWhere((item) =>
                item['number'] == num &&
                item['type'] == type &&
                item['count'] == count);
            if (idx != -1) {
              _draftBets.removeAt(idx);
              processedCount++;
            }
          } else {
            _addSingleBetToDraft(num, type, count, selectedUser);
            processedCount++;
          }
        }

        // --- CASE: 3 DIGITS (SUPER, BOX, SET, BOTH) ---
        int mainNumIdx =
            tokens.indexWhere((t) => RegExp(r'^\d{3}$').hasMatch(t));

        if (mainNumIdx != -1) {
          String num = tokens[mainNumIdx];
          bool isBox = tokens.any((t) =>
              t == 'BOX' || t == 'KBOX' || t == 'B' || t == 'K' || t == 'BOXK');
          bool isSet = tokens
              .any((t) => t == 'SET' || t == 'BB' || t == 'S' || t == 'ST');

          List<int> otherNumbers = [];
          for (int i = 0; i < tokens.length; i++) {
            if (i == mainNumIdx) continue;
            if (RegExp(r'^\d+$').hasMatch(tokens[i])) {
              otherNumbers.add(int.parse(tokens[i]));
            }
          }

          int superCount = 0;
          int boxCount = 0;

          if (isSet) {
            // Permutations mode (SET / BB)
            superCount = otherNumbers.isNotEmpty ? otherNumbers[0] : 0;
            boxCount = otherNumbers.length >= 2 ? otherNumbers[1] : 0;

            if (superCount > 0 || boxCount > 0) {
              List<String> perms = _getPermutations(num);
              for (String p in perms) {
                if (superCount > 0) handleProcessed(p, 'SUPER', superCount);
                if (boxCount > 0) handleProcessed(p, 'BOX', boxCount);
              }
            }
          } else {
            // Single Bet Mode (Standard for 123*10)
            if (isBox) {
              boxCount = otherNumbers.isNotEmpty ? otherNumbers[0] : 0;
            } else {
              if (otherNumbers.length >= 2) {
                superCount = otherNumbers[0];
                boxCount = otherNumbers[1];
              } else if (otherNumbers.isNotEmpty) {
                superCount = otherNumbers[0];
              }
            }

            if (superCount > 0) handleProcessed(num, 'SUPER', superCount);
            if (boxCount > 0) handleProcessed(num, 'BOX', boxCount);
          }
          continue;
        }

        // --- CASE: DOUBLE/SINGLE (Keywords first or implicit) ---
        List<String> typesFound = [];
        for (var t in tokens) {
          if (t == 'ABC') {
            typesFound.addAll(['A', 'B', 'C']);
          } else if (t == 'ALL') {
            if (_tabController.index == 0) typesFound.addAll(['A', 'B', 'C']);
            if (_tabController.index == 1)
              typesFound.addAll(['AB', 'BC', 'AC']);
          } else if (['A', 'B', 'C', 'AB', 'BC', 'AC'].contains(t)) {
            typesFound.add(t);
          }
        }
        typesFound = typesFound.toSet().toList(); // Unique

        if (typesFound.isNotEmpty) {
          List<String> numTokens =
              tokens.where((t) => RegExp(r'^\d+$').hasMatch(t)).toList();

          if (numTokens.length >= 2) {
            String targetNumber = numTokens[numTokens.length - 2];
            int targetCount = int.parse(numTokens.last);

            for (var t in typesFound) {
              int reqLen = ['A', 'B', 'C'].contains(t) ? 1 : 2;
              String finalNum = targetNumber.padLeft(reqLen, '0');
              if (finalNum.length > reqLen) {
                finalNum = finalNum.substring(0, reqLen);
              }
              handleProcessed(finalNum, t, targetCount);
            }
          } else if (numTokens.length == 1 &&
              _countController.text.isNotEmpty) {
            String targetNumber = numTokens[0];
            int targetCount = int.tryParse(_countController.text) ?? 5;

            for (var t in typesFound) {
              int reqLen = ['A', 'B', 'C'].contains(t) ? 1 : 2;
              String finalNum = targetNumber.padLeft(reqLen, '0');
              if (finalNum.length > reqLen) {
                finalNum = finalNum.substring(0, reqLen);
              }
              handleProcessed(finalNum, t, targetCount);
            }
          }
          continue;
        } else {
          List<String> numTokens =
              tokens.where((t) => RegExp(r'^\d+$').hasMatch(t)).toList();
          if (numTokens.length >= 2) {
            String num = numTokens[0];
            int count = int.parse(numTokens.last);
            String t =
                num.length == 1 ? 'A' : (num.length == 2 ? 'AB' : 'SUPER');
            handleProcessed(num, t, count);
          }
        }
      }
    });

    if (processedCount > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isRemoval
              ? 'Removed $processedCount bets from draft'
              : 'Added $processedCount bets to draft'),
          backgroundColor: isRemoval ? Colors.red[400] : Colors.green[600],
        ),
      );
    }
  }

  void _addSingleBetToDraft(
      String num, String type, int count, UserModel? user) {
    if (count <= 0) return;

    double unitPrice = ['A', 'B', 'C'].contains(type) ? 12.0 : 10.0;
    double commRate = 0;

    if (user != null) {
      if (['A', 'B', 'C'].contains(type)) {
        unitPrice = user.priceAbc;
        commRate = user.salesCommAbc;
      } else if (['AB', 'BC', 'AC'].contains(type)) {
        unitPrice = user.priceAbBcAc;
        commRate = user.salesCommAbBcAc;
      } else if (type == 'SUPER') {
        unitPrice = user.priceSuper;
        commRate = user.salesCommSuper;
      } else if (type == 'BOX') {
        unitPrice = user.priceBox;
        commRate = user.salesCommBox;
      }
    }

    _draftBets.insert(0, {
      'number': num,
      'count': count,
      'type': type,
      'price': unitPrice * count,
      'net_price': (unitPrice - commRate) * count,
    });
  }

  @override
  Widget build(BuildContext context) {
    final gameColor =
        Color(int.parse(widget.game.color.replaceFirst('#', '0xFF')));
    return Scaffold(
      appBar: AppBar(
        backgroundColor: gameColor,
        title: Text(widget.game.name),
        bottom: TabBar(
          controller: _tabController,
          indicator: UnderlineTabIndicator(
            borderSide: const BorderSide(width: 4, color: Colors.yellowAccent),
            insets: const EdgeInsets.symmetric(horizontal: 16),
          ),
          tabs: const [
            Tab(text: '1 DIGIT'),
            Tab(text: '2 DIGITS'),
            Tab(text: '3 DIGITS'),
          ],
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withOpacity(0.6),
          labelStyle: const TextStyle(
              fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1),
          unselectedLabelStyle:
              const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        actions: [
          if (!_isLoading) ...[
            IconButton(
              onPressed: _showPasteDialog,
              icon: const Icon(Icons.content_paste_search_rounded,
                  color: Colors.white),
              tooltip: 'Paste Bets',
            ),
            IconButton(
              onPressed: () {
                if (_draftBets.isNotEmpty) {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      title: const Text('Clear Draft?'),
                      content: const Text(
                          'This will remove all items from your current draft.'),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('CANCEL')),
                        TextButton(
                          onPressed: () {
                            setState(() => _draftBets.clear());
                            Navigator.pop(context);
                          },
                          child: const Text('CLEAR',
                              style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  );
                }
              },
              icon: const Icon(Icons.delete_forever_rounded,
                  color: Colors.white70),
              tooltip: 'Clear Draft',
            ),
            const SizedBox(width: 8),
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ElevatedButton(
                onPressed: (_isSubmitting || _draftBets.isEmpty)
                    ? null
                    : _submitDraftedBets,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.yellowAccent,
                  foregroundColor: Colors.black,
                  disabledBackgroundColor: Colors.white12,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  elevation: 4,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            color: Colors.black, strokeWidth: 2),
                      )
                    : const Text(
                        'SAVE',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 12),
          ],
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Container(
              color: Colors.grey[50],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      border: Border(bottom: BorderSide(color: Colors.black12)),
                    ),
                    child: _buildInputSection(),
                  ),
                  Expanded(
                    child: _buildDraftContainer(borderRadius: 0),
                  ),
                ],
              ),
            ),
      bottomNavigationBar: _buildStickyBottomBar(),
    );
  }

  Widget _buildInputSection() {
    final themeColor =
        Color(int.parse(widget.game.color.replaceFirst('#', '0xFF')));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _customerController,
                decoration: _inputDecoration(
                    label: 'Customer',
                    hint: 'Name/ID',
                    icon: Icons.person_outline),
              ),
            ),
            if (_user?.role != 'SUB_DEALER') const SizedBox(width: 12),
            if (_user?.role != 'SUB_DEALER')
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _users
                          .where((u) =>
                              u.id != _user?.id && u.role == 'SUB_DEALER')
                          .any((u) => u.username == _userController.text)
                      ? _userController.text
                      : null,
                  items: _users
                      .where((u) => u.id != _user?.id && u.role == 'SUB_DEALER')
                      .map((u) => DropdownMenuItem(
                            value: u.username,
                            child: Text(u.username,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                          ))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _userController.text = val;
                        // Recalculate draft prices for the NEW selected user
                        try {
                          final selectedUser =
                              _users.firstWhere((u) => u.username == val);
                          for (var bet in _draftBets) {
                            String t = bet['type'];
                            int count = bet['count'];
                            double uPrice = 10.0;
                            double cRate = 0.0;

                            if (['A', 'B', 'C'].contains(t)) {
                              uPrice = selectedUser.priceAbc;
                              cRate = selectedUser.salesCommAbc;
                            } else if (['AB', 'BC', 'AC'].contains(t)) {
                              uPrice = selectedUser.priceAbBcAc;
                              cRate = selectedUser.salesCommAbBcAc;
                            } else if (t == 'SUPER') {
                              uPrice = selectedUser.priceSuper;
                              cRate = selectedUser.salesCommSuper;
                            } else if (t == 'BOX') {
                              uPrice = selectedUser.priceBox;
                              cRate = selectedUser.salesCommBox;
                            }

                            bet['price'] = uPrice * count;
                            bet['net_price'] = (uPrice - cRate) * count;
                          }
                        } catch (_) {}
                      });
                    }
                  },
                  decoration: _inputDecoration(
                    label: 'Agent/Admin',
                    hint: 'Select User',
                    icon: Icons.admin_panel_settings_outlined,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        if (_isRangeEnabled &&
            (_tabController.index == 1 || _tabController.index == 2))
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _startController,
                  keyboardType: TextInputType.number,
                  decoration: _inputDecoration(
                      label: 'Start',
                      hint: _tabController.index == 1 ? '00' : '000'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _endController,
                  keyboardType: TextInputType.number,
                  decoration: _inputDecoration(
                      label: 'End',
                      hint: _tabController.index == 1 ? '99' : '999'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _stepController,
                  keyboardType: TextInputType.number,
                  decoration: _inputDecoration(label: 'Step', hint: '1'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _countController,
                  keyboardType: TextInputType.number,
                  decoration: _inputDecoration(label: 'Count', hint: 'Qty'),
                  style: const TextStyle(
                      fontWeight: FontWeight.w900, fontSize: 18),
                ),
              ),
              if (_tabController.index == 2) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _boxCountController,
                    keyboardType: TextInputType.number,
                    decoration:
                        _inputDecoration(label: 'Box Count', hint: 'Qty'),
                  ),
                ),
              ],
            ],
          )
        else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 1,
                child: TextField(
                  controller: _numberController,
                  focusNode: _numberFocusNode,
                  keyboardType: TextInputType.number,
                  maxLength: _selectedType == 'ALL'
                      ? (_tabController.index == 0 ? 1 : 2)
                      : _typeDigitMap[_selectedType],
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2),
                  decoration: _inputDecoration(label: 'Number', hint: 'Digits'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _countController,
                  focusNode: _countFocusNode,
                  keyboardType: TextInputType.number,
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: themeColor),
                  decoration: _inputDecoration(label: 'Count', hint: 'Qty'),
                ),
              ),
              if (_tabController.index == 2) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _boxCountController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Colors.blue),
                    decoration:
                        _inputDecoration(label: 'Box Count', hint: 'Qty'),
                  ),
                ),
              ],
              if (_tabController.index == 1 || _tabController.index == 2) ...[
                const SizedBox(width: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Transform.scale(
                      scale: 0.9,
                      child: Checkbox(
                        value: _isRangeEnabled,
                        activeColor: themeColor,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4)),
                        onChanged: (val) {
                          setState(() {
                            _isRangeEnabled = val ?? false;
                          });
                        },
                      ),
                    ),
                    const Text('R',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w900)),
                  ],
                ),
              ],
            ],
          ),
        if (_isRangeEnabled &&
            (_tabController.index == 1 || _tabController.index == 2))
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Text('Disable Range (R)'),
                Switch(
                  value: _isRangeEnabled,
                  activeColor: Color(
                      int.parse(widget.game.color.replaceFirst('#', '0xFF'))),
                  onChanged: (val) {
                    setState(() {
                      _isRangeEnabled = val;
                    });
                  },
                ),
              ],
            ),
          ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          alignment: WrapAlignment.start,
          children: _tabsMap[_tabController.index]!
              .map((type) => AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 82,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () => _triggerAddToDraft(type),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: themeColor,
                        foregroundColor: Colors.white,
                        elevation: 4,
                        shadowColor: themeColor.withOpacity(0.4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: EdgeInsets.zero,
                      ),
                      child: Text(type,
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5)),
                    ),
                  ))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildDraftSidebar() {
    return Container(); // No longer used
  }

  Widget _buildRecentBets() {
    if (_recentBets.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _recentBets
          .take(6)
          .map((bet) => Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('${bet.number} (${bet.type})',
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.bold)),
              ))
          .toList(),
    );
  }

  Widget _buildDraftContainer({double elevation = 0, double borderRadius = 0}) {
    final gameColor =
        Color(int.parse(widget.game.color.replaceFirst('#', '0xFF')));
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Column(
        children: [
          // Premium Colored Table Header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
            decoration: BoxDecoration(
              color: gameColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                const Expanded(
                  flex: 3,
                  child: Text('TYPE',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                          letterSpacing: 0.5)),
                ),
                const Expanded(
                  flex: 3,
                  child: Text('NUMBER',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                          letterSpacing: 0.5)),
                ),
                const Expanded(
                  flex: 2,
                  child: Text('QTY',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                          letterSpacing: 0.5)),
                ),
                const Expanded(
                  flex: 3,
                  child: Text('NET',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                          letterSpacing: 0.5),
                      textAlign: TextAlign.right),
                ),
                const SizedBox(width: 48), // Padding for the delete button
              ],
            ),
          ),

          if (_draftBets.isEmpty)
            Container(
              padding: const EdgeInsets.all(40),
              width: double.infinity,
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.shopping_basket_outlined,
                        size: 48, color: gameColor.withOpacity(0.2)),
                    const SizedBox(height: 12),
                    Text('No bets in draft',
                        style: TextStyle(
                            color: Colors.grey[400],
                            fontWeight: FontWeight.bold,
                            fontSize: 16)),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: _draftBets.length,
              itemBuilder: (context, index) {
                final draft = _draftBets[index];
                final isEven = index % 2 == 0;
                return Container(
                  decoration: BoxDecoration(
                    color: isEven ? Colors.white : gameColor.withOpacity(0.04),
                    border: Border(
                      bottom: BorderSide(
                          color: gameColor.withOpacity(0.1), width: 0.5),
                    ),
                  ),
                  padding:
                      const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text(
                          _formatTypeName(draft['type']),
                          style: TextStyle(
                            color: gameColor.withOpacity(0.8),
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          draft['number'],
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: Colors.black,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          draft['count'].toString(),
                          style: TextStyle(
                            color: gameColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          (draft['net_price'] ?? draft['price'])
                              .toStringAsFixed(1),
                          style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                      // Delete Button
                      Container(
                        width: 48,
                        alignment: Alignment.centerRight,
                        child: IconButton(
                          icon: Icon(Icons.remove_circle_outline_rounded,
                              color: Colors.red[300], size: 22),
                          onPressed: () =>
                              setState(() => _draftBets.removeAt(index)),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          splashRadius: 20,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _formatTypeName(String type) {
    if (type == 'SUPER') return 'LSK-SUPER';
    if (type == 'BOX') return 'BOX';
    return type;
  }

  Widget _buildStickyBottomBar() {
    if (_isLoading || _draftBets.isEmpty) return const SizedBox.shrink();

    final gameColor =
        Color(int.parse(widget.game.color.replaceFirst('#', '0xFF')));
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      decoration: BoxDecoration(
        color: gameColor,
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Total Qty: ${_draftBets.fold<int>(0, (sum, item) => sum + (item['count'] as int))}',
                style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w900),
              ),
              const Text('Grand Total',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Total: ₹${_draftBets.fold<double>(0, (sum, item) => sum + item['price']).toStringAsFixed(2)}',
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white70),
              ),
              Text(
                'Net: ₹${_draftBets.fold<double>(0, (sum, item) => sum + (item['net_price'] ?? item['price'])).toStringAsFixed(2)}',
                style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.yellowAccent),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title) {
    return Text(title,
        style: const TextStyle(
            fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey));
  }

  InputDecoration _inputDecoration(
      {String? label, String? hint, IconData? icon}) {
    final themeColor =
        Color(int.parse(widget.game.color.replaceFirst('#', '0xFF')));
    return InputDecoration(
      labelText: label,
      hintText: hint,
      counterText: "",
      prefixIcon:
          icon != null ? Icon(icon, color: themeColor.withOpacity(0.7)) : null,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
      ),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      filled: true,
      fillColor: Colors.grey[50],
      labelStyle: TextStyle(
          color: Colors.grey[600], fontWeight: FontWeight.bold, fontSize: 11),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: themeColor, width: 2),
      ),
    );
  }
}
