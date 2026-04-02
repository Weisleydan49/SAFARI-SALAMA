// mobile/lib/screens/sacco_admin_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class SaccoAdminScreen extends StatefulWidget {
  const SaccoAdminScreen({super.key});

  @override
  _SaccoAdminScreenState createState() => _SaccoAdminScreenState();
}

class _SaccoAdminScreenState extends State<SaccoAdminScreen>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic>? _saccoData;
  List<Map<String, dynamic>> _vehicles = [];
  List<Map<String, dynamic>> _drivers = [];
  Map<String, dynamic>? _analytics;
  bool _isLoading = true;
  String? _error;
  String? _saccoId;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadSaccoData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadSaccoData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userType = prefs.getString('user_type');
      final userId = prefs.getString('user_id');
      final token = prefs.getString('auth_token');

      if (userType != 'sacco_admin') {
        setState(() {
          _error = 'You are not authorized to access this page';
          _isLoading = false;
        });
        return;
      }

      if (userId == null || token == null) {
        setState(() {
          _error = 'User not authenticated';
          _isLoading = false;
        });
        return;
      }

      // For demo, use userId as saccoId - in production, get from user data
      _saccoId = userId;

      final futures = await Future.wait([
        ApiService.getSacco(saccoId: _saccoId!, token: token),
        ApiService.getSaccoVehicles(saccoId: _saccoId!, token: token),
        ApiService.getSaccoDrivers(saccoId: _saccoId!, token: token),
        ApiService.getSaccoAnalytics(saccoId: _saccoId!, days: 30, token: token),
      ]);

      setState(() {
        _saccoData = futures[0] as Map<String, dynamic>;
        _vehicles = futures[1] as List<Map<String, dynamic>>;
        _drivers = futures[2] as List<Map<String, dynamic>>;
        _analytics = futures[3] as Map<String, dynamic>;
        _isLoading = false;
        _error = null;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load sacco data: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sacco Admin'),
        centerTitle: true,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview', icon: Icon(Icons.dashboard)),
            Tab(text: 'Vehicles', icon: Icon(Icons.directions_car)),
            Tab(text: 'Drivers', icon: Icon(Icons.people)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, color: Colors.red, size: 48),
                      const SizedBox(height: 16),
                      Text(_error!, textAlign: TextAlign.center),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _loadSaccoData,
                        child: const Text('Retry'),
                      )
                    ],
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildOverviewTab(),
                    _buildVehiclesTab(),
                    _buildDriversTab(),
                  ],
                ),
    );
  }

  Widget _buildOverviewTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Sacco info card
        if (_saccoData != null)
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _saccoData!['name'] ?? 'N/A',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Reg. No: ${_saccoData!['registration_number'] ?? 'N/A'}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Phone: ${_saccoData!['phone'] ?? 'N/A'}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  if (_saccoData!['email'] != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Email: ${_saccoData!['email']}',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ]
                ],
              ),
            ),
          ),
        const SizedBox(height: 24),

        // Analytics cards
        if (_analytics != null) ...[
          Text(
            'Performance (30 days)',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            children: [
              _buildMetricCard(
                'Total Trips',
                _analytics!['total_trips'].toString(),
                Icons.directions_car,
                Colors.blue,
              ),
              _buildMetricCard(
                'Total Earnings',
                'KES ${_analytics!['total_earnings']}',
                Icons.attach_money,
                Colors.green,
              ),
              _buildMetricCard(
                'Vehicles',
                _analytics!['total_vehicles'].toString(),
                Icons.local_shipping,
                Colors.orange,
              ),
              _buildMetricCard(
                'Avg. Trip Value',
                'KES ${(_analytics!['average_trip_value'] as num).toStringAsFixed(2)}',
                Icons.trending_up,
                Colors.purple,
              ),
            ],
          ),
        ]
      ],
    );
  }

  Widget _buildVehiclesTab() {
    if (_vehicles.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.directions_car_outlined, size: 48, color: Colors.grey),
            SizedBox(height: 16),
            Text('No vehicles registered'),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _vehicles.length,
      itemBuilder: (context, index) {
        final vehicle = _vehicles[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      vehicle['registration_number'] ?? 'N/A',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: vehicle['is_online'] ? Colors.green : Colors.grey,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        vehicle['is_online'] ? 'Online' : 'Offline',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Type: ${vehicle['vehicle_type'] ?? 'N/A'}',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 4),
                Text(
                  'Capacity: ${vehicle['capacity']} passengers',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDriversTab() {
    if (_drivers.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 48, color: Colors.grey),
            SizedBox(height: 16),
            Text('No drivers registered'),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _drivers.length,
      itemBuilder: (context, index) {
        final driver = _drivers[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.green.shade100,
                      child: Text(
                        driver['name'][0].toUpperCase(),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            driver['name'] ?? 'N/A',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            driver['phone'] ?? 'N/A',
                            style: TextStyle(color: Colors.grey[600], fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: driver['is_active'] ? Colors.green : Colors.grey,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        driver['is_active'] ? 'Active' : 'Inactive',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMetricCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: color, size: 32),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
