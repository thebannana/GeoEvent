class SortOption {
  final String sortBy;
  final bool sortDescending;
  final String label;
  final bool isClientSideRanked;

  const SortOption({
    required this.sortBy,
    required this.sortDescending,
    required this.label,
    this.isClientSideRanked = false,
  });

  static const recommended = SortOption(
    sortBy: '',
    sortDescending: true,
    label: 'Recommended',
    isClientSideRanked: true,
  );

  static const soonest = SortOption(
    sortBy: 'StartDateTime',
    sortDescending: false,
    label: 'Soonest',
  );

  static const latest = SortOption(
    sortBy: 'StartDateTime',
    sortDescending: true,
    label: 'Latest',
  );

  static const mostLiked = SortOption(
    sortBy: 'LikesCount',
    sortDescending: true,
    label: 'Most liked',
  );

  static const mostViewed = SortOption(
    sortBy: 'ViewCount',
    sortDescending: true,
    label: 'Most viewed',
  );

  static const lowestPrice = SortOption(
    sortBy: 'Price',
    sortDescending: false,
    label: 'Lowest price',
  );

  static const highestPrice = SortOption(
    sortBy: 'Price',
    sortDescending: true,
    label: 'Highest price',
  );

  static const all = [
    recommended,
    soonest,
    latest,
    mostLiked,
    mostViewed,
    lowestPrice,
    highestPrice,
  ];
}