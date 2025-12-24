import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/vehicle.dart';
import '../models/trip.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/offline_trip_service.dart';
import '../services/connectivity_service.dart';

class ActiveTripScreen extends StatefulWidget {
  final Vehicle vehicle;

  const ActiveTripScreen({
    super.key,
    required this.vehicle,
  });

  @override
  State<ActiveTripScreen> createState() => _ActiveTripScreenState();
}

class _ActiveTripScreenState extends State<ActiveTripScreen> {
  GoogleMapController? _mapController;
  Trip? _currentTrip;
  Position? _startPosition;
  Position? _currentPosition;
  
  Timer? _timer;
  Timer? _locationTimer;
  Timer? _syncTimer;
  int _elapsedSeconds = 0;
  double _distanceTraveled = 0.0;
  
  bool _isStarting = true;
  bool _isEnding = false;
  bool _isOffline = false;
  
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  final List<LatLng> _routePoints = [];
  
  late ConnectivityService _connectivityService;

  @override
  void initState() {
    super.initState();
    _connectivityService = ConnectivityService();
    _connectivityService.startMonitoring();
    
    // Listen for connectivity changes
    _connectivityService.connectivityStream.listen((isConnected) {
      if (isConnected && _isOffline) {
        // Connection restored - sync offline data
        _syncOfflineData();
      }
      setState(() {
        _isOffline = !isConnected;
      });
    });
    
    _startTrip();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _locationTimer?.cancel();
    _syncTimer?.cancel();
    _mapController?.dispose();
    _connectivityService.stopMonitoring();
    super.dispose();
  }

  Future<void> _startTrip() async {
    try {
      // Get user ID
      final userId = await AuthService.getUserId();
      if (userId == null) {
        throw Exception('User not logged in');
      }

      // Get current location
      _startPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Start trip on backend (no fare amount - will be null)
      final tripData = await ApiService.startTrip(
        userId: userId,
        vehicleId: widget.vehicle.id,
        startLatitude: _startPosition!.latitude,
        startLongitude: _startPosition!.longitude,
      );

      setState(() {
        _currentTrip = Trip.fromJson(tripData);
        _currentPosition = _startPosition;
        _isStarting = false;
      });

      // Cache trip locally for offline access
      await OfflineTripService.cacheTrip(_currentTrip!);

      // Start timers
      _startTimers();
      _updateMarkers();

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start trip: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.pop(context);
      }
    }
  }

  void _startTimers() {
    // Timer for elapsed time
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _elapsedSeconds++;
      });
    });

    // Timer for location updates every 10 seconds
    _locationTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _updateLocation();
    });
  }

  Future<void> _updateLocation() async {
    try {
      Position newPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (_currentPosition != null) {
        // Calculate distance traveled
        double distance = Geolocator.distanceBetween(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
          newPosition.latitude,
          newPosition.longitude,
        ) / 1000; // Convert to km

        setState(() {
          _distanceTraveled += distance;
          _currentPosition = newPosition;
          _routePoints.add(LatLng(newPosition.latitude, newPosition.longitude));
        });

        _updateMarkers();
        _updatePolylines();

        // Queue location update for syncing
        if (_currentTrip != null) {
          await OfflineTripService.queueLocationUpdate(
            tripId: _currentTrip!.id,
            latitude: newPosition.latitude,
            longitude: newPosition.longitude,
            timestamp: DateTime.now(),
          );
        }

        // Move camera to current position
        _mapController?.animateCamera(
          CameraUpdate.newLatLng(
            LatLng(newPosition.latitude, newPosition.longitude),
          ),
        );
      }
    } catch (e) {
      print('Error updating location: $e');
    }
  }

  /// Sync offline data when connection is restored
  Future<void> _syncOfflineData() async {
    if (_currentTrip == null) return;
    
    try {
      print('Connection restored - syncing offline data...');
      final success = await OfflineTripService.syncQueuedLocations(_currentTrip!.id);
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Trip data synced successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Error syncing offline data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to sync: $e'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  void _updateMarkers() {
    final markers = <Marker>{};

    // Start position marker
    if (_startPosition != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('start'),
          position: LatLng(_startPosition!.latitude, _startPosition!.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: const InfoWindow(title: 'Start Point'),
        ),
      );
    }

    // Current position marker
    if (_currentPosition != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('current'),
          position: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: const InfoWindow(title: 'Current Location'),
        ),
      );
    }

    setState(() {
      _markers = markers;
    });
  }

  void _updatePolylines() {
    if (_routePoints.length < 2) return;

    setState(() {
      _polylines = {
        Polyline(
          polylineId: const PolylineId('route'),
          points: _routePoints,
          color: Colors.green,
          width: 5,
        ),
      };
    });
  }

  String _formatDuration(int seconds) {
    int hours = seconds ~/ 3600;
    int minutes = (seconds % 3600) ~/ 60;
    int remainingSeconds = seconds % 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m ${remainingSeconds}s';
  }

  Future<void> _endTrip() async {
    setState(() {
      _isEnding = true;
    });

    try {
      if (_currentTrip == null || _currentPosition == null) {
        throw Exception('No active trip');
      }

      // End trip on backend
      final tripData = await ApiService.endTrip(
        tripId: _currentTrip!.id,
        endLatitude: _currentPosition!.latitude,
        endLongitude: _currentPosition!.longitude,
      );

      final completedTrip = Trip.fromJson(tripData);

      // Stop timers
      _timer?.cancel();
      _locationTimer?.cancel();

      if (mounted) {
        // Show trip summary
        _showTripSummary(completedTrip);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to end trip: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() {
        _isEnding = false;
      });
    }
  }

  void _showTripSummary(Trip trip) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green[700], size: 30),
            const SizedBox(width: 12),
            const Text('Trip Completed'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSummaryRow('Vehicle', widget.vehicle.registrationNumber),
            _buildSummaryRow('Duration', _formatDuration(_elapsedSeconds)),
            _buildSummaryRow('Distance', '${_distanceTraveled.toStringAsFixed(2)} km'),
            const Divider(height: 24),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.payments, color: Colors.orange[700]),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Pay fare to conductor',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to map
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[700],
            ),
            child: const Text(
              'Done',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isStarting) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Starting Trip'),
          backgroundColor: Colors.green[700],
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text(
                'Starting your trip...',
                style: TextStyle(fontSize: 18),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Trip - ${widget.vehicle.registrationNumber}'),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          // Map
          GoogleMap(
            onMapCreated: (controller) {
              _mapController = controller;
              if (_startPosition != null) {
                controller.animateCamera(
                  CameraUpdate.newLatLngZoom(
                    LatLng(_startPosition!.latitude, _startPosition!.longitude),
                    15,
                  ),
                );
              }
            },
            initialCameraPosition: CameraPosition(
              target: _startPosition != null
                  ? LatLng(_startPosition!.latitude, _startPosition!.longitude)
                  : const LatLng(-1.286389, 36.817223),
              zoom: 15,
            ),
            markers: _markers,
            polylines: _polylines,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
          ),

          // Trip info card
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildInfoColumn(
                          Icons.timer,
                          'Duration',
                          _formatDuration(_elapsedSeconds),
                        ),
                        _buildInfoColumn(
                          Icons.route,
                          'Distance',
                          '${_distanceTraveled.toStringAsFixed(2)} km',
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 16,
                            color: Colors.orange[700],
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Pay fare to conductor',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange[900],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // End trip button
          Positioned(
            bottom: 24,
            left: 24,
            right: 24,
            child: ElevatedButton(
              onPressed: _isEnding ? null : _endTrip,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isEnding
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'END TRIP',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoColumn(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: Colors.green[700], size: 28),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ],
    );
  }
}