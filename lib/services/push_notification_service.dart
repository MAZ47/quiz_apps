import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../app_route.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (kDebugMode) {
    print('Handling a background message: ${message.messageId}');
    print('Background message data payload: ${message.data}');
  }
}

class PushNotificationService {
  // Singleton pattern
  static final PushNotificationService _instance =
  PushNotificationService._internal();

  factory PushNotificationService() {
    return _instance;
  }

  PushNotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  Future<void> _initLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsDarwin =
    DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const InitializationSettings initializationSettings =
    InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    // ফিক্স ১: settings: নামযুক্ত প্যারামিটার ব্যবহার করা হলো
    await _localNotificationsPlugin.initialize(
      settings: initializationSettings,
    );
  }

  Future<void> initialize() async {
    // ইউজারের কাছে নোটিফিকেশন পারমিশন চাওয়া
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      if (kDebugMode) {
        print('PushNotificationService: User granted permission');
      }
      // FCM টোকেন ফেচ করা
      String? token = await _firebaseMessaging.getToken();
      if (kDebugMode) {
        print('PushNotificationService FCM Token: $token');
      }
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      if (kDebugMode) {
        print('PushNotificationService: User granted provisional permission');
      }
    } else {
      if (kDebugMode) {
        print(
          'PushNotificationService: User declined or has not accepted permission',
        );
      }
    }

    // ব্যাকগ্রাউন্ড মেসেজ হ্যান্ডলার রেজিস্টার
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // লোকাল নোটিফিকেশন ইনিশিয়ালাইজ করা
    await _initLocalNotifications();

    // অ্যাপ ওপেন থাকা অবস্থায় নোটিফিকেশন হ্যান্ডেল করা
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (kDebugMode) {
        print('Handling a foreground message: ${message.messageId}');
        print('Foreground message data payload: ${message.data}');
      }

      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      if (notification != null && android != null) {
        // ফিক্স ২: show() মেথডে Named Parameters ব্যবহার করা হলো
        _localNotificationsPlugin.show(
          id: notification.hashCode,
          title: notification.title,
          body: notification.body,
          notificationDetails: const NotificationDetails(
            android: AndroidNotificationDetails(
              'high_importance_channel',
              'High Importance Notifications',
              channelDescription:
              'This channel is used for important notifications.',
              importance: Importance.max,
              priority: Priority.high,
              icon: '@mipmap/ic_launcher',
            ),
          ),
        );
      }
    });

    // নোটিফিকেশনে ক্লিক করলে অ্যাপের নির্দিষ্ট স্ক্রিনে যাওয়ার ব্যবস্থা করা
    await _setupInteractedMessage();
  }

  Future<void> _setupInteractedMessage() async {
    // ১. অ্যাপ সম্পূর্ণ বন্ধ (Terminated) থাকা অবস্থা থেকে নোটিফিকেশনে ক্লিক
    RemoteMessage? initialMessage =
    await FirebaseMessaging.instance.getInitialMessage();

    if (initialMessage != null) {
      _handleMessage(initialMessage, isInitial: true);
    }

    // ২. অ্যাপ ব্যাকগ্রাউন্ডে থাকা অবস্থা থেকে নোটিফিকেশনে ক্লিক
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleMessage(message, isInitial: false);
    });
  }

  void _handleMessage(RemoteMessage message, {bool isInitial = false}) {
    if (kDebugMode) {
      print(
        'PushNotificationService: Handling interacted message: ${message.messageId}',
      );
      print('Message data payload: ${message.data}');
    }

    try {
      final data = message.data;
      if (data.containsKey('path')) {
        final path = data['path'];
        if (path != null && path is String && path.isNotEmpty) {
          if (isInitial) {
            // Terminated অবস্থায় রাউট এবং অথ স্টেট রেন্ডার হওয়ার জন্য ১ সেকেন্ড ডিল
            Future.delayed(const Duration(milliseconds: 1000), () {
              AppRoute.instance.push(path);
            });
          } else {
            AppRoute.instance.push(path);
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print(
          'PushNotificationService: Error parsing route from FCM message: $e',
        );
      }
    }
  }
}