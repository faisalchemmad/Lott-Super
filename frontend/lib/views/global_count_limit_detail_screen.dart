import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../models/game_model.dart';
import '../utils/constants.dart';

class GlobalCountLimitDetailScreen extends StatefulWidget {
  final GameModel game;
  final int initialTab;
  const GlobalCountLimitDetailScreen(
      {super.key, required this.game, this.initialTab = 0});

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

    _loadGlobalNumberLimits();
  }

  Future<void> _loadGlobalNumberLimits() async {
    setState(() => _isLoadingNumbers = true);
    final apiService = Provider.of<ApiService>(context, listen: false);
    try {
      final limits = await apiService.getGlobalNumberLimits(widget.game.id);
      setState(() {
        _globalNumberLimits = limits;
        _isLoadingNumbers = false;
      });
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
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildKlSection(),
              const SizedBox(height: 16),
              _buildTnSection(),
              const SizedBox(height: 24),
              _buildUpdateButton(),
              const SizedBox(height: 20),
            ],
          ),
        ),
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

  Widget _buildNumberCountTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Number Limits List',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary),
              ),
              ElevatedButton.icon(
                onPressed: _showAddNumberLimitDialog,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('ADD LIMIT'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6)),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _isLoadingNumbers
              ? const Center(child: CircularProgressIndicator())
              : _globalNumberLimits.isEmpty
                  ? _buildEmptyState('No Global Number Limits Set')
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _globalNumberLimits.length,
                      itemBuilder: (context, index) {
                        final limit = _globalNumberLimits[index];
                        return _buildNumberLimitCard(limit);
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildNumberLimitCard(dynamic limit) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 4,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          _buildTypeBadge(limit['type']),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Number: ${limit['number']}',
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C3E50)),
                ),
                const SizedBox(height: 2),
                Text(
                  'System Max: ${limit['max_count']} counts',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Colors.blue, size: 20),
            onPressed: () => _showAddNumberLimitDialog(limit: limit),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded,
                color: Colors.red, size: 20),
            onPressed: () => _confirmDeleteNumberLimit(limit['id']),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeBadge(String type) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        type,
        style: const TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
            fontSize: 12),
      ),
    );
  }

  void _showAddNumberLimitDialog({dynamic limit}) {
    final bool isEditing = limit != null;
    final numController =
        TextEditingController(text: isEditing ? limit['number'] : '');
    final countController = TextEditingController(
        text: isEditing ? limit['max_count'].toString() : '');
    String selectedType = isEditing ? limit['type'] : 'SUPER';
    final types = ['A', 'B', 'C', 'AB', 'BC', 'AC', 'SUPER', 'BOX'];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
              isEditing
                  ? 'Edit Global Number Limit'
                  : 'Add Global Number Limit',
              style: const TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: selectedType,
                decoration: const InputDecoration(labelText: 'Bet Type'),
                items: types
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (val) => setDialogState(() => selectedType = val!),
              ),
              TextField(
                controller: numController,
                decoration:
                    const InputDecoration(labelText: 'Number (1-3 digits)'),
                keyboardType: TextInputType.number,
                enabled:
                    !isEditing, // Usually don't change the number itself when editing a limit
              ),
              TextField(
                controller: countController,
                decoration:
                    const InputDecoration(labelText: 'Max System Count'),
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
                if (numController.text.isEmpty || countController.text.isEmpty)
                  return;

                // Digit validation
                int reqDigits = 0;
                if (['A', 'B', 'C'].contains(selectedType)) {
                  reqDigits = 1;
                } else if (['AB', 'BC', 'AC'].contains(selectedType)) {
                  reqDigits = 2;
                } else if (['SUPER', 'BOX'].contains(selectedType)) {
                  reqDigits = 3;
                }

                if (numController.text.length != reqDigits) {
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
              style:
                  ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: Text(isEditing ? 'UPDATE' : 'ADD',
                  style: const TextStyle(color: Colors.white)),
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
