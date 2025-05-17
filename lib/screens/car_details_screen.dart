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
    debugPrint('========== CAR DETAILS SCREEN ==========');
    debugPrint('Initializing details screen for car: ${widget.car.id}');
    debugPrint('Car initial data:');
    debugPrint('  Name: ${widget.car.name}');
    debugPrint('  Status: ${widget.car.status}');
    debugPrint('  Speed: ${widget.car.speed} km/h');
    debugPrint('  Position: (${widget.car.latitude}, ${widget.car.longitude})');
    debugPrint('  Last Updated: ${widget.car.lastUpdated}');

    // Log potential issues with coordinates
    if (widget.car.latitude == 0.0 && widget.car.longitude == 0.0) {
      debugPrint(
          'WARNING: Car has default coordinates (0,0) - this may indicate missing or invalid location data');
    }

    _updateMarker();
  }

  @override
  void dispose() {
    debugPrint('Disposing CarDetailsScreen for car: ${widget.car.id}');
    _stopTracking();
    _mapController?.dispose();
    super.dispose();
  }

  void _updateMarker() {
    debugPrint('Updating marker for car: ${widget.car.id}');
    debugPrint(
        'Current position: (${widget.car.latitude}, ${widget.car.longitude})');

    setState(() {
      _markers = {
        Marker(
          markerId: MarkerId(widget.car.id.toString()),
          position: LatLng(widget.car.latitude, widget.car.longitude),
          infoWindow: InfoWindow(
            title: widget.car.name,
            snippet: '${widget.car.speed} km/h - ${widget.car.status}',
          ),
          icon: widget.car.status == 'Moving'
              ? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen)
              : BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      };
    });
    debugPrint('Marker updated. Marker count: ${_markers.length}');
  }

  void _startTracking() {
    debugPrint('Starting tracking for car: ${widget.car.id}');
    if (_isTracking) {
      debugPrint('Tracking already active - ignoring request');
      return;
    }

    setState(() {
      _isTracking = true;
    });

    debugPrint('Setting selected car in provider to ID: ${widget.car.id}');
    Provider.of<CarProvider>(context, listen: false)
        .setSelectedCar(widget.car.id);

    // Update the car's position on the map every second
    debugPrint('Setting up periodic tracking timer (1 second interval)');
    _trackingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      debugPrint('Tracking timer tick for car: ${widget.car.id}');
      final carProvider = Provider.of<CarProvider>(context, listen: false);
      final updatedCar = carProvider.getSelectedCar();

      if (updatedCar != null) {
        debugPrint('Retrieved updated car data:');
        debugPrint('  ID: ${updatedCar.id}');
        debugPrint('  Name: ${updatedCar.name}');
        debugPrint('  Status: ${updatedCar.status}');
        debugPrint('  Speed: ${updatedCar.speed} km/h');
        debugPrint(
            '  Position: (${updatedCar.latitude}, ${updatedCar.longitude})');

        // Check if position actually changed
        final positionChanged = updatedCar.latitude != widget.car.latitude ||
            updatedCar.longitude != widget.car.longitude;

        debugPrint('Position changed: $positionChanged');

        setState(() {
          _markers = {
            Marker(
              markerId: MarkerId(updatedCar.id.toString()),
              position: LatLng(updatedCar.latitude, updatedCar.longitude),
              infoWindow: InfoWindow(
                title: updatedCar.name,
                snippet: '${updatedCar.speed} km/h - ${updatedCar.status}',
              ),
              icon: updatedCar.status == 'Moving'
                  ? BitmapDescriptor.defaultMarkerWithHue(
                      BitmapDescriptor.hueGreen)
                  : BitmapDescriptor.defaultMarkerWithHue(
                      BitmapDescriptor.hueRed),
            ),
          };
        });

        // Move camera to follow the car
        if (_mapController != null) {
          debugPrint(
              'Animating camera to new position: (${updatedCar.latitude}, ${updatedCar.longitude})');
          _mapController!.animateCamera(
            CameraUpdate.newLatLng(
                LatLng(updatedCar.latitude, updatedCar.longitude)),
          );
        } else {
          debugPrint('Map controller is null - cannot animate camera');
        }
      } else {
        debugPrint('Warning: Updated car data is null');
      }
    });
  }

  void _stopTracking() {
    debugPrint('Stopping tracking for car: ${widget.car.id}');
    if (!_isTracking) {
      debugPrint('Tracking already inactive - ignoring request');
      return;
    }

    setState(() {
      _isTracking = false;
    });

    debugPrint('Cancelling tracking timer');
    _trackingTimer?.cancel();
    debugPrint('Clearing selected car in provider');
    Provider.of<CarProvider>(context, listen: false).setSelectedCar(null);
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('Building CarDetailsScreen for car: ${widget.car.id}');
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.car.name),
      ),
      body: Column(
        children: [
          // Car details card
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.car.name,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        widget.car.status == 'Moving'
                            ? Icons.directions_car
                            : Icons.car_rental,
                        color: widget.car.status == 'Moving'
                            ? Colors.green
                            : Colors.red,
                      ),
                      const SizedBox(width: 8),
                      Text(widget.car.status),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.speed),
                      const SizedBox(width: 8),
                      Text('${widget.car.speed} km/h'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.location_on),
                      const SizedBox(width: 8),
                      Text(
                        'Lat: ${widget.car.latitude.toStringAsFixed(5)}, '
                        'Lng: ${widget.car.longitude.toStringAsFixed(5)}',
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.update),
                      const SizedBox(width: 8),
                      Text('Last updated: ${widget.car.lastUpdated}'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Map showing the car's location
          Expanded(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(widget.car.latitude, widget.car.longitude),
                zoom: 16,
              ),
              markers: _markers,
              onMapCreated: (controller) {
                debugPrint('GoogleMap created. Setting map controller');
                _mapController = controller;
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
          debugPrint('Tracking button pressed. Current state: $_isTracking');
          _isTracking ? _stopTracking() : _startTracking();
        },
        icon: Icon(_isTracking ? Icons.stop : Icons.play_arrow),
        label: Text(_isTracking ? 'Stop Tracking' : 'Track This Car'),
      ),
    );
  }
}
