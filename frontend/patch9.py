import sys

p = r'd:\Gemini\Android\Lott_super\frontend\lib\views\sales_report_detail_screen.dart'
with open(p, 'r', encoding='utf-8') as f:
    c = f.read()

old_code = '''final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => InvoiceDetailScreen(
                          invoiceId: invoiceId,
                          isAgentRate: widget.isAgentRate)));'''

new_code = '''final result = await showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                useSafeArea: true,
                backgroundColor: Colors.transparent,
                builder: (context) => ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  child: InvoiceDetailScreen(
                    invoiceId: invoiceId,
                    isAgentRate: widget.isAgentRate,
                  ),
                ),
              );'''

if old_code in c:
    c = c.replace(old_code, new_code)
    with open(p, 'w', encoding='utf-8') as f:
        f.write(c)
    print("Patched successfully!")
else:
    print("Could not find old_code!")
