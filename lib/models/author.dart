class Author {
  final int id;
  final String name;
  final String country;
  final int birthYear;
  final DateTime? deletedAt;

  const Author({
    required this.id,
    required this.name,
    required this.country,
    required this.birthYear,
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;

  Author copyWith({
    String? name,
    String? country,
    int? birthYear,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return Author(
      id: id,
      name: name ?? this.name,
      country: country ?? this.country,
      birthYear: birthYear ?? this.birthYear,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }
}
