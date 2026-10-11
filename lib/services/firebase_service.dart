import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'firebase_options.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("Handling a background message: ${message.messageId}");
}

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  late FirebaseMessaging _firebaseMessaging;

  FirebaseService._internal() {
    _firebaseMessaging = FirebaseMessaging.instance;
  }

  factory FirebaseService() {
    return _instance;
  }

  Future<void> initialize() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Get and save initial FCM token
    final initialToken = await _firebaseMessaging.getToken();
    if (initialToken != null) {
      _saveFcmTokenToDatabase(initialToken);
    }

    // Listen for token refresh
    _firebaseMessaging.onTokenRefresh.listen((fcmToken) {
      print('FCM Token refreshed: $fcmToken');
      _saveFcmTokenToDatabase(fcmToken);
    });

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Got a message whilst in the foreground!');
      print('Message data: ${message.data}');

      if (message.notification != null) {
        print('Message also contained a notification: ${message.notification}');
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('A new onMessageOpenedApp event was published!');
      // Handle notification tap
    });

    final settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    print('User granted permission: ${settings.authorizationStatus}');
  }

  Future<String?> getToken() async {
    return await _firebaseMessaging.getToken();
  }

  Future<void> subscribeToTopic(String topic) async {
    await _firebaseMessaging.subscribeToTopic(topic);
    print('Subscribed to topic: $topic');
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    await _firebaseMessaging.unsubscribeFromTopic(topic);
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
