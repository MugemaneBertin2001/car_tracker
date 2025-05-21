import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import '../models/car_model.dart';

class CarService {
  final String baseUrl = 'https://cars-pooling.onrender.com/cars';
  static const String _carBoxName = 'carsBox';
  static const String _carDataKey = 'carData';
  static const String _lastUpdatedKey = 'lastUpdated';

  Future<List<Car>> fetchCars() async {
    try {
      final response = await http
          .get(Uri.parse(baseUrl))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        await _saveToHive(response.body);
        List<dynamic> carsJson = json.decode(response.body);
        List<Car> cars = [];
        for (final jsonItem in carsJson) {
          try {
            final car = Car.fromJson(jsonItem);
            cars.add(car);
          } catch (e) {
            debugPrint('Error parsing car JSON: $e');
          }
        }
        return cars;
      } else {
        return await _fetchFromHive();
      }
    } catch (e) {
      return await _fetchFromHive();
    }
  }

  Future<void> _saveToHive(String carData) async {
    try {
      if (!Hive.isBoxOpen(_carBoxName)) {
        await Hive.openBox(_carBoxName);
      }
      final box = Hive.box(_carBoxName);
      await box.put(_carDataKey, carData);
      await box.put(_lastUpdatedKey, DateTime.now().toIso8601String());
    } catch (e) {
      debugPrint('Error saving to Hive: $e');
    }
  }

  Future<List<Car>> _fetchFromHive() async {
    try {
      if (!Hive.isBoxOpen(_carBoxName)) {
        await Hive.openBox(_carBoxName);
      }
      final box = Hive.box(_carBoxName);
      final carData = box.get(_carDataKey);

      if (carData != null) {
        try {
          List<dynamic> carsJson = json.decode(carData);
          List<Car> cars = [];
          for (final jsonItem in carsJson) {
            try {
              final car = Car.fromJson(jsonItem);
              cars.add(car);
            } catch (e) {
              debugPrint('Error parsing cached car JSON: $e');
            }
          }
          return cars;
        } catch (e) {
          debugPrint('Error parsing cached JSON: $e');
          return [];
        }
      } else {
        return [];
      }
    } catch (e) {
      debugPrint('Error fetching from Hive: $e');
      return [];
    }
  }

  Future<String> getLastUpdatedTime() async {
    try {
      if (!Hive.isBoxOpen(_carBoxName)) {
        await Hive.openBox(_carBoxName);
      }
      final box = Hive.box(_carBoxName);
      final lastUpdated = box.get(_lastUpdatedKey);
      return lastUpdated ?? 'Never';
    } catch (e) {
      debugPrint('Error getting last updated time: $e');
      return 'Never';
    }
  }
}
