// Centralized API configuration
import 'package:flutter/foundation.dart'; //for kRelease mode

class ApiConfig {
  static String get baseUrl {
    if (kReleaseMode) {
      // This is used for 'flutter build web'
      return 'https://safarisalama-api.onrender.com';
    } else {
      // This is used for debugging on your physical device.
      // Replace with your computer's IP (e.g., 192.168.1.XX)
      return 'http://192.168.1.15:8000';
    }
  }

  static const String loginEndpoint = '/api/auth/login';
  static const String routesEndpoint = '/api/routes';
  static const String vehiclesEndpoint = '/api/vehicles';
  static const String emergencyEndpoint = '/api/emergency';
// Timeout duration for API requests
  static const Duration timeout = Duration(seconds: 10);
}
