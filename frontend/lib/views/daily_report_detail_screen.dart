import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../services/pdf_service.dart';
import '../utils/constants.dart';

class DailyReportDetailScreen extends StatefulWidget {
  final dynamic initialReportData;
  final DateTime fromDate;
  final DateTime toDate;
  final int? agentId;
  final int? selectedGameId;
  final bool dayDetail;
  final bool gameDetail;
  final bool userWise;
  final bool agentRate;
  final String agentName;

  const DailyReportDetailScreen({
    super.key,
    required this.initialReportData,
    required this.fromDate,
    required this.toDate,
    this.agentId,
    this.selectedGameId,
    this.dayDetail = false,
    this.gameDetail = false,
    this.userWise = false,
    this.agentRate = false,
    required this.agentName,
  });

  @override
  State<DailyReportDetailScreen> createState() =>
      _DailyReportDetailScreenState();
}

class _DailyReportDetailScreenState extends State<DailyReportDetailScreen> {
  late List<dynamic> _reportData;
  late DateTime _currentFromDate;
  late DateTime _currentToDate;
  bool _isLoading = false;

  final Map<String, List<dynamic>> _expandedChildren = {};
  final Set<String> _expandedKeys = {};
  final Set<String> _loadingKeys = {};

  String _getItemKey(dynamic item) {
    final uid = item['user_id'] ?? 0;
    final game = item['game'] ?? 'ALL';
    final date = item['date'] ?? 'ALL';
    final user = item['user'] ?? '';
    return '${uid}_${user}_${game}_$date';
  }

  @override
  void initState() {
    super.initState();
    _currentFromDate = widget.fromDate;
    _currentToDate = widget.toDate;

    if (widget.initialReportData is Map<String, dynamic>) {
      _reportData = widget.initialReportData['data'] ?? [];
    } else if (widget.initialReportData is List) {
      _reportData = widget.initialReportData;
    } else {
      _reportData = [];
    }
  }

  Future<void> _toggleExpand(dynamic item) async {
    final int? uid = item['user_id'];
    if (uid == null || !(item['is_drillable'] ?? false)) return;

    final String itemKey = _getItemKey(item);

    if (_expandedKeys.contains(itemKey)) {
      setState(() {
        _expandedKeys.remove(itemKey);
      });
      return;
    }

    if (_expandedChildren.containsKey(itemKey)) {
      setState(() {
        _expandedKeys.add(itemKey);
      });
      return;
    }

    setState(() {
      _loadingKeys.add(itemKey);
    });

    final apiService = Provider.of<ApiService>(context, listen: false);
    try {
      final response = await apiService.getDailyReport(
        fromDate: DateFormat('yyyy-MM-dd').format(_currentFromDate),
        toDate: DateFormat('yyyy-MM-dd').format(_currentToDate),
        userId: uid,
        gameIds:
            widget.selectedGameId != null ? [widget.selectedGameId!] : null,
        dayDetail: widget.dayDetail,
        gameDetail: widget.gameDetail,
        userDetail: true,
        agentRate: widget.agentRate,
      );

      List<dynamic> childData = [];
      if (response is Map<String, dynamic>) {
        childData = response['data'] ?? [];
      } else if (response is List) {
        childData = response;
      }

      final parentGame = item['game']?.toString();
      final parentDate = item['date']?.toString();

      // Filter children matching this row's specific game and date if applicable
      final validChildren = childData.where((c) {
        if (c['user_id'] == uid && c['user'] != 'Self') return false;
        if (parentGame != null && parentGame != '-' && parentGame != 'ALL') {
          if (c['game'] != null &&
              c['game'] != '-' &&
              c['game'] != 'ALL' &&
              c['game'] != parentGame) {
            return false;
          }
        }
        if (parentDate != null && parentDate != '-' && parentDate != 'ALL') {
          if (c['date'] != null &&
              c['date'] != '-' &&
              c['date'] != 'ALL' &&
              c['date'] != parentDate) {
            return false;
          }
        }
        return true;
      }).toList();

      setState(() {
        _expandedChildren[itemKey] = validChildren;
        _expandedKeys.add(itemKey);
        _loadingKeys.remove(itemKey);
      });
    } catch (e) {
      setState(() {
        _loadingKeys.remove(itemKey);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading subordinates: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _refreshData() async {
    setState(() => _isLoading = true);
    final apiService = Provider.of<ApiService>(context, listen: false);

    try {
      final response = await apiService.getDailyReport(
        fromDate: DateFormat('yyyy-MM-dd').format(_currentFromDate),
        toDate: DateFormat('yyyy-MM-dd').format(_currentToDate),
        userId: widget.agentId,
        gameIds:
            widget.selectedGameId != null ? [widget.selectedGameId!] : null,
        dayDetail: widget.dayDetail,
        gameDetail: widget.gameDetail,
        userDetail: true,
        agentRate: widget.agentRate,
      );

      setState(() {
        if (response is Map<String, dynamic>) {
          _reportData = response['data'] ?? [];
        } else if (response is List) {
          _reportData = response;
        }
        _expandedChildren.clear();
        _expandedKeys.clear();
        _loadingKeys.clear();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _shareAsPdf(
      double totalSale, double totalWin, double totalBalance) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Generating PDF...'), duration: Duration(seconds: 1)),
    );
    try {
      await PdfService.generateAndShareDailyReport(
        agentName: widget.agentName,
        fromDate: _currentFromDate,
        toDate: _currentToDate,
        reportData: _reportData,
        totalSale: totalSale,
        totalWinning: totalWin,
        totalBalance: totalBalance,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to generate PDF: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDesktop = defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.macOS;

    double totalSale =
        _reportData.fold(0, (sum, item) => sum + ((item['sale'] ?? 0) as num));
    double totalCommission = _reportData.fold(
        0, (sum, item) => sum + ((item['commission'] ?? 0) as num));
    double totalWinning = _reportData.fold(
        0, (sum, item) => sum + ((item['winning'] ?? 0) as num));
    double totalBalance = totalSale - (totalWinning + totalCommission);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Daily Report Results',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: AppColors.primary,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: () => _shareAsPdf(totalSale, totalWinning, totalBalance),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _refreshData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildSummaryHeader(
                    totalSale, totalCommission, totalWinning, totalBalance),
                _buildTableHeader(isDesktop),
                Expanded(
                  child: _reportData.isEmpty
                      ? const Center(
                          child: Text(
                            'No data found for selected period',
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      : ListView.separated(
                          itemCount: _reportData.length,
                          separatorBuilder: (c, i) => const Divider(
                              height: 1, color: Color(0xFFEEEEEE)),
                          itemBuilder: (context, index) {
                            return _buildTreeItem(
                              _reportData[index],
                              index,
                              isDesktop,
                              depth: 0,
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildTreeItem(dynamic item, int index, bool isDesktop,
      {int depth = 0}) {
    final String itemKey = _getItemKey(item);
    final bool isExpanded = _expandedKeys.contains(itemKey);
    final List<dynamic> children = _expandedChildren[itemKey] ?? [];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildReportRow(item, index, isDesktop, depth: depth),
        AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOutCubic,
          alignment: Alignment.topCenter,
          child: (isExpanded && children.isNotEmpty)
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: children.asMap().entries.map((entry) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Divider(height: 1, color: Color(0xFFEEEEEE)),
                        _buildTreeItem(
                          entry.value,
                          entry.key,
                          isDesktop,
                          depth: depth + 1,
                        ),
                      ],
                    );
                  }).toList(),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  String _formatAmount(num value) {
    if (value % 1 == 0) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(2);
  }

  Widget _buildSummaryHeader(double totalSale, double totalCommission,
      double totalWinning, double totalBalance) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
      color: Colors.white,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.grey.shade300, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: _buildNewStatItem(Icons.bar_chart_rounded, 'Total Sales',
                  '₹${_formatAmount(totalSale)}'),
            ),
            Container(width: 1, height: 50, color: Colors.grey.shade200),
            Expanded(
              child: _buildNewStatItem(Icons.emoji_events_rounded,
                  'Winning (Prz)', '₹${_formatAmount(totalWinning)}',
                  valueColor:
                      totalWinning > 0 ? const Color(0xFF10B981) : null),
            ),
            Container(width: 1, height: 50, color: Colors.grey.shade200),
            Expanded(
              child: _buildNewStatItem(Icons.percent_rounded, 'Dealer Comm',
                  '₹${_formatAmount(totalCommission)}',
                  valueColor:
                      totalCommission > 0 ? const Color(0xFF059669) : null),
            ),
            Container(width: 1, height: 50, color: Colors.grey.shade200),
            Expanded(
              child: _buildNewStatItem(Icons.account_balance_wallet_rounded,
                  'Net Total', '₹${_formatAmount(totalBalance)}',
                  valueColor:
                      totalBalance >= 0 ? const Color(0xFF10B981) : Colors.red),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNewStatItem(IconData icon, String label, String value,
      {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: AppColors.primary, size: 16),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                color: Colors.grey[600],
                fontSize: 9,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                  color: valueColor ?? AppColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader(bool isDesktop) {
    const headerStyle = TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.bold,
      fontSize: 11,
      letterSpacing: 0.5,
    );

    return Container(
      color: const Color(0xFF901C22),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      child: const Row(
        children: [
          Expanded(
            flex: 32,
            child: Text('USER', style: headerStyle),
          ),
          Expanded(
            flex: 22,
            child:
                Text('SALES', textAlign: TextAlign.right, style: headerStyle),
          ),
          Expanded(
            flex: 24,
            child: Text('PRZ/COMM',
                textAlign: TextAlign.right, style: headerStyle),
          ),
          Expanded(
            flex: 22,
            child:
                Text('TOTAL', textAlign: TextAlign.right, style: headerStyle),
          ),
        ],
      ),
    );
  }

  Color _parseColor(String? hexString, {Color defaultColor = Colors.white}) {
    if (hexString == null || hexString.isEmpty) return defaultColor;
    try {
      String hex = hexString.replaceAll('#', '');
      if (hex.length == 6) {
        hex = 'FF$hex';
      }
      return Color(int.parse(hex, radix: 16));
    } catch (_) {
      return defaultColor;
    }
  }

  Widget _buildReportRow(dynamic item, int index, bool isDesktop,
      {int depth = 0}) {
    final bool isEven = index % 2 == 0;
    final double sale = (item['sale'] ?? 0).toDouble();
    final double commission = (item['commission'] ?? 0).toDouble();
    final double winning = (item['winning'] ?? 0).toDouble();
    final double balance =
        (item['balance'] ?? (sale - (winning + commission))).toDouble();
    final bool isDrillable = item['is_drillable'] ?? false;
    final String itemKey = _getItemKey(item);
    final bool isExpanded = _expandedKeys.contains(itemKey);
    final bool isLoading = _loadingKeys.contains(itemKey);

    final String? gameColorHex = item['game_color'];
    final Color? gameColor = (gameColorHex != null && gameColorHex.isNotEmpty)
        ? _parseColor(gameColorHex)
        : null;

    String title = item['user'] ?? '-';
    if (title == '-' || title == 'ALL') {
      if (item['game'] != null &&
          item['game'] != '-' &&
          item['game'] != 'ALL') {
        title = item['game'];
      } else if (item['date'] != null && item['date'] != '-') {
        title = item['date'];
      }
    }

    List<String> subItems = [];
    if (item['game'] != null &&
        item['game'] != '-' &&
        item['game'] != 'ALL' &&
        item['game'] != title) {
      subItems.add(item['game']);
    }
    if (item['date'] != null && item['date'] != '-' && item['date'] != title) {
      subItems.add(item['date']);
    }
    String subTitle = subItems.join(' • ');

    Color rowBg;
    if (gameColor != null && widget.gameDetail) {
      if (depth == 0) {
        rowBg = gameColor.withOpacity(0.14);
      } else if (depth == 1) {
        rowBg = gameColor.withOpacity(0.08);
      } else {
        rowBg = gameColor.withOpacity(0.04);
      }
    } else {
      if (depth == 0) {
        rowBg = isEven ? const Color(0xFFF9F9F9) : Colors.white;
      } else if (depth == 1) {
        rowBg = const Color(0xFFF1F5F9);
      } else {
        rowBg = const Color(0xFFE2E8F0);
      }
    }

    final double leftPadding = 12.0 + (depth * 14.0);

    return InkWell(
      onTap: isDrillable ? () => _toggleExpand(item) : null,
      child: Container(
        decoration: BoxDecoration(
          color: rowBg,
          border: (gameColor != null && widget.gameDetail && depth == 0)
              ? Border(left: BorderSide(color: gameColor, width: 4.5))
              : null,
        ),
        padding:
            EdgeInsets.only(left: leftPadding, right: 12, top: 8, bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              flex: 32,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (depth > 0) ...[
                        const Icon(Icons.subdirectory_arrow_right_rounded,
                            size: 13, color: AppColors.primary),
                        const SizedBox(width: 3),
                      ],
                      Flexible(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontWeight:
                                depth == 0 ? FontWeight.bold : FontWeight.w600,
                            fontSize: depth == 0 ? 12 : 11.5,
                            color: isDrillable
                                ? AppColors.primary
                                : Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isDrillable) ...[
                        const SizedBox(width: 4),
                        if (isLoading)
                          const SizedBox(
                            width: 10,
                            height: 10,
                            child: CircularProgressIndicator(
                              strokeWidth: 1.5,
                              color: AppColors.primary,
                            ),
                          )
                        else
                          AnimatedRotation(
                            turns: isExpanded ? 0.25 : 0.0,
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeInOut,
                            child: const Icon(
                              Icons.keyboard_arrow_right_rounded,
                              size: 15,
                              color: AppColors.primary,
                            ),
                          ),
                      ],
                    ],
                  ),
                  if (subTitle.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.only(left: depth > 0 ? 16 : 0),
                      child: Text(
                        subTitle,
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              flex: 22,
              child: Text(
                _formatAmount(sale),
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: Colors.black87,
                ),
              ),
            ),
            Expanded(
              flex: 24,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _formatAmount(winning),
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: winning > 0
                          ? const Color(0xFF10B981)
                          : Colors.black87,
                    ),
                  ),
                  if (commission > 0)
                    Text(
                      'Com: ${_formatAmount(commission)}',
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF059669),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              flex: 22,
              child: Text(
                _formatAmount(balance),
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                  color: balance >= 0 ? const Color(0xFF10B981) : Colors.red,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
