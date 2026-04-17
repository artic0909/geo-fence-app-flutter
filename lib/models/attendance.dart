class Attendance {
  final int id;
  final String date;
  final String? checkIn;
  final String? checkOut;
  final String status;
  final String locationName;

  Attendance({
    required this.id,
    required this.date,
    this.checkIn,
    this.checkOut,
    required this.status,
    required this.locationName,
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

    // Determine location name from geofence or outside location
    String locName = "OFFICE HUB";
    if (json['geofence'] != null && json['geofence']['name'] != null) {
      locName = json['geofence']['name'].toString();
    } else if (json['checkin_location'] != null) {
      locName = json['checkin_location'].toString();
    }

    // Use date_formatted if available (sent by backend to prevent timezone shifts)
    String dateValue = (json['date_formatted'] ?? json['date'])?.toString() ?? '';

    return Attendance(
      id: parseId(json['id']),
      date: dateValue,
      checkIn: json['check_in']?.toString(),
      checkOut: json['check_out']?.toString(),
      status: parseStatus(json['status']),
      locationName: locName,
    );
  }
}