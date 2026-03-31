import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);
    await _localNotifications.initialize(settings: initSettings);

    await FirebaseMessaging.instance.requestPermission();
    FirebaseMessaging.onMessage.listen((message) async {
      final notif = message.notification;
      if (notif == null) return;

      const details = NotificationDetails(
        android: AndroidNotificationDetails(
          'tradehub_messages',
          'TradeHub Messages',
          importance: Importance.max,
          priority: Priority.high,
        ),
      );

      await _localNotifications.show(
        id: notif.hashCode,
        title: notif.title,
        body: notif.body,
        notificationDetails: details,
      );
    });
  }
}
