import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class AppGeolocation {
  Position? position;
  Future<Position?> getCurrentLocation() async {
    try {
      position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      return position!;
    } catch (e) {
      debugPrint('Error: $e');
      return null;
    }
  }
}
