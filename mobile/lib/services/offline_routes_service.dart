// mobile/lib/services/offline_routes_service.dart
import 'package:connectivity_plus/connectivity_plus.dart';
import 'offline_data_cache.dart';
import 'api_service.dart';

class OfflineRoutesService {
  static final Connectivity _connectivity = Connectivity();

  // Get routes with offline fallback
  static Future<List<Map<String, dynamic>>> getRoutesWithFallback() async {
    try {
      // Check connectivity
      final connectivityResult = await _connectivity.checkConnectivity();
      final isOnline = connectivityResult != ConnectivityResult.none;

      if (isOnline) {
        try {
          // Try to fetch from API
          final routes = await ApiService.getRoutes();
          
          // Cache the results
          await OfflineDataCache.cacheRoutes(
            routes.cast<Map<String, dynamic>>()
          );
          
          return routes.cast<Map<String, dynamic>>();
        } catch (e) {
          print('Failed to fetch routes from API: $e');
          // Fall through to cache fallback
        }
      }

      // Use cached data as fallback
      final cachedRoutes = await OfflineDataCache.getCachedRoutes();
      if (cachedRoutes != null && cachedRoutes.isNotEmpty) {
        print('Using cached routes (${cachedRoutes.length} routes)');
        return cachedRoutes;
      }

      // No data available
      throw Exception('No routes available. Please check your connection and try again.');
    } catch (e) {
      rethrow;
    }
  }

  // Get route details with offline fallback
  static Future<Map<String, dynamic>> getRouteWithFallback(String routeId) async {
    try {
      // Check connectivity
      final connectivityResult = await _connectivity.checkConnectivity();
      final isOnline = connectivityResult != ConnectivityResult.none;

      if (isOnline) {
        try {
          // Try to fetch from API
          final routes = await ApiService.getRoutes();
          
          // Find the route with matching ID
          for (var r in routes) {
            if (r['id'] == routeId) {
              return r as Map<String, dynamic>;
            }
          }
        } catch (e) {
          print('Failed to fetch route from API: $e');
        }
      }

      // Use cached data as fallback
      final cachedRoutes = await OfflineDataCache.getCachedRoutes();
      if (cachedRoutes != null && cachedRoutes.isNotEmpty) {
        for (var r in cachedRoutes) {
          if (r['id'] == routeId) {
            print('Using cached route');
            return r;
          }
        }
      }

      throw Exception('Route not found and no cached data available.');
    } catch (e) {
      rethrow;
    }
  }

  // Get vehicles with offline fallback
  static Future<List<Map<String, dynamic>>> getVehiclesWithFallback({String? routeId}) async {
    try {
      // Check connectivity
      final connectivityResult = await _connectivity.checkConnectivity();
      final isOnline = connectivityResult != ConnectivityResult.none;

      if (isOnline) {
        try {
          // Try to fetch from API
          final vehicles = await ApiService.getVehicleLocations(routeId: routeId);
          
          // Cache the results
          await OfflineDataCache.cacheVehicles(
            vehicles.cast<Map<String, dynamic>>()
          );
          
          return vehicles.cast<Map<String, dynamic>>();
        } catch (e) {
          print('Failed to fetch vehicles from API: $e');
        }
      }

      // Use cached data as fallback
      final cachedVehicles = await OfflineDataCache.getCachedVehicles();
      if (cachedVehicles != null && cachedVehicles.isNotEmpty) {
        print('Using cached vehicles (${cachedVehicles.length} vehicles)');
        
        // Filter by route if needed
        if (routeId != null) {
          return cachedVehicles
            .where((v) => v['route_id'] == routeId)
            .toList()
            .cast<Map<String, dynamic>>();
        }
        
        return cachedVehicles;
      }

      // Return empty list if no data
      print('No vehicles available');
      return [];
    } catch (e) {
      print('Error getting vehicles: $e');
      return [];
    }
  }

  // Check if device is online
  static Future<bool> isOnline() async {
    try {
      final result = await _connectivity.checkConnectivity();
      return result != ConnectivityResult.none;
    } catch (e) {
      return false;
    }
  }

  // Listen to connectivity changes
  static Stream<bool> onConnectivityChanged() {
    return _connectivity.onConnectivityChanged.map(
      (result) => result != ConnectivityResult.none,
    );
  }
}
