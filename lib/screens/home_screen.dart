import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../providers/car_provider.dart';
import '../models/car_model.dart';
import 'car_details_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  GoogleMapController? _mapController;
  final TextEditingController _searchController = TextEditingController();
  final Set<Marker> _markers = {};
  bool _isInitializing = true;
  MarkerId? _selectedMarkerId;
  bool _showFilters = false;
  bool _showCarList = false;
  LatLngBounds? _visibleRegion;

  // Default center position
  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(-1.94975, 30.05855),
    zoom: 14,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
  }

  Future<void> _initializeData() async {
    final carProvider = Provider.of<CarProvider>(context, listen: false);
    await carProvider.fetchCars();

    if (mounted) {
      setState(() {
        _isInitializing = false;
      });
      _zoomToFitAllMarkers(carProvider.cars);
    }
  }

  void _zoomToFitAllMarkers(List<Car> cars) {
    if (cars.isEmpty || _mapController == null) return;

    final LatLngBounds bounds = _calculateBounds(cars);
    _mapController?.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 100),
    );
  }

  LatLngBounds _calculateBounds(List<Car> cars) {
    double minLat = double.infinity;
    double maxLat = -double.infinity;
    double minLng = double.infinity;
    double maxLng = -double.infinity;

    for (final car in cars) {
      minLat = car.latitude < minLat ? car.latitude : minLat;
      maxLat = car.latitude > maxLat ? car.latitude : maxLat;
      minLng = car.longitude < minLng ? car.longitude : minLng;
      maxLng = car.longitude > maxLng ? car.longitude : maxLng;
    }

    return LatLngBounds(
      northeast: LatLng(maxLat, maxLng),
      southwest: LatLng(minLat, minLng),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  Set<Marker> _buildMarkers(List<Car> cars) {
    final newMarkers = <Marker>{};

    for (final car in cars) {
      final markerId = MarkerId(car.id.toString());
      newMarkers.add(
        Marker(
          markerId: markerId,
          position: LatLng(car.latitude, car.longitude),
          infoWindow: InfoWindow(
            title: car.name,
            snippet: '${car.speed} km/h - ${car.status}',
            onTap: () {
              _navigateToCarDetails(car);
            },
          ),
          icon: car.status == 'Moving'
              ? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen)
              : car.status == 'Stopped'
                  ? BitmapDescriptor.defaultMarkerWithHue(
                      BitmapDescriptor.hueRed)
                  : BitmapDescriptor.defaultMarkerWithHue(
                      BitmapDescriptor.hueBlue),
          onTap: () {
            _selectedMarkerId = markerId;
            _showMarkerInfoWindow(markerId);
          },
        ),
      );
    }

    return newMarkers;
  }

  void _navigateToCarDetails(Car car) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CarDetailsScreen(car: car),
        fullscreenDialog: true,
      ),
    ).then((_) {
      // Refresh data when returning from details screen
      Provider.of<CarProvider>(context, listen: false).fetchCars();
    });
  }

  Future<void> _showMarkerInfoWindow(MarkerId markerId) async {
    if (_mapController != null && _markers.any((m) => m.markerId == markerId)) {
      await _mapController?.showMarkerInfoWindow(markerId);
    }
  }

  Widget _buildFilterChip(String status, CarProvider carProvider) {
    final isSelected = carProvider.filterStatus == status;
    return FilterChip(
      label: Text(status),
      selected: isSelected,
      onSelected: (bool selected) {
        carProvider.setStatusFilter(selected ? status : 'All');
        if (selected &&
            _mapController != null &&
            carProvider.filteredCars.isNotEmpty) {
          _zoomToFitAllMarkers(carProvider.filteredCars);
        }
      },
      selectedColor: Theme.of(context).primaryColor,
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black,
      ),
    );
  }

  Widget _buildCarListItem(Car car) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: ListTile(
        leading: Icon(
          Icons.directions_car,
          color: car.status == 'Moving'
              ? Colors.green
              : car.status == 'Stopped'
                  ? Colors.red
                  : Colors.blue,
        ),
        title: Text(car.name),
        subtitle: Text('${car.speed} km/h - ${car.status}'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          _navigateToCarDetails(car);
          _mapController?.animateCamera(
            CameraUpdate.newLatLng(LatLng(car.latitude, car.longitude)),
          );
        },
      ),
    );
  }

  Widget _buildCarListPanel(CarProvider carProvider) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      bottom: _showCarList ? 0 : -300,
      left: 0,
      right: 0,
      height: 300,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              height: 48,
              alignment: Alignment.center,
              child: IconButton(
                icon: Icon(
                  _showCarList
                      ? Icons.keyboard_arrow_down
                      : Icons.keyboard_arrow_up,
                ),
                onPressed: () {
                  setState(() {
                    _showCarList = !_showCarList;
                  });
                },
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: carProvider.filteredCars.isEmpty
                  ? const Center(child: Text('No vehicles found'))
                  : ListView.builder(
                      itemCount: carProvider.filteredCars.length,
                      itemBuilder: (context, index) {
                        return _buildCarListItem(
                            carProvider.filteredCars[index]);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fleet Monitoring'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              setState(() {
                _showFilters = !_showFilters;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.list),
            onPressed: () {
              setState(() {
                _showCarList = !_showCarList;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              setState(() {
                _isInitializing = true;
              });
              await Provider.of<CarProvider>(context, listen: false)
                  .fetchCars();
              if (mounted) {
                setState(() {
                  _isInitializing = false;
                });
              }
            },
          ),
        ],
      ),
      body: Consumer<CarProvider>(
        builder: (context, carProvider, child) {
          if (_isInitializing && carProvider.cars.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (carProvider.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(carProvider.errorMessage),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () async {
                      setState(() {
                        _isInitializing = true;
                      });
                      await carProvider.fetchCars();
                      if (mounted) {
                        setState(() {
                          _isInitializing = false;
                        });
                      }
                    },
                    child: const Text('Try Again'),
                  ),
                ],
              ),
            );
          }

          _markers.clear();
          _markers.addAll(_buildMarkers(carProvider.filteredCars));

          return Stack(
            children: [
              GoogleMap(
                initialCameraPosition: _initialPosition,
                markers: _markers,
                onMapCreated: (controller) {
                  _mapController = controller;
                  // Zoom to fit all markers when map is ready
                  if (carProvider.cars.isNotEmpty) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _zoomToFitAllMarkers(carProvider.cars);
                    });
                  }
                },
                myLocationEnabled: true,
                myLocationButtonEnabled: true,
                onTap: (_) {
                  if (_selectedMarkerId != null) {
                    _mapController?.hideMarkerInfoWindow(_selectedMarkerId!);
                    _selectedMarkerId = null;
                  }
                },
              ),
              // Search Bar
              Positioned(
                top: 16,
                left: 16,
                right: 16,
                child: Material(
                  elevation: 4,
                  borderRadius: BorderRadius.circular(8),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: "Search for cars...",
                      prefixIcon: const Icon(Icons.search),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 15),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    onChanged: (value) {
                      carProvider.setSearchQuery(value);
                    },
                  ),
                ),
              ),
              // Status Filter
              if (_showFilters && carProvider.cars.isNotEmpty)
                Positioned(
                  top: 80,
                  left: 16,
                  right: 16,
                  child: Material(
                    elevation: 4,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      color: Colors.white,
                      child: Wrap(
                        spacing: 8,
                        children: [
                          _buildFilterChip('All', carProvider),
                          _buildFilterChip('Moving', carProvider),
                          _buildFilterChip('Stopped', carProvider),
                          _buildFilterChip('Idle', carProvider),
                        ],
                      ),
                    ),
                  ),
                ),
              // Car List Panel
              _buildCarListPanel(carProvider),
              // Floating action button to center on user location
              Positioned(
                bottom: _showCarList ? 320 : 20,
                right: 20,
                child: FloatingActionButton(
                  heroTag: 'centerLocation',
                  mini: true,
                  onPressed: () {
                    _mapController?.animateCamera(
                      CameraUpdate.zoomTo(14),
                    );
                  },
                  child: const Icon(Icons.center_focus_strong),
                ),
              ),
              // Floating action button to fit all markers in view
              Positioned(
                bottom: _showCarList ? 380 : 80,
                right: 20,
                child: FloatingActionButton(
                  heroTag: 'fitMarkers',
                  mini: true,
                  onPressed: () {
                    if (carProvider.filteredCars.isNotEmpty) {
                      _zoomToFitAllMarkers(carProvider.filteredCars);
                    }
                  },
                  child: const Icon(Icons.zoom_out_map),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
