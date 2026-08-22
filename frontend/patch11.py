import sys

p = r'd:\Gemini\Android\Lott_super\frontend\lib\views\sales_report_detail_screen.dart'
with open(p, 'r', encoding='utf-8') as f:
    c = f.read()

idx_start = c.find('Widget _buildSummaryHeader() {')
idx_end = c.find('Widget _buildNewStatItem', idx_start)

# We will replace from idx_start to idx_end
new_code = """Widget _buildSummaryHeader() {
    bool isAdminView = widget.userRole == 'SUPER_ADMIN' ||
        widget.userRole == 'ADMIN' ||
        widget.userRole == 'AGENT' ||
        widget.userRole == 'DEALER';

    String commLabel = isAdminView
        ? (widget.isAgentRate
            ? (widget.userRole == 'AGENT'
                ? 'Agent Comm'
                : (widget.userRole == 'DEALER'
                    ? 'Dealer Comm'
                    : (widget.userRole == 'SUPER_ADMIN'
                        ? 'User Comm'
                        : 'Admin Comm')))
            : 'Self Comm')
        : 'Total Commission';

    String netLabel = isAdminView
        ? (widget.isAgentRate
            ? (widget.userRole == 'AGENT'
                ? 'Agent Net'
                : (widget.userRole == 'DEALER'
                    ? 'Dealer Net'
                    : (widget.userRole == 'SUPER_ADMIN'
                        ? 'User Net'
                        : 'Admin Net')))
            : 'Self Net')
        : 'Net Amount';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Report Period Card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300, width: 1),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.calendar_month_rounded, color: AppColors.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('REPORT PERIOD',
                          style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5)),
                      const SizedBox(height: 2),
                      Text(
                        '${DateFormat('dd MMM').format(widget.fromDate)} - ${DateFormat('dd MMM yyyy').format(widget.toDate)}',
                        style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 14,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // 2. Summary 4-Column Card
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300, width: 1),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildNewStatItem(
                      Icons.people_alt_rounded, 'TotalCount', '${_currentReportData['count'] ?? 0}'),
                ),
                Container(width: 1, height: 60, color: Colors.grey.shade300),
                Expanded(
                  child: _buildNewStatItem(
                      Icons.percent_rounded, commLabel, '₹${_currentReportData['commission'] ?? 0}'),
                ),
                Container(width: 1, height: 60, color: Colors.grey.shade300),
                Expanded(
                  child: _buildNewStatItem(
                      Icons.account_balance_wallet_rounded, netLabel, '₹${_currentReportData['net'] ?? 0}'),
                ),
                Container(width: 1, height: 60, color: Colors.grey.shade300),
                Expanded(
                  child: _buildNewStatItem(
                      Icons.bar_chart_rounded, 'Total Sales', '₹${_currentReportData['sales'] ?? 0}'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  """

c = c[:idx_start] + new_code + c[idx_end:]
with open(p, 'w', encoding='utf-8') as f:
    f.write(c)
print('Patched correctly!')
