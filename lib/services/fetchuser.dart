import '../database.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserService {
  static Future<Map<String, dynamic>?> fetchUser(String uid) async {
    try {
      final userData = await Database.supabase
          .from('user')
          .select()
          .eq('uid', uid)
          .maybeSingle();

      if (userData != null) {
        final prefs = await SharedPreferences.getInstance();
        // variabel global pakai uid
        await prefs.setString('uid', uid);
      }
      return userData;
    } catch (e) {
      print('Error fetchUser: $e');
      return null;
    }
  }
}
