class LocationSimService {
  Future<String> getCurrentCity() async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    return 'Antananarivo';
  }

  Future<SimulatedLocation> getCurrentLocation() async {
    await Future<void>.delayed(const Duration(milliseconds: 450));
    return const SimulatedLocation(
      city: 'Antananarivo',
      latitude: -18.8792,
      longitude: 47.5079,
    );
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
