import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationSimService {
  static const double defaultLatitude = -18.8792;
  static const double defaultLongitude = 47.5079;
  static const String defaultCity = 'Antananarivo';

  Future<Position?> _determineRealPosition() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return null;
      }

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 5),
      );
    } catch (_) {
      return null;
    }
  }

  Future<String> getCurrentCity() async {
    try {
      final position = await _determineRealPosition();
      if (position == null) return defaultCity;

      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isNotEmpty) {
        final city = placemarks.first.locality ?? placemarks.first.subAdministrativeArea;
        if (city != null && city.isNotEmpty) {
          return city;
        }
      }
      return defaultCity;
    } catch (_) {
      return defaultCity;
    }
  }

  Future<SimulatedLocation> getCurrentLocation() async {
    try {
      final position = await _determineRealPosition();
      if (position == null) {
        return const SimulatedLocation(
          city: defaultCity,
          latitude: defaultLatitude,
          longitude: defaultLongitude,
        );
      }

      String city = defaultCity;
      try {
        final placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (placemarks.isNotEmpty) {
          final loc = placemarks.first.locality ?? placemarks.first.subAdministrativeArea;
          if (loc != null && loc.isNotEmpty) {
            city = loc;
          }
        }
      } catch (_) {}

      return SimulatedLocation(
        city: city,
        latitude: position.latitude,
        longitude: position.longitude,
      );
    } catch (_) {
      return const SimulatedLocation(
        city: defaultCity,
        latitude: defaultLatitude,
        longitude: defaultLongitude,
      );
    }
  }
}

class SimulatedLocation {
  const SimulatedLocation({
    required this.city,
    required this.latitude,
    required this.longitude,
  });

  final String city;
  final double latitude;
  final double longitude;
}
