import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/network.dart';
import '../data/admin_dashboard_api.dart';
import '../data/admin_dashboard_repository.dart';
import '../models/admin_dashboard_stats.dart';

final adminDashboardApiProvider = Provider<AdminDashboardApi>((ref) {
  final dio = ref.read(authenticatedDioProvider);
  return AdminDashboardApi(dio);
});

final adminDashboardRepositoryProvider =
    Provider<AdminDashboardRepository>((ref) {
  final api = ref.read(adminDashboardApiProvider);
  return AdminDashboardRepository(api);
});

final adminUsersDashboardStatsProvider =
    FutureProvider<AdminUsersDashboardStats>((ref) {
  final repository = ref.read(adminDashboardRepositoryProvider);
  return repository.getUsersStats();
});

final adminEventsDashboardStatsProvider =
    FutureProvider<AdminEventsDashboardStats>((ref) {
  final repository = ref.read(adminDashboardRepositoryProvider);
  return repository.getEventsStats();
});

final adminTicketsDashboardStatsProvider =
    FutureProvider<AdminTicketsDashboardStats>((ref) {
  final repository = ref.read(adminDashboardRepositoryProvider);
  return repository.getTicketsStats();
});

final adminDashboardStatsProvider =
    FutureProvider<AdminDashboardStatsBundle>((ref) {
  final repository = ref.read(adminDashboardRepositoryProvider);
  return repository.getDashboardStats();
});