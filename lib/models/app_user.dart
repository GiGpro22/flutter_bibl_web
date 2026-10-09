enum Role {
  admin(3, 'Администратор'),
  librarian(2, 'Библиотекарь'),
  reader(1, 'Читатель');

  final int level;
  final String label;
  const Role(this.level, this.label);

  static Role fromCode(String? code) {
    return switch (code?.toLowerCase()) {
      'admin' => Role.admin,
      'librarian' => Role.librarian,
      _ => Role.reader, // Безопасная деградация роли
    };
  }
}

class AppUser {
  final int id;
  final String email;
  final String name;
  final Role role;

  const AppUser({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
  });

  bool get isAdmin => role == Role.admin;
  bool get isLibrarian => role == Role.librarian;
  bool get isReader => role == Role.reader;

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
    id: json['id'] as int? ?? 0,
    email: json['email'] as String? ?? '',
    name: json['name'] as String? ?? '',
    role: Role.fromCode(json['role'] as String?),
  );
}