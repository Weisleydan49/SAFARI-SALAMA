// mobile/lib/screens/trip_tracking_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/vehicle.dart';
import '../models/trip.dart';
import '../models/route_model.dart';
import '../services/api_service.dart';
import '../services/websocket_service.dart';
import 'emergency_screen.dart';

class TripTrackingScreen extends StatefulWidget {
  final Trip trip;
  final RouteModel? route;
  final Vehicle? vehicle;

  const TripTrackingScreen({
    super.key,
    required this.trip,
    this.route,
    this.vehicle,
  });

  @override
  State<TripTrackingScreen> createState() => _TripTrackingScreenState();
}

class _TripTrackingScreenState extends State<TripTrackingScreen> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  
  Position? _currentPosition;
  Vehicle? _currentVehicle;
  Trip? _currentTrip;
  RouteModel? _currentRoute;
  
  late WebSocketService _wsService;
  Timer? _refreshTimer;
  Timer? _locationTimer;
  
  bool _isLoading = true;
  bool _isTripEnded = false;
  
  final LatLng _nairobiCenter = const LatLng(-1.286389, 36.817223);

  @override
  void initState() {
    super.initState();
    _currentTrip = widget.trip;
    _currentVehicle = widget.vehicle;
    _currentRoute = widget.route;
    
    _initializeTracking();
    _getCurrentLocation();
    _initWebSocket();
    _startRefreshTimer();
  }

  Future<void> _initializeTracking() async {
    try {
      // Fetch active trip details
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');
      
      if (userId != null) {
        final tripData = await ApiService.getActiveTrip(userId);
        if (tripData != null && mounted) {
          setState(() {
            _currentTrip = Trip.fromJson(tripData);
          });
          _updateMapMarkers();
        }
      }
    } catch (e) {
      debugPrint('Error initializing tracking: $e');
    }
  }

  Future<void> _initWebSocket() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id') ?? 'anonymous_passenger';
      
      _wsService = WebSocketService(
        userId: userId,
        onVehicleLocationUpdate: (updatedVehicle) {
          if (!mounted) return;
          setState(() {
            _currentVehicle = updatedVehicle;
            _updateMapMarkers();
          });
        },
      );
      
      _wsService.connect();
      
      if (_currentTrip?.routeId != null) {
        _wsService.subscribeToRoute(_currentTrip!.routeId!);
      }
    } catch (e) {
      debugPrint('Error initializing WebSocket: $e');
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permission denied');
      }

      Position position = await Geolocator.getCurrentPosition();
      if (mounted) {
        setState(() {
          _currentPosition = position;
          _isLoading = false;
        });
        _updateMapMarkers();
      }
    } catch (e) {
      debugPrint('Error getting location: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _startRefreshTimer() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) async {
      if (!_isTripEnded) {
        await _initializeTracking();
      }
    });
  }

  void _updateMapMarkers() {
    final markers = <Marker>{};

    // Vehicle location marker
    if (_currentVehicle != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('vehicle'),
          position: LatLng(
            _currentVehicle?.currentLatitude ?? 0.0,
            _currentVehicle?.currentLongitude ?? 0.0,
          ),
          infoWindow: InfoWindow(
            title: 'Vehicle',
            snippet: _currentVehicle!.registrationNumber,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueBlue,
          ),
        ),
      );
    }

    // Current position marker
    if (_currentPosition != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('current_location'),
          position: LatLng(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
          ),
          infoWindow: const InfoWindow(title: 'Your Location'),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          ),
        ),
      );
    }

    // Route stops markers
    if (_currentRoute != null && _currentRoute!.stops.isNotEmpty) {
      for (int i = 0; i < _currentRoute!.stops.length; i++) {
        final stop = _currentRoute!.stops[i];
        // Note: This assumes stops have location data in your API
        // Adjust marker color based on progress
        markers.add(
          Marker(
            markerId: MarkerId('stop_$i'),
            position: _nairobiCenter, // Replace with actual stop coordinates
            infoWindow: InfoWindow(
              title: 'Stop ${stop.sequence}',
              snippet: stop.stopName,
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueYellow,
            ),
          ),
        );
      }
    }

    if (mounted) {
      setState(() {
        _markers = markers;
      });
    }

    // Animate map to show both vehicle and user
    if (_currentVehicle != null && _mapController != null) {
      if (_currentVehicle!.currentLatitude != null && _currentVehicle!.currentLongitude != null) {
        _animateMapToLocation(
          LatLng(
            _currentVehicle!.currentLatitude!,
            _currentVehicle!.currentLongitude!,
          ),
        );
      }
    }
  }

  Future<void> _animateMapToLocation(LatLng location) async {
    await _mapController?.animateCamera(
      CameraUpdate.newLatLng(location),
    );
  }

  Future<void> _endTrip() async {
    if (_currentTrip == null || _currentPosition == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('End Trip?'),
        content: const Text('Are you sure you want to end this trip?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _completeTrip();
            },
            child: const Text('End Trip'),
          ),
        ],
      ),
    );
  }

  Future<void> _completeTrip() async {
    try {
      if (_currentTrip == null || _currentPosition == null) return;

      await ApiService.endTrip(
        tripId: _currentTrip!.id,
        endLatitude: _currentPosition!.latitude,
        endLongitude: _currentPosition!.longitude,
      );

      if (mounted) {
        setState(() {
          _isTripEnded = true;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Trip ended successfully'),
            backgroundColor: Colors.green,
          ),
        );

        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.pop(context);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error ending trip: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatDuration(DateTime startTime, DateTime? endTime) {
    final now = endTime ?? DateTime.now();
    final duration = now.difference(startTime);
    
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    
    if (hours > 0) {
      return '$hours h ${minutes} m';
    }
    return '${minutes} m';
  }

  double _calculateDistance() {
    // This would require calculating distance between waypoints
    // For now, return estimated distance from route
    return _currentRoute?.distanceKm ?? 0.0;
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _locationTimer?.cancel();
    _wsService.disconnect();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (!_isTripEnded) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Trip in Progress'),
              content: const Text('Do you want to end this trip?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Continue Trip'),
                ),
                TextButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    await _endTrip();
                  },
                  child: const Text('End Trip'),
                ),
              ],
            ),
          );
          return false;
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Trip Tracking'),
          backgroundColor: Colors.green[700],
          elevation: 0,
        ),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : Stack(
                children: [
                  // Map
                  GoogleMap(
                    onMapCreated: (controller) {
                      _mapController = controller;
                      _updateMapMarkers();
                    },
                    initialCameraPosition: CameraPosition(
                      target: _currentVehicle != null && _currentVehicle!.currentLatitude != null && _currentVehicle!.currentLongitude != null
                          ? LatLng(
                              _currentVehicle!.currentLatitude!,
                              _currentVehicle!.currentLongitude!,
                            )
                          : (_currentPosition != null
                              ? LatLng(
                                  _currentPosition!.latitude,
                                  _currentPosition!.longitude,
                                )
                              : _nairobiCenter),
                      zoom: 15,
                    ),
                    markers: _markers,
                    polylines: _polylines,
                    myLocationEnabled: true,
                    myLocationButtonEnabled: true,
                    mapToolbarEnabled: true,
                  ),
                  
                  // Trip info panel at bottom
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, -2),
                          ),
                        ],
                      ),
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Vehicle info
                              if (_currentVehicle != null)
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.green[50],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.directions_car,
                                        color: Colors.green[700],
                                      ),
                                      const SizedBox(width: 12),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _currentVehicle!.registrationNumber,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          Text(
                                            _currentVehicle!.vehicleType,
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              const SizedBox(height: 16),
                              
                              // Route info
                              if (_currentRoute != null)
                                Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Route: ${_currentRoute!.routeNumber}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    Text(
                                      '${_currentRoute!.origin} → ${_currentRoute!.destination}',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                  ],
                                ),
                              
                              // Trip stats
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  _buildStatColumn(
                                    'Time',
                                    _formatDuration(
                                      _currentTrip!.startTime,
                                      _currentTrip!.endTime,
                                    ),
                                  ),
                                  _buildStatColumn(
                                    'Distance',
                                    '${_calculateDistance().toStringAsFixed(1)} km',
                                  ),
                                  if (_currentTrip != null &&
                                      _currentTrip!.fareAmount != null)
                                    _buildStatColumn(
                                      'Fare',
                                      'KES ${_currentTrip!.fareAmount?.toStringAsFixed(0) ?? 'N/A'}',
                                    ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              
                              // Route stops
                              if (_currentRoute != null &&
                                  _currentRoute!.stops.isNotEmpty)
                                Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Upcoming Stops',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    SizedBox(
                                      height: 50,
                                      child: ListView.builder(
                                        scrollDirection: Axis.horizontal,
                                        itemCount: _currentRoute!.stops.length,
                                        itemBuilder: (context, index) {
                                          final stop =
                                              _currentRoute!.stops[index];
                                          return Container(
                                            margin: const EdgeInsets.only(
                                              right: 8,
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 8,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.blue[50],
                                              border: Border.all(
                                                color: Colors.blue[300]!,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  'Stop ${stop.sequence}',
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    fontWeight:
                                                        FontWeight.bold,
                                                  ),
                                                ),
                                                Text(
                                                  stop.stopName,
                                                  style: const TextStyle(
                                                    fontSize: 10,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                  ],
                                ),
                              
                              // Action buttons
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed:
                                          _isTripEnded ? null : _endTrip,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red[600],
                                        disabledBackgroundColor:
                                            Colors.grey[400],
                                      ),
                                      icon: const Icon(Icons.stop_circle),
                                      label: const Text('End Trip'),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                const EmergencyScreen(),
                                          ),
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.orange[600],
                                      ),
                                      icon: const Icon(Icons.warning),
                                      label: const Text('Emergency'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildStatColumn(String label, String value) {
    return Column(
      children: [
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
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}
