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
        width: 140,
        height: 80,
        alignment: Alignment.topCenter,
        child: GestureDetector(
          onTap: () => onTap?.call(business),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      business.name,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      business.categoryName,
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.black54,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.location_on,
                color: Colors.redAccent,
                size: 32,
              ),
            ],
          ),
        ),
      );
    }).toList();
  }
}
