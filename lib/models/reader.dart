class LibraryCard {
  final String cardNumber;
  final DateTime issueDate;
  final String status;

  const LibraryCard({
    required this.cardNumber,
    required this.issueDate,
    this.status = 'Активен',
  });

  Map<String, dynamic> toJson() => {
    'cardNumber': cardNumber,
    'issueDate': issueDate.toIso8601String(),
    'status': status,
  };

  factory LibraryCard.fromJson(Map<String, dynamic> json) => LibraryCard(
    cardNumber: json['cardNumber'] as String? ?? '',
    issueDate: json['issueDate'] != null ? DateTime.parse(json['issueDate'] as String) : DateTime.now(),
    status: json['status'] as String? ?? 'Активен',
  );

  LibraryCard copyWith({String? cardNumber, DateTime? issueDate, String? status}) => LibraryCard(
    cardNumber: cardNumber ?? this.cardNumber,
    issueDate: issueDate ?? this.issueDate,
    status: status ?? this.status,
  );
}

class Reader {
  final int id;
  final String fullName;
  final String email;
  final String phone;
  final LibraryCard card;
  final DateTime? deletedAt;

  const Reader({
    required this.id,
    required this.fullName,
    required this.email,
    this.phone = '',
    required this.card,
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;

  Map<String, dynamic> toJson() => {
    'id': id,
    'fullName': fullName,
    'email': email,
    'phone': phone,
    'card': card.toJson(),
    'deletedAt': deletedAt?.toIso8601String(),
  };

  factory Reader.fromJson(Map<String, dynamic> json) => Reader(
    id: json['id'] as int? ?? 0,
    fullName: json['fullName'] as String? ?? '',
    email: json['email'] as String? ?? '',
    phone: json['phone'] as String? ?? '',
    card: json['card'] != null 
        ? LibraryCard.fromJson(json['card'] as Map<String, dynamic>) 
        : LibraryCard(cardNumber: 'T-001', issueDate: DateTime.now()),
    deletedAt: json['deletedAt'] == null ? null : DateTime.tryParse(json['deletedAt'] as String),
  );

  Reader copyWith({
    int? id,
    String? fullName,
    String? email,
    String? phone,
    LibraryCard? card,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) => Reader(
    id: id ?? this.id,
    fullName: fullName ?? this.fullName,
    email: email ?? this.email,
    phone: phone ?? this.phone,
    card: card ?? this.card,
    deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
  );
}