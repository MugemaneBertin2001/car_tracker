import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import '../models/car_model.dart';

class CarService {
  final String baseUrl =
      'https://cars-pooling.onrender.com/cars';
  static const String _carBoxName = 'carsBox';
  static const String _carDataKey = 'carData';
  static const String _lastUpdatedKey = 'lastUpdated';

  Future<List<Car>> fetchCars() async {
    debugPrint('========== CAR SERVICE: FETCH CARS ==========');
    debugPrint('Attempting to fetch cars from API: $baseUrl');

    try {
      // Log HTTP request attempt
      debugPrint('Making HTTP GET request...');
      final response = await http
          .get(Uri.parse(baseUrl))
          .timeout(const Duration(seconds: 10));

      debugPrint('HTTP response status code: ${response.statusCode}');

      if (response.statusCode == 200) {
        // Log successful API response
        debugPrint('API request successful');
        debugPrint('Response body length: ${response.body.length} characters');

        // Log the raw response for debugging
        debugPrint(
            'First 500 characters of response: ${response.body.substring(0, response.body.length > 500 ? 500 : response.body.length)}...');

        try {
          // Parse the JSON
          debugPrint('Parsing JSON response...');
          List<dynamic> carsJson = json.decode(response.body);
          debugPrint(
              'Successfully parsed JSON. Number of car objects: ${carsJson.length}');

          // Save to Hive
          debugPrint('Saving data to Hive cache...');
          await _saveToHive(response.body);
          debugPrint('Data successfully saved to Hive');

          // Convert to Car objects
          List<Car> cars = [];

          for (int i = 0; i < carsJson.length; i++) {
            try {
              final car = Car.fromJson(carsJson[i]);
              cars.add(car);
              debugPrint(
                  'Car #${i + 1} successfully parsed: ID=${car.id}, Name=${car.name}, Position=(${car.latitude}, ${car.longitude})');
            } catch (e) {
              debugPrint('Error parsing car #${i + 1}: $e');
              debugPrint('Problematic JSON: ${carsJson[i]}');
            }
          }

          debugPrint('Successfully converted ${cars.length} cars from JSON');
          return cars;
        } catch (e) {
          debugPrint('JSON parsing error: $e');
          debugPrint('Falling back to Hive cache...');
          return await _fetchFromHive();
        }
      } else {
        // If server error, try Hive
        debugPrint(
            'API request failed with status code: ${response.statusCode}');
        debugPrint('Response body: ${response.body}');
        debugPrint('Falling back to Hive cache...');
        return await _fetchFromHive();
      }
    } catch (e) {
      // If network error, try Hive
      debugPrint('Network or other error: $e');
      debugPrint('Falling back to Hive cache...');
      return await _fetchFromHive();
    } finally {
      debugPrint('=======================================');
    }
  }

  Future<void> _saveToHive(String carData) async {
    debugPrint('Attempting to save data to Hive...');
    try {
      // Check if box is open
      if (!Hive.isBoxOpen(_carBoxName)) {
        debugPrint('Box $_carBoxName is not open. Opening box...');
        await Hive.openBox(_carBoxName);
      }

      final box = Hive.box(_carBoxName);
      await box.put(_carDataKey, carData);
      await box.put(_lastUpdatedKey, DateTime.now().toIso8601String());
      debugPrint('Data saved to Hive successfully');
    } catch (e) {
      debugPrint('Error saving to Hive: $e');
      // Try to initialize box if it doesn't exist
      try {
        debugPrint('Attempting to open/create Hive box...');
        await Hive.openBox(_carBoxName);
        final box = Hive.box(_carBoxName);
        await box.put(_carDataKey, carData);
        await box.put(_lastUpdatedKey, DateTime.now().toIso8601String());
        debugPrint('Successfully created and saved to new Hive box');
      } catch (e) {
        debugPrint('Fatal error with Hive storage: $e');
      }
    }
  }

  Future<List<Car>> _fetchFromHive() async {
    debugPrint('Attempting to fetch cars from Hive cache...');
    try {
      // Check if box is open
      if (!Hive.isBoxOpen(_carBoxName)) {
        debugPrint('Box $_carBoxName is not open. Opening box...');
        await Hive.openBox(_carBoxName);
      }

      final box = Hive.box(_carBoxName);
      final carData = box.get(_carDataKey);

      if (carData != null) {
        debugPrint('Found cached data in Hive');
        debugPrint('Cached data length: ${carData.length} characters');

        try {
          List<dynamic> carsJson = json.decode(carData);
          debugPrint(
              'Successfully parsed cached JSON. Car count: ${carsJson.length}');

          // Convert to Car objects
          List<Car> cars = [];

          for (int i = 0; i < carsJson.length; i++) {
            try {
              final car = Car.fromJson(carsJson[i]);
              cars.add(car);
              debugPrint(
                  'Cached car #${i + 1} successfully parsed: ID=${car.id}, Name=${car.name}');
            } catch (e) {
              debugPrint('Error parsing cached car #${i + 1}: $e');
            }
          }

          debugPrint('Successfully loaded ${cars.length} cars from cache');
          return cars;
        } catch (e) {
          debugPrint('Error parsing cached JSON: $e');
          return [];
        }
      } else {
        debugPrint('No cached data found in Hive');
        return [];
      }
    } catch (e) {
      debugPrint('Error fetching from Hive: $e');
      return [];
    }
  }

  Future<String> getLastUpdatedTime() async {
    debugPrint('Fetching last updated time from Hive...');
    try {
      // Check if box is open
      if (!Hive.isBoxOpen(_carBoxName)) {
        debugPrint('Box $_carBoxName is not open. Opening box...');
        await Hive.openBox(_carBoxName);
      }

      final box = Hive.box(_carBoxName);
      final lastUpdated = box.get(_lastUpdatedKey);

      if (lastUpdated != null) {
        debugPrint('Last updated time: $lastUpdated');
        return lastUpdated;
      } else {
        debugPrint('Last updated time not found in Hive');
        return 'Never';
      }
    } catch (e) {
      debugPrint('Error getting last updated time: $e');
      return 'Never';
    }
  }
}
