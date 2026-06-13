import 'package:flutter/material.dart';

class CategoryModel {
  const CategoryModel({
    required this.id,
    required this.name,
    required this.iconCodePoint,
  });

  final String id;
  final String name;
  final int iconCodePoint;

  IconData get icon => IconData(
        // ignore: non_const_argument_for_const_parameter
        iconCodePoint,
        fontFamily: 'MaterialIcons',
      );

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] as String,
      name: json['name'] as String,
      iconCodePoint: json['iconCodePoint'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'iconCodePoint': iconCodePoint,
    };
  }
}
