enum RefundRequestStatus {
  none,
  pending,
  processing,
  approved,
  rejected,
  failed,
  unknown;

  static RefundRequestStatus fromValue(String? value) {
    switch (value?.trim().toLowerCase()) {
      case '':
      case null:
        return RefundRequestStatus.none;
      case 'none':
        return RefundRequestStatus.none;
      case 'pending':
        return RefundRequestStatus.pending;
      case 'processing':
        return RefundRequestStatus.processing;
      case 'approved':
        return RefundRequestStatus.approved;
      case 'rejected':
        return RefundRequestStatus.rejected;
      case 'failed':
        return RefundRequestStatus.failed;
      default:
        return RefundRequestStatus.unknown;
    }
  }
}