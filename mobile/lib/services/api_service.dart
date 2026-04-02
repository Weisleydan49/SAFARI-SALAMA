// mobile/lib/services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;



class ApiService {
  //Use different url for web vs mobile
  static final String baseUrl = kIsWeb
      ? 'https://safarisalama-api.onrender.com'
      : (dotenv.env['API_BASE_URL'] ?? 'http://192.168.1.198:8000');
  // static final String baseUrl =! : dotenv.env['API_BASE_URL']!;


  // Helper method to get headers
  static Map<String, String> _getHeaders({String? token}) {
    final headers = {
      'Content-Type': 'application/json',
    };

    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  // Register user
  static Future<Map<String, dynamic>> register({
    required String phone,
    required String name,
    String? email,
    required String password,
    String userType = 'passenger',
  }) async {
    final url = Uri.parse('$baseUrl/api/auth/register');

    final response = await http.post(
      url,
      headers: _getHeaders(),
      body: jsonEncode({
        'phone': phone,
        'name': name,
        'email': email,
        'password': password,
        'user_type': userType,
      }),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Registration failed: ${response.body}');
    }
  }

  // Login user
  static Future<Map<String, dynamic>> login({
    required String phone,
    required String password,
  }) async {
    final url = Uri.parse('$baseUrl/api/auth/login');

    final response = await http.post(
      url,
      headers: _getHeaders(),
      body: jsonEncode({
        'phone': phone,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Login failed: ${response.body}');
    }
  }

  // Get all routes
  static Future<List<dynamic>> getRoutes() async {
    final url = Uri.parse('$baseUrl/api/routes');

    final response = await http.get(
      url,
      headers: _getHeaders(),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load routes');
    }
  }

  // Get vehicle locations
  static Future<List<dynamic>> getVehicleLocations({String? routeId}) async {
    var url = '$baseUrl/api/vehicles/location';
    if (routeId != null) {
      url += '?route_id=$routeId&is_online=true';
    }

    final response = await http.get(
      Uri.parse(url),
      headers: _getHeaders(),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load vehicles');
    }
  }

  // NEW METHOD: Get vehicles by route ID
  static Future<List<dynamic>> getVehiclesByRoute(String routeId) async {
    final url = Uri.parse('$baseUrl/api/vehicles/location?route_id=$routeId&is_online=true');

    final response = await http.get(
      url,
      headers: _getHeaders(),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load vehicles for route');
    }
  }

  // Start trip
  static Future<Map<String, dynamic>> startTrip({
    required String userId,
    String? vehicleId,
    required double startLatitude,
    required double startLongitude,
    String? routeId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    // userId must be passed as a query parameter as expected by the backend
    final response = await http.post(
      Uri.parse('$baseUrl/api/trips/start?user_id=$userId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        if (vehicleId != null && vehicleId.isNotEmpty) 'vehicle_id': vehicleId,
        'start_latitude': startLatitude,
        'start_longitude': startLongitude,
        if (routeId != null) 'route_id': routeId,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to start trip: ${response.body}');
    }
  }


  // End trip
  static Future<Map<String, dynamic>> endTrip({
    required String tripId,
    required double endLatitude,
    required double endLongitude,
  }) async {
    final url = Uri.parse('$baseUrl/api/trips/$tripId/end');

    final response = await http.patch(
      url,
      headers: _getHeaders(),
      body: jsonEncode({
        'end_latitude': endLatitude,
        'end_longitude': endLongitude,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to end trip: ${response.body}');
    }
  }

  // Send emergency alert
  static Future<Map<String, dynamic>> sendEmergencyAlert({
    required String userId,
    required double latitude,
    required double longitude,
    String alertType = 'general',
    String? description,
    String? vehicleId,
    String? tripId,
  }) async {
    final url = Uri.parse('$baseUrl/api/emergency?user_id=$userId');

    final response = await http.post(
      url,
      headers: _getHeaders(),
      body: jsonEncode({
        'alert_type': alertType,
        'latitude': latitude,
        'longitude': longitude,
        'description': description,
        'vehicle_id': vehicleId,
        'trip_id': tripId,
      }),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to send emergency alert: ${response.body}');
    }
  }

  // Get user's active trip
  static Future<Map<String, dynamic>?> getActiveTrip(String userId) async {
    final url = Uri.parse('$baseUrl/api/trips/user/$userId/active');

    final response = await http.get(
      url,
      headers: _getHeaders(),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 404) {
      return null; // No active trip
    } else {
      throw Exception('Failed to get active trip');
    }
  }

  // Sync queued location updates (for offline trips)
  static Future<Map<String, dynamic>> syncTripLocations({
    required String tripId,
    required List<Map<String, dynamic>> locations,
  }) async {
    final url = Uri.parse('$baseUrl/api/trips/$tripId/sync-locations');

    final response = await http.post(
      url,
      headers: _getHeaders(),
      body: jsonEncode({
        'locations': locations,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to sync trip locations: ${response.body}');
    }
  }

  // Get user profile
  static Future<Map<String, dynamic>> getUserProfile({
    required String userId,
    String? token,
  }) async {
    final url = Uri.parse('$baseUrl/api/users/$userId');

    final response = await http.get(
      url,
      headers: _getHeaders(token: token),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch user profile: ${response.body}');
    }
  }

  // Update user profile
  static Future<Map<String, dynamic>> updateUserProfile({
    required String userId,
    String? name,
    String? email,
    String? profilePhotoUrl,
    String? token,
  }) async {
    final url = Uri.parse('$baseUrl/api/users/$userId/profile');

    final body = {};
    if (name != null) body['name'] = name;
    if (email != null) body['email'] = email;
    if (profilePhotoUrl != null) body['profile_photo_url'] = profilePhotoUrl;

    final response = await http.patch(
      url,
      headers: _getHeaders(token: token),
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to update profile: ${response.body}');
    }
  }

  // Get trip history
  static Future<List<Map<String, dynamic>>> getTripHistory({
    required String userId,
    int skip = 0,
    int limit = 20,
    String? token,
  }) async {
    final url = Uri.parse('$baseUrl/api/trips/user/$userId/history?skip=$skip&limit=$limit');

    final response = await http.get(
      url,
      headers: _getHeaders(token: token),
    );

    if (response.statusCode == 200) {
      final List<dynamic> trips = jsonDecode(response.body);
      return trips.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to fetch trip history: ${response.body}');
    }
  }

  // Get driver dashboard
  static Future<Map<String, dynamic>> getDriverDashboard({
    required String driverId,
    String? token,
  }) async {
    final url = Uri.parse('$baseUrl/api/drivers/$driverId/dashboard');

    final response = await http.get(
      url,
      headers: _getHeaders(token: token),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch driver dashboard: ${response.body}');
    }
  }

  // Get driver earnings
  static Future<Map<String, dynamic>> getDriverEarnings({
    required String driverId,
    int days = 7,
    String? token,
  }) async {
    final url = Uri.parse('$baseUrl/api/drivers/$driverId/earnings?days=$days');

    final response = await http.get(
      url,
      headers: _getHeaders(token: token),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch driver earnings: ${response.body}');
    }
  }

  // Get driver rating
  static Future<Map<String, dynamic>> getDriverRating({
    required String driverId,
    String? token,
  }) async {
    final url = Uri.parse('$baseUrl/api/drivers/$driverId/rating');

    final response = await http.get(
      url,
      headers: _getHeaders(token: token),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch driver rating: ${response.body}');
    }
  }

  static Future<Map<String, dynamic>?> validateToken(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/auth/me'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // PAYMENT METHODS
  
  // Create payment for a trip
  static Future<Map<String, dynamic>> createPayment({
    required String tripId,
    required String amount,
    String paymentMethod = 'mpesa',
    String? phoneNumber,
    String? token,
  }) async {
    final url = Uri.parse('$baseUrl/api/payments/create');

    final response = await http.post(
      url,
      headers: _getHeaders(token: token),
      body: jsonEncode({
        'trip_id': tripId,
        'amount': amount,
        'payment_method': paymentMethod,
        if (phoneNumber != null) 'phone_number': phoneNumber,
      }),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to create payment: ${response.body}');
    }
  }

  // Get payment details
  static Future<Map<String, dynamic>> getPayment({
    required String paymentId,
    String? token,
  }) async {
    final url = Uri.parse('$baseUrl/api/payments/$paymentId');

    final response = await http.get(
      url,
      headers: _getHeaders(token: token),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch payment: ${response.body}');
    }
  }

  // Get payment history for user
  static Future<List<Map<String, dynamic>>> getPaymentHistory({
    required String userId,
    int skip = 0,
    int limit = 20,
    String? token,
  }) async {
    final url = Uri.parse('$baseUrl/api/payments/user/$userId/history?skip=$skip&limit=$limit');

    final response = await http.get(
      url,
      headers: _getHeaders(token: token),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> payments = data['payments'] ?? [];
      return payments.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to fetch payment history: ${response.body}');
    }
  }

  // RATING METHODS
  
  // Create a rating for a trip
  static Future<Map<String, dynamic>> createRating({
    required String tripId,
    required String driverId,
    required int score,
    String? feedback,
    String? passengerId,
    String? token,
  }) async {
    final url = Uri.parse('$baseUrl/api/ratings/?passenger_id=$passengerId');

    final response = await http.post(
      url,
      headers: _getHeaders(token: token),
      body: jsonEncode({
        'trip_id': tripId,
        'driver_id': driverId,
        'score': score,
        if (feedback != null) 'feedback': feedback,
      }),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to create rating: ${response.body}');
    }
  }

  // Get driver ratings
  static Future<Map<String, dynamic>> getDriverRatings({
    required String driverId,
    String? token,
  }) async {
    final url = Uri.parse('$baseUrl/api/ratings/driver/$driverId');

    final response = await http.get(
      url,
      headers: _getHeaders(token: token),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch driver ratings: ${response.body}');
    }
  }

  // Get trip rating
  static Future<Map<String, dynamic>> getTripRating({
    required String tripId,
    String? token,
  }) async {
    final url = Uri.parse('$baseUrl/api/ratings/trip/$tripId');

    final response = await http.get(
      url,
      headers: _getHeaders(token: token),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 404) {
      return {}; // No rating yet
    } else {
      throw Exception('Failed to fetch trip rating: ${response.body}');
    }
  }

  // SACCO/ADMIN METHODS
  
  // Get Sacco details
  static Future<Map<String, dynamic>> getSacco({
    required String saccoId,
    String? token,
  }) async {
    final url = Uri.parse('$baseUrl/api/admin/saccos/$saccoId');

    final response = await http.get(
      url,
      headers: _getHeaders(token: token),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch sacco: ${response.body}');
    }
  }

  // Get Sacco vehicles
  static Future<List<Map<String, dynamic>>> getSaccoVehicles({
    required String saccoId,
    String? token,
  }) async {
    final url = Uri.parse('$baseUrl/api/admin/saccos/$saccoId/vehicles');

    final response = await http.get(
      url,
      headers: _getHeaders(token: token),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> vehicles = data['vehicles'] ?? [];
      return vehicles.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to fetch sacco vehicles: ${response.body}');
    }
  }

  // Get Sacco drivers
  static Future<List<Map<String, dynamic>>> getSaccoDrivers({
    required String saccoId,
    String? token,
  }) async {
    final url = Uri.parse('$baseUrl/api/admin/saccos/$saccoId/drivers');

    final response = await http.get(
      url,
      headers: _getHeaders(token: token),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> drivers = data['drivers'] ?? [];
      return drivers.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to fetch sacco drivers: ${response.body}');
    }
  }

  // Get Sacco analytics
  static Future<Map<String, dynamic>> getSaccoAnalytics({
    required String saccoId,
    int days = 30,
    String? token,
  }) async {
    final url = Uri.parse('$baseUrl/api/admin/saccos/$saccoId/analytics?days=$days');

    final response = await http.get(
      url,
      headers: _getHeaders(token: token),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch sacco analytics: ${response.body}');
    }
  }
}

