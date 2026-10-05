class PageResult<T> {
  final List<T> items;
  final int page;
  final int size;
  final int total;

  const PageResult({
    required this.items,
    required this.page,
    required this.size,
    required this.total,
  });

  factory PageResult.empty() => const PageResult(
    items: [],
    page: 1,
    size: 5,
    total: 0,
  );

  int get totalPages => (total / size).ceil();
}