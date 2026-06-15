import 'package:hive/hive.dart';

part 'expense_model.g.dart';

@HiveType(typeId: 0)
class ExpenseModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String description;

  @HiveField(2)
  final double amount;

  @HiveField(3)
  final String category;

  @HiveField(4)
  final DateTime createdAt;

  @HiveField(5)
  final DateTime lastUpdated;

  @HiveField(6)
  final bool isDeleted;

  @HiveField(7)
  final bool isSynced;

  ExpenseModel({
    required this.id,
    required this.description,
    required this.amount,
    required this.category,
    required this.createdAt,
    required this.lastUpdated,
    this.isDeleted = false,
    this.isSynced = false,
  });

  factory ExpenseModel.fromJson(Map<String, dynamic> json) {
    return ExpenseModel(
      id: json['id'] as String,
      description: json['description'] as String,
      amount: (json['amount'] as num).toDouble(),
      category: json['category'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
      isDeleted: json['isDeleted'] as bool? ?? false,
      isSynced: true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'description': description,
      'amount': amount,
      'category': category,
      'createdAt': createdAt.toIso8601String(),
      'lastUpdated': lastUpdated.toIso8601String(),
      'isDeleted': isDeleted,
    };
  }

  ExpenseModel copyWith({
    String? id,
    String? description,
    double? amount,
    String? category,
    DateTime? createdAt,
    DateTime? lastUpdated,
    bool? isDeleted,
    bool? isSynced,
  }) {
    return ExpenseModel(
      id: id ?? this.id,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      isDeleted: isDeleted ?? this.isDeleted,
      isSynced: isSynced ?? this.isSynced,
    );
  }
}
