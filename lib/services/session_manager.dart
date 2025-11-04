//digunakan untuk mengelola sesi pengguna menggunakan SharedPreferences,
// termasuk menyimpan, mengambil, dan menghapus data sesi login.
import 'package:shared_preferences/shared_preferences.dart';

class SessionManager {
  static const String _keyUsername = 'username';
  static const String _keyLeaderId = 'leaderId';
  static const String _keyIsLoggedIn = 'isLoggedIn';

  // ✅ Simpan sesi login
  static Future<void> saveUserSession({
    required String username,
    required int leaderId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUsername, username);
    await prefs.setInt(_keyLeaderId, leaderId);
    await prefs.setBool(_keyIsLoggedIn, true);
  }

  // ✅ Ambil sesi user
  static Future<Map<String, dynamic>?> getUserSession() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool(_keyIsLoggedIn) ?? false;
    if (!isLoggedIn) return null;

    return {
      'username': prefs.getString(_keyUsername),
      'leaderId': prefs.getInt(_keyLeaderId),
    };
  }

  // ✅ Hapus sesi (logout)
  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  // ✅ Logout user (hapus sesi)
  static Future<void> logoutUser() async {
    await clearSession();  // Using the correct method name
  }
}
