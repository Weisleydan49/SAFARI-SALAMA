// mobile/lib/services/websocket_service.dart
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter/foundation.dart';
import '../models/vehicle.dart';
import 'api_service.dart';

class WebSocketService {
  WebSocketChannel? _channel;
  final String userId;
  
  // Callbacks for when we receive data
  final Function(Vehicle)? onVehicleLocationUpdate;

  WebSocketService({
    required this.userId,
    this.onVehicleLocationUpdate,
  });

  String get _wsUrl {
    // Convert http:// to ws:// and https:// to wss://
    String wsBase = ApiService.baseUrl.replaceFirst('http://', 'ws://').replaceFirst('https://', 'wss://');
    return '$wsBase/ws/tracking/$userId';
  }

  void connect() {
    try {
      _channel = WebSocketChannel.connect(Uri.parse(_wsUrl));
      
      _channel!.stream.listen(
        (message) {
          try {
            final data = jsonDecode(message);
            if (data['type'] == 'vehicle_location_update') {
              final vehicleData = data['data'];
              // Convert the lightweight socket data into a Vehicle format we can use to update UI
              if (onVehicleLocationUpdate != null) {
                final vehicle = Vehicle(
                  id: vehicleData['vehicle_id'],
                  registrationNumber: vehicleData['registration_number'],
                  currentLatitude: vehicleData['latitude'],
                  currentLongitude: vehicleData['longitude'],
                  isOnline: true,
                  capacity: 14, // default
                  vehicleType: 'minibus',
                  createdAt: DateTime.now(),
                );
                onVehicleLocationUpdate!(vehicle);
              }
            } else if (data['status'] == 'subscribed') {
              debugPrint('Successfully subscribed to route ${data['route_id']}');
            }
          } catch (e) {
            debugPrint('Error parsing websocket message: $e');
          }
        },
        onDone: () {
          debugPrint('WebSocket connection closed');
          // Optional: Implement reconnect logic here
        },
        onError: (error) {
          debugPrint('WebSocket error: $error');
        },
      );
      debugPrint('Connected to WebSocket at $_wsUrl');
    } catch (e) {
      debugPrint('Error connecting to WebSocket: $e');
    }
  }

  void subscribeToRoute(String routeId) {
    if (_channel != null) {
      _channel!.sink.add(jsonEncode({
        'action': 'subscribe',
        'route_id': routeId,
      }));
    }
  }

  void unsubscribeFromRoute(String routeId) {
    if (_channel != null) {
      _channel!.sink.add(jsonEncode({
        'action': 'unsubscribe',
        'route_id': routeId,
      }));
    }
  }

  void disconnect() {
    if (_channel != null) {
      _channel!.sink.close();
      _channel = null;
    }
  }
}
