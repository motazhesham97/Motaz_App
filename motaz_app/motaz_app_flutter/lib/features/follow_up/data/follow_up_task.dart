enum FollowUpTaskType {
  creditLimit,
  invoiceGap,
  expiredProduct,
}

class FollowUpTask {
  const FollowUpTask({
    required this.type,
    required this.clientId,
    required this.clientName,
    required this.title,
    required this.message,
    required this.priority,
    this.amount,
    this.limit,
    this.daysCount,
    this.invoiceId,
    this.invoiceRef,
    this.invoiceLineId,
    this.productId,
    this.productName,
    this.quantity,
    this.unitPrice,
    this.productionDate,
    this.expiryDate,
  });

  final FollowUpTaskType type;
  final String clientId;
  final String clientName;
  final String title;
  final String message;
  final int priority;
  final int? amount;
  final int? limit;
  final int? daysCount;
  final String? invoiceId;
  final String? invoiceRef;
  final String? invoiceLineId;
  final String? productId;
  final String? productName;
  final int? quantity;
  final int? unitPrice;
  final DateTime? productionDate;
  final DateTime? expiryDate;
}
