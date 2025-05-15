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
    }
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
          ),
          icon: car.status == 'Moving'
              ? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen)
              : BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          onTap: () {
            _selectedMarkerId = markerId;
            _showMarkerInfoWindow(markerId);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CarDetailsScreen(car: car),
              ),
            );
          },
        ),
      );
    }
    return newMarkers;
  }

  Future<void> _showMarkerInfoWindow(MarkerId markerId) async {
    try {
      if (_markers.any((m) => m.markerId == markerId)) {
        await _mapController?.showMarkerInfoWindow(markerId);
      }
    } catch (e) {
      debugPrint('Error showing info window: $e');
    }
  }

  Widget _buildFilterChip(String status, CarProvider carProvider) {
    final isSelected = carProvider.filterStatus == status;
    return FilterChip(
      label: Text(status),
      selected: isSelected,
      onSelected: (bool selected) {
        carProvider.setStatusFilter(selected ? status : 'All');
      },
      selectedColor: Theme.of(context).primaryColor,
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black,
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
              if (carProvider.cars.isNotEmpty)
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: Material(
                    elevation: 4,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildFilterChip('All', carProvider),
                            const SizedBox(width: 8),
                            _buildFilterChip('Moving', carProvider),
                            const SizedBox(width: 8),
                            _buildFilterChip('Parked', carProvider),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
