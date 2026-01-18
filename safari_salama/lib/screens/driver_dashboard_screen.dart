import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'package:intl/intl.dart';

class DriverDashboardScreen extends StatefulWidget {
  @override
  _DriverDashboardScreenState createState() => _DriverDashboardScreenState();
}

class _DriverDashboardScreenState extends State<DriverDashboardScreen> {
  Map<String, dynamic>? _dashboardData;
  Map<String, dynamic>? _earningsData;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');
      final token = prefs.getString('auth_token');
      final userType = prefs.getString('user_type');

      if (userId == null || token == null) {
        setState(() {
          _error = 'User not authenticated';
          _isLoading = false;
        });
        return;
      }

      if (userType != 'driver') {
        setState(() {
          _error = 'You are not a driver. This dashboard is for drivers only.';
          _isLoading = false;
        });
        return;
      }

      final dashboardFuture = ApiService.getDriverDashboard(
        driverId: userId,
        token: token,
      );

      final earningsFuture = ApiService.getDriverEarnings(
        driverId: userId,
        days: 7,
        token: token,
      );

      final results = await Future.wait([dashboardFuture, earningsFuture]);

      setState(() {
        _dashboardData = results[0] as Map<String, dynamic>;
        _earningsData = results[1] as Map<String, dynamic>;
        _isLoading = false;
        _error = null;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load dashboard: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Driver Dashboard'),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadDashboard,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, color: Colors.red, size: 48),
                      SizedBox(height: 16),
                      Text(_error!, textAlign: TextAlign.center),
                      SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _loadDashboard,
                        child: Text('Retry'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Driver Info Card
                      if (_dashboardData?['driver'] != null)
                        _buildDriverInfoCard(_dashboardData!['driver']),
                      SizedBox(height: 20),

                      // Active Trip Section
                      if (_dashboardData?['active_trip'] != null)
                        _buildActiveTrip(_dashboardData!['active_trip']),
                      if (_dashboardData?['active_trip'] == null)
                        Card(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Icon(Icons.info, color: Colors.blue),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Text('No active trips at the moment'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      SizedBox(height: 20),

                      // Today's Earnings
                      _buildEarningsCard(
                        'Today\'s Earnings',
                        _dashboardData?['earnings']?['today'] ?? 0,
                        _dashboardData?['earnings']?['today_trips'] ?? 0,
                        Colors.blue,
                      ),
                      SizedBox(height: 12),

                      // Total Earnings
                      _buildEarningsCard(
                        'Total Earnings',
                        _dashboardData?['earnings']?['total'] ?? 0,
                        _dashboardData?['earnings']?['total_trips'] ?? 0,
                        Colors.green,
                      ),
                      SizedBox(height: 20),

                      // Stats Grid
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        childAspectRatio: 1.2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        children: [
                          _buildStatCard(
                            'Trips Today',
                            '${_dashboardData?['stats']?['completed_today'] ?? 0}',
                            Icons.directions_car,
                            Colors.orange,
                          ),
                          _buildStatCard(
                            'Total Trips',
                            '${_dashboardData?['stats']?['total_trips'] ?? 0}',
                            Icons.history,
                            Colors.purple,
                          ),
                          _buildStatCard(
                            'Rating',
                            '${_dashboardData?['stats']?['average_rating'] ?? 4.5}★',
                            Icons.star,
                            Colors.amber,
                          ),
                          _buildStatCard(
                            'Avg/Trip',
                            'KES ${_formatNumber(_dashboardData?['earnings']?['average_per_trip'] ?? 0)}',
                            Icons.money,
                            Colors.teal,
                          ),
                        ],
                      ),
                      SizedBox(height: 20),

                      // Weekly Breakdown
                      if (_earningsData != null) _buildWeeklyBreakdown(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildDriverInfoCard(Map<String, dynamic> driver) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: Colors.blue.shade200,
              child: Icon(Icons.person, size: 40, color: Colors.white),
            ),
            SizedBox(height: 12),
            Text(
              driver['name'] ?? 'Driver',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              driver['phone'] ?? '',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.star, color: Colors.amber, size: 20),
                SizedBox(width: 4),
                Text(
                  '${driver['rating'] ?? 4.5}',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveTrip(Map<String, dynamic> trip) {
    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.directions_car_filled, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'Active Trip',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Text('Fare: KES ${_formatNumber(trip['fare_amount'] ?? 0)}'),
            SizedBox(height: 4),
            Text(
              'Started: ${_formatTime(trip['start_time'])}',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEarningsCard(String title, dynamic amount, int trips, Color color) {
    return Card(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          gradient: LinearGradient(
            colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'KES ${_formatNumber(amount)}',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '$trips trip${trips != 1 ? 's' : ''}',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              Icon(Icons.trending_up, color: color, size: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(fontSize: 11, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyBreakdown() {
    final List<dynamic> dailyData = _earningsData?['daily_breakdown'] ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Weekly Breakdown',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 12),
        Card(
          child: ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: dailyData.length,
            itemBuilder: (context, index) {
              final day = dailyData[index];
              return ListTile(
                title: Text(
                  _formatDate(day['date']),
                  style: TextStyle(fontSize: 13),
                ),
                subtitle: Text(
                  '${day['trips']} trip${day['trips'] != 1 ? 's' : ''}',
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
                trailing: Text(
                  'KES ${_formatNumber(day['earnings'])}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  String _formatNumber(dynamic value) {
    if (value == null) return '0.00';
    final num numValue = value is num ? value : 0;
    return numValue.toStringAsFixed(2);
  }

  String _formatTime(String? time) {
    if (time == null) return 'N/A';
    try {
      final dt = DateTime.parse(time);
      return DateFormat('HH:mm').format(dt);
    } catch (e) {
      return 'N/A';
    }
  }

  String _formatDate(String? date) {
    if (date == null) return 'N/A';
    try {
      final dt = DateTime.parse(date);
      return DateFormat('MMM dd, yyyy').format(dt);
    } catch (e) {
      return date;
    }
  }
}
