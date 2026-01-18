class Vehicle{
  final String id;
  final String registrationNumber;
  final String? routeId;
  final double? currentLatitude;
  final double? currentLongitude;
  final bool isOnline;
  final String vehicleType;
  final int capacity;

  Vehicle({
    required this.id,
    required this.registrationNumber,
    this.routeId,
    this.currentLatitude,
    this.currentLongitude,
    required this.isOnline,
    required this.vehicleType,
    required this.capacity,
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      id: json['id'],
      registrationNumber: json['registration_number'],
      routeId: json['route_id'],
      currentLatitude: json['current_latitude'] != null ? double.parse(
        json['current_latitude'].toString()) : null,
      currentLongitude: json['current_longitude'] != null ? double.parse(
          json['current_longitude'].toString()) : null,
      isOnline: json['is_online'] ?? false,
      vehicleType: json['vehicle_type'] ?? 'minibus',
      capacity: json['capacity'] ?? 14,
    );
  }
}