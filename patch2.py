
p = 'd:/Gemini/Android/Lott_super/frontend/lib/views/sales_report_detail_screen.dart'
with open(p, 'r', encoding='utf-8') as f:
    c = f.read()

import re

# First fix the padding so sides touch the edge on full view
padding_old = '''                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: Text('RECENT INVOICES',
                              style: TextStyle(
                                  color: Colors.grey[800],
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                  fontSize: 14)),
                        ),
                        const SizedBox(height: 16),
                        if (invoices.isEmpty)
                          Center(
                              child: Padding(
                            padding: const EdgeInsets.only(top: 40),
                            child: Column(
                              children: [
                                Icon(Icons.receipt_long_rounded,
                                    size: 60, color: Colors.grey[300]),
                                const SizedBox(height: 16),
                                Text('No invoices found',
                                    style: TextStyle(color: Colors.grey[400])),
                              ],
                            ),
                          ))
                        else
                          widget.searchNumber != null &&
                                  widget.searchNumber!.isNotEmpty
                              ? _buildSearchNumberTable(invoices)
                              : _buildInvoiceList(invoices),
                      ],
                    ),
                  ),'''

padding_new = '''                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text('RECENT INVOICES',
                            style: TextStyle(
                                color: Colors.grey[800],
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                                fontSize: 14)),
                      ),
                      const SizedBox(height: 16),
                      if (invoices.isEmpty)
                        Center(
                            child: Padding(
                          padding: const EdgeInsets.only(top: 40),
                          child: Column(
                            children: [
                              Icon(Icons.receipt_long_rounded,
                                  size: 60, color: Colors.grey[300]),
                              const SizedBox(height: 16),
                              Text('No invoices found',
                                  style: TextStyle(color: Colors.grey[400])),
                            ],
                          ),
                        ))
                      else
                        Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: (widget.fullView || (widget.searchNumber != null && widget.searchNumber!.isNotEmpty)) ? 0 : 20),
                          child: widget.searchNumber != null &&
                                  widget.searchNumber!.isNotEmpty
                              ? _buildSearchNumberTable(invoices)
                              : _buildInvoiceList(invoices),
                        ),
                    ],
                  ),'''

c = c.replace(padding_old, padding_new)

# Next, fix the ExpansionTile logic
# We need to replace the Column's child with ExpansionTile for widget.fullView
old_item = '''          return Container(
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Column(
              children: [
                // Invoice Header
                Container('''

new_item = '''          return Container(
            margin: const EdgeInsets.only(bottom: 12),
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
                title: Container('''

c = c.replace(old_item, new_item)

old_items_container = '''                // Invoice Items Header
                Container('''

new_items_container = '''                children: [
                  Container(color: Colors.white, child: Column(children: [
                  // Invoice Items Header
                  Container('''

c = c.replace(old_items_container, new_items_container)

old_end = '''                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          );
        }).toList(),
      );
    }'''

new_end = '''                      ],
                    ),
                  );
                }).toList(),
                  ]))
                ],
              ),
            ),
          );
        }).toList(),
      );
    }'''

c = c.replace(old_end, new_end)

with open(p, 'w', encoding='utf-8') as f:
    f.write(c)


