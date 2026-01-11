// Model to represent a matatu route
class RouteModel {
  final String id;
  final String name;
  final String routeNumber;
  final String origin;
  final String destination;
  final String? description;
  final int? estimatedDurationMinutes;
  final double? distanceKm;
  final double? fareAmount; // Added this field
  final bool isActive;
  final List<RouteStop> stops;

  RouteModel({
    required this.id,
    required this.name,
    required this.routeNumber,
    required this.origin,
    required this.destination,
    this.description,
    this.estimatedDurationMinutes,
    this.distanceKm,
    this.fareAmount, // Added this parameter
    this.isActive = true,
    this.stops = const [],
  });

  // Convert JSON from API to RouteModel object
  factory RouteModel.fromJson(Map<String, dynamic> json) {
    // Parse stops list from API response
    final stopsList = (json['stops'] as List?) ?? [];
    final stops = stopsList
        .map((stop) => RouteStop.fromJson(stop))
        .toList();

    // Helper function to safely convert string or number to double
    double? parseDouble(dynamic value) {
      if (value == null) return null;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value);
      return null;
    }

    return RouteModel(
      id: json['id'],
      name: json['name'],
      routeNumber: json['route_number'],
      origin: json['origin'],
      destination: json['destination'],
      description: json['description'],
      estimatedDurationMinutes: json['estimated_duration_minutes'],
      distanceKm: parseDouble(json['distance_km']), // Handles string or number
      fareAmount: parseDouble(json['fare_amount']), // Handles string or number
      isActive: json['is_active'] ?? true,
      stops: stops,
    );
  }

  // Convert RouteModel object to JSON for API
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'route_number': routeNumber,
      'origin': origin,
      'destination': destination,
      'description': description,
      'estimated_duration_minutes': estimatedDurationMinutes,
      'distance_km': distanceKm,
      'fare_amount': fareAmount,
      'is_active': isActive,
      'stops': stops.map((s) => s.toJson()).toList(),
    };
  }
}

// Model for route stops/waypoints
class RouteStop {
  final int sequence;
  final String stopName;

  RouteStop({
    required this.sequence,
    required this.stopName,
  });

  factory RouteStop.fromJson(Map<String, dynamic> json) {
    final stop = json['stop'];

    String stopName;
    if (stop is Map<String, dynamic>) {
      stopName = (stop['name'] ?? 'Unknown').toString();
    } else if (stop != null) {
      stopName = stop.toString(); // stop is a String
    } else if (json['stop_name'] != null) {
      stopName = json['stop_name'].toString(); // fallback if backend uses stop_name
    } else {
      stopName = 'Unknown';
    }

    final seq = json['sequence'];
    final sequence = (seq is int) ? seq : int.tryParse(seq?.toString() ?? '0') ?? 0;

    return RouteStop(
      sequence: sequence,
      stopName: stopName,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sequence': sequence,
      'stop': {'name': stopName},
    };
  }
}