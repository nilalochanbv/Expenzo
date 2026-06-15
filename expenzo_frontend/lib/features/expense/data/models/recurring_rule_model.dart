import 'package:hive/hive.dart';

part 'recurring_rule_model.g.dart';

@HiveType(typeId: 2)
class RecurringRuleModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String descriptionPattern;

  @HiveField(2)
  final double amount;

  @HiveField(3)
  final String category;

  @HiveField(4)
  final String frequency;

  @HiveField(5)
  final bool isActive;

  @HiveField(6)
  final DateTime lastUpdated;

  @HiveField(7)
  final bool isDeleted;

  @HiveField(8)
  final bool isSynced;

  RecurringRuleModel({
    required this.id,
    required this.descriptionPattern,
    required this.amount,
    required this.category,
    required this.frequency,
    required this.isActive,
    required this.lastUpdated,
    this.isDeleted = false,
    this.isSynced = false,
  });

  factory RecurringRuleModel.fromJson(Map<String, dynamic> json) {
    return RecurringRuleModel(
      id: json['id'] as String,
      descriptionPattern: json['descriptionPattern'] as String,
      amount: (json['amount'] as num).toDouble(),
      category: json['category'] as String,
      frequency: json['frequency'] as String,
      isActive: json['isActive'] as bool,
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
      isDeleted: json['isDeleted'] as bool? ?? false,
      isSynced: true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'descriptionPattern': descriptionPattern,
      'amount': amount,
      'category': category,
      'frequency': frequency,
      'isActive': isActive,
      'lastUpdated': lastUpdated.toIso8601String(),
      'isDeleted': isDeleted,
    };
  }

  RecurringRuleModel copyWith({
    String? id,
    String? descriptionPattern,
    double? amount,
    String? category,
    String? frequency,
    bool? isActive,
    DateTime? lastUpdated,
    bool? isDeleted,
    bool? isSynced,
  }) {
    return RecurringRuleModel(
      id: id ?? this.id,
      descriptionPattern: descriptionPattern ?? this.descriptionPattern,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      frequency: frequency ?? this.frequency,
      isActive: isActive ?? this.isActive,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      isDeleted: isDeleted ?? this.isDeleted,
      isSynced: isSynced ?? this.isSynced,
    );
  }
}
