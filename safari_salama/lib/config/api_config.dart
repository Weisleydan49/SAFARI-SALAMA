// Centralized API configuration
class ApiConfig {
  // Base URL for your backend API
  // Replace with your actual backend URL
  static const String baseUrl = 'http://192.168.8.108:8000';
  
  // API endpoints
  static const String loginEndpoint = '/api/auth/login';
  static const String routesEndpoint = '/api/routes';
  static const String vehiclesEndpoint = '/api/vehicles';
  static const String emergencyEndpoint = '/api/emergency';
  
  // Timeout duration for API requests
  static const Duration timeout = Duration(seconds: 10);
}

