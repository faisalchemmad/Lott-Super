import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
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
    with TickerProviderStateMixin {
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
  bool _is100Enabled = false;
  bool _is111Enabled = false;
  bool _isTnSetChecked = false;
  String _selectedStateCode = 'KL';
  Timer? _timer;
  Duration _remainingTime = Duration.zero;
  final TextEditingController _startController = TextEditingController();
  final TextEditingController _endController = TextEditingController();
  final TextEditingController _stepController =
      TextEditingController(text: '1');
  final FocusNode _numberFocusNode = FocusNode();
  final FocusNode _countFocusNode = FocusNode();
  final FocusNode _startFocusNode = FocusNode();
  final FocusNode _endFocusNode = FocusNode();
  final FocusNode _stepFocusNode = FocusNode();
  final FocusNode _boxCountFocusNode = FocusNode();

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
    '3D-10': 3,
    '3D-25': 3,
    '3D-30': 3,
    '3D-60': 3,
    '4D-110': 4,
    '4D-55': 4,
    '4D-20': 4,
  };

  final Map<int, List<String>> _tabsMap = {
    0: ['A', 'B', 'C', 'ALL'],
    1: ['AB', 'BC', 'AC', 'ALL'],
    2: ['SUPER', 'BOX', 'SET', 'BOTH'],
    3: ['SUPER', 'BOX', 'SET', 'BOTH'],
  };

  List<String> _getButtonsForTab(int tabIndex) {
    if (_selectedStateCode == 'TN') {
      if (tabIndex == 2) {
        return ['3D-10', '3D-25', '3D-30', '3D-60'];
      } else if (tabIndex == 3) {
        return ['4D-110', '4D-55', '4D-20'];
      }
    }
    return _tabsMap[tabIndex]!;
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: 2);
    _tabController.addListener(_tabListener);
    _numberController.addListener(_autoJumpToCount);
    _loadData();
    _startTimer();
  }

  void _startTimer() {
    try {
      final now = DateTime.now();
      final parts = widget.game.endTime.split(':');
      if (parts.length >= 2) {
        int hour = int.parse(parts[0]);
        int minute = int.parse(parts[1]);
        int second = parts.length > 2 ? int.parse(parts[2]) : 0;
        
        DateTime endDateTime = DateTime(now.year, now.month, now.day, hour, minute, second);
        
        if (endDateTime.isBefore(now)) {
          _remainingTime = Duration.zero;
        } else {
          _remainingTime = endDateTime.difference(now);
          _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
            if (mounted) {
              setState(() {
                if (_remainingTime.inSeconds > 0) {
                  _remainingTime -= const Duration(seconds: 1);
                } else {
                  _timer?.cancel();
                }
              });
            }
          });
        }
      }
    } catch (e) {
      // Ignore parsing errors
    }
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(d.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(d.inSeconds.remainder(60));
    return "${twoDigits(d.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  void _tabListener() {
    if (_tabController.indexIsChanging) return;
    setState(() {
      _selectedType = _getButtonsForTab(_tabController.index)[0];
      _numberController.clear();
      _countController.clear();
      _boxCountController.clear();
      _numberFocusNode.requestFocus();
    });
  }

  int _getRequiredDigits(String? type) {
    if (type == 'ALL') {
      return _tabController.index == 0 ? 1 : 2;
    }
    if (_tabController.index == 3) {
      return 4;
    }
    return _typeDigitMap[type ?? ''] ?? 3;
  }

  void _autoJumpToCount() {
    if (_numberController.text.isNotEmpty) {
      int requiredDigits = _getRequiredDigits(_selectedType);
      if (requiredDigits > 0 &&
          _numberController.text.length == requiredDigits) {
        if (!_countFocusNode.hasFocus) {
          _countFocusNode.requestFocus();
        }
      }
    }
  }

  int _getRangeDigits() {
    return _tabController.index == 1 ? 2 : 3;
  }

  void _autoJumpStartToEnd() {
    if (_startController.text.length == _getRangeDigits()) {
      _endFocusNode.requestFocus();
    }
  }

  void _autoJumpEndToStep() {
    if (_endController.text.length == _getRangeDigits()) {
      _countFocusNode.requestFocus(); // Skipping step as per usual lotto apps, or wait, user usually skips step. Let's jump to count.
    }
  }

  void _autoJumpStepToCount() {
    if (_stepController.text.length == 1) {
      _countFocusNode.requestFocus();
    }
  }

  void _autoJumpCountToBox() {
    if (_countController.text.length == 3) {
      if (_tabController.index >= 2) {
        _boxCountFocusNode.requestFocus();
      } else {
        _countFocusNode.unfocus();
      }
    }
  }

  void _autoJumpBoxToDone() {
    if (_boxCountController.text.length == 3) {
      _boxCountFocusNode.unfocus();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
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
    if (_countController.text.isNotEmpty) {
      int cVal = int.tryParse(_countController.text) ?? 0;
      int bVal = int.tryParse(_boxCountController.text) ?? 0;
      if (cVal == 0 && bVal == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('0 Count Not Allowed')));
        return;
      }
    }

    bool isSpecialMode = (_isRangeEnabled || _is100Enabled || _is111Enabled) &&
        (_tabController.index >= 1);

    if (isSpecialMode) {
      List<String> rangeNumbers = [];

      if (_is111Enabled) {
        if (_countController.text.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Please enter Count')));
          return;
        }
        if (_tabController.index == 3) {
          rangeNumbers = ['0000', '1111', '2222', '3333', '4444', '5555', '6666', '7777', '8888', '9999'];
        } else if (_tabController.index == 2) {
          rangeNumbers = ['000', '111', '222', '333', '444', '555', '666', '777', '888', '999'];
        } else if (_tabController.index == 1) {
          rangeNumbers = ['00', '11', '22', '33', '44', '55', '66', '77', '88', '99'];
        }
      } else if (_is100Enabled) {
        if (_countController.text.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Please enter Count')));
          return;
        }
        if (_tabController.index == 3) {
          rangeNumbers = ['0000', '1000', '2000', '3000', '4000', '5000', '6000', '7000', '8000', '9000'];
        } else if (_tabController.index == 2) {
          rangeNumbers = ['000', '100', '200', '300', '400', '500', '600', '700', '800', '900'];
        } else if (_tabController.index == 1) {
          rangeNumbers = ['00', '10', '20', '30', '40', '50', '60', '70', '80', '90'];
        }
      } else if (_isRangeEnabled) {
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

        int padWidth = _tabController.index == 1 ? 2 : 3;
        for (int i = start; i <= end; i += step) {
          rangeNumbers.add(i.toString().padLeft(padWidth, '0'));
        }
      }

      if (rangeNumbers.isEmpty) return;

      if (type == 'SET' && _tabController.index >= 2) {
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
              if (count > 0) {
                _draftBets.insert(0, {
                  'number': perm,
                  'count': count,
                  'type': 'SUPER',
                  'price': unitPrice * count,
                  'net_price': (unitPrice - commRate) * count,
                });
              }
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

    int requiredDigits = _getRequiredDigits(type);

    if (_numberController.text.length != requiredDigits) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Digits mismatch! Required: $requiredDigits')));
      return;
    }

    if (type == 'SET' || (_selectedStateCode == 'TN' && _isTnSetChecked && _tabController.index >= 2)) {
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

        if (type == 'SET') {
          // 1. Add all SUPER permutations
          for (String num in perms) {
            double unitPrice = selectedUser?.priceSuper ?? 10.0;
            double commRate = selectedUser?.salesCommSuper ?? 0.0;
            int count = int.parse(_countController.text);

            if (count > 0) {
              _draftBets.insert(0, {
                'number': num,
                'count': count,
                'type': 'SUPER',
                'price': unitPrice * count,
                'net_price': (unitPrice - commRate) * count,
              });
            }
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
        } else {
          // TN Custom Type Permutations (e.g. 3D-10)
          for (String num in perms) {
            double unitPrice = 0.0;
            double commRate = 0.0;
            if (selectedUser != null) {
              if (type == '3D-10') { unitPrice = selectedUser.tnPrice3d10; commRate = selectedUser.tnSalesComm3d10; }
              else if (type == '3D-25') { unitPrice = selectedUser.tnPrice3d25; commRate = selectedUser.tnSalesComm3d25; }
              else if (type == '3D-30') { unitPrice = selectedUser.tnPrice3d30; commRate = selectedUser.tnSalesComm3d30; }
              else if (type == '3D-60') { unitPrice = selectedUser.tnPrice3d60; commRate = selectedUser.tnSalesComm3d60; }
              else if (type == '4D-110') { unitPrice = selectedUser.tnPrice4d110; commRate = selectedUser.tnSalesComm4d110; }
              else if (type == '4D-55') { unitPrice = selectedUser.tnPrice4d55; commRate = selectedUser.tnSalesComm4d55; }
              else if (type == '4D-20') { unitPrice = selectedUser.tnPrice4d20; commRate = selectedUser.tnSalesComm4d20; }
            }
            int count = int.parse(_countController.text);

            if (count > 0) {
              _draftBets.insert(0, {
                'number': num,
                'count': count,
                'type': type,
                'price': unitPrice * count,
                'net_price': (unitPrice - commRate) * count,
              });
            }
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

          if (count > 0) {
            _draftBets.insert(0, {
              'number': num,
              'count': count,
              'type': t,
              'price': unitPrice * count,
              'net_price': (unitPrice - commRate) * count,
            });
          }
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
      bool isTN = _selectedStateCode == 'TN';
      if (isTN) {
        if (type == '3D-10') { unitPrice = user.tnPrice3d10; commRate = user.tnSalesComm3d10; }
        else if (type == '3D-25') { unitPrice = user.tnPrice3d25; commRate = user.tnSalesComm3d25; }
        else if (type == '3D-30') { unitPrice = user.tnPrice3d30; commRate = user.tnSalesComm3d30; }
        else if (type == '3D-60') { unitPrice = user.tnPrice3d60; commRate = user.tnSalesComm3d60; }
        else if (type == '4D-110') { unitPrice = user.tnPrice4d110; commRate = user.tnSalesComm4d110; }
        else if (type == '4D-55') { unitPrice = user.tnPrice4d55; commRate = user.tnSalesComm4d55; }
        else if (type == '4D-20') { unitPrice = user.tnPrice4d20; commRate = user.tnSalesComm4d20; }
        else if (['A', 'B', 'C'].contains(type)) {
          unitPrice = user.tnPriceAbc; commRate = user.tnSalesCommAbc;
        } else if (['AB', 'BC', 'AC'].contains(type)) {
          unitPrice = user.tnPriceAbBcAc; commRate = user.tnSalesCommAbBcAc;
        } else if (type == 'SUPER') {
          unitPrice = user.priceSuper; commRate = user.salesCommSuper;
        } else if (type == 'BOX') {
          unitPrice = user.priceBox; commRate = user.salesCommBox;
        }
      } else {
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
    }

    _draftBets.insert(0, {
      'number': num,
      'count': count,
      'type': type,
      'state': _selectedStateCode,
      'price': unitPrice * count,
      'net_price': (unitPrice - commRate) * count,
    });
  }

  @override
  Widget build(BuildContext context) {
    final gameColor =
        Color(int.parse(widget.game.color.replaceFirst('#', '0xFF')));
    return Scaffold(
      endDrawer: _buildEndDrawer(),
      appBar: AppBar(
        backgroundColor: gameColor,
        title: Row(
          children: [
            Text(widget.game.name),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF9EACB0), // Casio LCD pale green/grey background
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.black54, width: 1.5),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    offset: Offset(1, 1),
                    blurRadius: 1,
                  ),
                ],
              ),
              child: Text(
                _formatDuration(_remainingTime),
                style: GoogleFonts.shareTechMono(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF1A1A1A), // Dark text like LCD
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ],
        ),
        actions: [
          if (!_isLoading) ...[
            IconButton(
              onPressed: _showPasteDialog,
              icon: const Icon(Icons.content_paste_search_rounded,
                  color: Colors.white),
              tooltip: 'Paste Bets',
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
                  padding: const EdgeInsets.symmetric(horizontal: 16),
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
                          fontSize: 16,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                Container(
                  color: Colors.grey[50],
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Color(int.parse(widget.game.optionsBgColor.replaceFirst('#', '0xFF'))),
                          border: const Border(bottom: BorderSide(color: Colors.black12)),
                        ),
                        child: _buildInputSection(),
                      ),
                      Expanded(
                        child: _buildDraftContainer(borderRadius: 0),
                      ),
                      _buildStickyBottomBar(),
                    ],
                  ),
                ),
                Builder(
                  builder: (context) {
                    return Positioned(
                      right: 0,
                      top: MediaQuery.of(context).size.height / 3.5,
                      child: GestureDetector(
                        onTap: () => Scaffold.of(context).openEndDrawer(),
                        onHorizontalDragUpdate: (details) {
                          if (details.primaryDelta! < -2) {
                            Scaffold.of(context).openEndDrawer();
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 12),
                          decoration: BoxDecoration(
                            color: gameColor,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(8),
                              bottomLeft: Radius.circular(8),
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black38,
                                offset: Offset(-2, 2),
                                blurRadius: 4,
                              )
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.arrow_back_ios_rounded, color: Colors.white, size: 10),
                              RotatedBox(
                                quarterTurns: 3,
                                child: Text(
                                  _selectedStateCode,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 2),
                            ],
                          ),
                        ),
                      ),
                    );
                  }
                ),
              ],
            ),
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

                            bool isTN = _selectedStateCode == 'TN';
                            if (isTN) {
                              if (t == '3D-10') { uPrice = selectedUser.tnPrice3d10; cRate = selectedUser.tnSalesComm3d10; }
                              else if (t == '3D-25') { uPrice = selectedUser.tnPrice3d25; cRate = selectedUser.tnSalesComm3d25; }
                              else if (t == '3D-30') { uPrice = selectedUser.tnPrice3d30; cRate = selectedUser.tnSalesComm3d30; }
                              else if (t == '3D-60') { uPrice = selectedUser.tnPrice3d60; cRate = selectedUser.tnSalesComm3d60; }
                              else if (t == '4D-110') { uPrice = selectedUser.tnPrice4d110; cRate = selectedUser.tnSalesComm4d110; }
                              else if (t == '4D-55') { uPrice = selectedUser.tnPrice4d55; cRate = selectedUser.tnSalesComm4d55; }
                              else if (t == '4D-20') { uPrice = selectedUser.tnPrice4d20; cRate = selectedUser.tnSalesComm4d20; }
                              else if (['A', 'B', 'C'].contains(t)) {
                                uPrice = selectedUser.tnPriceAbc; cRate = selectedUser.tnSalesCommAbc;
                              } else if (['AB', 'BC', 'AC'].contains(t)) {
                                uPrice = selectedUser.tnPriceAbBcAc; cRate = selectedUser.tnSalesCommAbBcAc;
                              } else if (t == 'SUPER') {
                                uPrice = selectedUser.priceSuper; cRate = selectedUser.salesCommSuper;
                              } else if (t == 'BOX') {
                                uPrice = selectedUser.priceBox; cRate = selectedUser.salesCommBox;
                              }
                            } else {
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
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildDigitSelector(),
              if (_tabController.index >= 1)
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                    Transform.scale(
                  scale: 0.9,
                  child: Checkbox(
                    value: _is100Enabled,
                    activeColor: themeColor,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4)),
                    onChanged: (val) {
                      setState(() {
                        if (val == true) {
                          _is100Enabled = true;
                          _is111Enabled = false;
                          _isRangeEnabled = false;
                          _isTnSetChecked = false;
                        } else {
                          _is100Enabled = false;
                        }
                      });
                    },
                  ),
                ),
                Text((_selectedStateCode == 'TN' && _tabController.index == 3) ? '1000' : '100',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w900)),
                const SizedBox(width: 12),
                Transform.scale(
                  scale: 0.9,
                  child: Checkbox(
                    value: _is111Enabled,
                    activeColor: themeColor,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4)),
                    onChanged: (val) {
                      setState(() {
                        if (val == true) {
                          _is111Enabled = true;
                          _is100Enabled = false;
                          _isRangeEnabled = false;
                          _isTnSetChecked = false;
                        } else {
                          _is111Enabled = false;
                        }
                      });
                    },
                  ),
                ),
                Text((_selectedStateCode == 'TN' && _tabController.index == 3) ? '1111' : '111',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w900)),
                const SizedBox(width: 12),
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
                        if (val == true) {
                          _isRangeEnabled = true;
                          _is100Enabled = false;
                          _is111Enabled = false;
                          _isTnSetChecked = false;
                        } else {
                          _isRangeEnabled = false;
                        }
                      });
                    },
                  ),
                ),
                const Text('R',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w900)),
                if (_selectedStateCode == 'TN' && _tabController.index >= 2) ...[
                  const SizedBox(width: 12),
                  Transform.scale(
                    scale: 0.9,
                    child: Checkbox(
                      value: _isTnSetChecked,
                      activeColor: themeColor,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4)),
                      onChanged: (val) {
                        setState(() {
                          if (val == true) {
                            _isTnSetChecked = true;
                            _is100Enabled = false;
                            _is111Enabled = false;
                            _isRangeEnabled = false;
                          } else {
                            _isTnSetChecked = false;
                          }
                        });
                      },
                    ),
                  ),
                  const Text('SET',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w900)),
                ],
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (_isRangeEnabled &&
            (_tabController.index >= 1))
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: _startController,
                  focusNode: _startFocusNode,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  maxLength: _getRangeDigits(),
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w900),
                  decoration: _inputDecoration(
                      label: 'Start',
                      hint: _tabController.index == 1 ? '00' : '000'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _endController,
                  focusNode: _endFocusNode,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  maxLength: _getRangeDigits(),
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w900),
                  decoration: _inputDecoration(
                      label: 'End',
                      hint: _tabController.index == 1 ? '99' : '999'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _stepController,
                  focusNode: _stepFocusNode,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  maxLength: 2,
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w900),
                  decoration: _inputDecoration(label: 'Step', hint: '1'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _countController,
                  focusNode: _countFocusNode,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  maxLength: 3,
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: themeColor),
                  decoration: _inputDecoration(label: 'Count', hint: 'Qty'),
                ),
              ),
              if (_tabController.index >= 2) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _boxCountController,
                    focusNode: _boxCountFocusNode,
                    keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  maxLength: 3,
                    style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Colors.blue),
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
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  maxLength: _getRequiredDigits(_selectedType),
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
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  maxLength: 3,
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: themeColor),
                  decoration: _inputDecoration(label: 'Count', hint: 'Qty'),
                ),
              ),
              if (_tabController.index >= 2) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _boxCountController,
                    focusNode: _boxCountFocusNode,
                    keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  maxLength: 3,
                    style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Colors.blue),
                    decoration:
                        _inputDecoration(label: 'Box Count', hint: 'Qty'),
                  ),
                ),
              ],
            ],
          ),

        const SizedBox(height: 20),
        Row(
          children: _getButtonsForTab(_tabController.index)
              .map((type) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        height: 40,
                        child: ElevatedButton(
                          onPressed: () => _triggerAddToDraft(type),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: themeColor,
                            foregroundColor: Colors.white,
                            elevation: 4,
                            shadowColor: themeColor.withOpacity(0.4),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: EdgeInsets.zero,
                          ),
                          child: Text(type,
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0)),
                        ),
                      ),
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
                      const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
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
                        width: 40,
                        alignment: Alignment.centerRight,
                        child: InkWell(
                          onTap: () => setState(() => _draftBets.removeAt(index)),
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: Icon(Icons.remove_circle_outline_rounded,
                                color: Colors.red[300], size: 20),
                          ),
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
    return '${widget.game.name}-$type';
  }

  Widget _buildStickyBottomBar() {
    if (_isLoading) return const SizedBox.shrink();

    final gameColor =
        Color(int.parse(widget.game.color.replaceFirst('#', '0xFF')));
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
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
        children: [
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Qty', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    Text(
                      '${_draftBets.fold<int>(0, (sum, item) => sum + (item['count'] as int))}',
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Total', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    Text(
                      '₹${_draftBets.fold<double>(0, (sum, item) => sum + item['price']).toStringAsFixed(0)}',
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Net', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    Text(
                      '₹${_draftBets.fold<double>(0, (sum, item) => sum + (item['net_price'] ?? item['price'])).toStringAsFixed(0)}',
                      style: const TextStyle(color: Colors.yellowAccent, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDigitSelector() {
    return AnimatedBuilder(
      animation: _tabController,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(_selectedStateCode == 'TN' ? 4 : 3, (i) => i).map((index) {
              final isSelected = _tabController.index == index;
              return GestureDetector(
                onTap: () {
                  _tabController.animateTo(index);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.yellowAccent : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: isSelected ? Colors.black : Colors.grey.shade700,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
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
      border: const OutlineInputBorder(borderRadius: BorderRadius.zero),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
      ),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      filled: true,
      fillColor: Colors.grey[50],
      labelStyle: TextStyle(
          color: Colors.grey[600], fontWeight: FontWeight.bold, fontSize: 11),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: themeColor, width: 2),
      ),
    );
  }

  void _changeState(String stateCode) {
    if (_selectedStateCode == stateCode) return;
    setState(() {
      _selectedStateCode = stateCode;
      int length = stateCode == 'TN' ? 4 : 3;
      int newIndex = _tabController.index;
      if (newIndex >= length) newIndex = length - 1;
      
      _tabController.removeListener(_tabListener);
      _tabController.dispose();
      _tabController = TabController(length: length, vsync: this, initialIndex: newIndex);
      _tabController.addListener(_tabListener);
    });
  }

  Widget _buildEndDrawer() {
    final gameColor = Color(int.parse(widget.game.color.replaceFirst('#', '0xFF')));
    return Drawer(
      width: 250,
      child: Container(
        color: Colors.white,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: gameColor),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: const [
                  Text('Select State', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            ListTile(
              title: const Text('KL (Kerala)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              trailing: _selectedStateCode == 'KL' ? const Icon(Icons.check_circle, color: Colors.green) : null,
              onTap: () {
                _changeState('KL');
                Navigator.pop(context);
              },
            ),
            const Divider(),
            ListTile(
              title: const Text('TN (Tamil Nadu)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              trailing: _selectedStateCode == 'TN' ? const Icon(Icons.check_circle, color: Colors.green) : null,
              onTap: () {
                _changeState('TN');
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStateSelector() {
    return Container(
      margin: EdgeInsets.zero,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: ['KL', 'TN'].map((stateCode) {
          final isSelected = _selectedStateCode == stateCode;
          return GestureDetector(
            onTap: () {
              if (_selectedStateCode == stateCode) return;
              setState(() {
                _selectedStateCode = stateCode;
                int length = stateCode == 'TN' ? 4 : 3;
                int newIndex = _tabController.index;
                if (newIndex >= length) newIndex = length - 1;
                
                _tabController.removeListener(_tabListener);
                _tabController.dispose();
                _tabController = TabController(length: length, vsync: this, initialIndex: newIndex);
                _tabController.addListener(_tabListener);
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected ? Colors.yellowAccent : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  stateCode,
                  style: TextStyle(
                    color: isSelected ? Colors.black : Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
