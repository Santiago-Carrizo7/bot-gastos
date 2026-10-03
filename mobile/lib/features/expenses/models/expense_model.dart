class ExpenseModel {
  final String id;
  final String userId;
  final double amount;
  final String description;
  final String category;
  final String? categoryId;
  final DateTime date;
  final int installments;
  final String currency;
  final DateTime createdAt;

  ExpenseModel({
    required this.id,
    required this.userId,
    required this.amount,
    required this.description,
    required this.category,
    this.categoryId,
    required this.date,
    required this.installments,
    required this.currency,
    required this.createdAt,
  });

  factory ExpenseModel.fromJson(Map<String, dynamic> json) {
    return ExpenseModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      amount: double.tryParse(json['amount'].toString()) ?? 0.0,
      description: json['description'] as String? ?? '',
      category: json['category'] as String? ?? 'otros',
      categoryId: json['categoryId'] as String?,
      date: DateTime.tryParse(json['date'].toString()) ?? DateTime.now(),
      installments: (json['installments'] as num?)?.toInt() ?? 1,
      currency: json['currency'] as String? ?? 'ARS',
      createdAt: DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'amount': amount,
      'description': description,
      'category': category,
      'categoryId': categoryId,
      'date': date.toIso8601String(),
      'installments': installments,
      'currency': currency,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  ExpenseModel copyWith({
    String? id,
    String? userId,
    double? amount,
    String? description,
    String? category,
    String? categoryId,
    DateTime? date,
    int? installments,
    String? currency,
    DateTime? createdAt,
  }) {
    return ExpenseModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      category: category ?? this.category,
      categoryId: categoryId ?? this.categoryId,
      date: date ?? this.date,
      installments: installments ?? this.installments,
      currency: currency ?? this.currency,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
