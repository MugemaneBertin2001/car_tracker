import 'package:flutter/foundation.dart';
import '../models/car_model.dart';
import '../services/car_service.dart';

class CarProvider with ChangeNotifier {
  final CarService _carService = CarService();
  List<Car> _cars = [];
  String _searchQuery = '';
  String _filterStatus = 'All';
  String _errorMessage = '';
  bool _hasError = false;
  int? _selectedCarId;

  List<Car> get cars => _cars;
  String get searchQuery => _searchQuery;
  String get filterStatus => _filterStatus;
  String get errorMessage => _errorMessage;
  bool get hasError => _hasError;

  List<Car> get filteredCars {
    debugPrint('Getting filtered cars...');
    debugPrint('Total cars before filtering: ${_cars.length}');
    debugPrint('Current filter status: $_filterStatus');
    debugPrint('Current search query: "$_searchQuery"');

    // First, filter by status
    List<Car> result = _filterStatus == 'All'
        ? List.from(_cars)
        : _cars.where((car) => car.status == _filterStatus).toList();

    debugPrint('Cars after status filtering: ${result.length}');

    // Then, filter by search query
    if (_searchQuery.isNotEmpty) {
      result = result
          .where((car) =>
              car.name.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
      debugPrint('Cars after search query filtering: ${result.length}');
    }

    // Log the filtered cars
    debugPrint('=== Filtered Cars ===');
    for (int i = 0; i < result.length; i++) {
      final car = result[i];
      debugPrint(
          'Car #${i + 1}: ID=${car.id}, Name=${car.name}, Status=${car.status}, Position=(${car.latitude}, ${car.longitude})');
    }
    debugPrint('=====================');

    return result;
  }

  Future<void> fetchCars() async {
    debugPrint('CarProvider: Fetching cars...');
    try {
      _hasError = false;
      _errorMessage = '';
      notifyListeners();

      final cars = await _carService.fetchCars();

      debugPrint('CarProvider: Received ${cars.length} cars from service');

      // Check if we actually got cars with valid data
      bool hasValidCars = false;
      for (final car in cars) {
        if (car.id != -1 && car.latitude != 0.0 && car.longitude != 0.0) {
          hasValidCars = true;
          break;
        }
      }

      if (cars.isEmpty) {
        debugPrint('CarProvider: Error - No cars received');
        _hasError = true;
        _errorMessage = 'No car data available. Please try again later.';
      } else if (!hasValidCars) {
        debugPrint(
            'CarProvider: Error - No valid cars received, all have default/zero values');
        _hasError = true;
        _errorMessage = 'Invalid car data received. Please check API format.';
      } else {
        _cars = cars;
        debugPrint(
            'CarProvider: Successfully updated cars list with ${_cars.length} cars');

        // Log all cars for debugging
        debugPrint('=== All Cars ===');
        for (int i = 0; i < _cars.length; i++) {
          final car = _cars[i];
          debugPrint(
              'Car #${i + 1}: ID=${car.id}, Name=${car.name}, Status=${car.status}, Position=(${car.latitude}, ${car.longitude})');
        }
        debugPrint('===============');
      }
    } catch (e) {
      debugPrint('CarProvider: Error fetching cars: $e');
      _hasError = true;
      _errorMessage = 'Failed to load car data: $e';
    } finally {
      notifyListeners();
    }
  }

  void setSearchQuery(String query) {
    debugPrint('CarProvider: Setting search query to "$query"');
    _searchQuery = query;
    notifyListeners();
  }

  void setStatusFilter(String status) {
    debugPrint('CarProvider: Setting status filter to "$status"');
    _filterStatus = status;
    notifyListeners();
  }

  Future<String> getLastUpdatedTime() async {
    debugPrint('CarProvider: Getting last updated time');
    return await _carService.getLastUpdatedTime();
  }

  // Methods for car tracking functionality
  void setSelectedCar(int? carId) {
    debugPrint('CarProvider: Setting selected car ID to: $carId');
    _selectedCarId = carId;
    notifyListeners();
  }

  Car? getSelectedCar() {
    if (_selectedCarId == null) {
      debugPrint('CarProvider: No car selected');
      return null;
    }

    debugPrint('CarProvider: Getting selected car with ID: $_selectedCarId');
    try {
      // Find the car in the list
      final car = _cars.firstWhere((car) => car.id == _selectedCarId);
      debugPrint(
          'CarProvider: Found selected car: ${car.name} at position (${car.latitude}, ${car.longitude})');
      return car;
    } catch (e) {
      debugPrint('CarProvider: Error finding selected car: $e');
      return null;
    }
  }
}
