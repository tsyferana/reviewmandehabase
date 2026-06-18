import 'package:flutter/material.dart';

class CategoryModel {
  const CategoryModel({
    required this.id,
    required this.name,
    this.iconName,
  });

  final String id;
  final String name;
  final String? iconName;

  IconData get icon {
    switch (iconName) {
      case 'restaurants':
        return Icons.restaurant_rounded;
      case 'hotels':
        return Icons.hotel_rounded;
      case 'cafes':
        return Icons.local_cafe_rounded;
      case 'hair':
        return Icons.content_cut_rounded;
      case 'garages':
        return Icons.car_repair_rounded;
      case 'pharmacies':
        return Icons.local_pharmacy_rounded;
      case 'clinics':
        return Icons.local_hospital_rounded;
      case 'shops':
        return Icons.shopping_bag_rounded;
      case 'admin':
        return Icons.account_balance_rounded;
      default:
        return Icons.category_rounded;
    }
  }

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      iconName: json['icon_name']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'icon_name': iconName,
    };
  }
}
