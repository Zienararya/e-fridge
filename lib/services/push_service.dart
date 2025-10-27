import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:pushy_flutter/pushy_flutter.dart' as pushy;
import 'package:supabase_flutter/supabase_flutter.dart';

class PushService {
  static final _local = FlutterLocalNotificationsPlugin();

  static Future<void> initLocalNotifications() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _local.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );

    // Create default channel (Android 8+)
    const channel = AndroidNotificationChannel(
      'pushy_default',
      'Push Notifications',
      description: 'General notifications',
      importance: Importance.high,
    );
    await _local
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);
  }

  static Future<String> registerDeviceToken() async {
    // Register device with Pushy
    final token = await pushy.Pushy.register();
    return token;
  }

  static Future<void> upsertDeviceToken(String token) async {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;
    await supabase.from('devices').upsert({
      'user_id': userId,
      'token': token,
      'platform': Platform.isIOS ? 'ios' : 'android',
    });
  }

  static void listenBackgroundMessages() {
    // Ensure Pushy service is running
    pushy.Pushy.listen();
    pushy.Pushy.setNotificationListener((data) async {
      final title = (data['title'] ?? 'Notification').toString();
      final body = (data['message'] ?? data['body'] ?? '').toString();
      const android = AndroidNotificationDetails(
        'pushy_default',
        'Push Notifications',
        importance: Importance.high,
        priority: Priority.high,
      );
      const ios = DarwinNotificationDetails();
      await _local.show(
        0,
        title,
        body,
        const NotificationDetails(android: android, iOS: ios),
      );
    });
  }
}
