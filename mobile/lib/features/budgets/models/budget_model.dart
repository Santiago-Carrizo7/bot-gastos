class BudgetModel {
  final String id;
  final String category;
  final double budgetAmount;
  final double spentAmount;
  final double remainingAmount;
  final int percentageUsed;
  final bool isExceeded;
  final String currency;

  BudgetModel({
    required this.id,
    required this.category,
    required this.budgetAmount,
    required this.spentAmount,
    required this.remainingAmount,
    required this.percentageUsed,
    required this.isExceeded,
    required this.currency,
  });

  factory BudgetModel.fromJson(Map<String, dynamic> json) {
    return BudgetModel(
      id: json['id'] as String,
      category: json['category'] as String,
      budgetAmount: double.tryParse(json['budgetAmount'].toString()) ?? 0.0,
      spentAmount: double.tryParse(json['spentAmount'].toString()) ?? 0.0,
      remainingAmount: double.tryParse(json['remainingAmount'].toString()) ?? 0.0,
      percentageUsed: (json['percentageUsed'] as num?)?.toInt() ?? 0,
      isExceeded: json['isExceeded'] as bool? ?? false,
      currency: json['currency'] as String? ?? 'ARS',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category': category,
      'budgetAmount': budgetAmount,
      'spentAmount': spentAmount,
      'remainingAmount': remainingAmount,
      'percentageUsed': percentageUsed,
      'isExceeded': isExceeded,
      'currency': currency,
    };
  }
}
