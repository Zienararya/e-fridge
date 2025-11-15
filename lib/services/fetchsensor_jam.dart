// services/fetchsensor_jam.dart
import '../database.dart';
import 'package:shared_preferences/shared_preferences.dart';

class sensor_jamService {
  static Future<List<Map<String, dynamic>>> fetchSensorJam() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final deviceIdStr = prefs.getString('device_id');

      if (deviceIdStr == null) {
        print('device_id belum tersimpan.');
        return [];
      }

      final deviceId = int.tryParse(deviceIdStr);
      if (deviceId == null) {
        print('device_id tidak valid: $deviceIdStr');
        return [];
      }

      // Ambil data hanya untuk HARI INI (berdasarkan zona waktu lokal)
      final nowLocal = DateTime.now();
      final startOfDayLocal = DateTime(
        nowLocal.year,
        nowLocal.month,
        nowLocal.day,
      );
      final endOfDayLocal = startOfDayLocal.add(const Duration(days: 1));

      // Konversi ke UTC untuk dikirim ke Supabase (kolom bertipe timestamptz)
      final startIsoUtc = startOfDayLocal.toUtc().toIso8601String();
      final endIsoUtc = endOfDayLocal.toUtc().toIso8601String();

      final jamData = await Database.supabase
          .from('sensor_jam')
          .select()
          .eq('device_id', deviceId)
          .gte('timestamp', startIsoUtc)
          .lt('timestamp', endIsoUtc)
          .order('timestamp', ascending: true);

      return List<Map<String, dynamic>>.from(jamData);
    } catch (e) {
      print('Error fetchSensorJam: $e');
      return [];
    }
  }
}
