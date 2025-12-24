import 'package:flutter/material.dart';
import '../models/route_model.dart';
import '../services/route_service.dart';

class RoutesListScreen extends StatefulWidget {
  const RoutesListScreen({Key? key}) : super(key: key);

  @override
  State<RoutesListScreen> createState() => _RoutesListScreenState();
}

class _RoutesListScreenState extends State<RoutesListScreen> {
  final RouteService _routeService = RouteService();
  List<RouteModel> _routes = [];
  List<RouteModel> _filteredRoutes = [];
  bool _isLoading = true;
  String _errorMessage = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadRoutes(); // Load routes when screen opens
  }

  // Fetch routes from API
  Future<void> _loadRoutes() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final routes = await _routeService.getRoutes();
      setState(() {
        _routes = routes;
        _filteredRoutes = routes; // Initially show all routes
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  // Filter routes based on search query
  void _filterRoutes(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredRoutes = _routes; // Show all if search is empty
      } else {
        // Search in destination, origin, or route number
        _filteredRoutes = _routes.where((route) {
          return route.destination.toLowerCase().contains(query.toLowerCase()) ||
              route.origin.toLowerCase().contains(query.toLowerCase()) ||
              route.routeNumber.toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Available Routes'),
        backgroundColor: Colors.green,
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by destination or route number...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              onChanged: _filterRoutes, // Filter as user types
            ),
          ),

          // Loading indicator
          if (_isLoading)
            const Expanded(
              child: Center(
                child: CircularProgressIndicator(color: Colors.green),
              ),
            ),

          // Error message
          if (_errorMessage.isNotEmpty && !_isLoading)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 60, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(_errorMessage, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadRoutes,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),

          // Routes list
          if (!_isLoading && _errorMessage.isEmpty)
            Expanded(
              child: _filteredRoutes.isEmpty
                  ? const Center(child: Text('No routes found'))
                  : ListView.builder(
                      itemCount: _filteredRoutes.length,
                      itemBuilder: (context, index) {
                        final route = _filteredRoutes[index];
                        return _buildRouteCard(route);
                      },
                    ),
            ),
        ],
      ),
    );
  }

  // Build individual route card
  Widget _buildRouteCard(RouteModel route) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      child: ListTile(
        // Route number badge
        leading: CircleAvatar(
          backgroundColor: Colors.green,
          child: Text(
            route.routeNumber,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        
        // Route name and details
        title: Text(
          route.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            // Origin to destination
            Row(
              children: [
                const Icon(Icons.location_on, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(
                  child: Text('${route.origin} → ${route.destination}'),
                ),
              ],
            ),
            const SizedBox(height: 4),
            // Distance and duration
            Row(
              children: [
                const Icon(Icons.straighten, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text('${route.distanceKm?.toStringAsFixed(1) ?? '-'} km'),
                const SizedBox(width: 16),
                const Icon(Icons.access_time, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text('~${route.estimatedDurationMinutes} min'),
              ],
            ),
          ],
        ),
        
        // Tap to view route details
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          // Navigate to route details screen (we'll create this next)
          Navigator.pushNamed(
            context,
            '/route-details',
            arguments: route,
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}