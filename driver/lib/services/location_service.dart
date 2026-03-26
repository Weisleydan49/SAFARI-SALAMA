import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'network_service.dart';

class LocationService {
  StreamSubscription<Position>? _positionStream;

  Future<bool> handlePermissions() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    // Also check for background permission if needed
    if (await Permission.locationAlways.isDenied) {
      await Permission.locationAlways.request();
    }

    return true;
  }

  void startTracking(String driverId) {
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    );

    _positionStream = Geolocator.getPositionStream(locationSettings: locationSettings).listen(
      (Position position) {
        _sendLocationToBackend(driverId, position);
      },
    );
  }

  void stopTracking() {
    _positionStream?.cancel();
    _positionStream = null;
  }

  Future<void> _sendLocationToBackend(String driverId, Position position) async {
    try {
      final response = await NetworkService.post('drivers/update-location', {
        'driver_id': driverId,
        'latitude': position.latitude,
        'longitude': position.longitude,
        'timestamp': position.timestamp.toIso8601String(),
      });
      
      if (response.statusCode != 200) {
        print('Failed to update location: ${response.statusCode}');
      }
    } catch (e) {
      print('Error sending location: $e');
    }
  }
}
