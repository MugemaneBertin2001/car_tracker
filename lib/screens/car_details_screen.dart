import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../models/car_model.dart';
import '../providers/car_provider.dart';

class CarDetailsScreen extends StatefulWidget {
  final Car car;

  const CarDetailsScreen({
    Key? key,
    required this.car,
  }) : super(key: key);

  @override
  State<CarDetailsScreen> createState() => _CarDetailsScreenState();
}

class _CarDetailsScreenState extends State<CarDetailsScreen> {
  GoogleMapController? _mapController;
  bool _isTracking = false;
  Timer? _trackingTimer;
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _updateMarker(widget.car);
    // Start tracking automatically when screen loads
    if (!_isTracking) {
      _startTracking();
    }
  }

  @override
  void dispose() {
    _stopTracking();
    _mapController?.dispose();
    super.dispose();
  }

  void _updateMarker(Car car) {
    setState(() {
      // Create a single marker with the car's ID
      _markers = {
        Marker(
          markerId: MarkerId(car.id),
          position: LatLng(car.latitude, car.longitude),
          infoWindow: InfoWindow(
            title: car.name,
            snippet: '${car.speed} km/h - ${car.status}',
          ),
          icon: car.status == 'Moving'
              ? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen)
              : car.status == 'Stopped'
                  ? BitmapDescriptor.defaultMarkerWithHue(
                      BitmapDescriptor.hueRed)
                  : BitmapDescriptor.defaultMarkerWithHue(
                      BitmapDescriptor.hueBlue),
        ),
      };
    });
  }

  void _startTracking() {
    if (_isTracking) {
      return;
    }

    setState(() {
      _isTracking = true;
    });

    Provider.of<CarProvider>(context, listen: false)
        .setSelectedCar(widget.car.id);

    _trackingTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      final carProvider = Provider.of<CarProvider>(context, listen: false);
      final updatedCar = carProvider.getSelectedCar();

      if (updatedCar != null) {
        // Update marker with new position
        _updateMarker(updatedCar);

        // Only animate camera if map controller is initialized
        if (_mapController != null) {
          _mapController!.animateCamera(
            CameraUpdate.newLatLng(
                LatLng(updatedCar.latitude, updatedCar.longitude)),
          );
        }
      } else {
        _stopTracking();
      }
    });
  }

  void _stopTracking() {
    if (!_isTracking) {
      return;
    }

    setState(() {
      _isTracking = false;
    });

    _trackingTimer?.cancel();
    _trackingTimer = null;
    Provider.of<CarProvider>(context, listen: false).setSelectedCar(null);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CarProvider>(
      builder: (context, carProvider, child) {
        final currentCar = carProvider.cars.firstWhere(
          (car) => car.id == widget.car.id,
          orElse: () {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.of(context).pop();
            });
            return Car(
                id: widget.car.id,
                name: 'Error',
                latitude: 0.0,
                longitude: 0.0,
                speed: 0.0,
                status: 'Error',
                timestamp: '');
          },
        );

        if (currentCar.name == 'Error') {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(currentCar.name),
          ),
          body: Column(
            children: [
              Card(
                margin: const EdgeInsets.all(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentCar.name,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            currentCar.status == 'Moving'
                                ? Icons.directions_car
                                : Icons.car_rental,
                            color: currentCar.status == 'Moving'
                                ? Colors.green
                                : currentCar.status == 'Stopped'
                                    ? Colors.red
                                    : Colors.blue,
                          ),
                          const SizedBox(width: 8),
                          Text(currentCar.status),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.speed),
                          const SizedBox(width: 8),
                          Text('${currentCar.speed} km/h'),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.location_on),
                          const SizedBox(width: 8),
                          Text(
                            'Lat: ${currentCar.latitude.toStringAsFixed(5)}, '
                            'Lng: ${currentCar.longitude.toStringAsFixed(5)}',
                          ),
                        ],
                      ),
                      if (currentCar.timestamp.isNotEmpty)
                        const SizedBox(height: 8),
                      if (currentCar.timestamp.isNotEmpty)
                        Row(
                          children: [
                            const Icon(Icons.update),
                            const SizedBox(width: 8),
                            Text('Last updated: ${currentCar.timestamp}'),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: LatLng(currentCar.latitude, currentCar.longitude),
                    zoom: 16,
                  ),
                  markers: _markers,
                  onMapCreated: (controller) {
                    _mapController = controller;
                    if (currentCar.latitude != 0.0 ||
                        currentCar.longitude != 0.0) {
                      _mapController!.animateCamera(
                        CameraUpdate.newLatLng(
                            LatLng(currentCar.latitude, currentCar.longitude)),
                      );
                    }
                  },
                  mapType: MapType.normal,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                  zoomControlsEnabled: true,
                  zoomGesturesEnabled: true,
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () {
              _isTracking ? _stopTracking() : _startTracking();
            },
            icon: Icon(_isTracking ? Icons.stop : Icons.play_arrow),
            label: Text(_isTracking ? 'Stop Tracking' : 'Track This Car'),
          ),
        );
      },
    );
  }
}
