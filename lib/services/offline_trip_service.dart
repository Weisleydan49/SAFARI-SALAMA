import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/trip.dart';
import 'api_service.dart';

/// Service to handle offline trip functionality
/// Caches trip data and location updates locally
/// Syncs with backend when connection is restored
class OfflineTripService {
  static const String _activeTripKey = 'active_trip_offline';
  static const String _queuedLocationsKey = 'queued_locations';
  static const String _isSyncingKey = 'is_syncing_trip';

  /// Cache the current trip locally
  static Future<void> cacheTrip(Trip trip) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _activeTripKey,
      jsonEncode(trip.toJson()),
    );
  }

  /// Get cached trip (for offline access)
  static Future<Trip?> getCachedTrip() async {
    final prefs = await SharedPreferences.getInstance();
    final tripJson = prefs.getString(_activeTripKey);
    
    if (tripJson == null) return null;
    
    try {
      final decoded = jsonDecode(tripJson) as Map<String, dynamic>;
      return Trip.fromJson(decoded);
    } catch (e) {
      print('Error decoding cached trip: $e');
      return null;
    }
  }

  /// Queue a location update for later sync
  static Future<void> queueLocationUpdate({
    required String tripId,
    required double latitude,
    required double longitude,
    required DateTime timestamp,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Get existing queued locations
    final existingJson = prefs.getString(_queuedLocationsKey);
    List<Map<String, dynamic>> queued = [];
    
    if (existingJson != null) {
      final decoded = jsonDecode(existingJson) as List;
      queued = decoded.cast<Map<String, dynamic>>().toList();
    }
    
    // Add new location
    queued.add({
      'trip_id': tripId,
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp.toIso8601String(),
    });
    
    // Keep only last 100 locations to avoid storage bloat
    if (queued.length > 100) {
      queued = queued.skip(queued.length - 100).toList();
    }
    
    // Save back to prefs
    await prefs.setString(_queuedLocationsKey, jsonEncode(queued));
  }

  /// Get all queued location updates
  static Future<List<Map<String, dynamic>>> getQueuedLocations() async {
    final prefs = await SharedPreferences.getInstance();
    final locationsJson = prefs.getString(_queuedLocationsKey);
    
    if (locationsJson == null) return [];
    
    try {
      final decoded = jsonDecode(locationsJson) as List;
      return decoded.cast<Map<String, dynamic>>().toList();
    } catch (e) {
      print('Error decoding queued locations: $e');
      return [];
    }
  }

  /// Clear cached trip (after sync or cancellation)
  static Future<void> clearCachedTrip() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_activeTripKey);
  }

  /// Clear queued locations (after successful sync)
  static Future<void> clearQueuedLocations() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_queuedLocationsKey);
  }

  /// Sync queued locations with backend
  /// Called when device comes back online
  static Future<bool> syncQueuedLocations(String tripId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Check if already syncing
      final isSyncing = prefs.getBool(_isSyncingKey) ?? false;
      if (isSyncing) {
        print('Trip sync already in progress');
        return false;
      }
      
      // Mark as syncing
      await prefs.setBool(_isSyncingKey, true);
      
      final queuedLocations = await getQueuedLocations();
      
      if (queuedLocations.isEmpty) {
        print('No queued locations to sync');
        await prefs.setBool(_isSyncingKey, false);
        return true;
      }
      
      print('Syncing ${queuedLocations.length} queued locations for trip $tripId');
      
      // Send all queued locations to backend
      // This endpoint accepts batch location updates
      await ApiService.syncTripLocations(
        tripId: tripId,
        locations: queuedLocations,
      );
      
      // Clear queued locations after successful sync
      await clearQueuedLocations();
      
      print('Trip locations synced successfully');
      await prefs.setBool(_isSyncingKey, false);
      return true;
      
    } catch (e) {
      print('Error syncing trip locations: $e');
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_isSyncingKey, false);
      return false;
    }
  }

  /// Check if there are pending syncs
  static Future<bool> hasPendingSync() async {
    final queuedLocations = await getQueuedLocations();
    return queuedLocations.isNotEmpty;
  }
}
