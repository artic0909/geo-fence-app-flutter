class AttendanceSession {
  final int? id;
  final String? checkIn;
  final String? checkOut;
  final String checkInTime;
  final String checkOutTime;
  final String duration;
  final int seconds;
  final String type;
  final String location;
  final String? reason;
  final bool isAutoCheckoutTrap;

  AttendanceSession({
    this.id,
    this.checkIn,
    this.checkOut,
    required this.checkInTime,
    required this.checkOutTime,
    required this.duration,
    this.seconds = 0,
    this.type = 'normal',
    this.location = 'OFFICE HUB',
    this.reason,
    this.isAutoCheckoutTrap = false,
  });

  factory AttendanceSession.fromJson(Map<String, dynamic> json) {
    return AttendanceSession(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? ''),
      checkIn: json['check_in']?.toString(),
      checkOut: json['check_out']?.toString(),
      checkInTime: json['check_in_time']?.toString() ?? '--:--',
      checkOutTime: json['check_out_time']?.toString() ?? '--:--',
      duration: json['duration']?.toString() ?? json['total_time']?.toString() ?? '--:--',
      seconds: int.tryParse(json['seconds']?.toString() ?? '0') ?? 0,
      type: json['type']?.toString() ?? 'normal',
      location: json['checkin_loc']?.toString() ?? 'OFFICE HUB',
      reason: json['reason']?.toString(),
      isAutoCheckoutTrap: json['is_auto_checkout_trap'] == true || json['is_auto_checkout_trap'] == 1 || json['is_auto_checkout_trap'] == '1',
    );
  }
}

class Attendance {
  final int id;
  final String date;
  final String? checkIn;
  final String? checkOut;
  final String status;
  final String locationName;
  final String? checkInLoc;
  final String? checkOutLoc;
  final String? reason;
  final String type;
  final bool isAutoCheckoutTrap;
  final String? totalTime;
  final String? totalTimeFormatted;
  final int? totalMinutes;
  final List<AttendanceSession> sessions;

  Attendance({
    required this.id,
    required this.date,
    this.checkIn,
    this.checkOut,
    required this.status,
    required this.locationName,
    this.checkInLoc,
    this.checkOutLoc,
    this.reason,
    required this.type,
    this.isAutoCheckoutTrap = false,
    this.totalTime,
    this.totalTimeFormatted,
    this.totalMinutes,
    this.sessions = const [],
  });

  factory Attendance.fromJson(Map<String, dynamic> json) {
    int parseId(dynamic id) {
      if (id is int) return id;
      if (id is String) return int.tryParse(id) ?? 0;
      return 0;
    }

    String parseStatus(dynamic status) {
      if (status is String) return status;
      return 'present';
    }

    String locName = "OFFICE HUB";
    if (json['geofence'] != null && json['geofence']['name'] != null) {
      locName = json['geofence']['name'].toString();
    } else if (json['checkin_location'] != null) {
      locName = json['checkin_location'].toString();
    }

    String dateValue = (json['date_formatted'] ?? json['date'])?.toString() ?? '';

    List<AttendanceSession> sessionsList = [];
    if (json['sessions'] is List) {
      for (var s in json['sessions']) {
        if (s is Map<String, dynamic>) {
          sessionsList.add(AttendanceSession.fromJson(s));
        }
      }
    }

    return Attendance(
      id: parseId(json['id']),
      date: dateValue,
      checkIn: json['check_in']?.toString(),
      checkOut: json['check_out']?.toString(),
      status: parseStatus(json['status']),
      locationName: locName,
      checkInLoc: json['checkin_loc']?.toString(),
      checkOutLoc: json['checkout_loc']?.toString(),
      reason: json['reason']?.toString(),
      type: json['type']?.toString() ?? 'normal',
      isAutoCheckoutTrap: json['is_auto_checkout_trap'] == true || json['is_auto_checkout_trap'] == 1 || json['is_auto_checkout_trap'] == '1',
      totalTime: json['total_time']?.toString(),
      totalTimeFormatted: json['total_time_formatted']?.toString(),
      totalMinutes: json['total_minutes'] != null ? int.tryParse(json['total_minutes'].toString()) : null,
      sessions: sessionsList,
    );
  }

  bool get isOutside => type == 'outside';
}
