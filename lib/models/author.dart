class Author {
  final int id;
  final String name;
  final String country;
  final int birthYear;
  final String biography;
  final DateTime? deletedAt;
  final bool _legacyDeleted;

  const Author({
    required this.id,
    required this.name,
    this.country = '',
    this.birthYear = 0,
    this.biography = '',
    this.deletedAt,
    bool isDeleted = false,
  }) : _legacyDeleted = isDeleted;

  bool get isDeleted => deletedAt != null || _legacyDeleted;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'country': country,
    'birthYear': birthYear,
    'biography': biography,
    'deletedAt': deletedAt?.toIso8601String(),
    'isDeleted': isDeleted,
  };

  factory Author.fromJson(Map<String, dynamic> json) => Author(
    id: json['id'] as int? ?? 0,
    name: json['name'] as String? ?? '',
    country: json['country'] as String? ?? '',
    birthYear: json['birthYear'] as int? ?? 0,
    biography: json['biography'] as String? ?? '',
    deletedAt: json['deletedAt'] == null ? null : DateTime.tryParse(json['deletedAt'] as String),
    isDeleted: json['isDeleted'] as bool? ?? false,
  );

  Author copyWith({
    int? id,
    String? name,
    String? country,
    int? birthYear,
    String? biography,
    DateTime? deletedAt,
    bool? isDeleted,
    bool clearDeletedAt = false,
  }) => Author(
    id: id ?? this.id,
    name: name ?? this.name,
    country: country ?? this.country,
    birthYear: birthYear ?? this.birthYear,
    biography: biography ?? this.biography,
    deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    isDeleted: clearDeletedAt ? false : (isDeleted ?? _legacyDeleted),
  );
}