// lib/services/auth_service.dart
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    // Cek apakah 'uid' atau 'user_id' sudah disimpan
    final uid = prefs.getString('uid');
    final userId = prefs.getString('user_id');
    return uid != null || userId != null;
  }

  // Opsional: logout
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('uid');
    await prefs.remove('user_id');
    await prefs.remove('alamat');
    // Hapus data lain jika perlu
  }
}
