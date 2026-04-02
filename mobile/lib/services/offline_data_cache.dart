// mobile/lib/services/offline_data_cache.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class OfflineDataCache {
  static const String _routesKey = 'cached_routes';
  static const String _vehiclesKey = 'cached_vehicles';
  static const String _routesTimestampKey = 'routes_cache_timestamp';
  static const String _vehiclesTimestampKey = 'vehicles_cache_timestamp';
  static const int _cacheValidityDays = 7;

  // Cache routes data locally
  static Future<void> cacheRoutes(List<Map<String, dynamic>> routes) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final routesJson = jsonEncode(routes);
      await prefs.setString(_routesKey, routesJson);
      await prefs.setInt(_routesTimestampKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      print('Error caching routes: $e');
    }
  }

  // Get cached routes
  static Future<List<Map<String, dynamic>>?> getCachedRoutes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Check if cache is still valid
      if (!isCacheValid(
        await prefs.getInt(_routesTimestampKey),
      )) {
        return null; // Cache expired
      }

      final routesJson = prefs.getString(_routesKey);
      if (routesJson == null) return null;

      final List<dynamic> decoded = jsonDecode(routesJson);
      return decoded.cast<Map<String, dynamic>>();
    } catch (e) {
      print('Error retrieving cached routes: $e');
      return null;
    }
  }

  // Cache vehicles data locally
  static Future<void> cacheVehicles(List<Map<String, dynamic>> vehicles) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final vehiclesJson = jsonEncode(vehicles);
      await prefs.setString(_vehiclesKey, vehiclesJson);
      await prefs.setInt(_vehiclesTimestampKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      print('Error caching vehicles: $e');
    }
  }

  // Get cached vehicles
  static Future<List<Map<String, dynamic>>?> getCachedVehicles() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Check if cache is still valid
      if (!isCacheValid(
        await prefs.getInt(_vehiclesTimestampKey),
      )) {
        return null; // Cache expired
      }

      final vehiclesJson = prefs.getString(_vehiclesKey);
      if (vehiclesJson == null) return null;

      final List<dynamic> decoded = jsonDecode(vehiclesJson);
      return decoded.cast<Map<String, dynamic>>();
    } catch (e) {
      print('Error retrieving cached vehicles: $e');
      return null;
    }
  }

  // Check if cache is still valid
  static bool isCacheValid(int? timestamp) {
    if (timestamp == null) return false;
    
    final cachedTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final difference = now.difference(cachedTime).inDays;
    
    return difference < _cacheValidityDays;
  }

  // Clear all cache
  static Future<void> clearAllCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_routesKey);
      await prefs.remove(_vehiclesKey);
      await prefs.remove(_routesTimestampKey);
      await prefs.remove(_vehiclesTimestampKey);
    } catch (e) {
      print('Error clearing cache: $e');
    }
  }

  // Get cache info
  static Future<Map<String, dynamic>> getCacheInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      return {
        'routes_cached': prefs.containsKey(_routesKey),
        'vehicles_cached': prefs.containsKey(_vehiclesKey),
        'routes_count': _getListLength(prefs.getString(_routesKey)),
        'vehicles_count': _getListLength(prefs.getString(_vehiclesKey)),
      };
    } catch (e) {
      return {};
    }
  }

  static int _getListLength(String? jsonStr) {
    if (jsonStr == null) return 0;
    try {
      final decoded = jsonDecode(jsonStr);
      if (decoded is List) return decoded.length;
      return 0;
    } catch (e) {
      return 0;
    }
  }
}
