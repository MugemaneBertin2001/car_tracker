import 'dart:async';
import 'package:flutter/material.dart';
import '../models/car_model.dart';
import '../services/car_service.dart';

class CarProvider extends ChangeNotifier {
  final CarService _carService = CarService();
  List<Car> _cars = [];
  List<Car> _filteredCars = [];
  String _searchQuery = '';
  String _statusFilter = 'All';
  bool _isLoading = false;
  bool _hasError = false;
  String _errorMessage = '';
  Timer? _timer;
  int? _selectedCarId;

  CarProvider() {
    _initFetchCars();
  }

  List<Car> get cars => _cars;
  List<Car> get filteredCars => _filteredCars;
  bool get isLoading => _isLoading;
  bool get hasError => _hasError;
  String get errorMessage => _errorMessage;
  int? get selectedCarId => _selectedCarId;
  String get filterStatus => _statusFilter; // Added missing getter

  void _initFetchCars() {
    fetchCars();
    // Schedule real-time updates every 5 seconds
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!_isLoading) {
        // Only fetch if not already loading
        fetchCars();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> fetchCars() async {
    try {
      _isLoading = true;
      notifyListeners();

      _cars = await _carService.fetchCars();
      _applyFilters();

      _hasError = false;
      _errorMessage = '';
    } catch (e) {
      _hasError = true;
      _errorMessage = 'Failed to fetch cars: ${e.toString()}';
      // Keep showing the last successfully fetched data if available
      if (_cars.isEmpty) {
        _filteredCars = [];
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setSelectedCar(int? carId) {
    _selectedCarId = carId;
    notifyListeners();
  }

  Car? getSelectedCar() {
    if (_selectedCarId == null) return null;
    return _cars.firstWhere(
      (car) => car.id == _selectedCarId,
      orElse: () => Car(
        id: -1,
        name: 'Unknown',
        latitude: 0,
        longitude: 0,
        speed: 0,
        status: 'Unknown',
      ),
    );
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    _applyFilters();
    notifyListeners();
  }

  void setStatusFilter(String status) {
    _statusFilter = status;
    _applyFilters();
    notifyListeners();
  }

  void _applyFilters() {
    _filteredCars = _cars.where((car) {
      // Apply search filter
      final matchesSearch =
          car.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              car.id.toString().contains(_searchQuery);

      // Apply status filter
      final matchesStatus =
          _statusFilter == 'All' || car.status == _statusFilter;

      return matchesSearch && matchesStatus;
    }).toList();
  }
}
