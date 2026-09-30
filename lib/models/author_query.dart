class AuthorQuery {
  final String search;
  final String? country;
  final String sortField;
  final bool sortAscending;
  final int page;
  final int size;
  final bool includeDeleted;

  static const _unset = Object();

  const AuthorQuery({
    this.search = '',
    this.country,
    this.sortField = 'name',
    this.sortAscending = true,
    this.page = 1,
    this.size = 10,
    this.includeDeleted = false,
  });

  AuthorQuery copyWith({
    String? search,
    Object? country = _unset,
    String? sortField,
    bool? sortAscending,
    int? page,
    int? size,
    bool? includeDeleted,
  }) {
    return AuthorQuery(
      search: search ?? this.search,
      country: country == _unset ? this.country : country as String?,
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
    if (country != null && country!.isNotEmpty) map['country'] = country!;
    if (sortField != 'name') map['sort'] = sortField;
    if (!sortAscending) map['asc'] = 'false';
    if (page > 1) map['page'] = page.toString();
    if (size != 10) map['size'] = size.toString();
    if (includeDeleted) map['deleted'] = 'true';
    return map;
  }

  factory AuthorQuery.fromQueryParams(Map<String, String> params) {
    return AuthorQuery(
      search: params['q'] ?? '',
      country: params['country'],
      sortField: params['sort'] ?? 'name',
      sortAscending: params['asc'] != 'false',
      page: int.tryParse(params['page'] ?? '1') ?? 1,
      size: int.tryParse(params['size'] ?? '10') ?? 10,
      includeDeleted: params['deleted'] == 'true',
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthorQuery &&
          runtimeType == other.runtimeType &&
          search == other.search &&
          country == other.country &&
          sortField == other.sortField &&
          sortAscending == other.sortAscending &&
          page == other.page &&
          size == other.size &&
          includeDeleted == other.includeDeleted;

  @override
  int get hashCode => Object.hash(
        search,
        country,
        sortField,
        sortAscending,
        page,
        size,
        includeDeleted,
      );
}
