import 'package:flutter/material.dart';

class DrawerSectionData {
  final String title;
  final List<DrawerItemData> items;
  const DrawerSectionData({required this.title, required this.items});
}

class DrawerItemData {
  final IconData icon;
  final String label;
  final String route;
  final LinearGradient gradient;
  final bool isActive;
  final String? badge;

  const DrawerItemData({
    required this.icon,
    required this.label,
    required this.route,
    required this.gradient,
    this.isActive = false,
    this.badge,
  });
}
