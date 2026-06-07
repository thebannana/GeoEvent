class SortOption {
  final String sortBy;
  final bool sortDescending;

  const SortOption({
    required this.sortBy,
    required this.sortDescending,
  });

  static const soonest = SortOption(
    sortBy: 'StartDateTime',
    sortDescending: false,
  );

  static const latest = SortOption(
    sortBy: 'StartDateTime',
    sortDescending: true,
  );

  static const mostLiked = SortOption(
    sortBy: 'LikesCount',
    sortDescending: true,
  );

  static const mostViewed = SortOption(
    sortBy: 'ViewCount',
    sortDescending: true,
  );

  static const lowestPrice = SortOption(
    sortBy: 'Price',
    sortDescending: false,
  );

  static const highestPrice = SortOption(
    sortBy: 'Price',
    sortDescending: true,
  );

  String get label {
    if (sortBy == 'LikesCount' && sortDescending) return 'Most liked';
    if (sortBy == 'ViewCount' && sortDescending) return 'Most viewed';
    if (sortBy == 'Price' && !sortDescending) return 'Lowest price';
    if (sortBy == 'Price' && sortDescending) return 'Highest price';
    if (sortBy == 'StartDateTime' && !sortDescending) return 'Soonest';
    if (sortBy == 'StartDateTime' && sortDescending) return 'Latest';
    return 'Sort';
  }

  static const all = <SortOption>[
    soonest,
    latest,
    mostLiked,
    mostViewed,
    lowestPrice,
    highestPrice,
  ];
}