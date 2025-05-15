import 'dart:convert';

class Car {
  final int id;
  final String name;
  double latitude;
  double longitude;
  double speed;
  String status;

  Car({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.speed,
    required this.status,
  });

  factory Car.fromJson(Map<String, dynamic> json) {
    return Car(
      id: json['id'],
      name: json['name'],
      latitude: json['latitude'],
      longitude: json['longitude'],
      speed: json['speed'],
      status: json['status'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'speed': speed,
      'status': status,
    };
  }
}
