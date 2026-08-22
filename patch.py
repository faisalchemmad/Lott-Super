
p = 'd:/Gemini/Android/Lott_super/frontend/lib/views/sales_report_detail_screen.dart'
with open(p, 'r', encoding='utf-8') as f:
    c = f.read()

import re

start_idx = c.find('return Container(', c.find('final displayId = inv'))
end_idx = c.find('}).toList(),', start_idx)

old_item_code = c[start_idx:end_idx]

new_item_code = '''return Container(
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              color: Colors.white,
            ),
            child: Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: const EdgeInsets.only(right: 8),
                backgroundColor: const Color(0xFF1A233E),
                collapsedBackgroundColor: const Color(0xFF1A233E),
                iconColor: Colors.white,
                collapsedIconColor: Colors.white,
                title: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 0),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(dateStr,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600)),
                            Text(timeStr,
                                style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(displayId,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontStyle: FontStyle.italic)),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(inv['user__username'] ?? '',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold)),
                      ),
                      Expanded(
                        flex: 1,
                        child: Text('',
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w500)),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                            '',
                            textAlign: TextAlign.right,
                            style: TextStyle(
                                color: (widget.userRole == \\
SUPER_ADMIN\\ ||
                                        widget.userRole == \\ADMIN\\ ||
                                        widget.userRole == \\AGENT\\ ||
                                        widget.userRole == \\DEALER\\)
                                    ? const Color(0xFF10B981)
                                    : Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w900)),
                      ),
                    ],
                  ),
                ),
                children: [
                  Container(color: Colors.white, child: Column(children: [
                  // Invoice Items Header
                  Container(
                    padding:
                        const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                    color: Colors.grey[100],
                    child: Row(
                      children: [
                        const Expanded(
                            flex: 3,
                            child: Text('TYPE',
                                style: TextStyle(
                                    fontSize: 10, fontWeight: FontWeight.bold))),
                        const Expanded(
                            flex: 2,
                            child: Text('NUM',
                                style: TextStyle(
                                    fontSize: 10, fontWeight: FontWeight.bold))),
                        const Expanded(
                            flex: 1,
                            child: Text('QTY',
                                style: TextStyle(
                                    fontSize: 10, fontWeight: FontWeight.bold))),
                        if (widget.userRole == 'SUPER_ADMIN' ||
                            widget.userRole == 'ADMIN' ||
                            widget.userRole == 'AGENT' ||
                            widget.userRole == 'DEALER') ...[
                          const Expanded(
                              flex: 2,
                              child: Text('NET',
                                  textAlign: TextAlign.right,
                                  style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold))),
                          const Expanded(
                              flex: 2,
                              child: Text('TOT',
                                  textAlign: TextAlign.right,
                                  style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF10B981)))),
                        ] else
                          const Expanded(
                              flex: 2,
                              child: Text('TOTAL',
                                  textAlign: TextAlign.right,
                                  style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold))),
                      ],
                    ),
                  ),
                  // Invoice Items
                  ...items.map((item) {
                    return Container(
                      decoration: BoxDecoration(
                        border:
                            Border(bottom: BorderSide(color: Colors.grey[200]!)),
                      ),
                      padding:
                          const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Text(
                                '-'
                                    .toUpperCase(),
                                style: const TextStyle(fontSize: 12)),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(item['number'].toString(),
                                style: const TextStyle(
                                    fontSize: 13, fontWeight: FontWeight.bold)),
                          ),
                          Expanded(
                            flex: 1,
                            child: Text('',
                                style: const TextStyle(fontSize: 13)),
                          ),
                          if (widget.userRole == 'SUPER_ADMIN' ||
                              widget.userRole == 'ADMIN' ||
                              widget.userRole == 'AGENT' ||
                              widget.userRole == 'DEALER') ...[
                            Expanded(
                              flex: 2,
                              child: Text(
                                  (item['count'] > 0 ? (item['net'] / item['count']) : 0.0)
                                      .toStringAsFixed(2),
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(fontSize: 12)),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text('',
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF10B981))),
                            ),
                          ] else
                            Expanded(
                              flex: 2,
                              child: Text('',
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(fontSize: 13)),
                            ),
                        ],
                      ),
                    );
                  }).toList(),
                  ]))
                ],
              ),
            ),
          );
'''

c = c.replace(old_item_code, new_item_code)

with open(p, 'w', encoding='utf-8') as f:
    f.write(c)


