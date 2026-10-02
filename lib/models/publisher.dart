class Publisher {
  final int id;
  final String name;
  final String city;
  final List<int> supportedGenreIds;
  final DateTime? deletedAt;

  const Publisher({
    required this.id,
    required this.name,
    this.city = '',
    this.supportedGenreIds = const [1, 2, 3],
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'city': city,
    'supportedGenreIds': supportedGenreIds,
    'deletedAt': deletedAt?.toIso8601String(),
  };

  factory Publisher.fromJson(Map<String, dynamic> json) => Publisher(
    id: json['id'] as int? ?? 0,
    name: json['name'] as String? ?? '',
    city: json['city'] as String? ?? '',
    supportedGenreIds: (json['supportedGenreIds'] as List?)?.whereType<int>().toList() ?? const [1, 2, 3],
    deletedAt: json['deletedAt'] == null ? null : DateTime.tryParse(json['deletedAt'] as String),
  );

  Publisher copyWith({
    int? id,
    String? name,
    String? city,
    List<int>? supportedGenreIds,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) => Publisher(
    id: id ?? this.id,
    name: name ?? this.name,
    city: city ?? this.city,
    supportedGenreIds: supportedGenreIds ?? this.supportedGenreIds,
    deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
  );
}