class EventTicketItem {
  final int ticketId;
  final int eventId;
  final String ticketType;
  final double price;
  final int totalQuantity;
  final int soldQuantity;
  final int availableQuantity;
  final bool isAvailable;
  final DateTime? saleStartDate;
  final DateTime? saleEndDate;
  final bool isActive;
  final String? description;
  final int? priceZoneId;

  const EventTicketItem({
    required this.ticketId,
    required this.eventId,
    required this.ticketType,
    required this.price,
    required this.totalQuantity,
    required this.soldQuantity,
    required this.availableQuantity,
    required this.isAvailable,
    required this.saleStartDate,
    required this.saleEndDate,
    required this.isActive,
    required this.description,
    required this.priceZoneId,
  });

  factory EventTicketItem.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      return DateTime.tryParse(value.toString());
    }

    return EventTicketItem(
      ticketId: (json['ticketId'] as num?)?.toInt() ?? 0,
      eventId: (json['eventId'] as num?)?.toInt() ?? 0,
      ticketType: json['ticketType']?.toString() ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0,
      totalQuantity: (json['totalQuantity'] as num?)?.toInt() ?? 0,
      soldQuantity: (json['soldQuantity'] as num?)?.toInt() ?? 0,
      availableQuantity: (json['availableQuantity'] as num?)?.toInt() ?? 0,
      isAvailable: json['isAvailable'] as bool? ?? false,
      saleStartDate: parseDate(json['saleStartDate']),
      saleEndDate: parseDate(json['saleEndDate']),
      isActive: json['isActive'] as bool? ?? true,
      description: json['description']?.toString(),
      priceZoneId: (json['priceZoneId'] as num?)?.toInt(),
    );
  }

  bool get isSoldOut => availableQuantity <= 0 || !isAvailable;
}

class CreateReservationRequest {
  final int eventId;
  final int eventTicketId;
  final int quantity;
  final String currency;
  final String? seatNumber;
  final String? section;
  final String? notes;

  const CreateReservationRequest({
    required this.eventId,
    required this.eventTicketId,
    required this.quantity,
    required this.currency,
    this.seatNumber,
    this.section,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
        'eventId': eventId,
        'eventTicketId': eventTicketId,
        'quantity': quantity,
        'currency': currency,
        if (seatNumber != null && seatNumber!.trim().isNotEmpty)
          'seatNumber': seatNumber!.trim(),
        if (section != null && section!.trim().isNotEmpty)
          'section': section!.trim(),
        if (notes != null && notes!.trim().isNotEmpty) 'notes': notes!.trim(),
      };
}

class ConfirmReservationRequest {
  final String paymentReference;
  final String paymentMethod;
  final double amount;
  final String currency;

  const ConfirmReservationRequest({
    required this.paymentReference,
    required this.paymentMethod,
    required this.amount,
    required this.currency,
  });

  Map<String, dynamic> toJson() => {
        'paymentReference': paymentReference,
        'paymentMethod': paymentMethod,
        'amount': amount,
        'currency': currency,
      };
}

class ReservationItem {
  final int reservationId;
  final int userId;
  final int eventId;
  final int? eventTicketId;
  final int quantity;
  final double totalAmount;
  final String currency;
  final String status;
  final DateTime createdAt;
  final DateTime? confirmedAt;
  final DateTime? cancelledAt;
  final DateTime? expiredAt;
  final DateTime expiresAt;
  final String? paymentReference;
  final String? notes;

  const ReservationItem({
    required this.reservationId,
    required this.userId,
    required this.eventId,
    required this.eventTicketId,
    required this.quantity,
    required this.totalAmount,
    required this.currency,
    required this.status,
    required this.createdAt,
    required this.confirmedAt,
    required this.cancelledAt,
    required this.expiredAt,
    required this.expiresAt,
    required this.paymentReference,
    required this.notes,
  });

  factory ReservationItem.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      return DateTime.tryParse(value.toString());
    }

    return ReservationItem(
      reservationId: (json['reservationId'] as num?)?.toInt() ?? 0,
      userId: (json['userId'] as num?)?.toInt() ?? 0,
      eventId: (json['eventId'] as num?)?.toInt() ?? 0,
      eventTicketId: (json['eventTicketId'] as num?)?.toInt(),
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0,
      currency: json['currency']?.toString() ?? 'BAM',
      status: json['status']?.toString() ?? '',
      createdAt: parseDate(json['createdAt']) ?? DateTime.now(),
      confirmedAt: parseDate(json['confirmedAt']),
      cancelledAt: parseDate(json['cancelledAt']),
      expiredAt: parseDate(json['expiredAt']),
      expiresAt: parseDate(json['expiresAt']) ?? DateTime.now(),
      paymentReference: json['paymentReference']?.toString(),
      notes: json['notes']?.toString(),
    );
  }

  bool get isConfirmed => status.toLowerCase() == 'confirmed';
}

class EventReservationSummaryItem {
  final int eventId;
  final int capacity;
  final int pendingCount;
  final int confirmedCount;
  final int reservedCount;
  final int availableCount;
  final int reservationCount;
  final bool isSoldOut;

  const EventReservationSummaryItem({
    required this.eventId,
    required this.capacity,
    required this.pendingCount,
    required this.confirmedCount,
    required this.reservedCount,
    required this.availableCount,
    required this.reservationCount,
    required this.isSoldOut,
  });

  factory EventReservationSummaryItem.fromJson(Map<String, dynamic> json) {
    return EventReservationSummaryItem(
      eventId: (json['eventId'] as num?)?.toInt() ?? 0,
      capacity: (json['capacity'] as num?)?.toInt() ?? 0,
      pendingCount: (json['pendingCount'] as num?)?.toInt() ?? 0,
      confirmedCount: (json['confirmedCount'] as num?)?.toInt() ?? 0,
      reservedCount: (json['reservedCount'] as num?)?.toInt() ?? 0,
      availableCount: (json['availableCount'] as num?)?.toInt() ?? 0,
      reservationCount: (json['reservationCount'] as num?)?.toInt() ?? 0,
      isSoldOut: json['isSoldOut'] as bool? ?? false,
    );
  }
}

class EventAttendeeItem {
  final int userId;
  final String username;
  final String? avatarUrl;
  final int quantity;

  const EventAttendeeItem({
    required this.userId,
    required this.username,
    required this.avatarUrl,
    required this.quantity,
  });

  factory EventAttendeeItem.fromJson(Map<String, dynamic> json) {
    return EventAttendeeItem(
      userId: (json['userId'] as num?)?.toInt() ?? 0,
      username: (json['username'] as String?)?.trim() ?? 'User',
      avatarUrl: json['avatarUrl']?.toString(),
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
    );
  }
}

class PagedResponse<T> {
  final List<T> items;
  final int totalCount;
  final int page;
  final int pageSize;

  const PagedResponse({
    required this.items,
    required this.totalCount,
    required this.page,
    required this.pageSize,
  });

  factory PagedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final rawItems = json['items'];
    final items = rawItems is List
        ? rawItems
            .whereType<Map>()
            .map((e) => fromJson(Map<String, dynamic>.from(e)))
            .toList()
        : <T>[];

    return PagedResponse(
      items: items,
      totalCount: (json['totalCount'] as num?)?.toInt() ?? items.length,
      page: (json['page'] as num?)?.toInt() ?? 1,
      pageSize: (json['pageSize'] as num?)?.toInt() ?? items.length,
    );
  }
}