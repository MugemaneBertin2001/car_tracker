import 'package:hive/hive.dart';

part 'car_model.g.dart';

@HiveType(typeId: 0)
class Car extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final double latitude;

  @HiveField(3)
  final double longitude;

  @HiveField(4)
  final double speed;

  @HiveField(5)
  final String status;

  // Removed model and year fields

  @HiveField(6) // Adjusted Hive field index
  final String timestamp;

  Car({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.speed,
    required this.status,
    // Removed model and year from constructor
    required this.timestamp,
  });

  factory Car.fromJson(Map<String, dynamic> json) {
    return Car(
      id: json['id'] as String,
      name: json['name'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      speed: (json['speed'] as num).toDouble(),
      status: json['status'] as String,
      // Removed parsing for model and year
      timestamp: json['timestamp'] as String,
    );
  }

  Car copyWith({
    String? id,
    String? name,
    double? latitude,
    double? longitude,
    double? speed,
    String? status,
    // Removed model and year from copyWith
    String? timestamp,
  }) {
    return Car(
      id: id ?? this.id,
      name: name ?? this.name,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      speed: speed ?? this.speed,
      status: status ?? this.status,
      // Removed model and year from copyWith
      timestamp: timestamp ?? this.timestamp,
    );
  }
}
