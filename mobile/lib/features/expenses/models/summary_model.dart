class CategorySummaryItem {
  final double total;
  final int count;

  CategorySummaryItem({required this.total, required this.count});

  factory CategorySummaryItem.fromJson(Map<String, dynamic> json) {
    return CategorySummaryItem(
      total: double.tryParse(json['total'].toString()) ?? 0.0,
      count: (json['count'] as num?)?.toInt() ?? 0,
    );
  }
}

class MonthlySummaryModel {
  final int year;
  final int month;
  final String monthName;
  final double total;
  final int count;
  final Map<String, CategorySummaryItem> categories;

  MonthlySummaryModel({
    required this.year,
    required this.month,
    required this.monthName,
    required this.total,
    required this.count,
    required this.categories,
  });

  factory MonthlySummaryModel.fromJson(Map<String, dynamic> json) {
    final rawCats = json['categories'] as Map<String, dynamic>? ?? {};
    final parsedCats = <String, CategorySummaryItem>{};

    rawCats.forEach((key, value) {
      if (value is Map<String, dynamic>) {
        parsedCats[key] = CategorySummaryItem.fromJson(value);
      }
    });

    return MonthlySummaryModel(
      year: (json['year'] as num?)?.toInt() ?? DateTime.now().year,
      month: (json['month'] as num?)?.toInt() ?? DateTime.now().month,
      monthName: json['monthName'] as String? ?? '',
      total: double.tryParse(json['total'].toString()) ?? 0.0,
      count: (json['count'] as num?)?.toInt() ?? 0,
      categories: parsedCats,
    );
  }
}

class MonthHistoryItem {
  final int year;
  final int month;
  final String monthName;
  final double total;
  final int count;

  MonthHistoryItem({
    required this.year,
    required this.month,
    required this.monthName,
    required this.total,
    required this.count,
  });

  factory MonthHistoryItem.fromJson(Map<String, dynamic> json) {
    return MonthHistoryItem(
      year: (json['year'] as num?)?.toInt() ?? DateTime.now().year,
      month: (json['month'] as num?)?.toInt() ?? DateTime.now().month,
      monthName: json['monthName'] as String? ?? '',
      total: double.tryParse(json['total'].toString()) ?? 0.0,
      count: (json['count'] as num?)?.toInt() ?? 0,
    );
  }
}

class AnalyticsModel {
  final MonthlySummaryModel current;
  final List<MonthHistoryItem> monthlyHistory;

  AnalyticsModel({
    required this.current,
    required this.monthlyHistory,
  });

  factory AnalyticsModel.fromJson(Map<String, dynamic> json) {
    final curJson = json['current'] as Map<String, dynamic>? ?? {};
    final rawHistory = json['monthlyHistory'] as List<dynamic>? ?? [];

    return AnalyticsModel(
      current: MonthlySummaryModel.fromJson(curJson),
      monthlyHistory: rawHistory
          .map((item) => MonthHistoryItem.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}
