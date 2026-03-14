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
  late TextEditingController _countA;
  late TextEditingController _countB;
  late TextEditingController _countC;
  late TextEditingController _countAB;
  late TextEditingController _countBC;
  late TextEditingController _countAC;
  late TextEditingController _countSuper;
  late TextEditingController _countBox;
  bool _isLoading = false;

  // Global Number Limits Tab Data
  List<dynamic> _globalNumberLimits = [];
  bool _isLoadingNumbers = true;

  @override
  void initState() {
    super.initState();
    _tabController =
        TabController(length: 2, vsync: this, initialIndex: widget.initialTab);
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
    super.dispose();
  }

  Future<void> _updateTypeLimits() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final apiService = Provider.of<ApiService>(context, listen: false);

    try {
      final updatedData = {
        'global_count_a': int.parse(_countA.text),
        'global_count_b': int.parse(_countB.text),
        'global_count_c': int.parse(_countC.text),
        'global_count_ab': int.parse(_countAB.text),
        'global_count_bc': int.parse(_countBC.text),
        'global_count_ac': int.parse(_countAC.text),
        'global_count_super': int.parse(_countSuper.text),
        'global_count_box': int.parse(_countBox.text),
      };

      await apiService.updateGame(widget.game.id, updatedData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Global type limits updated successfully!'),
              backgroundColor: Colors.green),
        );
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
      child: Column(
        children: [
          _buildInfoCard(
              'These limits apply system-wide per number for each game type (e.g., 500 means each number allows 500 counts individually).'),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('Single Digit Limits'),
                  const SizedBox(height: 12),
                  _buildGrid([
                    _buildLimitField(
                        'A Count', _countA, Icons.looks_one_rounded),
                    _buildLimitField(
                        'B Count', _countB, Icons.looks_two_rounded),
                    _buildLimitField('C Count', _countC, Icons.looks_3_rounded),
                  ]),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Double Digit Limits'),
                  const SizedBox(height: 12),
                  _buildGrid([
                    _buildLimitField(
                        'AB Count', _countAB, Icons.filter_2_rounded),
                    _buildLimitField(
                        'BC Count', _countBC, Icons.filter_2_rounded),
                    _buildLimitField(
                        'AC Count', _countAC, Icons.filter_2_rounded),
                  ]),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Three Digit Limits'),
                  const SizedBox(height: 12),
                  _buildGrid([
                    _buildLimitField(
                        'SUPER Count', _countSuper, Icons.star_rounded),
                    _buildLimitField(
                        'BOX Count', _countBox, Icons.inventory_2_rounded),
                  ]),
                  const SizedBox(height: 40),
                  _buildUpdateButton(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNumberCountTab() {
    return Column(
      children: [
        _buildInfoCard(
            'Set system-wide limits for specific numbers (e.g., number 123 restricted to 50 counts total).'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
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
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          _buildTypeBadge(limit['type']),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Number: ${limit['number']}',
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C3E50)),
                ),
                Text(
                  'System Max: ${limit['max_count']} counts',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Colors.blue),
            onPressed: () => _showAddNumberLimitDialog(limit: limit),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
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
                      SnackBar(
                          content: Text('Number must be $reqDigits digits')),
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

  Widget _buildInfoCard(String text) {
    return Container(
      width: double.infinity,
      color: AppColors.primary,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: Colors.white, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style:
                  TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
          letterSpacing: 0.5),
    );
  }

  Widget _buildGrid(List<Widget> children) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 2.2,
      children: children,
    );
  }

  Widget _buildLimitField(
      String label, TextEditingController controller, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 20, color: Colors.grey),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide.none),
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) return 'Enter value';
          if (int.tryParse(value) == null) return 'Invalid';
          return null;
        },
      ),
    );
  }

  Widget _buildUpdateButton() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _updateTypeLimits,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          elevation: 2,
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
                    fontWeight: FontWeight.bold,
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
