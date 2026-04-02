// mobile/lib/screens/routes_list_screen.dart
import 'package:flutter/material.dart';
import '../models/route_model.dart';
import '../services/route_service.dart';
import '../services/offline_routes_service.dart';
import 'route_detail_screen.dart';

class RoutesListScreen extends StatefulWidget {
  const RoutesListScreen({super.key});

  @override
  State<RoutesListScreen> createState() => _RoutesListScreenState();
}

class _RoutesListScreenState extends State<RoutesListScreen> {
  final RouteService _routeService = RouteService();
  List<RouteModel> _routes = [];
  List<RouteModel> _filteredRoutes = [];
  bool _isLoading = true;
  String _errorMessage = '';
  bool _isOfflineMode = false;
  final TextEditingController _searchController = TextEditingController();
  double? _minPrice;
  double? _maxPrice;

  @override
  void initState() {
    super.initState();
    _loadRoutes();
  }

  // Fetch routes from API with offline fallback
  Future<void> _loadRoutes() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Try online first, fall back to offline cache
      List<Map<String, dynamic>> routesData;
      try {
        final onlineRoutes = await _routeService.getRoutes();
        routesData = onlineRoutes.cast<Map<String, dynamic>>();
        setState(() => _isOfflineMode = false);
      } catch (e) {
        print('API fetch failed, trying offline cache...');
        routesData = await OfflineRoutesService.getRoutesWithFallback();
        setState(() => _isOfflineMode = true);
      }

      final routes = routesData
          .map((data) => RouteModel.fromJson(data))
          .toList();

      setState(() {
        _routes = routes;
        _filteredRoutes = routes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading routes: $e';
        _isLoading = false;
      });
    }
  }

  // Filter routes based on search and price range
  void _filterRoutes(String query) {
    setState(() {
      var filtered = _routes;

      // Text search
      if (query.isNotEmpty) {
        filtered = filtered.where((route) {
          return route.destination.toLowerCase().contains(query.toLowerCase()) ||
              route.origin.toLowerCase().contains(query.toLowerCase()) ||
              route.routeNumber.toLowerCase().contains(query.toLowerCase());
        }).toList();
      }

      // Price range filter
      if (_minPrice != null || _maxPrice != null) {
        filtered = filtered.where((route) {
          final fare = route.fareAmount ?? 0;
          if (_minPrice != null && fare < _minPrice!) return false;
          if (_maxPrice != null && fare > _maxPrice!) return false;
          return true;
        }).toList();
      }

      _filteredRoutes = filtered;
    });
  }

  void _showPriceFilterDialog() {
    showDialog(
      context: context,
      builder: (context) {
        String minInput = _minPrice?.toString() ?? '';
        String maxInput = _maxPrice?.toString() ?? '';

        return AlertDialog(
          title: const Text('Filter by Price'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Min Price (KES)',
                  prefixIcon: Icon(Icons.attach_money),
                ),
                onChanged: (val) => minInput = val,
              ),
              const SizedBox(height: 12),
              TextField(
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Max Price (KES)',
                  prefixIcon: Icon(Icons.attach_money),
                ),
                onChanged: (val) => maxInput = val,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _minPrice = minInput.isEmpty ? null : double.tryParse(minInput);
                  _maxPrice = maxInput.isEmpty ? null : double.tryParse(maxInput);
                });
                _filterRoutes(_searchController.text);
                Navigator.pop(context);
              },
              child: const Text('Apply'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Available Routes'),
        backgroundColor: Colors.green,
        actions: [
          if (_isOfflineMode)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Tooltip(
                message: 'Using cached data - offline mode',
                child: Row(
                  children: [
                    Icon(Icons.cloud_off, size: 20),
                    SizedBox(width: 8),
                  ],
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Search and filter bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search by destination...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                    ),
                    onChanged: _filterRoutes,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.tune, color: Colors.white),
                    onPressed: _showPriceFilterDialog,
                  ),
                ),
              ],
            ),
          ),

          // Offline mode indicator
          if (_isOfflineMode)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                border: Border.all(color: Colors.orange),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.cloud_off, color: Colors.orange.shade700, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Using cached routes. Connect to internet for latest data.',
                      style: TextStyle(color: Colors.orange.shade700, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),

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
          // Navigate to route details screen with direct navigation
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RouteDetailScreen(route: route),
            ),
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