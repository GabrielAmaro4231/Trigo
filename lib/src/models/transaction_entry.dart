class TransactionEntry {
  const TransactionEntry({
    required this.id,
    required this.amountMinorUnits,
    required this.createdAt,
    this.tagId,
  });

  final String id;

  /// Expenses are stored as negative minor units.
  final int amountMinorUnits;
  final DateTime createdAt;
  final String? tagId;
}
