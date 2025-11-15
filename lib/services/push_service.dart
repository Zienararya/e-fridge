import 'dart:io' show Platform;

import 'package:firebase_core/firebase_core.dart';
import 'package:efridge/firebase_options.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../database.dart';

// Top-level background handler for FCM data messages
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Ensure bindings and Firebase are initialized in background isolate
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (_) {}
  // For background messages with a "notification" payload, Android displays
  // the system notification automatically. For pure data messages, you may
  // optionally generate a local notification here (requires plugin setup in bg).
}

class PushService {
  static final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  static Future<void> _initLocalNotifications() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _local.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );

    // Android 13+ permission via local notifications plugin
    await _local
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();

    // iOS permission prompt
    await _local
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    const channel = AndroidNotificationChannel(
      'fcm_foreground',
      'FCM Foreground Notifications',
      description: 'Notifikasi saat aplikasi di foreground',
      importance: Importance.high,
    );
    await _local
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);
  }

  static Future<void> initAndRegister() async {
    if (_initialized) return;
    _initialized = true;

    // 1) Init Firebase (safe to call multiple times)
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } catch (_) {}

    // 2) Register background handler once
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // 3) Request (iOS) permission and setup local notifications for foreground
    await _initLocalNotifications();
    try {
      await FirebaseMessaging.instance.requestPermission();
    } catch (_) {}

    // 4) Listen for foreground messages and show local notifications
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      final notification = message.notification;
      if (notification != null) {
        final android = notification.android;
        await _local.show(
          notification.hashCode,
          notification.title ?? 'Pemberitahuan',
          notification.body ?? '',
          NotificationDetails(
            android: AndroidNotificationDetails(
              'fcm_foreground',
              'FCM Foreground Notifications',
              channelDescription: 'Notifikasi saat aplikasi di foreground',
              importance: Importance.high,
              priority: Priority.high,
              icon: android?.smallIcon ?? '@mipmap/ic_launcher',
            ),
            iOS: const DarwinNotificationDetails(),
          ),
        );
      }
    });

    // 5) Handle message taps
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      // You can navigate or track analytics here if needed
    });
    // Optionally read the message that opened the app from a terminated state
    try {
      await FirebaseMessaging.instance.getInitialMessage();
    } catch (_) {}

    // 6) Get token and register to Supabase
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await _saveTokenToSupabase(token);
      }
      // Keep token up to date
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
        await _saveTokenToSupabase(newToken);
      });
    } catch (e) {
      debugPrint('FCM token error: $e');
    }
  }

  static Future<void> _saveTokenToSupabase(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? userIdStr = prefs.getString('user_id');
      if (userIdStr == null) {
        final uid = prefs.getString('uid');
        if (uid != null) {
          final row = await Database.supabase
              .from('user')
              .select('id')
              .eq('uid', uid)
              .maybeSingle();
          userIdStr = row?['id']?.toString();
          if (userIdStr != null) await prefs.setString('user_id', userIdStr);
        }
      }

      final userId = int.tryParse(userIdStr ?? '');
      if (userId == null) return;

      final platform = Platform.operatingSystem; // 'android', 'ios', etc.
      final data = {
        'user_id': userId,
        'token': token,
        'platform': platform,
        'updated_at': DateTime.now().toIso8601String(),
      };

      // Upsert by unique token to avoid duplicates
      await Database.supabase
          .from('device_tokens')
          .upsert(data, onConflict: 'token');
    } catch (e) {
      debugPrint('Failed to save FCM token: $e');
    }
  }
}
