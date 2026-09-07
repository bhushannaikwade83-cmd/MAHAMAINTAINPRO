import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  GlobalKey<NavigatorState>? navigatorKey;

  Future<void> init(GlobalKey<NavigatorState> key) async {
    navigatorKey = key;

    // Request notification permissions (iOS)
    await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Get FCM token and save to preferences
    final token = await _firebaseMessaging.getToken();
    if (token != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('fcmToken', token);
      print('FCM Token: $token');
    }

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _handleNotification(message);
    });

    // Handle background messages
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleNotificationTap(message);
    });

    // Handle terminated app messages
    final initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }

    // Token refresh listener
    _firebaseMessaging.onTokenRefresh.listen((newToken) async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('fcmToken', newToken);
      print('FCM Token refreshed: $newToken');
    });
  }

  void _handleNotification(RemoteMessage message) {
    final notification = message.notification;
    final data = message.data;

    if (notification != null) {
      _showLocalNotification(
        title: notification.title ?? 'Maha Maintain',
        body: notification.body ?? '',
        data: data,
      );
    }
  }

  void _handleNotificationTap(RemoteMessage message) {
    final data = message.data;
    final notificationType = data['type'];
    final requestId = data['request_id'];

    if (navigatorKey?.currentState != null && requestId != null) {
      _navigateToRequest(int.tryParse(requestId) ?? 0, notificationType);
    }
  }

  void _showLocalNotification({
    required String title,
    required String body,
    required Map<String, dynamic> data,
  }) {
    // Local notification handling
    // You can integrate with flutter_local_notifications for native notifications
    print('Notification - Title: $title, Body: $body');
  }

  void _navigateToRequest(int requestId, String? notificationType) {
    // Navigate to live tracking or booking details based on notification type
    if (requestId > 0) {
      // navigatorKey?.currentState?.pushNamed('/live-tracking', arguments: requestId);
    }
  }
}

class NotificationPayload {
  final String type; // 'vendor_assigned', 'vendor_arrived', 'job_completed', etc.
  final int requestId;
  final String title;
  final String body;
  final Map<String, dynamic> data;

  NotificationPayload({
    required this.type,
    required this.requestId,
    required this.title,
    required this.body,
    required this.data,
  });

  Map<String, String> toMap() => {
        'type': type,
        'request_id': requestId.toString(),
        'title': title,
        'body': body,
      };
}
