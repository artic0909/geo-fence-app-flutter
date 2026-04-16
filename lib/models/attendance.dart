class Attendance {
  final int id;
  final String date;
  final String? checkIn;
  final String? checkOut;
  final String status;

  Attendance({
    required this.id,
    required this.date,
    this.checkIn,
    this.checkOut,
    required this.status,
  });

  factory Attendance.fromJson(Map<String, dynamic> json) {
    // Handle both string and int types for ID
    int parseId(dynamic id) {
      if (id is int) return id;
      if (id is String) return int.tryParse(id) ?? 0;
      return 0;
    }

    // Handle status with default value
    String parseStatus(dynamic status) {
      if (status is String) return status;
      return 'present'; // default value
    }

    return Attendance(
      id: parseId(json['id']),
      date: json['date']?.toString() ?? '',
      checkIn: json['check_in']?.toString(),
      checkOut: json['check_out']?.toString(),
      status: parseStatus(json['status']),
    );
  }
}