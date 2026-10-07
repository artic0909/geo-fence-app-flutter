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

  static String formatSeconds(int totalSeconds) {
    return formatDuration(Duration(seconds: totalSeconds));
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

  /// Query app usage statistics for a specific interval
  static Future<List<Map<String, dynamic>>> getAppUsageList(DateTime startTime, DateTime endTime) async {
    if (!Platform.isAndroid) return [];

    try {
      DateTime start = startTime;
      DateTime end = endTime;
      if (end.isBefore(start) || end.difference(start).inSeconds < 1) {
        return [];
      }

      final List<AppUsageInfo> rawList = await AppUsage().getAppUsage(start, end);
      final List<Map<String, dynamic>> usageList = [];

      for (final info in rawList) {
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

      usageList.sort((a, b) => (b['usage_seconds'] as int).compareTo(a['usage_seconds'] as int));
      return usageList;
    } catch (e) {
      debugPrint("AppUsageService error getting usage: $e");
      return [];
    }
  }

  /// Parse string time like '13:00:00' or '13:00' on a given date
  static DateTime? parseTimeToDate(DateTime baseDate, String? timeStr) {
    if (timeStr == null || timeStr.trim().isEmpty) return null;
    try {
      final parts = timeStr.trim().split(':');
      if (parts.length >= 2) {
        int h = int.parse(parts[0]);
        int m = int.parse(parts[1]);
        int s = parts.length > 2 ? int.parse(parts[2]) : 0;
        return DateTime(baseDate.year, baseDate.month, baseDate.day, h, m, s);
      }
    } catch (e) {
      debugPrint("Error parsing time $timeStr: $e");
    }
    return null;
  }

  /// Query structured app usage split by Before Lunch and After Lunch
  static Future<Map<String, dynamic>> getStructuredAppUsage(
    DateTime checkInTime,
    DateTime checkOutTime, {
    String? lunchStartTime,
    String? lunchEndTime,
  }) async {
    if (!Platform.isAndroid) {
      return {
        'before_lunch': [],
        'after_lunch': [],
        'summary': [],
        'total_tracked_seconds': 0,
        'total_tracked_formatted': '0s',
      };
    }

    final DateTime? lunchStart = parseTimeToDate(checkInTime, lunchStartTime);
    final DateTime? lunchEnd = parseTimeToDate(checkInTime, lunchEndTime);

    List<Map<String, dynamic>> beforeLunchList = [];
    List<Map<String, dynamic>> afterLunchList = [];

    if (lunchStart != null && lunchEnd != null && lunchEnd.isAfter(lunchStart)) {
      // 1. Before Lunch period: checkInTime to min(checkOutTime, lunchStart)
      DateTime bStart = checkInTime;
      DateTime bEnd = checkOutTime.isBefore(lunchStart) ? checkOutTime : lunchStart;
      if (bStart.isBefore(bEnd)) {
        beforeLunchList = await getAppUsageList(bStart, bEnd);
      }

      // 2. After Lunch period: max(checkInTime, lunchEnd) to checkOutTime
      if (checkOutTime.isAfter(lunchEnd)) {
        DateTime aStart = checkInTime.isAfter(lunchEnd) ? checkInTime : lunchEnd;
        DateTime aEnd = checkOutTime;
        if (aStart.isBefore(aEnd)) {
          afterLunchList = await getAppUsageList(aStart, aEnd);
        }
      }
    } else {
      // No lunch period configured: everything goes to before_lunch / single session
      beforeLunchList = await getAppUsageList(checkInTime, checkOutTime);
    }

    // 3. Build unified summary map by package_name
    final Map<String, Map<String, dynamic>> summaryMap = {};

    for (var app in beforeLunchList) {
      String pkg = app['package_name'];
      String name = app['app_name'];
      int secs = app['usage_seconds'] ?? 0;

      summaryMap[pkg] = {
        'package_name': pkg,
        'app_name': name,
        'before_lunch_seconds': secs,
        'before_lunch_formatted': formatSeconds(secs),
        'after_lunch_seconds': 0,
        'after_lunch_formatted': '0s',
        'total_seconds': secs,
        'total_formatted': formatSeconds(secs),
      };
    }

    for (var app in afterLunchList) {
      String pkg = app['package_name'];
      String name = app['app_name'];
      int secs = app['usage_seconds'] ?? 0;

      if (summaryMap.containsKey(pkg)) {
        int bSecs = summaryMap[pkg]!['before_lunch_seconds'] as int;
        int total = bSecs + secs;
        summaryMap[pkg]!['after_lunch_seconds'] = secs;
        summaryMap[pkg]!['after_lunch_formatted'] = formatSeconds(secs);
        summaryMap[pkg]!['total_seconds'] = total;
        summaryMap[pkg]!['total_formatted'] = formatSeconds(total);
      } else {
        summaryMap[pkg] = {
          'package_name': pkg,
          'app_name': name,
          'before_lunch_seconds': 0,
          'before_lunch_formatted': '0s',
          'after_lunch_seconds': secs,
          'after_lunch_formatted': formatSeconds(secs),
          'total_seconds': secs,
          'total_formatted': formatSeconds(secs),
        };
      }
    }

    final List<Map<String, dynamic>> summaryList = summaryMap.values.toList();
    summaryList.sort((a, b) => (b['total_seconds'] as int).compareTo(a['total_seconds'] as int));

    int totalTrackedSeconds = summaryList.fold(0, (acc, item) => acc + (item['total_seconds'] as int));

    return {
      'before_lunch': beforeLunchList,
      'after_lunch': afterLunchList,
      'summary': summaryList,
      'total_tracked_seconds': totalTrackedSeconds,
      'total_tracked_formatted': formatSeconds(totalTrackedSeconds),
      'lunch_start_time': lunchStartTime,
      'lunch_end_time': lunchEndTime,
    };
  }
}
