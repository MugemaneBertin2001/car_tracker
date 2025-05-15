import 'dart:convert';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import '../models/car_model.dart';

class CarService {
  final String baseUrl =
      'https://68260a2e397e48c91314bda1.mockapi.io/api/v1/cars';
  static const String _carBoxName = 'carsBox';
  static const String _carDataKey = 'carData';
  static const String _lastUpdatedKey = 'lastUpdated';

  Future<List<Car>> fetchCars() async {
    try {
      final response = await http.get(Uri.parse(baseUrl));

      if (response.statusCode == 200) {
        // Save to Hive
        await _saveToHive(response.body);
        List<dynamic> carsJson = json.decode(response.body);
        return carsJson.map((carJson) => Car.fromJson(carJson)).toList();
      } else {
        // If server error, try Hive
        return await _fetchFromHive();
      }
    } catch (e) {
      // If network error, try Hive
      return await _fetchFromHive();
    }
  }

  Future<void> _saveToHive(String carData) async {
    final box = Hive.box(_carBoxName);
    await box.put(_carDataKey, carData);
    await box.put(_lastUpdatedKey, DateTime.now().toIso8601String());
  }

  Future<List<Car>> _fetchFromHive() async {
    try {
      final box = Hive.box(_carBoxName);
      final carData = box.get(_carDataKey);

      if (carData != null) {
        List<dynamic> carsJson = json.decode(carData);
        return carsJson.map((carJson) => Car.fromJson(carJson)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<String> getLastUpdatedTime() async {
    try {
      final box = Hive.box(_carBoxName);
      final lastUpdated = box.get(_lastUpdatedKey);
      return lastUpdated ?? 'Never';
    } catch (e) {
      return 'Never';
    }
  }
}
