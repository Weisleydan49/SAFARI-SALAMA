import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/route_model.dart';
import '../config/api_config.dart';

class RouteService {
  // Fetch all available routes from the API
  Future<List<RouteModel>> getRoutes() async {
    try {
      // Make GET request to routes endpoint
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/routes'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      // Check if request was successful
      if (response.statusCode == 200) {
        // Decode JSON response
        final List<dynamic> data = json.decode(response.body);
        
        // Convert each JSON object to RouteModel
        return data.map((json) => RouteModel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load routes: ${response.statusCode}');
      }
    } catch (e) {
      // Handle any errors (network, timeout, etc.)
      throw Exception('Error fetching routes: $e');
    }
  }

  // Search routes by destination name
  Future<List<RouteModel>> searchRoutes(String query) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/routes/search?q=$query'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => RouteModel.fromJson(json)).toList();
      } else {
        throw Exception('Search failed: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error searching routes: $e');
    }
  }
}