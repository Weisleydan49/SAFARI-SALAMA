import 'package:flutter/material.dart';
import '../models/route_model.dart';

// Screen that displays detailed information about a selected route
class RouteDetailScreen extends StatelessWidget {
  final RouteModel route;

  const RouteDetailScreen({Key? key, required this.route}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(route.name),
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
            
            // Waypoints list
            _buildWaypointsSection(),
          ],
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
                  Text(route.origin, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward, color: Colors.green),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('To', style: TextStyle(color: Colors.grey)),
                  Text(route.destination, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
        Expanded(child: _buildStatCard('Distance', '${route.distanceKm?.toStringAsFixed(1) ?? '-'} km', Icons.straighten)),
        const SizedBox(width: 10),
        Expanded(child: _buildStatCard('Duration', '~${route.estimatedDurationMinutes ?? '-'} min', Icons.access_time)),
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

  // Displays list of stops along the route
  Widget _buildWaypointsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Route Stops', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        // Shows all stops along the route
        ...route.stops.map((stop) {
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