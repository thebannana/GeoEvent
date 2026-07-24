import '../models/admin_dashboard_stats.dart';
import 'admin_dashboard_api.dart';

class AdminDashboardRepository {
  const AdminDashboardRepository(this.api);

  final AdminDashboardApi api;

  Future<AdminUsersDashboardStats> getUsersStats() => api.getUsersStats();

  Future<AdminEventsDashboardStats> getEventsStats() => api.getEventsStats();

  Future<AdminTicketsDashboardStats> getTicketsStats() => api.getTicketsStats();

  Future<AdminDashboardStatsBundle> getDashboardStats() =>
      api.getDashboardStats();
}