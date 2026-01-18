import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/trip.dart';
import '../services/api_service.dart';
import 'package:intl/intl.dart';

class TripHistoryScreen extends StatefulWidget {
  @override
  _TripHistoryScreenState createState() => _TripHistoryScreenState();
}

class _TripHistoryScreenState extends State<TripHistoryScreen> {
  List<Trip> _trips = [];
  bool _isLoading = true;
  String? _error;
  int _skip = 0;
  final int _limit = 20;
  bool _hasMore = true;
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    _loadTripHistory();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      if (_hasMore && !_isLoading) {
        _loadMoreTrips();
      }
    }
  }

  Future<void> _loadTripHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');
      final token = prefs.getString('auth_token');

      if (userId == null || token == null) {
        setState(() {
          _error = 'User not authenticated';
          _isLoading = false;
        });
        return;
      }

      final tripsData = await ApiService.getTripHistory(
        userId: userId,
        skip: 0,
        limit: _limit,
        token: token,
      );

      final trips = tripsData.map((data) => Trip.fromJson(data)).toList();

      setState(() {
        _trips = trips;
        _skip = _limit;
        _hasMore = trips.length == _limit;
        _isLoading = false;
        _error = null;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load trip history: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMoreTrips() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');
      final token = prefs.getString('auth_token');

      if (userId == null || token == null) return;

      final tripsData = await ApiService.getTripHistory(
        userId: userId,
        skip: _skip,
        limit: _limit,
        token: token,
      );

      final trips = tripsData.map((data) => Trip.fromJson(data)).toList();

      if (!mounted) return;

      setState(() {
        _trips.addAll(trips);
        _skip += _limit;
        _hasMore = trips.length == _limit;
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load more trips: $e')),
      );
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy HH:mm').format(date);
  }

  String _formatDuration(int? minutes) {
    if (minutes == null) return 'N/A';
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (hours > 0) {
      return '$hours h ${mins} m';
    } else {
      return '$mins m';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Trip History'),
        centerTitle: true,
        elevation: 0,
      ),
      body: _isLoading && _trips.isEmpty
          ? Center(child: CircularProgressIndicator())
          : _error != null && _trips.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, color: Colors.red, size: 48),
                      SizedBox(height: 16),
                      Text(_error!, textAlign: TextAlign.center),
                      SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _loadTripHistory,
                        child: Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _trips.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.directions_car_outlined,
                              color: Colors.grey, size: 48),
                          SizedBox(height: 16),
                          Text('No trips yet',
                              style: TextStyle(fontSize: 16, color: Colors.grey)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: EdgeInsets.all(12),
                      itemCount: _trips.length + (_hasMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == _trips.length) {
                          return Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Center(
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }

                        final trip = _trips[index];
                        return _buildTripCard(trip);
                      },
                    ),
    );
  }

  Widget _buildTripCard(Trip trip) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date and Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    _formatDate(trip.startTime),
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Completed',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),

            // Trip Details Grid
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              childAspectRatio: 2,
              children: [
                _buildDetailItem('Duration', _formatDuration(trip.durationMinutes)),
                _buildDetailItem('Fare', 'KES ${trip.fareAmount?.toStringAsFixed(2) ?? 'N/A'}'),
                _buildDetailItem('Distance', '${trip.distanceKm?.toStringAsFixed(2) ?? 'N/A'} km'),
                _buildDetailItem('Payment', trip.paymentStatus ?? 'pending'),
              ],
            ),

            SizedBox(height: 12),

            // Trip ID
            Text(
              'Trip ID: ${trip.id.substring(0, 8)}...',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
