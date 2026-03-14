import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../models/bet_model.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';

class InvoiceDetailScreen extends StatefulWidget {
  final String invoiceId;
  final bool isAgentRate;
  const InvoiceDetailScreen(
      {super.key, required this.invoiceId, this.isAgentRate = true});

  @override
  State<InvoiceDetailScreen> createState() => _InvoiceDetailScreenState();
}

class _InvoiceDetailScreenState extends State<InvoiceDetailScreen> {
  List<BetModel> _bets = [];
  bool _isLoading = true;
  bool _canEditDeleteSys = true;

  @override
  void initState() {
    super.initState();
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    final apiService = Provider.of<ApiService>(context, listen: false);
    
    // Fetch settings and details in parallel for faster loading
    final results = await Future.wait([
      apiService.getInvoiceDetails(widget.invoiceId, adminRate: widget.isAgentRate),
      apiService.getSystemSettings(),
      apiService.getProfile(), // To check if current user is SUPER_ADMIN
    ]);

    final bets = results[0] as List<BetModel>;
    final settings = results[1] as Map<String, dynamic>;
    final currentUser = results[2] as UserModel?;

    bool allowedBySystem = true;
    if (currentUser?.role != 'SUPER_ADMIN') {
      // 1. Check Global Master Switch
      allowedBySystem = settings['can_edit_delete_invoice'] ?? true;
      
      // 2. Check Game-Wise Settings (from first bet in invoice)
      if (allowedBySystem && bets.isNotEmpty) {
        final firstBet = bets.first;
        if (firstBet.gameCanEditDelete == false) {
          allowedBySystem = false;
        } else if (firstBet.gameEditDeleteLimitTime != null) {
          try {
            final timeStr = firstBet.gameEditDeleteLimitTime!;
            final parts = timeStr.split(':');
            final limit = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
            final now = TimeOfDay.now();
            if (now.hour > limit.hour || (now.hour == limit.hour && now.minute > limit.minute)) {
              allowedBySystem = false;
            }
          } catch (_) {}
        }
      }
    }

    if (mounted) {
      setState(() {
        _bets = bets;
        _canEditDeleteSys = allowedBySystem;
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteInvoice() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Invoice?'),
        content: const Text(
            'This will delete all bets in this invoice. This action cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final success = await apiService.deleteInvoice(widget.invoiceId);
      if (success && mounted) {
        Navigator.pop(context, true); // Return true to indicate deletion
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Invoice deleted')));
      }
    }
  }

  void _showEditBetDialog(BetModel bet) {
    final numController = TextEditingController(text: bet.number);
    final countController = TextEditingController(text: bet.count.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Bet'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: numController,
              decoration: const InputDecoration(labelText: 'Number'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: countController,
              decoration: const InputDecoration(labelText: 'Quantity/Count'),
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
              final apiService =
                  Provider.of<ApiService>(context, listen: false);
              final success = await apiService.updateBet(
                bet.id,
                numController.text,
                int.tryParse(countController.text) ?? bet.count,
              );
              if (success && mounted) {
                Navigator.pop(context);
                _fetchDetails();
                ScaffoldMessenger.of(context)
                    .showSnackBar(const SnackBar(content: Text('Bet updated')));
              }
            },
            child: const Text('UPDATE'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteBet(int betId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Bet?'),
        content: const Text(
            'This will permanently remove this item from the invoice.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final success = await apiService.deleteBet(betId);
      if (success && mounted) {
        _fetchDetails();
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Bet deleted')));
      }
    }
  }

  void _shareInvoice() {
    if (_bets.isEmpty) return;

    final firstBet = _bets.first;
    final billId = widget.invoiceId.split('-').last.toUpperCase();
    final dateStr = DateFormat('dd/MM/yyyy').format(firstBet.createdAt);
    final timeStr = DateFormat('HH:mm:ss').format(firstBet.createdAt);
    final agentName = firstBet.username;

    double totalGrossAmount = 0;
    int totalCount = 0;
    String itemsText = "GAME   TYPE   NUM   QTY   TOT\n";

    for (var b in _bets) {
      final subtotal = b.amount * b.count;
      totalCount += b.count;
      totalGrossAmount += subtotal;

      itemsText +=
          "${b.gameName.padRight(6).substring(0, 6)} ${b.type.toUpperCase().padRight(5)} ${b.number.padRight(5)} ${b.count.toString().padRight(5)} ${subtotal.toStringAsFixed(0).padLeft(5)}\n";
    }

    String shareText = "INV No : $billId\n"
        "Date : $dateStr\n"
        "Customer : $agentName\n"
        "Sales Time : $timeStr\n"
        "Total Amount : ${totalGrossAmount.toStringAsFixed(0)}\n"
        "Total Count : $totalCount\n\n"
        "$itemsText";

    Share.share(shareText);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final billId = widget.invoiceId.split('-').last.toUpperCase();
    final firstBet = _bets.isNotEmpty ? _bets.first : null;
    final agentName = firstBet?.username ?? 'Unknown';

    // Calculations
    int totalCount = 0;
    double totalNet = 0;
    double totalGross = 0;

    for (var b in _bets) {
      totalCount += b.count;
      totalNet += b.netAmount;
      totalGross += b.totalAmount;
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Invoice Detail',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFF9C212C),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded, color: Colors.white),
            onPressed: _shareInvoice,
            tooltip: 'Share Invoice',
          ),
          if (_canEditDeleteSys)
            IconButton(
              icon: const Icon(Icons.delete_forever_rounded),
              onPressed: _deleteInvoice,
              tooltip: 'Delete Invoice',
            ),
        ],
      ),
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            color: const Color(0xFF9C212C),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('BILL ID: $billId',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                        child: Text('AGENT: ${agentName.toUpperCase()}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w400))),
                    const Expanded(
                        child: Text('CUSTOMER:',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w400))),
                  ],
                ),
              ],
            ),
          ),

          // Purple Summary Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            color: Colors.purple[900],
            child: Row(
              children: [
                Expanded(
                    child:
                        _buildSummaryLabel('COUNT: $totalCount', Colors.white)),
                Expanded(
                    child: _buildSummaryLabel(
                        'TOT NET: ${totalNet.toStringAsFixed(2)}',
                        Colors.white)),
                Expanded(
                    child: _buildSummaryLabel(
                        'TOT: ${totalGross.toStringAsFixed(2)}', Colors.white)),
              ],
            ),
          ),

          // Table Header
          Container(
            color: Colors.grey[200],
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: const Row(
              children: [
                Expanded(flex: 2, child: _TableHeader('GAME')),
                Expanded(flex: 2, child: _TableHeader('NUM')),
                Expanded(flex: 1, child: _TableHeader('CNT')),
                Expanded(flex: 2, child: _TableHeader('NET')),
                Expanded(flex: 2, child: _TableHeader('T.AMT')),
                Expanded(flex: 2, child: _TableHeader('ACTION')),
              ],
            ),
          ),

          // Table Body
          Expanded(
            child: ListView.builder(
              itemCount: _bets.length,
              itemBuilder: (context, index) {
                final bet = _bets[index];
                return GestureDetector(
                  onTap: _canEditDeleteSys ? () => _showEditBetDialog(bet) : null,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                    decoration: BoxDecoration(
                      color: index % 2 == 1 ? Colors.white : Colors.purple[50],
                      border:
                          Border(bottom: BorderSide(color: Colors.grey[350]!)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                            flex: 2, child: _TableCell(bet.type.toUpperCase())),
                        Expanded(
                            flex: 2,
                            child: _TableCell(bet.number, isBold: true)),
                        Expanded(
                            flex: 1, child: _TableCell(bet.count.toString())),
                        Expanded(
                            flex: 2,
                            child: _TableCell((bet.netAmount / bet.count)
                                .toStringAsFixed(1))),
                        Expanded(
                            flex: 2,
                            child:
                                _TableCell(bet.totalAmount.toStringAsFixed(0))),
                        Expanded(
                          flex: 2,
                          child: _canEditDeleteSys 
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  GestureDetector(
                                    onTap: () => _showEditBetDialog(bet),
                                    child: const Icon(Icons.edit_note_rounded,
                                        color: Colors.blue, size: 20),
                                  ),
                                  const SizedBox(width: 8),
                                  GestureDetector(
                                    onTap: () => _deleteBet(bet.id),
                                    child: const Icon(Icons.delete_outline_rounded,
                                        color: Colors.red, size: 20),
                                  ),
                                ],
                              )
                            : const Icon(Icons.lock_outline, color: Colors.grey, size: 16),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // OK Button
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF536976),
                padding:
                    const EdgeInsets.symmetric(horizontal: 50, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('OK',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryLabel(String text, Color color) {
    return Text(
      text,
      style: TextStyle(
          color: color,
          fontSize: 15,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5),
    );
  }
}

class _TableHeader extends StatelessWidget {
  final String title;
  const _TableHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      textAlign: TextAlign.center,
      style: TextStyle(
          color: Colors.grey[700],
          fontSize: 14,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5),
    );
  }
}

class _TableCell extends StatelessWidget {
  final String text;
  final bool isBold;
  const _TableCell(this.text, {this.isBold = false});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: TextStyle(
          fontSize: 15,
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          color: Colors.black87),
    );
  }
}
