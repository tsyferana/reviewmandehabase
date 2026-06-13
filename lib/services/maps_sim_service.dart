import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/business_model.dart';

class MapsSimService {
  static const LatLng antananarivoCenter = LatLng(-18.8792, 47.5079);

  Set<Marker> buildBusinessMarkers(List<BusinessModel> businesses) {
    return businesses.map((business) {
      return Marker(
        markerId: MarkerId(business.id),
        position: LatLng(business.latitude, business.longitude),
        infoWindow: InfoWindow(
          title: business.name,
          snippet: '${business.rating.toStringAsFixed(1)} - '
              '${business.distanceKm.toStringAsFixed(1)} km',
        ),
      );
    }).toSet();
  }
}
