import 'package:flutter/material.dart';
import '../models/route_model.dart';
import '../models/vehicle.dart';
import '../services/api_service.dart';
import 'active_trip_screen.dart';

// Screen that displays detailed information about a selected route
class RouteDetailScreen extends StatefulWidget {
  final RouteModel route;

  const RouteDetailScreen({Key? key, required this.route}) : super(key: key);

  @override
  State<RouteDetailScreen> createState() => _RouteDetailScreenState();
}

class _RouteDetailScreenState extends State<RouteDetailScreen> {
  List<Vehicle> _vehiclesOnRoute = [];
  bool _isLoadingVehicles = false;

  @override
  void initState() {
    super.initState();
    _loadVehiclesOnRoute();
  }

  // Load vehicles operating on this route
  Future<void> _loadVehiclesOnRoute() async {
    setState(() {
      _isLoadingVehicles = true;
    });

    try {
      // Fetch vehicles on this route from API
      final vehiclesData = await ApiService.getVehiclesByRoute(widget.route.id);
      final vehicles = vehiclesData
          .map((data) => Vehicle.fromJson(data))
          .where((v) => v.isOnline) // Only show online vehicles
          .toList();

      setState(() {
        _vehiclesOnRoute = vehicles;
        _isLoadingVehicles = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingVehicles = false;
      });
      // Show error but don't block the UI
      print('Error loading vehicles: $e');
    }
  }

  // Show bottom sheet to select a vehicle for this route
  void _showVehicleSelectionSheet() {
    if (_vehiclesOnRoute.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No vehicles available on this route at the moment'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    }
// Start trip without selecting specific vehicle
  void _startTripWithoutVehicle() {
    // Navigate directly to active trip without vehicle selection
    // Backend will assign any available vehicle on this route
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ActiveTripScreen(
          vehicle: Vehicle(
            id: '', // Empty - backend will assign
            registrationNumber: 'Any Available',
            isOnline: true,
            vehicleType: 'matatu',
            capacity: 14,
          ),
          route: widget.route,
        ),
      ),
    );
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Select a Vehicle',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green[100],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_vehiclesOnRoute.length} available',
                    style: TextStyle(
                      color: Colors.green[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _vehiclesOnRoute.length,
                itemBuilder: (context, index) {
                  final vehicle = _vehiclesOnRoute[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: Image.asset(
                        'assets/images/safari_salama_logo.png',
                        width: 40,
                        height: 40,
                      ),
                      title: Text(
                        vehicle.registrationNumber,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        '${vehicle.vehicleType} • Capacity: ${vehicle.capacity}',
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        Navigator.pop(context);
                        // Navigate to active trip screen with both vehicle and route
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ActiveTripScreen(
                              vehicle: vehicle,
                              route: widget.route,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.route.name),
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Route header with origin and destination
            _buildRouteHeader(),
            const SizedBox(height: 20),

            // Route statistics cards (distance and duration only)
            _buildStatsRow(),
            const SizedBox(height: 20),

            // Available vehicles section
            _buildAvailableVehiclesSection(),
            const SizedBox(height: 20),

            // Waypoints list
            _buildWaypointsSection(),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
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
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Select Vehicle Button
              ElevatedButton(
                onPressed: _showVehicleSelectionSheet,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoadingVehicles
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
                    : const Text(
                  'Select Vehicle & Start Trip',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Start Without Selecting Button
              OutlinedButton(
                onPressed: _startTripWithoutVehicle,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(color: Colors.green[700]!),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Start Trip (Any Vehicle)',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[700],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      );
    
  }

  // Displays origin and destination with arrow
  Widget _buildRouteHeader() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('From', style: TextStyle(color: Colors.grey)),
                  Text(widget.route.origin, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward, color: Colors.green),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('To', style: TextStyle(color: Colors.grey)),
                  Text(widget.route.destination, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Shows distance and duration only
  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(child: _buildStatCard('Distance', '${widget.route.distanceKm?.toStringAsFixed(1) ?? '-'} km', Icons.straighten)),
        const SizedBox(width: 10),
        Expanded(child: _buildStatCard('Duration', '~${widget.route.estimatedDurationMinutes ?? '-'} min', Icons.access_time)),
      ],
    );
  }

  // Individual stat card widget
  Widget _buildStatCard(String label, String value, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: Colors.green),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  // Shows available vehicles on this route
  Widget _buildAvailableVehiclesSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Available Vehicles',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                if (!_isLoadingVehicles)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _vehiclesOnRoute.isEmpty ? Colors.grey[300] : Colors.green[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_vehiclesOnRoute.length} online',
                      style: TextStyle(
                        color: _vehiclesOnRoute.isEmpty ? Colors.grey[700] : Colors.green[700],
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (_isLoadingVehicles)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(color: Colors.green),
                ),
              )
            else if (_vehiclesOnRoute.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  'No vehicles currently available on this route',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  'Tap "Start Trip" below to select a vehicle',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Displays list of stops along the route
  Widget _buildWaypointsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Route Stops', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        // Shows all stops along the route
        ...widget.route.stops.map((stop) {
          return _buildWaypointItem(stop.sequence, stop.stopName);
        }).toList(),
      ],
    );
  }

  // Single stop item with sequence number and name
  Widget _buildWaypointItem(int sequence, String name) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: Colors.green,
            child: Text('$sequence', style: const TextStyle(color: Colors.white, fontSize: 12)),
          ),
          const SizedBox(width: 12),
          Text(name, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }
}