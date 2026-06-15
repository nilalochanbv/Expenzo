import 'package:hive/hive.dart';

part 'budget_model.g.dart';

@HiveType(typeId: 1)
class BudgetModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String category;

  @HiveField(2)
  final double amountLimit;

  @HiveField(3)
  final int month;

  @HiveField(4)
  final int year;

  @HiveField(5)
  final DateTime lastUpdated;

  @HiveField(6)
  final bool isDeleted;

  @HiveField(7)
  final bool isSynced;

  BudgetModel({
    required this.id,
    required this.category,
    required this.amountLimit,
    required this.month,
    required this.year,
    required this.lastUpdated,
    this.isDeleted = false,
    this.isSynced = false,
  });

  factory BudgetModel.fromJson(Map<String, dynamic> json) {
    return BudgetModel(
      id: json['id'] as String,
      category: json['category'] as String,
      amountLimit: (json['amountLimit'] as num).toDouble(),
      month: json['month'] as int,
      year: json['year'] as int,
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
      isDeleted: json['isDeleted'] as bool? ?? false,
      isSynced: true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category': category,
      'amountLimit': amountLimit,
      'month': month,
      'year': year,
      'lastUpdated': lastUpdated.toIso8601String(),
      'isDeleted': isDeleted,
    };
  }

  BudgetModel copyWith({
    String? id,
    String? category,
    double? amountLimit,
    int? month,
    int? year,
    DateTime? lastUpdated,
    bool? isDeleted,
    bool? isSynced,
  }) {
    return BudgetModel(
      id: id ?? this.id,
      category: category ?? this.category,
      amountLimit: amountLimit ?? this.amountLimit,
      month: month ?? this.month,
      year: year ?? this.year,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      isDeleted: isDeleted ?? this.isDeleted,
      isSynced: isSynced ?? this.isSynced,
    );
  }
}
