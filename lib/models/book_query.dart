class BookQuery {
  final String search;
  final int? genreId;
  final int? publisherId;
  final int? yearFrom;
  final int? yearTo;
  final String sortField;
  final bool sortAscending;
  final int page;
  final int size;
  final bool includeDeleted;

  static const _unset = Object();

  const BookQuery({
    this.search = '',
    this.genreId,
    this.publisherId,
    this.yearFrom,
    this.yearTo,
    this.sortField = 'title',
    this.sortAscending = true,
    this.page = 1,
    this.size = 10,
    this.includeDeleted = false,
  });

  BookQuery copyWith({
    String? search,
    Object? genreId = _unset,
    Object? publisherId = _unset,
    Object? yearFrom = _unset,
    Object? yearTo = _unset,
    String? sortField,
    bool? sortAscending,
    int? page,
    int? size,
    bool? includeDeleted,
  }) {
    return BookQuery(
      search: search ?? this.search,
      genreId: genreId == _unset ? this.genreId : genreId as int?,
      publisherId: publisherId == _unset ? this.publisherId : publisherId as int?,
      yearFrom: yearFrom == _unset ? this.yearFrom : yearFrom as int?,
      yearTo: yearTo == _unset ? this.yearTo : yearTo as int?,
      sortField: sortField ?? this.sortField,
      sortAscending: sortAscending ?? this.sortAscending,
      page: page ?? 1,
      size: size ?? this.size,
      includeDeleted: includeDeleted ?? this.includeDeleted,
    );
  }

  Map<String, String> toQueryParams() {
    final map = <String, String>{};
    if (search.isNotEmpty) map['q'] = search;
    if (genreId != null) map['genre'] = genreId.toString();
    if (publisherId != null) map['publisher'] = publisherId.toString();
    if (yearFrom != null) map['yearFrom'] = yearFrom.toString();
    if (yearTo != null) map['yearTo'] = yearTo.toString();
    if (sortField != 'title') map['sort'] = sortField;
    if (!sortAscending) map['asc'] = 'false';
    if (page > 1) map['page'] = page.toString();
    if (size != 10) map['size'] = size.toString();
    if (includeDeleted) map['deleted'] = 'true';
    return map;
  }

  factory BookQuery.fromQueryParams(Map<String, String> params) {
    return BookQuery(
      search: params['q'] ?? '',
      genreId: int.tryParse(params['genre'] ?? ''),
      publisherId: int.tryParse(params['publisher'] ?? ''),
      yearFrom: int.tryParse(params['yearFrom'] ?? ''),
      yearTo: int.tryParse(params['yearTo'] ?? ''),
      sortField: params['sort'] ?? 'title',
      sortAscending: params['asc'] != 'false',
      page: int.tryParse(params['page'] ?? '1') ?? 1,
      size: int.tryParse(params['size'] ?? '10') ?? 10,
      includeDeleted: params['deleted'] == 'true',
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BookQuery &&
          runtimeType == other.runtimeType &&
          search == other.search &&
          genreId == other.genreId &&
          publisherId == other.publisherId &&
          yearFrom == other.yearFrom &&
          yearTo == other.yearTo &&
          sortField == other.sortField &&
          sortAscending == other.sortAscending &&
          page == other.page &&
          size == other.size &&
          includeDeleted == other.includeDeleted;

  @override
  int get hashCode => Object.hash(
        search,
        genreId,
        publisherId,
        yearFrom,
        yearTo,
        sortField,
        sortAscending,
        page,
        size,
        includeDeleted,
      );
}
