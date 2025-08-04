/// Model to track running balance for each tenant
/// This maintains the current advance/due amount for each tenant
class TenantBalanceModel {
  final String id;
  final String tenantId;
  final String tenantName;
  final double currentBalance; // Positive = Due (tenant owes), Negative = Advance (tenant paid extra)
  final DateTime lastUpdated;
  final String lastTransactionType; // 'bill' or 'payment'
  final String? lastTransactionId;

  TenantBalanceModel({
    required this.id,
    required this.tenantId,
    required this.tenantName,
    required this.currentBalance,
    required this.lastUpdated,
    required this.lastTransactionType,
    this.lastTransactionId,
  });

  factory TenantBalanceModel.fromMap(Map<String, dynamic> map) {
    return TenantBalanceModel(
      id: map['id'] ?? '',
      tenantId: map['tenantId'] ?? '',
      tenantName: map['tenantName'] ?? '',
      currentBalance: (map['currentBalance'] ?? 0).toDouble(),
      lastUpdated: DateTime.fromMillisecondsSinceEpoch(map['lastUpdated'] ?? 0),
      lastTransactionType: map['lastTransactionType'] ?? '',
      lastTransactionId: map['lastTransactionId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tenantId': tenantId,
      'tenantName': tenantName,
      'currentBalance': currentBalance,
      'lastUpdated': lastUpdated.millisecondsSinceEpoch,
      'lastTransactionType': lastTransactionType,
      'lastTransactionId': lastTransactionId,
    };
  }

  TenantBalanceModel copyWith({
    String? id,
    String? tenantId,
    String? tenantName,
    double? currentBalance,
    DateTime? lastUpdated,
    String? lastTransactionType,
    String? lastTransactionId,
  }) {
    return TenantBalanceModel(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      tenantName: tenantName ?? this.tenantName,
      currentBalance: currentBalance ?? this.currentBalance,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      lastTransactionType: lastTransactionType ?? this.lastTransactionType,
      lastTransactionId: lastTransactionId ?? this.lastTransactionId,
    );
  }

  // Helper methods for easy understanding
  bool get hasDue => currentBalance > 0;
  bool get hasAdvance => currentBalance < 0;
  bool get isBalanced => currentBalance == 0;

  double get dueAmount => hasDue ? currentBalance : 0.0;
  double get advanceAmount => hasAdvance ? currentBalance.abs() : 0.0;

  String get balanceStatus {
    if (hasDue) return 'Due';
    if (hasAdvance) return 'Advance';
    return 'Balanced';
  }

  String get formattedBalance {
    if (hasDue) return '₹${dueAmount.toStringAsFixed(0)} Due';
    if (hasAdvance) return '₹${advanceAmount.toStringAsFixed(0)} Advance';
    return 'Balanced';
  }
}