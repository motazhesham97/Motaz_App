import os

# T011 stub — minimal placeholder for InvoiceFormScreen
# Full implementation deferred to Phase 4
lines = [
    "import 'package:flutter/material.dart';",
    "",
    "class InvoiceFormScreen extends StatelessWidget {",
    "  const InvoiceFormScreen({super.key});",
    "",
    "  @override",
    "  Widget build(BuildContext context) {",
    "    return Scaffold(",
    "      appBar: AppBar(title: const Text('إنشاء فاتورة')),",
    "      body: const Center(child: Text('Invoice form — coming soon')),",
    "    );",
    "  }",
    "}",
]

content = '\n'.join(lines) + '\n'
outpath = r'D:\Motaz_App2\motaz_app\motaz_app_flutter\lib\features\invoices\presentation\invoice_form_screen.dart'
with open(outpath, 'w', encoding='utf-8', newline='\n') as f:
    f.write(content)
print('InvoiceFormScreen stub written.')
