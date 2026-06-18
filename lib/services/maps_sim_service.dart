import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models/business_model.dart';

class MapsSimService {
  static const LatLng antananarivoCenter = LatLng(-18.8792, 47.5079);

  List<Marker> buildBusinessMarkers(
    List<BusinessModel> businesses, {
    void Function(BusinessModel)? onTap,
  }) {
    return businesses.map((business) {
      return Marker(
        point: LatLng(business.latitude, business.longitude),
        width: 44,
        height: 44,
        child: GestureDetector(
          onTap: () => onTap?.call(business),
          child: const Icon(
            Icons.location_on,
            color: Colors.redAccent,
            size: 44,
          ),
        ),
      );
    }).toList();
  }
}
