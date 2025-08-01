class PropertyModel {
  final String id;
  final String houseNumber;
  final String location;
  final int numberOfFlights;
  final List<int> roomsPerFlight; // Number of rooms in each flight
  final String ownerId;
  final DateTime createdAt;
  final DateTime? updatedAt;

  PropertyModel({
    required this.id,
    required this.houseNumber,
    required this.location,
    required this.numberOfFlights,
    required this.roomsPerFlight,
    required this.ownerId,
    required this.createdAt,
    this.updatedAt,
  });

  factory PropertyModel.fromMap(Map<String, dynamic> map) {
    return PropertyModel(
      id: map['id'] ?? '',
      houseNumber: map['houseNumber'] ?? '',
      location: map['location'] ?? '',
      numberOfFlights: map['numberOfFlights'] ?? 0,
      roomsPerFlight: List<int>.from(map['roomsPerFlight'] ?? []),
      ownerId: map['ownerId'] ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
      updatedAt: map['updatedAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['updatedAt'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'houseNumber': houseNumber,
      'location': location,
      'numberOfFlights': numberOfFlights,
      'roomsPerFlight': roomsPerFlight,
      'ownerId': ownerId,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt?.millisecondsSinceEpoch,
    };
  }

  PropertyModel copyWith({
    String? id,
    String? houseNumber,
    String? location,
    int? numberOfFlights,
    List<int>? roomsPerFlight,
    String? ownerId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PropertyModel(
      id: id ?? this.id,
      houseNumber: houseNumber ?? this.houseNumber,
      location: location ?? this.location,
      numberOfFlights: numberOfFlights ?? this.numberOfFlights,
      roomsPerFlight: roomsPerFlight ?? this.roomsPerFlight,
      ownerId: ownerId ?? this.ownerId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Helper method to get total rooms
  int get totalRooms => roomsPerFlight.fold(0, (sum, rooms) => sum + rooms);

  // Helper method to get property display name
  String get displayName => 'House $houseNumber, $location';
}