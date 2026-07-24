import 'package:dio/dio.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/auth_interceptor.dart';
import '../models/admin_dashboard_stats.dart';

class AdminDashboardApi {
  const AdminDashboardApi(this.dio);

  final Dio dio;

  Future<AdminUsersDashboardStats> getUsersStats() async {
    final response = await dio.get(
      ApiEndpoints.adminDashboardUsers,
      options: Options(
        extra: const {
          AuthInterceptor.allowRefreshKey: true,
        },
      ),
    );

    final raw = response.data;
    if (raw is! Map) {
      throw const FormatException('Invalid admin users dashboard response.');
    }

    return AdminUsersDashboardStats.fromJson(
      Map<String, dynamic>.from(raw),
    );
  }

  Future<AdminEventsDashboardStats> getEventsStats() async {
    final response = await dio.get(
      ApiEndpoints.adminDashboardEvents,
      options: Options(
        extra: const {
          AuthInterceptor.allowRefreshKey: true,
        },
      ),
    );

    final raw = response.data;
    if (raw is! Map) {
      throw const FormatException('Invalid admin events dashboard response.');
    }

    return AdminEventsDashboardStats.fromJson(
      Map<String, dynamic>.from(raw),
    );
  }

  Future<AdminTicketsDashboardStats> getTicketsStats() async {
    final response = await dio.get(
      ApiEndpoints.adminDashboardTickets,
      options: Options(
        extra: const {
          AuthInterceptor.allowRefreshKey: true,
        },
      ),
    );

    final raw = response.data;
    if (raw is! Map) {
      throw const FormatException('Invalid admin tickets dashboard response.');
    }

    return AdminTicketsDashboardStats.fromJson(
      Map<String, dynamic>.from(raw),
    );
  }

  Future<AdminDashboardStatsBundle> getDashboardStats() async {
    final responses = await Future.wait([
      dio.get(
        ApiEndpoints.adminDashboardUsers,
        options: Options(
          extra: const {
            AuthInterceptor.allowRefreshKey: true,
          },
        ),
      ),
      dio.get(
        ApiEndpoints.adminDashboardEvents,
        options: Options(
          extra: const {
            AuthInterceptor.allowRefreshKey: true,
          },
        ),
      ),
      dio.get(
        ApiEndpoints.adminDashboardTickets,
        options: Options(
          extra: const {
            AuthInterceptor.allowRefreshKey: true,
          },
        ),
      ),
    ]);

    final usersRaw = responses[0].data;
    final eventsRaw = responses[1].data;
    final ticketsRaw = responses[2].data;

    if (usersRaw is! Map) {
      throw const FormatException('Invalid admin users dashboard response.');
    }
    if (eventsRaw is! Map) {
      throw const FormatException('Invalid admin events dashboard response.');
    }
    if (ticketsRaw is! Map) {
      throw const FormatException('Invalid admin tickets dashboard response.');
    }

    return AdminDashboardStatsBundle(
      users: AdminUsersDashboardStats.fromJson(
        Map<String, dynamic>.from(usersRaw),
      ),
      events: AdminEventsDashboardStats.fromJson(
        Map<String, dynamic>.from(eventsRaw),
      ),
      tickets: AdminTicketsDashboardStats.fromJson(
        Map<String, dynamic>.from(ticketsRaw),
      ),
    );
  }
}