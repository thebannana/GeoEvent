import 'package:flutter/material.dart';

class ProfileMenuItem {
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool isDestructive;
  final VoidCallback? onTap;

  const ProfileMenuItem({
    required this.icon,
    required this.title,
    this.subtitle,
    this.isDestructive = false,
    this.onTap,
  });
}