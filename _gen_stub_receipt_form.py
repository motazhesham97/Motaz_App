import os

# ReceiptFormScreen stub — minimal placeholder
lines = [
    "import 'package:flutter/material.dart';",
    "",
    "class ReceiptFormScreen extends StatelessWidget {",
    "  const ReceiptFormScreen({super.key});",
    "",
    "  @override",
    "  Widget build(BuildContext context) {",
    "    return Scaffold(",
    "      appBar: AppBar(title: const Text('إضافة دفعة')),",
    "      body: const Center(child: Text('Receipt form — coming soon')),",
    "    );",
    "  }",
    "}",
]

content = '\n'.join(lines) + '\n'
outpath = r'D:\Motaz_App2\motaz_app\motaz_app_flutter\lib\features\receipts\presentation\receipt_form_screen.dart'
with open(outpath, 'w', encoding='utf-8', newline='\n') as f:
    f.write(content)
print('ReceiptFormScreen stub written.')
