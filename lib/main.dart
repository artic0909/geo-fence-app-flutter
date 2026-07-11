import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'screens/splash_screen.dart';
import 'screens/role_selection_screen.dart';
import 'screens/home_screen.dart';
import 'screens/history_screen.dart';
import 'services/background_location_service.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  _showNotification(message);
}

void _showNotification(RemoteMessage message) async {
  const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
    'admin_alerts_v2', // new id for new sound
    'Admin Alerts', // title
    importance: Importance.max,
    priority: Priority.high,
    fullScreenIntent: true,
    playSound: true,
    sound: RawResourceAndroidNotificationSound('alert'),
    enableVibration: true,
    category: AndroidNotificationCategory.alarm,
    timeoutAfter: 5000,
  );
  
  const NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);
      
  await flutterLocalNotificationsPlugin.show(
    id: message.hashCode,
    title: message.notification?.title ?? message.data['title'] ?? 'ADMIN ALERT',
    body: message.notification?.body ?? message.data['body'] ?? 'Return to app immediately!',
    notificationDetails: platformChannelSpecifics,
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
  
  await flutterLocalNotificationsPlugin.initialize(
    settings: initializationSettings,
    onDidReceiveNotificationResponse: (details) {
      debugPrint('Notification clicked: ${details.payload}');
    },
  );

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'admin_alerts_v2', // id
    'Admin Alerts', // title
    description: 'High priority alerts from Admin', // description
    importance: Importance.max,
    playSound: true,
    sound: RawResourceAndroidNotificationSound('alert'),
    enableVibration: true,
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    debugPrint('Foreground FCM received: ${message.messageId}');
    _showNotification(message);
  });

  // Do not await to prevent blocking runApp when OS restarts app after permission change
  BackgroundLocationService.initializeService().catchError((e) => debugPrint(e.toString()));
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Smart Geofence Attendance',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const SplashScreen(),
      routes: {
        '/login': (context) => const RoleSelectionScreen(),
        '/home': (context) => const HomeScreen(),
        '/history': (context) => const HistoryScreen(),
      },
    );
  }
}