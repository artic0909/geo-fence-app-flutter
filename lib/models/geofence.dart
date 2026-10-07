class Geofence {
  final int id;
  final String name;
  final double latitude;
  final double longitude;
  final int radius;
  final int? trackingRadius;
  final String address;
  final bool isActive;

  Geofence({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.radius,
    this.trackingRadius,
    required this.address,
    required this.isActive,
  });

  factory Geofence.fromJson(Map<String, dynamic> json) {
    return Geofence(
      id: json['id'] is int ? json['id'] : (int.tryParse(json['id']?.toString() ?? '0') ?? 0),
      name: json['name']?.toString() ?? '',
      latitude: double.tryParse(json['latitude']?.toString() ?? '0.0') ?? 0.0,
      longitude: double.tryParse(json['longitude']?.toString() ?? '0.0') ?? 0.0,
      radius: json['radius'] is int ? json['radius'] : (int.tryParse(json['radius']?.toString() ?? '100') ?? 100),
      trackingRadius: json['tracking_radius'] != null ? int.tryParse(json['tracking_radius'].toString()) : null,
      address: json['address']?.toString() ?? '',
      isActive: json['is_active'] == 1 || json['is_active'] == true || json['is_active'] == '1',
    );
  }
}
