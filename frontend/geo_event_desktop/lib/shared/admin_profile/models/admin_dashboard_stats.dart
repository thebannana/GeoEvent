class AdminUsersDashboardStats {
  const AdminUsersDashboardStats({
    required this.activeUsersCount,
    required this.totalReportsCount,
    required this.bookmarksCount,
    required this.commentsCount,
    required this.likedEventsCount,
    required this.topSegments,
    required this.topGenres,
    required this.topSubGenres,
  });

  final int activeUsersCount;
  final int totalReportsCount;
  final int bookmarksCount;
  final int commentsCount;
  final int likedEventsCount;
  final List<CategoryUsageStat> topSegments;
  final List<CategoryUsageStat> topGenres;
  final List<CategoryUsageStat> topSubGenres;

  factory AdminUsersDashboardStats.fromJson(Map<String, dynamic> json) {
    return AdminUsersDashboardStats(
      activeUsersCount: (json['activeUsersCount'] as num?)?.toInt() ?? 0,
      totalReportsCount: (json['totalReportsCount'] as num?)?.toInt() ?? 0,
      bookmarksCount: (json['bookmarksCount'] as num?)?.toInt() ?? 0,
      commentsCount: (json['commentsCount'] as num?)?.toInt() ?? 0,
      likedEventsCount: (json['likedEventsCount'] as num?)?.toInt() ?? 0,
      topSegments: ((json['topSegments'] as List?) ?? const [])
          .map(
            (e) => CategoryUsageStat.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList(),
      topGenres: ((json['topGenres'] as List?) ?? const [])
          .map(
            (e) => CategoryUsageStat.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList(),
      topSubGenres: ((json['topSubGenres'] as List?) ?? const [])
          .map(
            (e) => CategoryUsageStat.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList(),
    );
  }
}

class CategoryUsageStat {
  const CategoryUsageStat({
    required this.id,
    required this.name,
    required this.count,
  });

  final int id;
  final String name;
  final int count;

  factory CategoryUsageStat.fromJson(Map<String, dynamic> json) {
    return CategoryUsageStat(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: (json['name'] ?? '').toString(),
      count: (json['count'] as num?)?.toInt() ?? 0,
    );
  }
}

class AdminEventsDashboardStats {
  const AdminEventsDashboardStats({
    required this.totalEventsCount,
    required this.confirmedEventsCount,
    required this.pendingEventsCount,
    required this.completedEventsCount,
    required this.cancelledEventsCount,
    required this.totalLikesCount,
    required this.totalBookmarksCount,
    required this.totalCommentsCount,
    required this.totalViewsCount,
    required this.mostLikedEvents,
    required this.mostViewedEvents,
    required this.mostCommentedEvents,
    required this.mostBookmarkedEvents,
  });

  final int totalEventsCount;
  final int confirmedEventsCount;
  final int pendingEventsCount;
  final int completedEventsCount;
  final int cancelledEventsCount;
  final int totalLikesCount;
  final int totalBookmarksCount;
  final int totalCommentsCount;
  final int totalViewsCount;
  final List<TopEventStat> mostLikedEvents;
  final List<TopEventStat> mostViewedEvents;
  final List<TopEventStat> mostCommentedEvents;
  final List<TopEventStat> mostBookmarkedEvents;

  factory AdminEventsDashboardStats.fromJson(Map<String, dynamic> json) {
    return AdminEventsDashboardStats(
      totalEventsCount: (json['totalEventsCount'] as num?)?.toInt() ?? 0,
      confirmedEventsCount: (json['confirmedEventsCount'] as num?)?.toInt() ?? 0,
      pendingEventsCount: (json['pendingEventsCount'] as num?)?.toInt() ?? 0,
      completedEventsCount: (json['completedEventsCount'] as num?)?.toInt() ?? 0,
      cancelledEventsCount: (json['cancelledEventsCount'] as num?)?.toInt() ?? 0,
      totalLikesCount: (json['totalLikesCount'] as num?)?.toInt() ?? 0,
      totalBookmarksCount: (json['totalBookmarksCount'] as num?)?.toInt() ?? 0,
      totalCommentsCount: (json['totalCommentsCount'] as num?)?.toInt() ?? 0,
      totalViewsCount: (json['totalViewsCount'] as num?)?.toInt() ?? 0,
      mostLikedEvents: ((json['mostLikedEvents'] as List?) ?? const [])
          .map(
            (e) => TopEventStat.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList(),
      mostViewedEvents: ((json['mostViewedEvents'] as List?) ?? const [])
          .map(
            (e) => TopEventStat.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList(),
      mostCommentedEvents: ((json['mostCommentedEvents'] as List?) ?? const [])
          .map(
            (e) => TopEventStat.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList(),
      mostBookmarkedEvents: ((json['mostBookmarkedEvents'] as List?) ?? const [])
          .map(
            (e) => TopEventStat.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList(),
    );
  }
}

class TopEventStat {
  const TopEventStat({
    required this.eventId,
    required this.title,
    required this.imageUrl,
    required this.status,
    required this.startDateTime,
    required this.count,
  });

  final int eventId;
  final String title;
  final String? imageUrl;
  final String status;
  final DateTime? startDateTime;
  final int count;

  factory TopEventStat.fromJson(Map<String, dynamic> json) {
    return TopEventStat(
      eventId: (json['eventId'] as num?)?.toInt() ?? 0,
      title: (json['title'] ?? '').toString(),
      imageUrl: json['imageUrl']?.toString(),
      status: (json['status'] ?? '').toString(),
      startDateTime: json['startDateTime'] != null
          ? DateTime.tryParse(json['startDateTime'].toString())
          : null,
      count: (json['count'] as num?)?.toInt() ?? 0,
    );
  }
}

class AdminTicketsDashboardStats {
  const AdminTicketsDashboardStats({
    required this.totalReservations,
    required this.pendingReservations,
    required this.confirmedReservations,
    required this.cancelledReservations,
    required this.expiredReservations,
    required this.totalTickets,
    required this.activeTickets,
    required this.usedTickets,
    required this.cancelledTickets,
    required this.grossRevenue,
    required this.netRevenue,
    required this.refundedAmount,
    required this.payPalRevenue,
    required this.cashRevenue,
    required this.pendingCashRevenue,
    required this.totalPayments,
    required this.completedPayments,
    required this.pendingPayments,
    required this.refundedPayments,
    required this.currency,
  });

  final int totalReservations;
  final int pendingReservations;
  final int confirmedReservations;
  final int cancelledReservations;
  final int expiredReservations;

  final int totalTickets;
  final int activeTickets;
  final int usedTickets;
  final int cancelledTickets;

  final double grossRevenue;
  final double netRevenue;
  final double refundedAmount;

  final double payPalRevenue;
  final double cashRevenue;
  final double pendingCashRevenue;

  final int totalPayments;
  final int completedPayments;
  final int pendingPayments;
  final int refundedPayments;

  final String currency;

  factory AdminTicketsDashboardStats.fromJson(Map<String, dynamic> json) {
    return AdminTicketsDashboardStats(
      totalReservations: (json['totalReservations'] as num?)?.toInt() ?? 0,
      pendingReservations: (json['pendingReservations'] as num?)?.toInt() ?? 0,
      confirmedReservations: (json['confirmedReservations'] as num?)?.toInt() ?? 0,
      cancelledReservations: (json['cancelledReservations'] as num?)?.toInt() ?? 0,
      expiredReservations: (json['expiredReservations'] as num?)?.toInt() ?? 0,
      totalTickets: (json['totalTickets'] as num?)?.toInt() ?? 0,
      activeTickets: (json['activeTickets'] as num?)?.toInt() ?? 0,
      usedTickets: (json['usedTickets'] as num?)?.toInt() ?? 0,
      cancelledTickets: (json['cancelledTickets'] as num?)?.toInt() ?? 0,
      grossRevenue: (json['grossRevenue'] as num?)?.toDouble() ?? 0,
      netRevenue: (json['netRevenue'] as num?)?.toDouble() ?? 0,
      refundedAmount: (json['refundedAmount'] as num?)?.toDouble() ?? 0,
      payPalRevenue: (json['payPalRevenue'] as num?)?.toDouble() ?? 0,
      cashRevenue: (json['cashRevenue'] as num?)?.toDouble() ?? 0,
      pendingCashRevenue: (json['pendingCashRevenue'] as num?)?.toDouble() ?? 0,
      totalPayments: (json['totalPayments'] as num?)?.toInt() ?? 0,
      completedPayments: (json['completedPayments'] as num?)?.toInt() ?? 0,
      pendingPayments: (json['pendingPayments'] as num?)?.toInt() ?? 0,
      refundedPayments: (json['refundedPayments'] as num?)?.toInt() ?? 0,
      currency: (json['currency'] as String?)?.trim().isNotEmpty == true
          ? (json['currency'] as String).trim()
          : 'BAM',
    );
  }
}

class AdminDashboardStatsBundle {
  const AdminDashboardStatsBundle({
    required this.users,
    required this.events,
    required this.tickets,
  });

  final AdminUsersDashboardStats users;
  final AdminEventsDashboardStats events;
  final AdminTicketsDashboardStats tickets;
}