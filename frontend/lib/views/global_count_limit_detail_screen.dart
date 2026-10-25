import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../models/game_model.dart';
import '../models/user_model.dart';
import '../utils/constants.dart';

class GlobalCountLimitDetailScreen extends StatefulWidget {
  final GameModel game;
  final int initialTab;
  final UserModel? user;
  const GlobalCountLimitDetailScreen(
      {super.key, required this.game, this.initialTab = 0, this.user});

  @override
  State<GlobalCountLimitDetailScreen> createState() =>
      _GlobalCountLimitDetailScreenState();
}

class _GlobalCountLimitDetailScreenState
    extends State<GlobalCountLimitDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  // KL Controllers
  late TextEditingController _countA;
  late TextEditingController _countB;
  late TextEditingController _countC;
  late TextEditingController _countAB;
  late TextEditingController _countBC;
  late TextEditingController _countAC;
  late TextEditingController _countSuper;
  late TextEditingController _countBox;

  // Rush Time Controllers
  late TextEditingController _rushTimeMinutes;
  late TextEditingController _rushTimeMaxCount;

  // KL Rush Controllers
  late TextEditingController _rushCountA;
  late TextEditingController _rushCountB;
  late TextEditingController _rushCountC;
  late TextEditingController _rushCountAB;
  late TextEditingController _rushCountBC;
  late TextEditingController _rushCountAC;
  late TextEditingController _rushCountSuper;
  late TextEditingController _rushCountBox;

  // TN Rush Controllers
  late TextEditingController _rushTnCountA;
  late TextEditingController _rushTnCountB;
  late TextEditingController _rushTnCountC;
  late TextEditingController _rushTnCountAB;
  late TextEditingController _rushTnCountBC;
  late TextEditingController _rushTnCountAC;
  late TextEditingController _rushTnCount3d10;
  late TextEditingController _rushTnCount3d25;
  late TextEditingController _rushTnCount3d30;
  late TextEditingController _rushTnCount3d60;
  late TextEditingController _rushTnCount4d110;
  late TextEditingController _rushTnCount4d55;
  late TextEditingController _rushTnCount4d20;

  // TN Controllers
  late TextEditingController _globalTnCountA;
  late TextEditingController _globalTnCountB;
  late TextEditingController _globalTnCountC;
  late TextEditingController _globalTnCountAB;
  late TextEditingController _globalTnCountBC;
  late TextEditingController _globalTnCountAC;
  late TextEditingController _globalTnCount3d10;
  late TextEditingController _globalTnCount3d25;
  late TextEditingController _globalTnCount3d30;
  late TextEditingController _globalTnCount3d60;
  late TextEditingController _globalTnCount4d110;
  late TextEditingController _globalTnCount4d55;
  late TextEditingController _globalTnCount4d20;

  bool _isLoading = false;

  // Global Number Limits Tab Data
  List<dynamic> _globalNumberLimits = [];
  bool _isLoadingNumbers = true;
  UserModel? _user;

  // Betting-Screen style Quick Number Limit Add
  int _selectedDigitTab = 2; // 0: 1-Digit, 1: 2-Digit, 2: 3-Digit, 3: 4-Digit
  final TextEditingController _quickNumberController = TextEditingController();
  final TextEditingController _quickCountController = TextEditingController();
  final FocusNode _quickNumberFocusNode = FocusNode();
  final FocusNode _quickCountFocusNode = FocusNode();
  bool _isQuickSubmitting = false;

  void _autoJumpQuickNumber() {
    int reqDigits = _selectedDigitTab + 1;
    if (_quickNumberController.text.length == reqDigits) {
      _quickCountFocusNode.requestFocus();
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController =
        TabController(length: 2, vsync: this, initialIndex: widget.initialTab);
    // KL
    _countA = TextEditingController(text: widget.game.globalCountA.toString());
    _countB = TextEditingController(text: widget.game.globalCountB.toString());
    _countC = TextEditingController(text: widget.game.globalCountC.toString());
    _countAB =
        TextEditingController(text: widget.game.globalCountAb.toString());
    _countBC =
        TextEditingController(text: widget.game.globalCountBc.toString());
    _countAC =
        TextEditingController(text: widget.game.globalCountAc.toString());
    _countSuper =
        TextEditingController(text: widget.game.globalCountSuper.toString());
    _countBox =
        TextEditingController(text: widget.game.globalCountBox.toString());

    // TN
    _globalTnCountA =
        TextEditingController(text: widget.game.globalTnCountA.toString());
    _globalTnCountB =
        TextEditingController(text: widget.game.globalTnCountB.toString());
    _globalTnCountC =
        TextEditingController(text: widget.game.globalTnCountC.toString());
    _globalTnCountAB =
        TextEditingController(text: widget.game.globalTnCountAb.toString());
    _globalTnCountBC =
        TextEditingController(text: widget.game.globalTnCountBc.toString());
    _globalTnCountAC =
        TextEditingController(text: widget.game.globalTnCountAc.toString());
    _globalTnCount3d10 =
        TextEditingController(text: widget.game.globalTnCount3d10.toString());
    _globalTnCount3d25 =
        TextEditingController(text: widget.game.globalTnCount3d25.toString());
    _globalTnCount3d30 =
        TextEditingController(text: widget.game.globalTnCount3d30.toString());
    _globalTnCount3d60 =
        TextEditingController(text: widget.game.globalTnCount3d60.toString());
    _globalTnCount4d110 =
        TextEditingController(text: widget.game.globalTnCount4d110.toString());
    _globalTnCount4d55 =
        TextEditingController(text: widget.game.globalTnCount4d55.toString());
    _globalTnCount4d20 =
        TextEditingController(text: widget.game.globalTnCount4d20.toString());

    _rushTimeMinutes = TextEditingController(
        text: widget.game.rushTimeMinutes > 0 ? widget.game.rushTimeMinutes.toString() : '0');
    _rushTimeMaxCount = TextEditingController(
        text: widget.game.rushTimeMaxCount > 0 ? widget.game.rushTimeMaxCount.toString() : '0');
    _rushTimeMinutes.addListener(() => setState(() {}));
    _rushTimeMaxCount.addListener(() => setState(() {}));

    // Rush KL
    _rushCountA = TextEditingController(text: widget.game.rushCountA.toString());
    _rushCountB = TextEditingController(text: widget.game.rushCountB.toString());
    _rushCountC = TextEditingController(text: widget.game.rushCountC.toString());
    _rushCountAB = TextEditingController(text: widget.game.rushCountAb.toString());
    _rushCountBC = TextEditingController(text: widget.game.rushCountBc.toString());
    _rushCountAC = TextEditingController(text: widget.game.rushCountAc.toString());
    _rushCountSuper = TextEditingController(text: widget.game.rushCountSuper.toString());
    _rushCountBox = TextEditingController(text: widget.game.rushCountBox.toString());

    // Rush TN
    _rushTnCountA = TextEditingController(text: widget.game.rushTnCountA.toString());
    _rushTnCountB = TextEditingController(text: widget.game.rushTnCountB.toString());
    _rushTnCountC = TextEditingController(text: widget.game.rushTnCountC.toString());
    _rushTnCountAB = TextEditingController(text: widget.game.rushTnCountAb.toString());
    _rushTnCountBC = TextEditingController(text: widget.game.rushTnCountBc.toString());
    _rushTnCountAC = TextEditingController(text: widget.game.rushTnCountAc.toString());
    _rushTnCount3d10 = TextEditingController(text: widget.game.rushTnCount3d10.toString());
    _rushTnCount3d25 = TextEditingController(text: widget.game.rushTnCount3d25.toString());
    _rushTnCount3d30 = TextEditingController(text: widget.game.rushTnCount3d30.toString());
    _rushTnCount3d60 = TextEditingController(text: widget.game.rushTnCount3d60.toString());
    _rushTnCount4d110 = TextEditingController(text: widget.game.rushTnCount4d110.toString());
    _rushTnCount4d55 = TextEditingController(text: widget.game.rushTnCount4d55.toString());
    _rushTnCount4d20 = TextEditingController(text: widget.game.rushTnCount4d20.toString());

    _user = widget.user;
    if (_user != null && _user!.effectiveGameMode == 'TN') {
      _selectedNumberLimitTab = 1;
    }

    _quickNumberController.addListener(_autoJumpQuickNumber);

    _loadGlobalNumberLimits();
  }

  Future<void> _loadGlobalNumberLimits() async {
    setState(() => _isLoadingNumbers = true);
    final apiService = Provider.of<ApiService>(context, listen: false);
    try {
      final limits = await apiService.getGlobalNumberLimits(widget.game.id);
      UserModel? user = _user;
      if (user == null) {
        user = await apiService.getProfile();
      }
      if (mounted) {
        setState(() {
          _user = user;
          if (user != null && user.effectiveGameMode == 'TN') {
            _selectedNumberLimitTab = 1;
          }
          _globalNumberLimits = limits;
          _isLoadingNumbers = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading number limits: $e')),
        );
      }
      setState(() => _isLoadingNumbers = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _countA.dispose();
    _countB.dispose();
    _countC.dispose();
    _countAB.dispose();
    _countBC.dispose();
    _countAC.dispose();
    _countSuper.dispose();
    _countBox.dispose();

    _globalTnCountA.dispose();
    _globalTnCountB.dispose();
    _globalTnCountC.dispose();
    _globalTnCountAB.dispose();
    _globalTnCountBC.dispose();
    _globalTnCountAC.dispose();
    _globalTnCount3d10.dispose();
    _globalTnCount3d25.dispose();
    _globalTnCount3d30.dispose();
    _globalTnCount3d60.dispose();
    _globalTnCount4d110.dispose();
    _globalTnCount4d55.dispose();
    _globalTnCount4d20.dispose();
    _rushTimeMinutes.dispose();
    _rushTimeMaxCount.dispose();
    _rushCountA.dispose();
    _rushCountB.dispose();
    _rushCountC.dispose();
    _rushCountAB.dispose();
    _rushCountBC.dispose();
    _rushCountAC.dispose();
    _rushCountSuper.dispose();
    _rushCountBox.dispose();
    _rushTnCountA.dispose();
    _rushTnCountB.dispose();
    _rushTnCountC.dispose();
    _rushTnCountAB.dispose();
    _rushTnCountBC.dispose();
    _rushTnCountAC.dispose();
    _rushTnCount3d10.dispose();
    _rushTnCount3d25.dispose();
    _rushTnCount3d30.dispose();
    _rushTnCount3d60.dispose();
    _rushTnCount4d110.dispose();
    _rushTnCount4d55.dispose();
    _rushTnCount4d20.dispose();
    _quickNumberController.dispose();
    _quickCountController.dispose();
    _quickNumberFocusNode.dispose();
    _quickCountFocusNode.dispose();
    super.dispose();
  }

  Future<void> _updateTypeLimits() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final apiService = Provider.of<ApiService>(context, listen: false);

    try {
      final updatedData = {
        // KL
        'global_count_a': int.parse(_countA.text),
        'global_count_b': int.parse(_countB.text),
        'global_count_c': int.parse(_countC.text),
        'global_count_ab': int.parse(_countAB.text),
        'global_count_bc': int.parse(_countBC.text),
        'global_count_ac': int.parse(_countAC.text),
        'global_count_super': int.parse(_countSuper.text),
        'global_count_box': int.parse(_countBox.text),
        // TN
        'global_tn_count_a': int.parse(_globalTnCountA.text),
        'global_tn_count_b': int.parse(_globalTnCountB.text),
        'global_tn_count_c': int.parse(_globalTnCountC.text),
        'global_tn_count_ab': int.parse(_globalTnCountAB.text),
        'global_tn_count_bc': int.parse(_globalTnCountBC.text),
        'global_tn_count_ac': int.parse(_globalTnCountAC.text),
        'global_tn_count_3d_10': int.parse(_globalTnCount3d10.text),
        'global_tn_count_3d_25': int.parse(_globalTnCount3d25.text),
        'global_tn_count_3d_30': int.parse(_globalTnCount3d30.text),
        'global_tn_count_3d_60': int.parse(_globalTnCount3d60.text),
        'global_tn_count_4d_110': int.parse(_globalTnCount4d110.text),
        'global_tn_count_4d_55': int.parse(_globalTnCount4d55.text),
        'global_tn_count_4d_20': int.parse(_globalTnCount4d20.text),
        'rush_time_minutes': int.tryParse(_rushTimeMinutes.text.trim()) ?? 0,
        'rush_time_max_count': int.tryParse(_rushTimeMaxCount.text.trim()) ?? 0,
        'rush_count_a': int.tryParse(_rushCountA.text.trim()) ?? 0,
        'rush_count_b': int.tryParse(_rushCountB.text.trim()) ?? 0,
        'rush_count_c': int.tryParse(_rushCountC.text.trim()) ?? 0,
        'rush_count_ab': int.tryParse(_rushCountAB.text.trim()) ?? 0,
        'rush_count_bc': int.tryParse(_rushCountBC.text.trim()) ?? 0,
        'rush_count_ac': int.tryParse(_rushCountAC.text.trim()) ?? 0,
        'rush_count_super': int.tryParse(_rushCountSuper.text.trim()) ?? 0,
        'rush_count_box': int.tryParse(_rushCountBox.text.trim()) ?? 0,
        'rush_tn_count_a': int.tryParse(_rushTnCountA.text.trim()) ?? 0,
        'rush_tn_count_b': int.tryParse(_rushTnCountB.text.trim()) ?? 0,
        'rush_tn_count_c': int.tryParse(_rushTnCountC.text.trim()) ?? 0,
        'rush_tn_count_ab': int.tryParse(_rushTnCountAB.text.trim()) ?? 0,
        'rush_tn_count_bc': int.tryParse(_rushTnCountBC.text.trim()) ?? 0,
        'rush_tn_count_ac': int.tryParse(_rushTnCountAC.text.trim()) ?? 0,
        'rush_tn_count_3d_10': int.tryParse(_rushTnCount3d10.text.trim()) ?? 0,
        'rush_tn_count_3d_25': int.tryParse(_rushTnCount3d25.text.trim()) ?? 0,
        'rush_tn_count_3d_30': int.tryParse(_rushTnCount3d30.text.trim()) ?? 0,
        'rush_tn_count_3d_60': int.tryParse(_rushTnCount3d60.text.trim()) ?? 0,
        'rush_tn_count_4d_110': int.tryParse(_rushTnCount4d110.text.trim()) ?? 0,
        'rush_tn_count_4d_55': int.tryParse(_rushTnCount4d55.text.trim()) ?? 0,
        'rush_tn_count_4d_20': int.tryParse(_rushTnCount4d20.text.trim()) ?? 0,
      };

      await apiService.updateGame(widget.game.id, updatedData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Global type limits updated successfully!'),
              backgroundColor: Colors.green),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error updating limits: $e'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
            '${widget.game.name} ${widget.initialTab == 1 ? "Number Counts" : "Count Limits"}',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: widget.initialTab == 1
          ? _buildNumberCountTab()
          : _buildTypeLimitsTab(),
    );
  }

  Widget _buildTypeLimitsTab() {
    if (_user == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildRushTimeCard(),
              const SizedBox(height: 16),
              if (_user!.isKlEnabled) ...[
                _buildKlSection(),
                const SizedBox(height: 16),
              ],
              if (_user!.isTnEnabled) ...[
                _buildTnSection(),
                const SizedBox(height: 16),
              ],
              const SizedBox(height: 16),
              _buildUpdateButton(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRushTimeCard() {
    int minutes = int.tryParse(_rushTimeMinutes.text.trim()) ?? 0;
    bool isActive = minutes > 0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isActive ? Colors.amber.shade800 : Colors.grey.shade300,
          width: isActive ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isActive ? Colors.amber.shade800 : Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.timer_rounded, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'RUSH TIME LIMIT (LAST MINUTES)',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                        color: isActive ? Colors.brown.shade900 : Colors.black87,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      'End Time: ${widget.game.endTime}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isActive ? Colors.green.shade50 : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: isActive ? Colors.green.shade300 : Colors.grey.shade300,
                  ),
                ),
                child: Text(
                  isActive ? 'ACTIVE' : 'OFF',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: isActive ? Colors.green.shade800 : Colors.grey.shade600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'അവസാന മിനിറ്റുകളിൽ ഓരോ ടൈപ്പിനും പരമാവധി കയറാവുന്ന കൗണ്ട് ഇവിടെ സെറ്റ് ചെയ്യാം (0 നൽകിയാൽ ലിമിറ്റ് ഉണ്ടാവില്ല).',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 12),
          // Last minutes input
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Last Minutes (സമയം)',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    const SizedBox(height: 4),
                    TextFormField(
                      controller: _rushTimeMinutes,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
                      decoration: InputDecoration(
                        hintText: 'e.g. 10',
                        suffixText: 'Min',
                        filled: true,
                        fillColor: Colors.amber.shade50.withOpacity(0.4),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: BorderSide(color: Colors.amber.shade800, width: 1.5),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // KL Rush Limit Section
          if (_user!.isKlEnabled) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blue.shade50.withOpacity(0.35),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.primary.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: const Text('KL',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11)),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'KL RUSH LIMITS (LAST MINUTES)',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _buildSectionTitle('KL 3 Digit Rush Limits', AppColors.primary),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(child: _buildLimitField('SUPER', _rushCountSuper, Icons.star_rounded, AppColors.primary)),
                      const SizedBox(width: 8),
                      Expanded(child: _buildLimitField('BOX', _rushCountBox, Icons.inventory_2_rounded, AppColors.primary)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _buildSectionTitle('KL 2 Digit Rush Limits', AppColors.primary),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(child: _buildLimitField('AB', _rushCountAB, Icons.filter_2_rounded, AppColors.primary)),
                      const SizedBox(width: 8),
                      Expanded(child: _buildLimitField('BC', _rushCountBC, Icons.filter_2_rounded, AppColors.primary)),
                      const SizedBox(width: 8),
                      Expanded(child: _buildLimitField('AC', _rushCountAC, Icons.filter_2_rounded, AppColors.primary)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _buildSectionTitle('KL Single Digit Rush Limits', AppColors.primary),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(child: _buildLimitField('A', _rushCountA, Icons.looks_one_rounded, AppColors.primary)),
                      const SizedBox(width: 8),
                      Expanded(child: _buildLimitField('B', _rushCountB, Icons.looks_two_rounded, AppColors.primary)),
                      const SizedBox(width: 8),
                      Expanded(child: _buildLimitField('C', _rushCountC, Icons.looks_3_rounded, AppColors.primary)),
                    ],
                  ),
                ],
              ),
            ),
          ],

          // TN Rush Limit Section
          if (_user!.isTnEnabled) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.deepOrange.shade50.withOpacity(0.35),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.deepOrange.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.deepOrange,
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: const Text('TN',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11)),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'TN RUSH LIMITS (LAST MINUTES)',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 12, color: Colors.deepOrange),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _buildSectionTitle('TN 3 Digit Rush Limits', Colors.deepOrange),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(child: _buildLimitField('3D-10', _rushTnCount3d10, Icons.star_rounded, Colors.deepOrange)),
                      const SizedBox(width: 8),
                      Expanded(child: _buildLimitField('3D-25', _rushTnCount3d25, Icons.star_rounded, Colors.deepOrange)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(child: _buildLimitField('3D-30', _rushTnCount3d30, Icons.star_rounded, Colors.deepOrange)),
                      const SizedBox(width: 8),
                      Expanded(child: _buildLimitField('3D-60', _rushTnCount3d60, Icons.star_rounded, Colors.deepOrange)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _buildSectionTitle('TN 4 Digit Rush Limits', Colors.deepOrange),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(child: _buildLimitField('4D-110', _rushTnCount4d110, Icons.inventory_2_rounded, Colors.deepOrange)),
                      const SizedBox(width: 8),
                      Expanded(child: _buildLimitField('4D-55', _rushTnCount4d55, Icons.inventory_2_rounded, Colors.deepOrange)),
                      const SizedBox(width: 8),
                      Expanded(child: _buildLimitField('4D-20', _rushTnCount4d20, Icons.inventory_2_rounded, Colors.deepOrange)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _buildSectionTitle('TN 2 Digit Rush Limits', Colors.deepOrange),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(child: _buildLimitField('AB', _rushTnCountAB, Icons.filter_2_rounded, Colors.deepOrange)),
                      const SizedBox(width: 8),
                      Expanded(child: _buildLimitField('BC', _rushTnCountBC, Icons.filter_2_rounded, Colors.deepOrange)),
                      const SizedBox(width: 8),
                      Expanded(child: _buildLimitField('AC', _rushTnCountAC, Icons.filter_2_rounded, Colors.deepOrange)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _buildSectionTitle('TN Single Digit Rush Limits', Colors.deepOrange),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(child: _buildLimitField('A', _rushTnCountA, Icons.looks_one_rounded, Colors.deepOrange)),
                      const SizedBox(width: 8),
                      Expanded(child: _buildLimitField('B', _rushTnCountB, Icons.looks_two_rounded, Colors.deepOrange)),
                      const SizedBox(width: 8),
                      Expanded(child: _buildLimitField('C', _rushTnCountC, Icons.looks_3_rounded, Colors.deepOrange)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildKlSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border:
            Border.all(color: AppColors.primary.withOpacity(0.3), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'KL',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 12),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'KERALA GLOBAL LIMITS',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: AppColors.primary,
                    letterSpacing: 0.5),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildSectionTitle('Single Digit Limits'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                  child: _buildLimitField(
                      'A Count', _countA, Icons.looks_one_rounded)),
              const SizedBox(width: 8),
              Expanded(
                  child: _buildLimitField(
                      'B Count', _countB, Icons.looks_two_rounded)),
              const SizedBox(width: 8),
              Expanded(
                  child: _buildLimitField(
                      'C Count', _countC, Icons.looks_3_rounded)),
            ],
          ),
          const SizedBox(height: 14),
          _buildSectionTitle('Double Digit Limits'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                  child: _buildLimitField(
                      'AB Count', _countAB, Icons.filter_2_rounded)),
              const SizedBox(width: 8),
              Expanded(
                  child: _buildLimitField(
                      'BC Count', _countBC, Icons.filter_2_rounded)),
              const SizedBox(width: 8),
              Expanded(
                  child: _buildLimitField(
                      'AC Count', _countAC, Icons.filter_2_rounded)),
            ],
          ),
          const SizedBox(height: 14),
          _buildSectionTitle('Three Digit Limits'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                  child: _buildLimitField(
                      'SUPER Count', _countSuper, Icons.star_rounded)),
              const SizedBox(width: 8),
              Expanded(
                  child: _buildLimitField(
                      'BOX Count', _countBox, Icons.inventory_2_rounded)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTnSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border:
            Border.all(color: Colors.deepOrange.withOpacity(0.3), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.deepOrange,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'TN',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 12),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'TAMIL NADU GLOBAL LIMITS',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Colors.deepOrange,
                    letterSpacing: 0.5),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildSectionTitle('TN Single Digit Limits', Colors.deepOrange),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                  child: _buildLimitField('A Count', _globalTnCountA,
                      Icons.looks_one_rounded, Colors.deepOrange)),
              const SizedBox(width: 8),
              Expanded(
                  child: _buildLimitField('B Count', _globalTnCountB,
                      Icons.looks_two_rounded, Colors.deepOrange)),
              const SizedBox(width: 8),
              Expanded(
                  child: _buildLimitField('C Count', _globalTnCountC,
                      Icons.looks_3_rounded, Colors.deepOrange)),
            ],
          ),
          const SizedBox(height: 14),
          _buildSectionTitle('TN Double Digit Limits', Colors.deepOrange),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                  child: _buildLimitField('AB Count', _globalTnCountAB,
                      Icons.filter_2_rounded, Colors.deepOrange)),
              const SizedBox(width: 8),
              Expanded(
                  child: _buildLimitField('BC Count', _globalTnCountBC,
                      Icons.filter_2_rounded, Colors.deepOrange)),
              const SizedBox(width: 8),
              Expanded(
                  child: _buildLimitField('AC Count', _globalTnCountAC,
                      Icons.filter_2_rounded, Colors.deepOrange)),
            ],
          ),
          const SizedBox(height: 14),
          _buildSectionTitle('TN 3 Digit Limits', Colors.deepOrange),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                  child: _buildLimitField('3D-10', _globalTnCount3d10,
                      Icons.star_rounded, Colors.deepOrange)),
              const SizedBox(width: 8),
              Expanded(
                  child: _buildLimitField('3D-25', _globalTnCount3d25,
                      Icons.star_rounded, Colors.deepOrange)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                  child: _buildLimitField('3D-30', _globalTnCount3d30,
                      Icons.star_rounded, Colors.deepOrange)),
              const SizedBox(width: 8),
              Expanded(
                  child: _buildLimitField('3D-60', _globalTnCount3d60,
                      Icons.star_rounded, Colors.deepOrange)),
            ],
          ),
          const SizedBox(height: 14),
          _buildSectionTitle('TN 4 Digit Limits', Colors.deepOrange),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                  child: _buildLimitField('4D-110', _globalTnCount4d110,
                      Icons.inventory_2_rounded, Colors.deepOrange)),
              const SizedBox(width: 8),
              Expanded(
                  child: _buildLimitField('4D-55', _globalTnCount4d55,
                      Icons.inventory_2_rounded, Colors.deepOrange)),
              const SizedBox(width: 8),
              Expanded(
                  child: _buildLimitField('4D-20', _globalTnCount4d20,
                      Icons.inventory_2_rounded, Colors.deepOrange)),
            ],
          ),
        ],
      ),
    );
  }

  int _selectedNumberLimitTab = 0; // 0 for KL, 1 for TN

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

  Widget _buildNumberCountTab() {
    final klLimits =
        _globalNumberLimits.where((l) => _klTypes.contains(l['type'])).toList();
    final tnLimits =
        _globalNumberLimits.where((l) => _tnTypes.contains(l['type'])).toList();

    final isTn = _selectedNumberLimitTab == 1;
    final currentLimits = isTn ? tnLimits : klLimits;
    final activeColor = isTn ? Colors.deepOrange : AppColors.primary;

    if (_user != null && _user!.effectiveGameMode == 'TN') {
      _selectedNumberLimitTab = 1;
    } else if (_user != null && _user!.effectiveGameMode == 'KL') {
      _selectedNumberLimitTab = 0;
    }

    return Column(
      children: [
        // Sub-tabs for KL and TN only if subscribed to both
        if (_user != null && _user!.isBothEnabled)
        Container(
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(6),
                  onTap: () => setState(() => _selectedNumberLimitTab = 0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: _selectedNumberLimitTab == 0
                          ? AppColors.primary
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'KL LIMITS (${klLimits.length})',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _selectedNumberLimitTab == 0
                            ? Colors.white
                            : Colors.grey.shade700,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(6),
                  onTap: () => setState(() => _selectedNumberLimitTab = 1),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: _selectedNumberLimitTab == 1
                          ? Colors.deepOrange
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'TN LIMITS (${tnLimits.length})',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _selectedNumberLimitTab == 1
                            ? Colors.white
                            : Colors.grey.shade700,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Betting-Screen-style quick input bar
        _buildQuickInputSection(isTn, activeColor),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isTn ? 'Active Tamil Nadu Number Limits (${currentLimits.length})' : 'Active Kerala Number Limits (${currentLimits.length})',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: activeColor),
              ),
            ],
          ),
        ),
        if (currentLimits.isNotEmpty) _buildTableHeader(activeColor),
        Expanded(
          child: _isLoadingNumbers
              ? const Center(child: CircularProgressIndicator())
              : currentLimits.isEmpty
                  ? _buildEmptyState(isTn
                      ? 'No TN Number Limits Set'
                      : 'No KL Number Limits Set')
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                      itemCount: currentLimits.length,
                      itemBuilder: (context, index) {
                        final limit = currentLimits[index];
                        return _buildNumberLimitCard(limit, activeColor);
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

      for (var t in targetTypes) {
        await apiService.createGlobalNumberLimit(widget.game.id, number, t, count);
      }

      await _loadGlobalNumberLimits();
      _quickNumberController.clear();
      _quickNumberFocusNode.requestFocus();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Limit added: $number [$btn] -> $count'),
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

  Widget _buildNumberLimitCard(dynamic limit, Color badgeColor) {
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
              child: _buildTypeBadge(limit['type'], badgeColor),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              '${limit['number']}',
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
              '${limit['max_count']}',
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
                InkWell(
                  onTap: () => _showAddNumberLimitDialog(limit: limit),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child:
                        Icon(Icons.edit_outlined, color: Colors.blue, size: 18),
                  ),
                ),
                const SizedBox(width: 4),
                InkWell(
                  onTap: () => _confirmDeleteNumberLimit(limit['id']),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(Icons.delete_outline_rounded,
                        color: Colors.red, size: 18),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeBadge(String type, [Color color = AppColors.primary]) {
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

  void _showAddNumberLimitDialog({dynamic limit, bool isTn = false}) {
    final bool isEditing = limit != null;
    final bool isTnLimit = isEditing ? _tnTypes.contains(limit['type']) : isTn;
    final types = isTnLimit ? _tnTypes.toList() : _klTypes.toList();

    final numController =
        TextEditingController(text: isEditing ? limit['number'] : '');
    final countController = TextEditingController(
        text: isEditing ? limit['max_count'].toString() : '');
    String selectedType =
        isEditing ? limit['type'] : (isTnLimit ? '3D-10' : 'SUPER');

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
          content: Column(
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
                  labelText: 'Max System Count',
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
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

                // Digit validation
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

                // Ensure no non-numeric multi-numbers
                if (int.tryParse(numController.text) == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Please enter a valid single number')),
                  );
                  return;
                }

                final apiService =
                    Provider.of<ApiService>(context, listen: false);
                bool success;
                if (isEditing) {
                  success =
                      await apiService.updateGlobalNumberLimit(limit['id'], {
                    'type': selectedType,
                    'max_count': int.parse(countController.text),
                  });
                } else {
                  success = await apiService.createGlobalNumberLimit(
                    widget.game.id,
                    numController.text,
                    selectedType,
                    int.parse(countController.text),
                  );
                }

                if (success) {
                  Navigator.pop(context);
                  _loadGlobalNumberLimits();
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

  Future<void> _confirmDeleteNumberLimit(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Limit?'),
        content: const Text(
            'Are you sure you want to remove this system-wide number limit?'),
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
      final success = await apiService.deleteGlobalNumberLimit(id);
      if (success) _loadGlobalNumberLimits();
    }
  }

  Widget _buildSectionTitle(String title, [Color color = AppColors.primary]) {
    return Text(
      title.toUpperCase(),
      style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: color,
          letterSpacing: 0.5),
    );
  }

  Widget _buildLimitField(String label, TextEditingController controller,
      [IconData? icon, Color activeColor = AppColors.primary]) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      style: const TextStyle(
          fontWeight: FontWeight.w900, fontSize: 13, color: Colors.black87),
      decoration: InputDecoration(
        labelText: label.toUpperCase(),
        labelStyle: TextStyle(
            color: activeColor,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.2),
        floatingLabelBehavior: FloatingLabelBehavior.always,
        filled: true,
        fillColor: Colors.white,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        prefixIcon:
            icon != null ? Icon(icon, size: 14, color: activeColor) : null,
        prefixIconConstraints: icon != null
            ? const BoxConstraints(minWidth: 24, minHeight: 24)
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: activeColor, width: 1.5),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return 'Enter value';
        if (int.tryParse(value) == null) return 'Invalid';
        return null;
      },
    );
  }

  Widget _buildUpdateButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _updateTypeLimits,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          elevation: 4,
          shadowColor: AppColors.primary.withOpacity(0.4),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2))
            : const Text('UPDATE GLOBAL TYPE LIMITS',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1)),
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
          Text(msg,
              style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 16,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
