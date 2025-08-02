class PaymentModel {
  final String id;
  final String tenantId;
  final String tenantName;
  final String? billId; // Reference to bill if payment is against a specific bill
  final DateTime paymentDate;
  final double amount;
  final String paymentType; // "Cash", "Bank Transfer", "UPI", "Cheque"
  final String description;
  final String status; // "Paid", "Due", "Advance"
  final double balanceAmount; // Positive for advance, negative for due
  final String? notes;
  final DateTime createdAt;
  final DateTime? updatedAt;

  PaymentModel({
    required this.id,
    required this.tenantId,
    required this.tenantName,
    this.billId,
    required this.paymentDate,
    required this.amount,
    required this.paymentType,
    required this.description,
    required this.status,
    this.balanceAmount = 0.0,
    this.notes,
    required this.createdAt,
    this.updatedAt,
  });

  factory PaymentModel.fromMap(Map<String, dynamic> map) {
    return PaymentModel(
      id: map['id'] ?? '',
      tenantId: map['tenantId'] ?? '',
      tenantName: map['tenantName'] ?? '',
      billId: map['billId'],
      paymentDate: DateTime.fromMillisecondsSinceEpoch(map['paymentDate'] ?? 0),
      amount: (map['amount'] ?? 0).toDouble(),
      paymentType: map['paymentType'] ?? '',
      description: map['description'] ?? '',
      status: map['status'] ?? 'Paid',
      balanceAmount: (map['balanceAmount'] ?? 0).toDouble(),
      notes: map['notes'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
      updatedAt: map['updatedAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['updatedAt'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tenantId': tenantId,
      'tenantName': tenantName,
      'billId': billId,
      'paymentDate': paymentDate.millisecondsSinceEpoch,
      'amount': amount,
      'paymentType': paymentType,
      'description': description,
      'status': status,
      'balanceAmount': balanceAmount,
      'notes': notes,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt?.millisecondsSinceEpoch,
    };
  }

  PaymentModel copyWith({
    String? id,
    String? tenantId,
    String? tenantName,
    String? billId,
    DateTime? paymentDate,
    double? amount,
    String? paymentType,
    String? description,
    String? status,
    double? balanceAmount,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PaymentModel(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      tenantName: tenantName ?? this.tenantName,
      billId: billId ?? this.billId,
      paymentDate: paymentDate ?? this.paymentDate,
      amount: amount ?? this.amount,
      paymentType: paymentType ?? this.paymentType,
      description: description ?? this.description,
      status: status ?? this.status,
      balanceAmount: balanceAmount ?? this.balanceAmount,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Helper methods
  String get formattedDate {
    return '${paymentDate.day}/${paymentDate.month}/${paymentDate.year}';
  }

  String get statusColor {
    switch (status.toLowerCase()) {
      case 'paid':
        return 'green';
      case 'due':
        return 'red';
      case 'advance':
        return 'blue';
      default:
        return 'grey';
    }
  }
}