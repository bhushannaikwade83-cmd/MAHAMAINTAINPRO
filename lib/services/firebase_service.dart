import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;

final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("Handling a background message: ${message.messageId}");
}

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();

  // Not resolved until initialize() runs and Firebase.initializeApp() has
  // succeeded - FirebaseMessaging.instance touches the default Firebase app
  // immediately, so grabbing it any earlier (e.g. in this constructor, as
  // this used to do) throws before initialize()'s own try/catch - or even
  // main.dart's catchError - ever gets a chance to run. On web specifically,
  // without a configured service worker/VAPID key, that throw comes back as
  // a raw JS interop error that crashes app startup entirely.
  FirebaseMessaging? _firebaseMessaging;

  FirebaseService._internal();

  factory FirebaseService() {
    return _instance;
  }

  Future<void> initialize() async {
    if (!kIsWeb) {
      // Firebase initialization for native platforms
      // This would normally use firebase_options.dart
      try {
        await Firebase.initializeApp();
      } catch (e) {
        print('Firebase initialization error: $e');
      }
    }

    await _localNotifications.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
    );

    // Push notifications are a nice-to-have, not something app startup
    // should ever fail over - if messaging isn't available (unsupported
    // platform, missing web push config, permission plumbing not set up
    // yet), log it and move on rather than taking the whole app down.
    try {
      final messaging = FirebaseMessaging.instance;
      _firebaseMessaging = messaging;

      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      final initialToken = await messaging.getToken();
      if (initialToken != null) {
        _saveFcmTokenToDatabase(initialToken);
      }

      messaging.onTokenRefresh.listen((fcmToken) {
        print('FCM Token refreshed: $fcmToken');
        _saveFcmTokenToDatabase(fcmToken);
      });

      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print('Got a message whilst in the foreground!');
        print('Message data: ${message.data}');

        final notification = message.notification;
        if (notification != null) {
          // FCM only auto-shows a system banner when the app is backgrounded -
          // in the foreground it silently delivers the message with nothing
          // shown unless we display it ourselves.
          _localNotifications.show(
            DateTime.now().millisecondsSinceEpoch ~/ 1000,
            notification.title,
            notification.body,
            const NotificationDetails(
              android: AndroidNotificationDetails(
                'maha_maintain_default',
                'Maha Maintain Pro',
                channelDescription: 'Order, payment, complaint and society updates',
                importance: Importance.high,
                priority: Priority.high,
              ),
              iOS: DarwinNotificationDetails(),
            ),
          );
        }
      });

      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        print('A new onMessageOpenedApp event was published!');
        // Handle notification tap
      });

      final settings = await messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      print('User granted permission: ${settings.authorizationStatus}');
    } catch (e) {
      print('Push notifications unavailable on this platform/build: $e');
    }
  }

  Future<String?> getToken() async {
    return await _firebaseMessaging?.getToken();
  }

  Future<void> subscribeToTopic(String topic) async {
    await _firebaseMessaging?.subscribeToTopic(topic);
    print('Subscribed to topic: $topic');
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    await _firebaseMessaging?.unsubscribeFromTopic(topic);
    print('Unsubscribed from topic: $topic');
  }

  Future<void> _saveFcmTokenToDatabase(String fcmToken) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userPhone = prefs.getString('user_phone') ?? '';
      final userName = prefs.getString('user_name') ?? '';

      if (userPhone.isEmpty) {
        print('User phone not set yet, skipping FCM save');
        return;
      }

      final response = await http.post(
        Uri.parse('https://digitrixmedia.com/mahamaintainpro/api/save-user-fcm.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'phone': userPhone,
          'name': userName,
          'fcm_token': fcmToken,
        }),
      );

      if (response.statusCode == 200) {
        print('FCM token saved to users table');
      } else {
        print('Failed to save FCM token: ${response.statusCode}');
      }
    } catch (e) {
      print('Error saving FCM token: $e');
    }
  }
}
