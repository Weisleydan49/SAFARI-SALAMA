import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/vehicle.dart';
import '../models/route_model.dart';
import '../services/api_service.dart';

class ActiveTripScreen extends StatefulWidget {
  final Vehicle vehicle;
  final RouteModel? route; // Optional route parameter

  const ActiveTripScreen({
    super.key,
    required this.vehicle,
    this.route, // Route is optional - works with or without it
  });

  @override
  State<ActiveTripScreen> createState() => _ActiveTripScreenState();
}

class _ActiveTripScreenState extends State<ActiveTripScreen> {
  GoogleMapController? _mapController;
  bool _isTripStarted = false;
  bool _isTripEnded = false;
  String? _tripId;
  String? _userId;
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _loadUserId();
    _getCurrentLocation();
  }

  // Load user ID from SharedPreferences
  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userId = prefs.getString('user_id');
    });
  }

  // Get current GPS location
  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }

      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        _currentPosition = position;
      });
    } catch (e) {
      print('Error getting location: $e');
    }
  }

  Future<void> _startTrip() async {
    if (_userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User not logged in'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Get current location if not available
    if (_currentPosition == null) {
      await _getCurrentLocation();
      if (_currentPosition == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to get your location'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    try {
      // Call API to start trip with all required parameters
      final response = await ApiService.startTrip(
        userId: _userId!,
        vehicleId: widget.vehicle.id,
        startLatitude: _currentPosition!.latitude,
        startLongitude: _currentPosition!.longitude,
        routeId: widget.route?.id,
      );

      setState(() {
        _isTripStarted = true;
        _tripId = response['id'] ?? response['trip_id'];
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Trip started successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start trip: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _endTrip() async {
    if (_tripId == null) return;

    // Get current location for end coordinates
    await _getCurrentLocation();
    if (_currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to get your location'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      await ApiService.endTrip(
        tripId: _tripId!,
        endLatitude: _currentPosition!.latitude,
        endLongitude: _currentPosition!.longitude,
      );

      setState(() {
        _isTripEnded = true;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Trip ended successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate back after 2 seconds
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
            content: Text('Failed to end trip: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _confirmEndTrip() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('End Trip'),
        content: const Text('Are you sure you want to end this trip?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _endTrip();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('End Trip'),
          ),
        ],
      ),
    );
  }

  LatLng _getInitialPosition() {
    if (_currentPosition != null) {
      return LatLng(_currentPosition!.latitude, _currentPosition!.longitude);
    }
    if (widget.vehicle.currentLatitude != null &&
        widget.vehicle.currentLongitude != null) {
      return LatLng(
        widget.vehicle.currentLatitude!,
        widget.vehicle.currentLongitude!,
      );
    }
    return const LatLng(-1.286389, 36.817223); // Nairobi default
  }

  Set<Marker> _buildMarkers() {
    final markers = <Marker>{};

    // Current location marker (blue)
    if (_currentPosition != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('my_location'),
          position: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: const InfoWindow(title: 'My Location'),
        ),
      );
    }

    // Vehicle marker (azure)
    if (widget.vehicle.currentLatitude != null &&
        widget.vehicle.currentLongitude != null) {
      markers.add(
        Marker(
          markerId: MarkerId(widget.vehicle.id),
          position: LatLng(
            widget.vehicle.currentLatitude!,
            widget.vehicle.currentLongitude!,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          infoWindow: InfoWindow(title: widget.vehicle.registrationNumber),
        ),
      );
    }

    return markers;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isTripStarted ? 'Trip in Progress' : 'Start Trip'),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Map
          Expanded(
            flex: 2,
            child: GoogleMap(
              onMapCreated: (controller) {
                _mapController = controller;
              },
              initialCameraPosition: CameraPosition(
                target: _getInitialPosition(),
                zoom: 13,
              ),
              markers: _buildMarkers(),
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
            ),
          ),

          // Trip information
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Vehicle info
                    Row(
                      children: [
                        Image.asset(
                          'assets/images/safari_salama_logo.png',
                          width: 50,
                          height: 50,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.vehicle.registrationNumber,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${widget.vehicle.vehicleType} • Capacity: ${widget.vehicle.capacity}',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    // Route info (if available)
                    if (widget.route != null) ...[
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 16),
                      const Text(
                        'Route Information',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildRouteInfo(
                        Icons.trip_origin,
                        'From',
                        widget.route!.origin,
                        Colors.green,
                      ),
                      const SizedBox(height: 8),
                      _buildRouteInfo(
                        Icons.location_on,
                        'To',
                        widget.route!.destination,
                        Colors.red,
                      ),
                      const SizedBox(height: 8),
                      _buildRouteInfo(
                        Icons.route,
                        'Route',
                        '${widget.route!.routeNumber} - ${widget.route!.name}',
                        Colors.blue,
                      ),
                      if (widget.route!.distanceKm != null) ...[
                        const SizedBox(height: 8),
                        _buildRouteInfo(
                          Icons.straighten,
                          'Distance',
                          '${widget.route!.distanceKm!.toStringAsFixed(1)} km',
                          Colors.orange,
                        ),
                      ],
                      if (widget.route!.estimatedDurationMinutes != null) ...[
                        const SizedBox(height: 8),
                        _buildRouteInfo(
                          Icons.access_time,
                          'Duration',
                          '~${widget.route!.estimatedDurationMinutes} min',
                          Colors.purple,
                        ),
                      ],
                    ],

                    const SizedBox(height: 20),

                    // Trip status
                    if (_isTripStarted && !_isTripEnded)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.green[700]),
                            const SizedBox(width: 8),
                            const Text(
                              'Trip in progress',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),

                    if (_isTripEnded)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.blue[700]),
                            const SizedBox(width: 8),
                            const Text(
                              'Trip completed',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 20),

                    // Action button
                    if (!_isTripEnded)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isTripStarted ? _confirmEndTrip : _startTrip,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isTripStarted
                                ? Colors.red[700]
                                : Colors.green[700],
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            _isTripStarted ? 'End Trip' : 'Start Trip',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteInfo(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}