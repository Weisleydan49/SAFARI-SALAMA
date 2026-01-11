import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../services/api_service.dart';
import '../models/vehicle.dart';
import 'emergency_screen.dart';
import 'active_trip_screen.dart';
import 'routes_list_screen.dart';
import 'dart:async';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  
  // Default location: Nairobi CBD
  final LatLng _nairobiCenter = const LatLng(-1.286389, 36.817223);
  LatLng? _currentPosition;
  
  Set<Marker> _markers = {};
  List<Vehicle> _vehicles = [];
  bool _isLoading = true;
  Timer? _refreshTimer;
  
  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _loadVehicles();
    
    // Auto-refresh vehicles every 5 seconds to show real-time updates
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _loadVehicles();
    });
  }
  
  @override
  void dispose() {
    _refreshTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }
  
  // Get user's current location using GPS
  Future<void> _getCurrentLocation() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return;
      }
      
      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return;
        }
      }
      
      // Get current position
      Position position = await Geolocator.getCurrentPosition();
      
      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
      });
      
      // Move camera to current location
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(_currentPosition!, 13),
      );
    } catch (e) {
      print('Error getting location: $e');
    }
  }
  
  // Load vehicles from API
  Future<void> _loadVehicles() async {
    try {
      final vehiclesData = await ApiService.getVehicleLocations();
      
      // Filter vehicles that have valid coordinates
      final vehicles = vehiclesData
          .map((data) => Vehicle.fromJson(data))
          .where((v) => v.currentLatitude != null && v.currentLongitude != null)
          .toList();
      
      setState(() {
        _vehicles = vehicles;
        _updateMarkers();
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading vehicles: $e');
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load vehicles: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  // Update markers on the map
  void _updateMarkers() {
    final markers = <Marker>{};
    
    // Add user location marker (blue)
    if (_currentPosition != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('my_location'),
          position: _currentPosition!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: const InfoWindow(title: 'My Location'),
        ),
      );
    }
    
    // Add vehicle markers (green for online, red for offline)
    for (var vehicle in _vehicles) {
      if (vehicle.currentLatitude != null && vehicle.currentLongitude != null) {
        markers.add(
          Marker(
            markerId: MarkerId(vehicle.id),
            position: LatLng(vehicle.currentLatitude!, vehicle.currentLongitude!),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              vehicle.isOnline ? BitmapDescriptor.hueGreen : BitmapDescriptor.hueRed,
            ),
            infoWindow: InfoWindow(
              title: vehicle.registrationNumber,
              snippet: '${vehicle.isOnline ? "Online" : "Offline"} • Capacity: ${vehicle.capacity}',
            ),
            onTap: () => _showVehicleDetails(vehicle),
          ),
        );
      }
    }
    
    setState(() {
      _markers = markers;
    });
  }
  
  // Show vehicle details in bottom sheet
  void _showVehicleDetails(Vehicle vehicle) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Safari Salama logo - replaced bus icon (medium size)
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
                        vehicle.registrationNumber,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        children: [
                          // Online/offline status indicator
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: vehicle.isOnline ? Colors.green : Colors.red,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            vehicle.isOnline ? 'Online' : 'Offline',
                            style: TextStyle(
                              color: vehicle.isOnline ? Colors.green : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildDetailRow('Vehicle Type', vehicle.vehicleType),
            _buildDetailRow('Capacity', '${vehicle.capacity} passengers'),
            const SizedBox(height: 20),
            // Start trip button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  // Navigate to active trip screen
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ActiveTripScreen(vehicle: vehicle),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Start Trip',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // Helper widget to build detail rows
  Widget _buildDetailRow(String label, String value) {
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
    return Scaffold(
      body: Stack(
        children: [
          // Google Map
          GoogleMap(
            onMapCreated: (controller) {
              _mapController = controller;
            },
            initialCameraPosition: CameraPosition(
              target: _currentPosition ?? _nairobiCenter,
              zoom: 13,
            ),
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            mapType: MapType.normal,
            zoomControlsEnabled: false,
          ),
          
          // Refresh button - top right
          Positioned(
            top: 50,
            right: 16,
            child: FloatingActionButton(
              mini: true,
              backgroundColor: Colors.white,
              onPressed: _loadVehicles,
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh, color: Colors.black87),
            ),
          ),
          
          // Emergency button - bottom right (red for urgency)
          Positioned(
            bottom: 80,
            right: 16,
            child: FloatingActionButton(
              backgroundColor: Colors.red,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const EmergencyScreen(),
                  ),
                );
              },
              child: const Icon(Icons.emergency, color: Colors.white, size: 30),
            ),
          ),

          Positioned(
            bottom: 150,
            right: 16,
            child: FloatingActionButton.extended(
              backgroundColor: Colors.green[700],
              onPressed: () {
                //Navigate to routes list for trip selection
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const RoutesListScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.add_road, color: Colors.white),
              label: const Text(
                'Start Trip',
                style: TextStyle(
                  color: Colors.white),
                ),
              ),
          ),
          
          // Vehicle count indicator - top left with Safari Salama logo
          Positioned(
            top: 50,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Safari Salama logo - replaced bus icon (small size)
                  Image.asset(
                    'assets/images/safari_salama_logo.png',
                    width: 24,
                    height: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${_vehicles.length} Matatus',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}