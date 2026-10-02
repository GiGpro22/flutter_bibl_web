class Book {
  final int id;
  final String title;
  final String isbn;
  final int year;
  final int pages;
  final int publisherId;
  final List<int> authorIds;
  final List<int> genreIds;
  final int copiesTotal;
  final int copiesAvailable;
  final DateTime? deletedAt;
  final bool _legacyDeleted;

  const Book({
    required this.id,
    required this.title,
    this.isbn = '',
    this.year = 0,
    this.pages = 0,
    this.publisherId = 0,
    this.authorIds = const [],
    this.genreIds = const [],
    this.copiesTotal = 1,
    this.copiesAvailable = 1,
    this.deletedAt,
    bool isDeleted = false,
  }) : _legacyDeleted = isDeleted;

  bool get isDeleted => deletedAt != null || _legacyDeleted;

  int get authorId => authorIds.isNotEmpty ? authorIds.first : publisherId;
  String get genre => genreIds.isNotEmpty ? genreIds.first.toString() : '';

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'isbn': isbn,
    'year': year,
    'pages': pages,
    'publisherId': publisherId,
    'authorIds': authorIds,
    'genreIds': genreIds,
    'copiesTotal': copiesTotal,
    'copiesAvailable': copiesAvailable,
    'deletedAt': deletedAt?.toIso8601String(),
    'isDeleted': isDeleted,
  };

  factory Book.fromJson(Map<String, dynamic> json) => Book(
    id: json['id'] as int? ?? 0,
    title: json['title'] as String? ?? '',
    isbn: json['isbn'] as String? ?? '',
    year: json['year'] as int? ?? 0,
    pages: json['pages'] as int? ?? 0,
    publisherId: json['publisherId'] as int? ?? 0,
    authorIds: (json['authorIds'] as List?)?.whereType<int>().toList() ?? const [],
    genreIds: (json['genreIds'] as List?)?.whereType<int>().toList() ?? const [],
    copiesTotal: json['copiesTotal'] as int? ?? 0,
    copiesAvailable: json['copiesAvailable'] as int? ?? 0,
    deletedAt: json['deletedAt'] == null ? null : DateTime.tryParse(json['deletedAt'] as String),
    isDeleted: json['isDeleted'] as bool? ?? false,
  );

  Book copyWith({
    int? id,
    String? title,
    String? isbn,
    int? year,
    int? pages,
    int? publisherId,
    List<int>? authorIds,
    List<int>? genreIds,
    int? copiesTotal,
    int? copiesAvailable,
    DateTime? deletedAt,
    bool? isDeleted,
    bool clearDeletedAt = false,
  }) => Book(
    id: id ?? this.id,
    title: title ?? this.title,
    isbn: isbn ?? this.isbn,
    year: year ?? this.year,
    pages: pages ?? this.pages,
    publisherId: publisherId ?? this.publisherId,
    authorIds: authorIds ?? this.authorIds,
    genreIds: genreIds ?? this.genreIds,
    copiesTotal: copiesTotal ?? this.copiesTotal,
    copiesAvailable: copiesAvailable ?? this.copiesAvailable,
    deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    isDeleted: clearDeletedAt ? false : (isDeleted ?? _legacyDeleted),
  );
}