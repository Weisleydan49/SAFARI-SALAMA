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
    this.isActive = true,
    this.stops = const [],
  });

  // Convert JSON from API to RouteModel object
  factory RouteModel.fromJson(Map<String, dynamic> json) {
    final stopsList = (json['stops'] as List?) ?? [];
    final stops = stopsList
        .map((stop) => RouteStop.fromJson(stop))
        .toList();
    
    return RouteModel(
      id: json['id'],
      name: json['name'],
      routeNumber: json['route_number'],
      origin: json['origin'],
      destination: json['destination'],
      description: json['description'],
      estimatedDurationMinutes: json['estimated_duration_minutes'],
      distanceKm: json['distance_km']?.toDouble(),
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
    return RouteStop(
      sequence: json['sequence'] ?? 0,
      stopName: json['stop']['name'] ?? json['stop'] ?? 'Unknown',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sequence': sequence,
      'stop': {'name': stopName},
    };
  }
}