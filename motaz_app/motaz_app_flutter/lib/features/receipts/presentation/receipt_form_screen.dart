import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/device_service.dart';
import '../../../core/database/enums/parent_entity_type.dart';
import '../../attachments/application/document_attachment_service.dart';
import '../../attachments/presentation/document_photo_field.dart';
import '../../clients/application/client_providers.dart';
import '../application/receipt_providers.dart';

class ReceiptFormScreen extends ConsumerStatefulWidget {
  const ReceiptFormScreen({
    super.key,
    this.invoiceId,
    this.clientId,
    this.maxAmount,
    this.existingReceipt,
  });

  final String? invoiceId;
  final String? clientId;
  final int? maxAmount;
  final Receipt? existingReceipt;

  @override
  ConsumerState<ReceiptFormScreen> createState() => _ReceiptFormScreenState();
}

class _ReceiptFormScreenState extends ConsumerState<ReceiptFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final _clientNameController = TextEditingController();
  final _clientFocusNode = FocusNode();
  DateTime _receiptDate = DateTime.now();
  Client? _selectedClient;
  String? _attachmentPath;
  String? _loadedAttachmentPath;
  bool _saving = false;
  bool _loadingClient = true;

  bool get _isEditing => widget.existingReceipt != null;
  String? get _invoiceId =>
      widget.invoiceId ?? widget.existingReceipt?.invoiceId;
  String? get _clientId => widget.clientId ?? widget.existingReceipt?.clientId;
  bool get _isInvoiceLinked => _invoiceId != null;

  int get _amount {
    final text = _amountController.text.trim();
    if (text.isEmpty) return 0;
    final parsed = double.tryParse(text);
    if (parsed == null) return 0;
    return (parsed * 100).round();
  }

  @override
  void initState() {
    super.initState();
    final existing = widget.existingReceipt;
    if (existing != null) {
      _receiptDate = existing.receiptDate;
      _amountController.text = (existing.amount / 100).toStringAsFixed(2);
      _noteController.text = existing.note ?? '';
      unawaited(_loadExistingReceiptPhoto());
    }

    if (_clientId != null) {
      _loadClient();
    } else {
      _loadingClient = false;
    }
    unawaited(_recoverLostReceiptPhoto());
  }

  Future<void> _loadClient() async {
    try {
      final client = await ref
          .read(clientRepositoryProvider)
          .getById(_clientId!);
      if (mounted) {
        setState(() {
          _selectedClient = client;
          _clientNameController.text = client.displayName;
          _loadingClient = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loadingClient = false);
      }
    }
  }

  bool _matchesWordPrefix(String value, String query) {
    final normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) return true;
    final terms = normalizedQuery.split(RegExp(r'\s+'));
    final words = value
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();
    return terms.every(
      (term) => words.any((word) => word.startsWith(term)),
    );
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _receiptDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _receiptDate = picked;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_saving) return;

    final typedClientName = _clientNameController.text.trim();
    final selectedClient = _selectedClient;
    if (!_isInvoiceLinked &&
        (selectedClient == null ||
            selectedClient.displayName.trim() != typedClientName)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('هذا العميل غير مسجل أو غير موجود')),
      );
      return;
    }

    if (_amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('المبلغ يجب أن يكون أكبر من صفر')),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final device = await ref
          .read(deviceServiceProvider)
          .ensureCurrentDevice();
      if (!mounted) return;

      final repo = ref.read(receiptRepositoryProvider);
      final note = _noteController.text.trim();
      late final String receiptId;

      if (_isEditing) {
        await repo.updateReceipt(
          id: widget.existingReceipt!.id,
          clientId: _isInvoiceLinked
              ? widget.existingReceipt!.clientId
              : _selectedClient!.id,
          amount: _amount,
          receiptDate: _receiptDate,
          note: note.isEmpty ? null : note,
          deviceId: device.id,
        );
        receiptId = widget.existingReceipt!.id;
      } else if (_isInvoiceLinked) {
        final created = await repo.createInvoiceLinked(
          clientId: _clientId!,
          invoiceId: _invoiceId!,
          amount: _amount,
          receiptDate: _receiptDate,
          note: note.isEmpty ? null : note,
          deviceId: device.id,
        );
        receiptId = created.id;
      } else {
        final created = await repo.createGeneral(
          clientId: _selectedClient!.id,
          amount: _amount,
          receiptDate: _receiptDate,
          note: note.isEmpty ? null : note,
          deviceId: device.id,
        );
        receiptId = created.id;
      }

      await _stageReceiptPhoto(receiptId);

      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _captureReceiptPhoto() async {
    final path = await ref
        .read(documentAttachmentServiceProvider)
        .captureDocumentPhoto(context);
    if (path != null && mounted) {
      setState(() => _attachmentPath = path);
    }
  }

  Future<void> _recoverLostReceiptPhoto() async {
    final path = await ref
        .read(documentAttachmentServiceProvider)
        .recoverLostDocumentPhoto();
    if (path != null && mounted && _attachmentPath == null) {
      setState(() => _attachmentPath = path);
    }
  }

  Future<void> _loadExistingReceiptPhoto() async {
    final receipt = widget.existingReceipt;
    if (receipt == null) return;
    final path = await ref
        .read(documentAttachmentServiceProvider)
        .loadLatestLocalPhotoPath(
          parentEntityType: ParentEntityType.RECEIPT,
          parentEntityId: receipt.id,
        );
    if (path != null && mounted && _attachmentPath == null) {
      setState(() {
        _attachmentPath = path;
        _loadedAttachmentPath = path;
      });
    }
  }

  Future<void> _stageReceiptPhoto(String receiptId) async {
    final path = _attachmentPath;
    if (path == null) return;
    if (path == _loadedAttachmentPath) return;
    await ref
        .read(documentAttachmentServiceProvider)
        .stagePhoto(
          parentEntityType: ParentEntityType.RECEIPT,
          parentEntityId: receiptId,
          localFilePath: path,
        );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    _clientNameController.dispose();
    _clientFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingClient) {
      return Scaffold(
        appBar: AppBar(title: const Text('سند قبض')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final title = _isEditing
        ? 'تعديل سند قبض'
        : _isInvoiceLinked
        ? 'إضافة دفعة مرتبطة بفاتورة'
        : 'إضافة دفعة عامة';

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildClientField(),
              const SizedBox(height: 12),
              _buildDateField(),
              const SizedBox(height: 12),
              _buildAmountField(),
              if (_isInvoiceLinked && widget.maxAmount != null && !_isEditing)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'المتبقي على الفاتورة: ${(widget.maxAmount! / 100).toStringAsFixed(2)} ر.ي. ويمكن تسجيل مبلغ أكبر كرصيد له للعميل.',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ),
              const SizedBox(height: 12),
              _buildNoteField(),
              const SizedBox(height: 12),
              DocumentPhotoField(
                label: 'إضافة صورة السند',
                localPath: _attachmentPath,
                onCapture: _captureReceiptPhoto,
                onRemove: () => setState(() => _attachmentPath = null),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Theme.of(context).colorScheme.surface,
                        ),
                      )
                    : const Text('حفظ'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClientField() {
    if (_isInvoiceLinked) {
      return InputDecorator(
        decoration: const InputDecoration(labelText: 'العميل'),
        child: Text(_selectedClient?.displayName ?? '---'),
      );
    }

    final clients =
        ref.watch(activeClientListProvider).value ?? const <Client>[];
    return RawAutocomplete<Client>(
      textEditingController: _clientNameController,
      focusNode: _clientFocusNode,
      displayStringForOption: (client) => client.displayName,
      optionsBuilder: (textEditingValue) {
        final query = textEditingValue.text.trim();
        if (query.isEmpty) return const Iterable<Client>.empty();
        if (_selectedClient?.displayName.trim() == query) {
          return const Iterable<Client>.empty();
        }
        final normalized = query.toLowerCase();
        return clients.where((client) {
          final phone = client.phone?.toLowerCase() ?? '';
          final code = client.clientCode?.toLowerCase() ?? '';
          return _matchesWordPrefix(client.displayName, query) ||
              phone.startsWith(normalized) ||
              code.startsWith(normalized);
        });
      },
      onSelected: (client) {
        setState(() {
          _selectedClient = client;
          _clientNameController.text = client.displayName;
        });
        _clientFocusNode.unfocus();
      },
      fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
        return TextFormField(
          controller: controller,
          focusNode: focusNode,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          decoration: const InputDecoration(
            labelText: 'العميل *',
            hintText: 'اكتب بداية أي كلمة من اسم العميل',
            prefixIcon: Icon(Icons.person_search_rounded),
          ),
          onChanged: (value) {
            final normalized = value.trim().toLowerCase();
            Client? exactMatch;
            for (final client in clients) {
              if (client.displayName.trim().toLowerCase() == normalized) {
                exactMatch = client;
                break;
              }
            }
            if (exactMatch != null) {
              setState(() => _selectedClient = exactMatch);
              return;
            }
            final selected = _selectedClient;
            if (selected != null &&
                selected.displayName.trim() != value.trim()) {
              setState(() => _selectedClient = null);
            }
          },
          validator: (_) {
            if (_selectedClient == null) {
              return 'هذا العميل غير مسجل أو غير موجود';
            }
            return null;
          },
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(8),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 240),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final client = options.elementAt(index);
                  return ListTile(
                    title: Text(client.displayName),
                    subtitle: client.phone != null
                        ? Text(client.phone!)
                        : client.clientCode != null
                        ? Text(client.clientCode!)
                        : null,
                    onTap: () => onSelected(client),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDateField() {
    return InkWell(
      onTap: _selectDate,
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'تاريخ الدفعة',
          suffixIcon: Icon(Icons.calendar_today),
        ),
        child: Text(
          '${_receiptDate.year}-${_receiptDate.month.toString().padLeft(2, '0')}-${_receiptDate.day.toString().padLeft(2, '0')}',
        ),
      ),
    );
  }

  Widget _buildAmountField() {
    return TextFormField(
      controller: _amountController,
      decoration: const InputDecoration(
        labelText: 'المبلغ *',
        suffixText: 'ر.ي.',
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      validator: (v) {
        if (v == null || v.trim().isEmpty) {
          return 'المبلغ مطلوب';
        }
        final parsed = double.tryParse(v.trim());
        if (parsed == null) {
          return 'أدخل رقم صحيح';
        }
        if (parsed <= 0) {
          return 'المبلغ يجب أن يكون أكبر من صفر';
        }
        return null;
      },
    );
  }

  Widget _buildNoteField() {
    return TextFormField(
      controller: _noteController,
      decoration: const InputDecoration(
        labelText: 'ملاحظة',
        alignLabelWithHint: true,
      ),
      maxLines: 3,
    );
  }
}
