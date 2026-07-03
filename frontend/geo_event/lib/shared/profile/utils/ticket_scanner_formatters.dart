class TicketScannerFormatters {
  const TicketScannerFormatters._();

  static String formatPrice(num? price) {
    if (price == null || price <= 0) {
      return 'Free';
    }

    if (price % 1 == 0) {
      return '${price.toInt()}\$';
    }

    return '${price.toStringAsFixed(2)}\$';
  }
}