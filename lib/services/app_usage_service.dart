import 'dart:io';
import 'dart:convert';
import 'dart:math' as math;
import 'package:app_usage/app_usage.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    
    String base = rawAppName.isNotEmpty ? rawAppName : packageName.split('.').last;
    if (base.isEmpty) return packageName;
    
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

  /// Capture cumulative snapshot of all apps foreground seconds up to this exact moment
  static Future<Map<String, int>> captureSnapshot() async {
    if (!Platform.isAndroid) return {};
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day, 0, 0, 0);
      final List<AppUsageInfo> rawList = await AppUsage().getAppUsage(startOfDay, now);
      
      final Map<String, int> snapshot = {};
      for (final info in rawList) {
        if (info.usage.inSeconds <= 0) continue;
        if (_ignoredPackages.any((pkg) => info.packageName.contains(pkg))) continue;
        snapshot[info.packageName] = info.usage.inSeconds;
      }
      return snapshot;
    } catch (e) {
      debugPrint("AppUsageService captureSnapshot error: $e");
      return {};
    }
  }

  /// Save baseline at check-in time into SharedPreferences
  static Future<void> saveCheckInBaseline(String keyPrefix) async {
    try {
      final snapshot = await captureSnapshot();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('${keyPrefix}_app_baseline', jsonEncode(snapshot));
      debugPrint("AppUsageService: Baseline saved for $keyPrefix (${snapshot.length} apps)");
    } catch (e) {
      debugPrint("Error saving check-in baseline: $e");
    }
  }

  /// Read baseline snapshot from SharedPreferences
  static Future<Map<String, int>> getSavedBaseline(String keyPrefix) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('${keyPrefix}_app_baseline');
      if (raw != null && raw.isNotEmpty) {
        final Map<String, dynamic> decoded = jsonDecode(raw);
        return decoded.map((k, v) => MapEntry(k, int.tryParse(v.toString()) ?? 0));
      }
    } catch (e) {
      debugPrint("Error reading baseline: $e");
    }
    return {};
  }

  /// Parse string time like '13:00:00' or '13:00' dynamically on a given date
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
      debugPrint("Error parsing dynamic time $timeStr: $e");
    }
    return null;
  }

  /// Query structured app usage with mathematical delta verification against baseline
  static Future<Map<String, dynamic>> getStructuredAppUsage(
    DateTime checkInTime,
    DateTime checkOutTime, {
    String? lunchStartTime,
    String? lunchEndTime,
    String keyPrefix = 'check_in',
    bool isFinalCheckout = false,
  }) async {
    if (!Platform.isAndroid) {
      return {
        'before_lunch': [],
        'after_lunch': [],
        'summary': [],
        'total_tracked_seconds': 0,
        'total_tracked_formatted': '0s',
        'lunch_start_time': lunchStartTime,
        'lunch_end_time': lunchEndTime,
      };
    }

    // 1. Calculate actual elapsed duty windows (Hard ceilings)
    final int totalSessionElapsedSeconds = math.max(0, checkOutTime.difference(checkInTime).inSeconds);
    if (totalSessionElapsedSeconds <= 0) {
      return {
        'before_lunch': [],
        'after_lunch': [],
        'summary': [],
        'total_tracked_seconds': 0,
        'total_tracked_formatted': '0s',
        'lunch_start_time': lunchStartTime,
        'lunch_end_time': lunchEndTime,
      };
    }

    final DateTime? lunchStart = parseTimeToDate(checkInTime, lunchStartTime);
    final DateTime? lunchEnd = parseTimeToDate(checkInTime, lunchEndTime);
    final bool hasLunch = lunchStart != null && lunchEnd != null && lunchEnd.isAfter(lunchStart);

    int beforeDutyWindowSeconds = totalSessionElapsedSeconds;
    int afterDutyWindowSeconds = 0;

    if (hasLunch) {
      if (checkInTime.isBefore(lunchStart)) {
        DateTime bEnd = checkOutTime.isBefore(lunchStart) ? checkOutTime : lunchStart;
        beforeDutyWindowSeconds = math.max(0, bEnd.difference(checkInTime).inSeconds);
      } else {
        beforeDutyWindowSeconds = 0;
      }

      if (checkOutTime.isAfter(lunchEnd)) {
        DateTime aStart = checkInTime.isAfter(lunchEnd) ? checkInTime : lunchEnd;
        afterDutyWindowSeconds = math.max(0, checkOutTime.difference(aStart).inSeconds);
      } else {
        afterDutyWindowSeconds = 0;
      }
    }

    final int totalDutySeconds = math.max(1, beforeDutyWindowSeconds + afterDutyWindowSeconds);

    // 2. Read baseline snapshots
    final Map<String, int> checkInBaseline = await getSavedBaseline(keyPrefix);
    final Map<String, int> checkOutSnapshot = await captureSnapshot();
    final Map<String, int> lunchStartSnapshot = await getSavedBaseline('${keyPrefix}_lunch_start');
    final Map<String, int> lunchEndBaseline = await getSavedBaseline('${keyPrefix}_lunch_end');

    // 3. Calculate true deltas for each app
    final Map<String, int> appBeforeDeltas = {};
    final Map<String, int> appAfterDeltas = {};

    final Set<String> allPackages = {...checkOutSnapshot.keys, ...checkInBaseline.keys};

    for (final pkg in allPackages) {
      if (_ignoredPackages.any((ip) => pkg.contains(ip))) continue;

      int currentCumulative = checkOutSnapshot[pkg] ?? 0;
      
      // If checkInBaseline exists, use it; otherwise fallback to 0 delta if app was not actively used
      int baselineCumulative = checkInBaseline.containsKey(pkg) ? checkInBaseline[pkg]! : currentCumulative;
      int totalDelta = (currentCumulative - baselineCumulative).clamp(0, totalSessionElapsedSeconds);

      if (totalDelta <= 0) continue;

      if (hasLunch && (beforeDutyWindowSeconds > 0 || afterDutyWindowSeconds > 0)) {
        int bDelta = 0;
        int aDelta = 0;

        if (beforeDutyWindowSeconds > 0 && afterDutyWindowSeconds > 0) {
          // Both sessions were active
          if (lunchStartSnapshot.isNotEmpty && lunchStartSnapshot.containsKey(pkg)) {
            int lStart = lunchStartSnapshot[pkg]!;
            bDelta = (lStart - baselineCumulative).clamp(0, beforeDutyWindowSeconds);
            int lEnd = lunchEndBaseline.containsKey(pkg) ? lunchEndBaseline[pkg]! : lStart;
            aDelta = (currentCumulative - lEnd).clamp(0, afterDutyWindowSeconds);
          } else {
            // Split proportionally based on window sizes
            double bRatio = beforeDutyWindowSeconds / totalDutySeconds;
            bDelta = (totalDelta * bRatio).round().clamp(0, beforeDutyWindowSeconds);
            aDelta = (totalDelta - bDelta).clamp(0, afterDutyWindowSeconds);
          }
        } else if (beforeDutyWindowSeconds > 0) {
          bDelta = totalDelta.clamp(0, beforeDutyWindowSeconds);
        } else if (afterDutyWindowSeconds > 0) {
          aDelta = totalDelta.clamp(0, afterDutyWindowSeconds);
        }

        if (bDelta > 0) appBeforeDeltas[pkg] = bDelta;
        if (aDelta > 0) appAfterDeltas[pkg] = aDelta;
      } else {
        appBeforeDeltas[pkg] = totalDelta.clamp(0, beforeDutyWindowSeconds);
      }
    }

    // 4. Mathematical Screen Invariant: Total active screen time cannot exceed working window
    // (A user can only look at 1 app at a time on screen)
    int sumBefore = appBeforeDeltas.values.fold(0, (sum, v) => sum + v);
    if (sumBefore > beforeDutyWindowSeconds && beforeDutyWindowSeconds > 0) {
      double scale = beforeDutyWindowSeconds / sumBefore;
      appBeforeDeltas.updateAll((pkg, val) => math.max(1, (val * scale).floor()));
    }

    int sumAfter = appAfterDeltas.values.fold(0, (sum, v) => sum + v);
    if (sumAfter > afterDutyWindowSeconds && afterDutyWindowSeconds > 0) {
      double scale = afterDutyWindowSeconds / sumAfter;
      appAfterDeltas.updateAll((pkg, val) => math.max(1, (val * scale).floor()));
    }

    // 5. Build structured lists and summary
    List<Map<String, dynamic>> beforeLunchList = [];
    List<Map<String, dynamic>> afterLunchList = [];
    final Map<String, Map<String, dynamic>> summaryMap = {};

    appBeforeDeltas.forEach((pkg, secs) {
      final String friendlyName = _cleanAppName(pkg, '');
      beforeLunchList.add({
        'package_name': pkg,
        'app_name': friendlyName,
        'usage_seconds': secs,
        'usage_formatted': formatSeconds(secs),
      });

      summaryMap[pkg] = {
        'package_name': pkg,
        'app_name': friendlyName,
        'before_lunch_seconds': secs,
        'before_lunch_formatted': formatSeconds(secs),
        'after_lunch_seconds': 0,
        'after_lunch_formatted': '0s',
        'total_seconds': secs,
        'total_formatted': formatSeconds(secs),
      };
    });

    appAfterDeltas.forEach((pkg, secs) {
      final String friendlyName = _cleanAppName(pkg, '');
      afterLunchList.add({
        'package_name': pkg,
        'app_name': friendlyName,
        'usage_seconds': secs,
        'usage_formatted': formatSeconds(secs),
      });

      if (summaryMap.containsKey(pkg)) {
        int bSecs = summaryMap[pkg]!['before_lunch_seconds'] as int;
        int tot = bSecs + secs;
        summaryMap[pkg]!['after_lunch_seconds'] = secs;
        summaryMap[pkg]!['after_lunch_formatted'] = formatSeconds(secs);
        summaryMap[pkg]!['total_seconds'] = tot;
        summaryMap[pkg]!['total_formatted'] = formatSeconds(tot);
      } else {
        summaryMap[pkg] = {
          'package_name': pkg,
          'app_name': friendlyName,
          'before_lunch_seconds': 0,
          'before_lunch_formatted': '0s',
          'after_lunch_seconds': secs,
          'after_lunch_formatted': formatSeconds(secs),
          'total_seconds': secs,
          'total_formatted': formatSeconds(secs),
        };
      }
    });

    beforeLunchList.sort((a, b) => (b['usage_seconds'] as int).compareTo(a['usage_seconds'] as int));
    afterLunchList.sort((a, b) => (b['usage_seconds'] as int).compareTo(a['usage_seconds'] as int));

    final List<Map<String, dynamic>> summaryList = summaryMap.values.toList();
    summaryList.sort((a, b) => (b['total_seconds'] as int).compareTo(a['total_seconds'] as int));

    int totalTrackedSeconds = summaryList.fold(0, (acc, item) => acc + (item['total_seconds'] as int));

    if (isFinalCheckout) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('${keyPrefix}_app_baseline');
      await prefs.remove('${keyPrefix}_lunch_start_app_baseline');
      await prefs.remove('${keyPrefix}_lunch_end_app_baseline');
    }

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
