import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import 'api_service.dart';

class AuthService {
  static const String _tokenKey = 'auth_token';
  static const String _userIdKey = 'user_id';
  static const String _userNameKey = 'user_name';
  static const String _userPhoneKey = 'user_phone';
  static const String _userTypeKey = 'user_type';

  // Save auth data locally
  static Future<void> saveAuthData({
    required String token,
    required User user,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_userIdKey, user.id);
    await prefs.setString(_userNameKey, user.name);
    await prefs.setString(_userPhoneKey, user.phone);
    await prefs.setString(_userTypeKey, user.userType);
  }

  // Get saved token
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  // Get saved user ID
  static Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userIdKey);
  }

  // Get saved user name
  static Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userNameKey);
  }

  // Get saved user phone
  static Future<String?> getUserPhone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userPhoneKey);
  }

  // Get saved user type
  static Future<String?> getUserType() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userTypeKey);
  }

 // In auth_service.dart, replace isLoggedIn() with this:

static Future<bool> isLoggedIn() async {
  final token = await getToken();
  
  // If no token exists, user is not logged in
  if (token == null || token.isEmpty) {
    return false;
  }
  
  // Validate token with backend
  try {
    // Try to fetch user profile using the token
    // If this succeeds, token is valid
    final response = await ApiService.validateToken(token);
    return response != null;
  } catch (e) {
    // Token is invalid or expired
    // Clear the stored data
    await logout();
    return false;
  }
}

  // Logout
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  // Register
  static Future<User> register({
    required String phone,
    required String name,
    String? email,
    required String password,
  }) async {
    final response = await ApiService.register(
      phone: phone,
      name: name,
      email: email,
      password: password,
    );
    
    return User.fromJson(response);
  }

  // Login
  static Future<Map<String, dynamic>> login({
    required String phone,
    required String password,
  }) async {
    final response = await ApiService.login(
      phone: phone,
      password: password,
    );
    
    final user = User.fromJson(response['user']);
    final token = response['access_token'];
    
    await saveAuthData(token: token, user: user);
    
    return {
      'user': user,
      'token': token,
    };
  }
}