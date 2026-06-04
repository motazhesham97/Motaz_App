enum ActivityType { invoice, receipt, expense, returnItem, voidAction }

class ActivityFeedItem {
  final ActivityType type;
  final String entityId;
  final String reference;
  final DateTime timestamp;

  ActivityFeedItem({
    required this.type,
    required this.entityId,
    required this.reference,
    required this.timestamp,
  });
}
