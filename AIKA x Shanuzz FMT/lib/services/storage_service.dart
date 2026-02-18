import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _tokenKey = 'user_token';
  static const String _userNameKey = 'user_name';
  static const String _userReffidKey = 'user_reffid';

  Future<void> saveUserCredentials(String token, String name, String reffid) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_userNameKey, name);
    await prefs.setString(_userReffidKey, reffid);
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userNameKey);
  }

  Future<String?> getUserReffid() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userReffidKey);
  }

  Future<void> clearUserCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userNameKey);
    await prefs.remove(_userReffidKey);
  }

  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}
