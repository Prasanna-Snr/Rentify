class InquiryModel {
  final String id;
  final String propertyId;
  final String propertyTitle;
  final String inquirerName;
  final String inquirerEmail;
  final String inquirerPhone;
  final String message;
  final String status; // pending, responded, closed
  final DateTime createdAt;
  final DateTime? respondedAt;

  InquiryModel({
    required this.id,
    required this.propertyId,
    required this.propertyTitle,
    required this.inquirerName,
    required this.inquirerEmail,
    required this.inquirerPhone,
    required this.message,
    this.status = 'pending',
    required this.createdAt,
    this.respondedAt,
  });

  factory InquiryModel.fromMap(Map<String, dynamic> map) {
    return InquiryModel(
      id: map['id'] ?? '',
      propertyId: map['propertyId'] ?? '',
      propertyTitle: map['propertyTitle'] ?? '',
      inquirerName: map['inquirerName'] ?? '',
      inquirerEmail: map['inquirerEmail'] ?? '',
      inquirerPhone: map['inquirerPhone'] ?? '',
      message: map['message'] ?? '',
      status: map['status'] ?? 'pending',
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
      respondedAt: map['respondedAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['respondedAt'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'propertyId': propertyId,
      'propertyTitle': propertyTitle,
      'inquirerName': inquirerName,
      'inquirerEmail': inquirerEmail,
      'inquirerPhone': inquirerPhone,
      'message': message,
      'status': status,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'respondedAt': respondedAt?.millisecondsSinceEpoch,
    };
  }

  InquiryModel copyWith({
    String? id,
    String? propertyId,
    String? propertyTitle,
    String? inquirerName,
    String? inquirerEmail,
    String? inquirerPhone,
    String? message,
    String? status,
    DateTime? createdAt,
    DateTime? respondedAt,
  }) {
    return InquiryModel(
      id: id ?? this.id,
      propertyId: propertyId ?? this.propertyId,
      propertyTitle: propertyTitle ?? this.propertyTitle,
      inquirerName: inquirerName ?? this.inquirerName,
      inquirerEmail: inquirerEmail ?? this.inquirerEmail,
      inquirerPhone: inquirerPhone ?? this.inquirerPhone,
      message: message ?? this.message,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      respondedAt: respondedAt ?? this.respondedAt,
    );
  }
}