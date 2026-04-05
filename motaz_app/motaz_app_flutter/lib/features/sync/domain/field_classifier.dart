class FieldClassifier {
  static const Map<String, Set<String>> autoMergeFields = {
    'CLIENT': {'displayName', 'phone', 'note', 'clientCode'},
    'PRODUCT': {'description', 'isActive'},
    'SALES_INVOICE': {'note'},
    'RECEIPT': {'note'},
    'EXPENSE': {'note'},
    'SALES_RETURN': {'note'},
    'ATTACHMENT_METADATA': {
      'storageReference',
      'secureUrl',
      'fileType',
      'fileSize',
    },
  };

  static const Map<String, Set<String>> conflictRequiredFields = {
    'PRODUCT': {'name', 'defaultSalePrice'},
    'SALES_INVOICE': {
      'clientId',
      'invoiceDate',
      'discount',
      'total',
      'status',
      'voidReason',
    },
    'SALES_INVOICE_LINE': {
      'invoiceId',
      'productId',
      'quantity',
      'unitPrice',
      'lineTotal',
    },
    'RECEIPT': {
      'receiptType',
      'clientId',
      'invoiceId',
      'amount',
      'receiptDate',
      'status',
      'voidReason',
    },
    'RECEIPT_ALLOCATION': {'receiptId', 'invoiceId', 'allocatedAmount'},
    'EXPENSE': {
      'category',
      'amount',
      'expenseDate',
      'status',
      'voidReason',
    },
    'SALES_RETURN': {
      'invoiceId',
      'returnDate',
      'totalReturnedAmount',
      'status',
      'voidReason',
    },
    'SALES_RETURN_LINE': {
      'returnId',
      'invoiceLineId',
      'returnedQuantity',
      'returnedAmount',
    },
  };

  static Set<String> getConflictRequiredFields(String entityType) {
    return conflictRequiredFields[entityType] ?? {};
  }

  static bool hasConflictRequiredFieldChanges(
    String entityType,
    Set<String> changedFields,
  ) {
    final required = getConflictRequiredFields(entityType);
    return changedFields.intersection(required).isNotEmpty;
  }

  static bool hasOnlyAutoMergeFieldChanges(
    String entityType,
    Set<String> changedFields,
  ) {
    return !hasConflictRequiredFieldChanges(entityType, changedFields);
  }
}
