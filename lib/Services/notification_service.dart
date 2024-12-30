import 'package:firebase_messaging/firebase_messaging.dart';
import 'dart:developer';

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  /// Initialize notifications
  Future<void> initialize() async {
    // Request notification permissions for iOS
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      log("Foreground message received: ${message.notification?.title}, ${message.notification?.body}");
    });

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);

    // Print FCM token for testing
    String? token = await _messaging.getToken();
    print("FCM Token: $token");
  }
}

/// Background message handler
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  log("Background message received: ${message.notification?.title}, ${message.notification?.body}");
}
