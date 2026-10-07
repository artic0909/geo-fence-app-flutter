import 'dart:io';
import 'package:app_usage/app_usage.dart';
import 'package:flutter/foundation.dart';

class AppUsageService {
  static final Map<String, String> _knownApps = {
    'com.google.android.youtube': 'YouTube',
    'com.whatsapp': 'WhatsApp',
    'com.whatsapp.w4b': 'WhatsApp Business',
    'com.instagram.android': 'Instagram',
    'com.facebook.katana': 'Facebook',
    'com.facebook.orca': 'Messenger',
    'com.facebook.lite': 'Facebook Lite',
    'com.snapchat.android': 'Snapchat',
    'com.twitter.android': 'X (Twitter)',
    'com.android.chrome': 'Google Chrome',
    'com.google.android.gm': 'Gmail',
    'com.spotify.music': 'Spotify',
    'com.netflix.mediaclient': 'Netflix',
    'com.amazon.mShop.android.shopping': 'Amazon',
    'com.flipkart.android': 'Flipkart',
    'com.google.android.apps.messaging': 'Messages',
    'com.google.android.dialer': 'Phone / Dialer',
    'com.google.android.apps.maps': 'Google Maps',
    'com.google.android.apps.photos': 'Google Photos',
    'org.telegram.messenger': 'Telegram',
    'org.telegram.plus': 'Telegram Plus',
    'com.zhiliaoapp.musically': 'TikTok',
    'com.ss.android.ugc.trill': 'TikTok',
    'com.pubg.imobile': 'BGMI',
    'com.tencent.ig': 'PUBG Mobile',
    'com.dts.freefireth': 'Free Fire',
    'com.dts.freefiremax': 'Free Fire MAX',
    'com.king.candycrushsaga': 'Candy Crush',
    'com.supercell.clashofclans': 'Clash of Clans',
    'com.google.android.googlequicksearchbox': 'Google Search',
    'com.google.android.play.games': 'Google Play Games',
    'com.android.vending': 'Google Play Store',
  };

  static const List<String> _ignoredPackages = [
    'smart.geofence',
    'palgeo_app',
    'com.example.palgeo_app',
    'com.android.systemui',
    'com.google.android.inputmethod.latin',
    'com.sec.android.inputmethod',
    'com.google.android.apps.nexuslauncher',
    'com.sec.android.app.launcher',
  ];

  static String _cleanAppName(String packageName, String rawAppName) {
    if (_knownApps.containsKey(packageName)) {
      return _knownApps[packageName]!;
    }
    
    // Format package tail or raw name
    String base = rawAppName.isNotEmpty ? rawAppName : packageName.split('.').last;
    if (base.isEmpty) return packageName;
    
    // Replace underscores/hyphens and capitalize
    String words = base.replaceAll('_', ' ').replaceAll('-', ' ');
    return words.split(' ').map((w) {
      if (w.isEmpty) return '';
      return w[0].toUpperCase() + (w.length > 1 ? w.substring(1) : '');
    }).join(' ');
  }

  static String formatDuration(Duration duration) {
    final int hours = duration.inHours;
    final int minutes = duration.inMinutes.remainder(60);
    final int seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  /// Check whether app usage stats permission is active
  static Future<bool> checkPermission() async {
    if (!Platform.isAndroid) return true;
    try {
      final now = DateTime.now();
      await AppUsage().getAppUsage(now.subtract(const Duration(seconds: 5)), now);
      return true;
    } catch (e) {
      debugPrint("AppUsage permission check error: $e");
      return false;
    }
  }

  /// Query app usage statistics between check-in and check-out
  static Future<List<Map<String, dynamic>>> getAppUsageList(DateTime startTime, DateTime endTime) async {
    if (!Platform.isAndroid) return [];

    try {
      // Ensure start is before end
      DateTime start = startTime;
      DateTime end = endTime;
      if (end.isBefore(start) || end.difference(start).inSeconds < 1) {
        start = end.subtract(const Duration(minutes: 1));
      }

      final List<AppUsageInfo> rawList = await AppUsage().getAppUsage(start, end);
      
      final List<Map<String, dynamic>> usageList = [];

      for (final info in rawList) {
        // Skip ignored packages and 0 usage
        if (info.usage.inSeconds <= 0) continue;
        if (_ignoredPackages.any((pkg) => info.packageName.contains(pkg))) continue;

        final String friendlyName = _cleanAppName(info.packageName, info.appName);

        usageList.add({
          'package_name': info.packageName,
          'app_name': friendlyName,
          'usage_seconds': info.usage.inSeconds,
          'usage_formatted': formatDuration(info.usage),
          'start_time': info.startDate.toIso8601String(),
          'end_time': info.endDate.toIso8601String(),
        });
      }

      // Sort by usage seconds descending (most used first)
      usageList.sort((a, b) => (b['usage_seconds'] as int).compareTo(a['usage_seconds'] as int));

      debugPrint("AppUsageService: Collected ${usageList.length} app usage records");
      return usageList;
    } catch (e) {
      debugPrint("AppUsageService error getting usage: $e");
      return [];
    }
  }
}
