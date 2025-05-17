import 'package:flutter/foundation.dart';

class Car {
  final int id;
  final String name;
  final String status;
  final double speed;
  final double latitude;
  final double longitude;
  final String lastUpdated;

  Car({
    required this.id,
    required this.name,
    required this.status,
    required this.speed,
    required this.latitude,
    required this.longitude,
    required this.lastUpdated,
  });

  factory Car.fromJson(Map<String, dynamic> json) {
    // Debug log to track what data is being parsed
    debugPrint('=== Parsing Car from JSON ===');
    debugPrint('Raw JSON: $json');

    try {
      // Parse ID
      final id = _parseId(json['id']);
      debugPrint('Parsed ID: $id');

      // Parse name
      final name = json['name']?.toString() ?? 'Unknown';
      debugPrint('Parsed name: $name');

      // Parse status
      final status = json['status']?.toString() ?? 'Unknown';
      debugPrint('Parsed status: $status');

      // Parse speed
      final speed = _parseDouble(json['speed']);
      debugPrint('Parsed speed: $speed');

      // Parse location
      final latitude = _parseDouble(json['latitude']);
      final longitude = _parseDouble(json['longitude']);
      debugPrint('Parsed location: ($latitude, $longitude)');

      // Parse lastUpdated
      final lastUpdated =
          json['lastUpdated']?.toString() ?? DateTime.now().toIso8601String();
      debugPrint('Parsed lastUpdated: $lastUpdated');

      debugPrint('=== Successfully parsed Car object ===');

      return Car(
        id: id,
        name: name,
        status: status,
        speed: speed,
        latitude: latitude,
        longitude: longitude,
        lastUpdated: lastUpdated,
      );
    } catch (e) {
      debugPrint('ERROR parsing Car: $e');
      // Return a default object when parsing fails
      debugPrint('=== Created fallback Car object ===');
      return Car(
        id: -1,
        name: 'Error Car',
        status: 'Error',
        speed: 0.0,
        latitude: 0.0,
        longitude: 0.0,
        lastUpdated: DateTime.now().toIso8601String(),
      );
    }
  }

  // Helper method to safely parse ID
  static int _parseId(dynamic value) {
    if (value == null) return -1;

    if (value is int) {
      return value;
    }

    if (value is String) {
      try {
        return int.parse(value);
      } catch (e) {
        debugPrint('Failed to parse ID from string: $value');
        return -1;
      }
    }

    debugPrint('Unknown ID type: ${value.runtimeType}');
    return -1;
  }

  // Helper method to safely parse doubles
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;

    if (value is double) {
      return value;
    }

    if (value is int) {
      return value.toDouble();
    }

    if (value is String) {
      try {
        return double.parse(value);
      } catch (e) {
        debugPrint('Failed to parse double from string: $value');
        return 0.0;
      }
    }

    debugPrint('Unknown numeric type: ${value.runtimeType}');
    return 0.0;
  }

  @override
  String toString() {
    return 'Car{id: $id, name: $name, status: $status, speed: $speed, position: ($latitude, $longitude)}';
  }
}
