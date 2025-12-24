import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class EmergencyScreen extends StatefulWidget {
  const EmergencyScreen({super.key});

  @override
  State<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends State<EmergencyScreen> {
  String _selectedAlertType = 'general';
  final _descriptionController = TextEditingController();
  bool _isSending = false;

  final List<Map<String, dynamic>> _alertTypes = [
    {'value': 'general', 'label': 'General Emergency', 'icon': Icons.warning},
    {'value': 'accident', 'label': 'Accident', 'icon': Icons.car_crash},
    {'value': 'harassment', 'label': 'Harassment', 'icon': Icons.report_problem},
    {'value': 'theft', 'label': 'Theft', 'icon': Icons.security},
    {'value': 'medical', 'label': 'Medical Emergency', 'icon': Icons.medical_services},
  ];

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _sendEmergencyAlert() async {
    setState(() {
      _isSending = true;
    });

    try {
      // Get user ID
      final userId = await AuthService.getUserId();
      if (userId == null) {
        throw Exception('User not logged in');
      }

      // Get current location
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Send alert
      await ApiService.sendEmergencyAlert(
        userId: userId,
        latitude: position.latitude,
        longitude: position.longitude,
        alertType: _selectedAlertType,
        description: _descriptionController.text.trim().isEmpty 
            ? null 
            : _descriptionController.text.trim(),
      );

      if (mounted) {
        // Show success message
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Emergency alert sent successfully!\nHelp is on the way.',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send alert: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  void _showConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.red, size: 30),
            SizedBox(width: 12),
            Text('Send Emergency Alert?'),
          ],
        ),
        content: const Text(
          'This will immediately notify emergency services and your emergency contacts with your current location.',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _sendEmergencyAlert();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text(
              'Send Alert',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency Alert'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Warning icon and message
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.emergency,
                    size: 60,
                    color: Colors.red[700],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Emergency Help',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.red[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Use this only in case of real emergency. Your location and details will be shared with authorities and emergency contacts.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Alert type selection
            const Text(
              'Type of Emergency',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            // Alert type buttons
            ...(_alertTypes.map((type) => Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: InkWell(
                onTap: () {
                  setState(() {
                    _selectedAlertType = type['value'];
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _selectedAlertType == type['value']
                        ? Colors.red.shade50
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _selectedAlertType == type['value']
                          ? Colors.red
                          : Colors.grey.shade300,
                      width: 2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        type['icon'],
                        color: _selectedAlertType == type['value']
                            ? Colors.red
                            : Colors.grey[700],
                      ),
                      const SizedBox(width: 16),
                      Text(
                        type['label'],
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: _selectedAlertType == type['value']
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: _selectedAlertType == type['value']
                              ? Colors.red[700]
                              : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )).toList()),

            const SizedBox(height: 24),

            // Description field
            const Text(
              'Additional Details (Optional)',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Describe the situation...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
              ),
            ),
            const SizedBox(height: 32),

            // Send alert button
            ElevatedButton(
              onPressed: _isSending ? null : _showConfirmationDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isSending
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.emergency, color: Colors.white),
                        SizedBox(width: 12),
                        Text(
                          'SEND EMERGENCY ALERT',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}