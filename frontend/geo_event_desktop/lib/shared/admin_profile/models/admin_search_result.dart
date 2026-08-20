import 'package:flutter/material.dart';

import '../../shell/models/admin_shell_models.dart';

class AdminSearchResult {
  const AdminSearchResult({
    required this.page,
    required this.title,
    required this.description,
    required this.icon,
    required this.keywords,
  });

  final AdminShellPage page;
  final String title;
  final String description;
  final IconData icon;
  final List<String> keywords;
}