class TenantModel {
  final String id;
  final String tenantName;
  final double roomRent; // Required field
  final String ownerId;
  
  // Optional bills with checkbox flags
  final bool hasWaterBill;
  final double? waterBillAmount;
  
  final bool hasElectricityBill;
  final double? electricityUnitFee;
  
  final bool hasGarbageBill;
  final double? garbageBillAmount;
  
  final DateTime createdAt;
  final DateTime? updatedAt;

  TenantModel({
    required this.id,
    required this.tenantName,
    required this.roomRent,
    required this.ownerId,
    this.hasWaterBill = false,
    this.waterBillAmount,
    this.hasElectricityBill = false,
    this.electricityUnitFee,
    this.hasGarbageBill = false,
    this.garbageBillAmount,
    required this.createdAt,
    this.updatedAt,
  });

  factory TenantModel.fromMap(Map<String, dynamic> map) {
    return TenantModel(
      id: map['id'] ?? '',
      tenantName: map['tenantName'] ?? '',
      roomRent: (map['roomRent'] ?? 0).toDouble(),
      ownerId: map['ownerId'] ?? '',
      hasWaterBill: map['hasWaterBill'] ?? false,
      waterBillAmount: map['waterBillAmount']?.toDouble(),
      hasElectricityBill: map['hasElectricityBill'] ?? false,
      electricityUnitFee: map['electricityUnitFee']?.toDouble(),
      hasGarbageBill: map['hasGarbageBill'] ?? false,
      garbageBillAmount: map['garbageBillAmount']?.toDouble(),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
      updatedAt: map['updatedAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['updatedAt'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tenantName': tenantName,
      'roomRent': roomRent,
      'ownerId': ownerId,
      'hasWaterBill': hasWaterBill,
      'waterBillAmount': waterBillAmount,
      'hasElectricityBill': hasElectricityBill,
      'electricityUnitFee': electricityUnitFee,
      'hasGarbageBill': hasGarbageBill,
      'garbageBillAmount': garbageBillAmount,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt?.millisecondsSinceEpoch,
    };
  }

  TenantModel copyWith({
    String? id,
    String? tenantName,
    double? roomRent,
    String? ownerId,
    bool? hasWaterBill,
    double? waterBillAmount,
    bool? hasElectricityBill,
    double? electricityUnitFee,
    bool? hasGarbageBill,
    double? garbageBillAmount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TenantModel(
      id: id ?? this.id,
      tenantName: tenantName ?? this.tenantName,
      roomRent: roomRent ?? this.roomRent,
      ownerId: ownerId ?? this.ownerId,
      hasWaterBill: hasWaterBill ?? this.hasWaterBill,
      waterBillAmount: waterBillAmount ?? this.waterBillAmount,
      hasElectricityBill: hasElectricityBill ?? this.hasElectricityBill,
      electricityUnitFee: electricityUnitFee ?? this.electricityUnitFee,
      hasGarbageBill: hasGarbageBill ?? this.hasGarbageBill,
      garbageBillAmount: garbageBillAmount ?? this.garbageBillAmount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Helper method to calculate total monthly cost
  double get totalMonthlyCost {
    double total = roomRent;
    
    if (hasWaterBill && waterBillAmount != null) {
      total += waterBillAmount!;
    }
    
    if (hasElectricityBill && electricityUnitFee != null) {
      // Note: For electricity, this is per unit fee, actual bill would depend on usage
      // For display purposes, we'll just show the unit fee
      total += electricityUnitFee!;
    }
    
    if (hasGarbageBill && garbageBillAmount != null) {
      total += garbageBillAmount!;
    }
    
    return total;
  }

  // Helper method to get display name
  String get displayName => tenantName;
}