class Loan {
  final int id;
  final String bookTitle;
  final String issueDate;
  final String dueDate;
  final bool isExtended;

  const Loan({
    required this.id,
    required this.bookTitle,
    required this.issueDate,
    required this.dueDate,
    required this.isExtended,
  });

  factory Loan.fromJson(Map<String, dynamic> json) => Loan(
    id: json['id'] as int? ?? 0,
    bookTitle: json['bookTitle'] as String? ?? '',
    issueDate: json['issueDate'] as String? ?? '',
    dueDate: json['dueDate'] as String? ?? '',
    isExtended: json['isExtended'] as bool? ?? false,
  );
}