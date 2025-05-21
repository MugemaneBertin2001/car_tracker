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
  String? _selectedCarId;
  bool _isInitialLoadComplete = false;

  List<Car> get cars => _cars;
  String get searchQuery => _searchQuery;
  String get filterStatus => _filterStatus;
  String get errorMessage => _errorMessage;
  bool get hasError => _hasError;
  bool get isInitialLoadComplete => _isInitialLoadComplete;

  List<Car> get filteredCars {
    List<Car> result = _filterStatus == 'All'
        ? List.from(_cars)
        : _cars.where((car) => car.status == _filterStatus).toList();

    if (_searchQuery.isNotEmpty) {
      result = result
          .where((car) =>
              car.name.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }
    return result;
  }

  Future<void> fetchCars() async {
    try {
      final cars = await _carService.fetchCars();
      bool hasValidData = cars.isNotEmpty &&
          cars.any((car) =>
              car.id.isNotEmpty &&
              (car.latitude != 0.0 || car.longitude != 0.0));

      if (hasValidData) {
        _cars = cars;
        _hasError = false;
        _errorMessage = '';
      } else {
        _hasError = true;
        if (cars.isEmpty) {
          _errorMessage = 'No car data available from the server.';
        } else {
          _errorMessage = 'Received invalid car data format from the server.';
        }
      }
    } catch (e) {
      _hasError = true;
      if (e.toString().contains('Failed host lookup') ||
          e.toString().contains('Network is unreachable')) {
        _errorMessage = 'Network error. Could not connect to the server.';
      } else if (e.toString().contains('Timeout')) {
        _errorMessage = 'Request timed out. Please try again.';
      } else {
        _errorMessage = 'Failed to load car data: ${e.toString()}';
      }
    } finally {
      _isInitialLoadComplete = true;
      notifyListeners();
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setStatusFilter(String status) {
    _filterStatus = status;
    notifyListeners();
  }

  Future<String> getLastUpdatedTime() async {
    return await _carService.getLastUpdatedTime();
  }

  void setSelectedCar(String? carId) {
    _selectedCarId = carId;
    notifyListeners();
  }

  Car? getSelectedCar() {
    if (_selectedCarId == null) {
      return null;
    }
    try {
      final car = _cars.firstWhere((car) => car.id == _selectedCarId,
          orElse: () => throw Exception('Car not found'));
      return car;
    } catch (e) {
      _selectedCarId = null;
      return null;
    }
  }
}
