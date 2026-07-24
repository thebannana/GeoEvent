import 'package:flutter/material.dart';

enum AdminShellPage {
  dashboard,
  users,
  events,
  categories,
  contentModeration,
  settings,
}

class AdminNavItem {
  const AdminNavItem({
    required this.page,
    required this.label,
    required this.icon,
    required this.section,
  });

  final AdminShellPage page;
  final String label;
  final IconData icon;
  final String section;
}

class AdminShellItems {
  static const menu = <AdminNavItem>[
    AdminNavItem(
      page: AdminShellPage.dashboard,
      label: 'Dashboard',
      icon: Icons.dashboard_outlined,
      section: 'Menu',
    ),
    AdminNavItem(
      page: AdminShellPage.users,
      label: 'Users',
      icon: Icons.group_outlined,
      section: 'Menu',
    ),
    AdminNavItem(
      page: AdminShellPage.events,
      label: 'Events',
      icon: Icons.calendar_month_outlined,
      section: 'Menu',
    ),
    AdminNavItem(
      page: AdminShellPage.categories,
      label: 'Categories',
      icon: Icons.task_alt_outlined,
      section: 'Menu',
    ),
    AdminNavItem(
      page: AdminShellPage.contentModeration,
      label: 'Content Moderation',
      icon: Icons.warning_amber_rounded,
      section: 'Menu',
    ),
  ];

  static const general = <AdminNavItem>[
    AdminNavItem(
      page: AdminShellPage.settings,
      label: 'Settings',
      icon: Icons.settings_outlined,
      section: 'General',
    ),
  ];
}