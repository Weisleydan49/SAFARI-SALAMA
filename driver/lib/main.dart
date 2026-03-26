import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'services/location_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  runApp(const DriverApp());
}

class DriverApp extends StatelessWidget {
  const DriverApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Safari Salama Driver',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const DriverHomePage(),
    );
  }
}

class DriverHomePage extends StatefulWidget {
  const DriverHomePage({super.key});

  @override
  State<DriverHomePage> createState() => _DriverHomePageState();
}

class _DriverHomePageState extends State<DriverHomePage> {
  final LocationService _locationService = LocationService();
  bool _isTracking = false;
  String _status = 'Offline';
  final TextEditingController _driverIdController = TextEditingController(text: 'driver_001');

  void _toggleTracking() async {
    if (_isTracking) {
      _locationService.stopTracking();
      setState(() {
        _isTracking = false;
        _status = 'Offline';
      });
    } else {
      bool hasPermission = await _locationService.handlePermissions();
      if (hasPermission) {
        _locationService.startTracking(_driverIdController.text);
        setState(() {
          _isTracking = true;
          _status = 'Online & Tracking';
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permissions are required.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Safari Salama Driver'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.directions_car,
              size: 100,
              color: Colors.blue,
            ),
            const SizedBox(height: 30),
            TextField(
              controller: _driverIdController,
              decoration: const InputDecoration(
                labelText: 'Driver ID',
                border: OutlineInputBorder(),
              ),
              enabled: !_isTracking,
            ),
            const SizedBox(height: 20),
            Text(
              'Status: $_status',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: _isTracking ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: _toggleTracking,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isTracking ? Colors.red : Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: Text(
                  _isTracking ? 'Go Offline' : 'Go Online',
                  style: const TextStyle(fontSize: 20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

