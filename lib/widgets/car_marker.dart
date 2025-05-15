import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/car_model.dart';

class CarMarkerHelper {
  static Future<BitmapDescriptor> getCarMarkerIcon(Car car, BuildContext context) async {

    
    final IconData iconData = car.status == 'Moving' 
        ? Icons.directions_car 
        : Icons.car_rental;

    final pictureRecorder = PictureRecorder();
    final canvas = Canvas(pictureRecorder);
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    final iconStr = String.fromCharCode(iconData.codePoint);

    textPainter.text = TextSpan(
      text: iconStr,
      style: TextStyle(
        letterSpacing: 0.0,
        fontSize: 48.0,
        fontFamily: iconData.fontFamily,
        color: car.status == 'Moving' ? Colors.green : Colors.red,
      ),
    );
    
    textPainter.layout();
    textPainter.paint(canvas, Offset(0.0, 0.0));

    final picture = pictureRecorder.endRecording();
    final image = await picture.toImage(48, 48);
    final bytes = await image.toByteData(format: ImageByteFormat.png);

    return BitmapDescriptor.fromBytes(bytes!.buffer.asUint8List());
    
  }
}