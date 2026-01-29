class Trip {
  final String id;
  final String userId;
  final String vehicleId;
  final String? routeId;
  final double? startLatitude;
  final double? startLongitude;
  final double? endLatitude;
  final double? endLongitude;
  final DateTime startTime;
  final DateTime? endTime;
  final int? durationMinutes;
  final double? distanceKm;
  final double? fareAmount;
  final String paymentStatus;
  final String tripStatus;

  Trip({
    required this.id,
    required this.userId,
    required this.vehicleId,
    this.routeId,
    this.startLatitude,
    this.startLongitude,
    this.endLatitude,
    this.endLongitude,
    required this.startTime,
    this.endTime,
    this.durationMinutes,
    this.distanceKm,
    this.fareAmount,
    required this.paymentStatus,
    required this.tripStatus,
  });

  factory Trip.fromJson(Map<String, dynamic> json) {
    return Trip(
      id: json['id'],
      userId: json['user_id'],
      vehicleId: json['vehicle_id'],
      routeId: json['route_id'],
      startLatitude: json['start_latitude'] != null
          ? double.parse(json['start_latitude'].toString())
          : null,
      startLongitude: json['start_longitude'] != null
          ? double.parse(json['start_longitude'].toString())
          : null,
      endLatitude: json['end_latitude'] != null
          ? double.parse(json['end_latitude'].toString())
          : null,
      endLongitude: json['end_longitude'] != null
          ? double.parse(json['end_longitude'].toString())
          : null,
      startTime: DateTime.parse(json['start_time']),
      endTime: json['end_time'] != null 
          ? DateTime.parse(json['end_time']) 
          : null,
      durationMinutes: json['duration_minutes'],
      distanceKm: json['distance_km'] != null
          ? double.parse(json['distance_km'].toString())
          : null,
      fareAmount: json['fare_amount'] != null
          ? double.parse(json['fare_amount'].toString())
          : null,
      paymentStatus: json['payment_status'],
      tripStatus: json['trip_status'],
    );
  }

  // Convert Trip to JSON for caching
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'vehicle_id': vehicleId,
      'route_id': routeId,
      'start_latitude': startLatitude,
      'start_longitude': startLongitude,
      'end_latitude': endLatitude,
      'end_longitude': endLongitude,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'duration_minutes': durationMinutes,
      'distance_km': distanceKm,
      'fare_amount': fareAmount,
      'payment_status': paymentStatus,
      'trip_status': tripStatus,
    };
  }
}