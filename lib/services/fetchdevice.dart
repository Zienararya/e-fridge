// services/fetchdevice.dart
import '../database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

class Fetchdevice {
  // Stream yang memperbarui data setiap interval
  static Stream<List<Map<String, dynamic>>> watchDevices({
    Duration interval = const Duration(seconds: 5),
  }) async* {
    while (true) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final uid = prefs.getString('uid');

        if (uid == null) {
          print('UID belum tersimpan.');
          yield [];
          await Future.delayed(interval);
          continue;
        }

        final devices = await Database.supabase
            .from('device')
            .select()
            .eq('user', uid);

        final deviceList = List<Map<String, dynamic>>.from(devices);

        if (deviceList.isNotEmpty) {
          await prefs.setString('device_id', deviceList[0]['id'].toString());
          print('Device ID tersimpan: ${deviceList[0]['id']}');
        }

        yield deviceList;
      } catch (e) {
        print('Error in watchDevices: $e');
        yield [];
      }

      // Tunggu sebelum fetch berikutnya
      await Future.delayed(interval);
    }
  }
}
