import 'package:shared_preferences/shared_preferences.dart';

class AuthManager {
  static const String _loginKey = 'user_logged_in';
  static const String _usernameKey = 'username';
  static const String _emailKey = 'email';
  
  // Singleton pattern
  static final AuthManager _instance = AuthManager._internal();
  factory AuthManager() => _instance;
  AuthManager._internal();

  // Current login state
  bool _isLoggedIn = false;
  String _username = '';
  String _email = '';

  // Getters
  bool get isLoggedIn => _isLoggedIn;
  String get username => _username;
  String get email => _email;

  // Initialize the service by loading saved login state
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _isLoggedIn = prefs.getBool(_loginKey) ?? false;
    _username = prefs.getString(_usernameKey) ?? '';
    _email = prefs.getString(_emailKey) ?? '';
  }

  // Login method
  Future<bool> login(String username, String email) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // In a real app, you would validate credentials with your backend
      // For demo purposes, we'll accept any non-empty username/email
      if (username.isNotEmpty && email.isNotEmpty) {
        _isLoggedIn = true;
        _username = username;
        _email = email;
        
        // Save to SharedPreferences
        await prefs.setBool(_loginKey, true);
        await prefs.setString(_usernameKey, username);
        await prefs.setString(_emailKey, email);
        
        return true;
      }
      return false;
    } catch (e) {
      // Handle login error silently in production
      return false;
    }
  }

  // Logout method
  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      _isLoggedIn = false;
      _username = '';
      _email = '';
      
      // Remove from SharedPreferences
      await prefs.remove(_loginKey);
      await prefs.remove(_usernameKey);
      await prefs.remove(_emailKey);
    } catch (e) {
      // Handle logout error silently in production
    }
  }

  // Check if user is logged in (useful for route guards)
  Future<bool> checkLoginStatus() async {
    await initialize();
    return _isLoggedIn;
  }
}
