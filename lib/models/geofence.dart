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
      id: json['id'],
      name: json['name'],
      latitude: double.parse(json['latitude'].toString()),
      longitude: double.parse(json['longitude'].toString()),
      radius: json['radius'],
      trackingRadius: json['tracking_radius'],
      address: json['address'] ?? '',
      isActive: json['is_active'] == 1,
    );
  }
}