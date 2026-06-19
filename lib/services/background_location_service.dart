import 'dart:async';
import 'dart:ui';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import 'location_service.dart';

class BackgroundLocationService {
  static Future<void> initializeService() async {
    final service = FlutterBackgroundService();

    /// OPTIONAL: only for Android
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'location_tracking', // id
      'Location Tracking', // title
      description: 'Progressing background location tracking.', // description
      importance: Importance.low, // importance must be low or higher to show notification
    );

    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    // Initialize notifications
    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
    
    try {
      await flutterLocalNotificationsPlugin.initialize(initializationSettings);
      
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    } catch (e) {
      print("Notification Channel Error: $e");
    }

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: true,
        isForegroundMode: true,
        notificationChannelId: 'location_tracking',
        initialNotificationTitle: 'Tracking Active',
        initialNotificationContent: 'Monitoring location presence...',
        foregroundServiceNotificationId: 888,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: true,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );

    service.startService();
  }

  @pragma('vm:entry-point')
  static Future<bool> onIosBackground(ServiceInstance service) async {
    return true;
  }

  @pragma('vm:entry-point')
  static void onStart(ServiceInstance service) async {
    DartPluginRegistrant.ensureInitialized();

    if (service is AndroidServiceInstance) {
      service.on('setAsForeground').listen((event) {
        service.setAsForegroundService();
      });

      service.on('setAsBackground').listen((event) {
        service.setAsBackgroundService();
      });
    }

    service.on('stopService').listen((event) {
      service.stopSelf();
    });

    // Bring to foreground to ensure it keeps running
    if (service is AndroidServiceInstance) {
      service.setAsForegroundService();
    }

    // Timer for periodic updates
    Timer.periodic(const Duration(seconds: 30), (timer) async {
      try {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('token');
        if (token == null) {
          print("Background Service: No Auth Token, skipping update.");
          return;
        }

        bool isLocationEnabled = await Geolocator.isLocationServiceEnabled();
        if (!isLocationEnabled) {
          print("Location Services are DISABLED");
          // Here we could try to send a "Location OFF" status to a separate field 
          // but for now the admin will see Signal Lost after 2 min.
        } else {
          Position pos = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.medium,
            timeLimit: const Duration(seconds: 15),
          );
          await ApiService.updateLocation(pos.latitude, pos.longitude);
          
          if (service is AndroidServiceInstance) {
            service.setForegroundNotificationInfo(
              title: "Live Tracking Active",
              content: "Last presence sync: ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}",
            );
          }
        }
      } catch (e) {
        print("Background Tracking Error: $e");
      }
    });

    // Listen for Location Status Changes
    Geolocator.getServiceStatusStream().listen((ServiceStatus status) {
      if (status == ServiceStatus.disabled) {
        // We could send an immediate "Location OFF" signal here
        print("Location Services Turned OFF");
      } else {
        print("Location Services Turned ON");
      }
    });
  }
}
