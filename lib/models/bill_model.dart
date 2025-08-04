class BillModel {
  final String id;
  final String tenantId;
  final String tenantName;
  final DateTime billDate;
  final String billMonth; // Format: "YYYY-MM"
  
  // Fixed charges
  final double roomRent;
  final bool includeWater;
  final double? waterAmount;
  final bool includeGarbage;
  final double? garbageAmount;
  
  // Electricity details
  final bool includeElectricity;
  final double? electricityAmount;
  
  // Carry-forward amount from previous bills/payments
  final double carryForwardAmount; // Positive = Due, Negative = Advance
  
  // Totals
  final double totalAmount;
  final String status; // "Unpaid", "Paid", "Partial", "Overdue"
  final double paidAmount;
  final double balanceAmount;
  
  final DateTime createdAt;
  final DateTime? updatedAt;

  BillModel({
    required this.id,
    required this.tenantId,
    required this.tenantName,
    required this.billDate,
    required this.billMonth,
    required this.roomRent,
    this.includeWater = false,
    this.waterAmount,
    this.includeGarbage = false,
    this.garbageAmount,
    this.includeElectricity = false,
    this.electricityAmount,
    this.carryForwardAmount = 0.0,
    required this.totalAmount,
    this.status = 'Unpaid',
    this.paidAmount = 0.0,
    this.balanceAmount = 0.0,
    required this.createdAt,
    this.updatedAt,
  });

  factory BillModel.fromMap(Map<String, dynamic> map) {
    return BillModel(
      id: map['id'] ?? '',
      tenantId: map['tenantId'] ?? '',
      tenantName: map['tenantName'] ?? '',
      billDate: DateTime.fromMillisecondsSinceEpoch(map['billDate'] ?? 0),
      billMonth: map['billMonth'] ?? '',
      roomRent: (map['roomRent'] ?? 0).toDouble(),
      includeWater: map['includeWater'] ?? false,
      waterAmount: map['waterAmount']?.toDouble(),
      includeGarbage: map['includeGarbage'] ?? false,
      garbageAmount: map['garbageAmount']?.toDouble(),
      includeElectricity: map['includeElectricity'] ?? false,
      electricityAmount: map['electricityAmount']?.toDouble(),
      carryForwardAmount: (map['carryForwardAmount'] ?? 0).toDouble(),
      totalAmount: (map['totalAmount'] ?? 0).toDouble(),
      status: map['status'] ?? 'Unpaid',
      paidAmount: (map['paidAmount'] ?? 0).toDouble(),
      balanceAmount: (map['balanceAmount'] ?? 0).toDouble(),
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
      'billDate': billDate.millisecondsSinceEpoch,
      'billMonth': billMonth,
      'roomRent': roomRent,
      'includeWater': includeWater,
      'waterAmount': waterAmount,
      'includeGarbage': includeGarbage,
      'garbageAmount': garbageAmount,
      'includeElectricity': includeElectricity,
      'electricityAmount': electricityAmount,
      'carryForwardAmount': carryForwardAmount,
      'totalAmount': totalAmount,
      'status': status,
      'paidAmount': paidAmount,
      'balanceAmount': balanceAmount,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt?.millisecondsSinceEpoch,
    };
  }

  BillModel copyWith({
    String? id,
    String? tenantId,
    String? tenantName,
    DateTime? billDate,
    String? billMonth,
    double? roomRent,
    bool? includeWater,
    double? waterAmount,
    bool? includeGarbage,
    double? garbageAmount,
    bool? includeElectricity,
    double? electricityAmount,
    double? carryForwardAmount,
    double? totalAmount,
    String? status,
    double? paidAmount,
    double? balanceAmount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BillModel(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      tenantName: tenantName ?? this.tenantName,
      billDate: billDate ?? this.billDate,
      billMonth: billMonth ?? this.billMonth,
      roomRent: roomRent ?? this.roomRent,
      includeWater: includeWater ?? this.includeWater,
      waterAmount: waterAmount ?? this.waterAmount,
      includeGarbage: includeGarbage ?? this.includeGarbage,
      garbageAmount: garbageAmount ?? this.garbageAmount,
      includeElectricity: includeElectricity ?? this.includeElectricity,
      electricityAmount: electricityAmount ?? this.electricityAmount,
      carryForwardAmount: carryForwardAmount ?? this.carryForwardAmount,
      totalAmount: totalAmount ?? this.totalAmount,
      status: status ?? this.status,
      paidAmount: paidAmount ?? this.paidAmount,
      balanceAmount: balanceAmount ?? this.balanceAmount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Helper methods
  String get formattedBillMonth {
    final parts = billMonth.split('-');
    if (parts.length == 2) {
      final year = parts[0];
      final month = int.parse(parts[1]);
      final monthNames = [
        '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${monthNames[month]} $year';
    }
    return billMonth;
  }

  double get remainingBalance => totalAmount - paidAmount;
  
  bool get isFullyPaid => paidAmount >= totalAmount;
  
  bool get isOverdue {
    final now = DateTime.now();
    final dueDate = DateTime(billDate.year, billDate.month + 1, 10); // Due by 10th of next month
    return now.isAfter(dueDate) && !isFullyPaid;
  }
}