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
    _updateMarker();
  }

  @override
  void dispose() {
    _stopTracking();
    _mapController?.dispose();
    super.dispose();
  }

  void _updateMarker() {
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
  }

  void _startTracking() {
    if (_isTracking) return;

    setState(() {
      _isTracking = true;
    });

    Provider.of<CarProvider>(context, listen: false)
        .setSelectedCar(widget.car.id);

    // Update the car's position on the map every second
    _trackingTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      final carProvider = Provider.of<CarProvider>(context, listen: false);
      final updatedCar = carProvider.getSelectedCar();

      if (updatedCar != null) {
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
        _mapController?.animateCamera(
          CameraUpdate.newLatLng(
              LatLng(updatedCar.latitude, updatedCar.longitude)),
        );
      }
    });
  }

  void _stopTracking() {
    if (!_isTracking) return;

    setState(() {
      _isTracking = false;
    });

    _trackingTimer?.cancel();
    Provider.of<CarProvider>(context, listen: false).setSelectedCar(null);
  }

  @override
  Widget build(BuildContext context) {
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
                      Icon(Icons.speed),
                      const SizedBox(width: 8),
                      Text('${widget.car.speed} km/h'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.location_on),
                      const SizedBox(width: 8),
                      Text(
                        'Lat: ${widget.car.latitude.toStringAsFixed(5)}, '
                        'Lng: ${widget.car.longitude.toStringAsFixed(5)}',
                      ),
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
                _mapController = controller;
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isTracking ? _stopTracking : _startTracking,
        icon: Icon(_isTracking ? Icons.stop : Icons.play_arrow),
        label: Text(_isTracking ? 'Stop Tracking' : 'Track This Car'),
      ),
    );
  }
}
