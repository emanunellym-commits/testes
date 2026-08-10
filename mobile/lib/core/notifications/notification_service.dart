import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../network/api_client.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

class NotificationService {
  NotificationService._();

  static final instance = NotificationService._();

  final local = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    await Firebase.initializeApp();

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();

    await local.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );

    final androidImpl = local.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    await androidImpl?.createNotificationChannel(
      const AndroidNotificationChannel(
        'messages',
        'Mensagens',
        description: 'Novas mensagens do LiveChat',
        importance: Importance.high,
      ),
    );

    await androidImpl?.createNotificationChannel(
      const AndroidNotificationChannel(
        'calls',
        'Chamadas',
        description: 'Chamadas recebidas do LiveChat',
        importance: Importance.max,
        playSound: true,
      ),
    );

    final messaging = FirebaseMessaging.instance;

    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    final token = await messaging.getToken();
    if (token != null) {
      await registerToken(token);
    }

    messaging.onTokenRefresh.listen(registerToken);

    FirebaseMessaging.onMessage.listen((message) async {
      final notification = message.notification;
      if (notification == null) return;

      final kind = message.data['kind'];
      final channel = kind == 'incoming_call' ? 'calls' : 'messages';

      await local.show(
        message.hashCode,
        notification.title ?? 'LiveChat',
        notification.body ?? '',
        NotificationDetails(
          android: AndroidNotificationDetails(
            channel,
            channel == 'calls' ? 'Chamadas' : 'Mensagens',
            importance: kind == 'incoming_call'
                ? Importance.max
                : Importance.high,
            priority: Priority.high,
            fullScreenIntent: kind == 'incoming_call',
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: message.data.toString(),
      );
    });
  }

  Future<void> registerToken(String token) async {
    try {
      await ApiClient.instance.dio.post('/push/token', data: {
        'token': token,
        'platform': Platform.isIOS ? 'ios' : 'android',
      });
    } catch (_) {
      // O token será reenviado quando o app iniciar novamente.
    }
  }
}
