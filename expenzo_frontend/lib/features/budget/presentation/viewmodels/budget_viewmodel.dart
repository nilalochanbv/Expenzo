import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../../expense/data/models/expense_model.dart';
import '../../../expense/domain/repositories/expense_repository.dart';
import '../../data/models/budget_model.dart';

class BudgetViewModel extends ChangeNotifier {
  final ExpenseRepository repository;

  List<BudgetModel> _budgets = [];

  List<BudgetModel> get budgets => _budgets;

  BudgetViewModel({required this.repository}) {
    loadBudgets();
  }

  void loadBudgets() {
    _budgets = repository.getBudgets();
    notifyListeners();
  }

  double getSpentForBudget(BudgetModel budget, List<ExpenseModel> expenses) {
    return expenses
        .where((e) =>
            e.category.toLowerCase() == budget.category.toLowerCase() &&
            e.createdAt.month == budget.month &&
            e.createdAt.year == budget.year)
        .fold(0.0, (sum, e) => sum + e.amount);
  }

  double getBudgetProgress(BudgetModel budget, List<ExpenseModel> expenses) {
    if (budget.amountLimit == 0.0) return 0.0;
    final spent = getSpentForBudget(budget, expenses);
    return spent / budget.amountLimit;
  }

  String? getBudgetWarningMessage(BudgetModel budget, List<ExpenseModel> expenses) {
    final progress = getBudgetProgress(budget, expenses);
    final spent = getSpentForBudget(budget, expenses);
    if (progress >= 1.0) {
      return '🚨 Budget exceeded! You spent ₹${spent.toStringAsFixed(0)} of ₹${budget.amountLimit.toStringAsFixed(0)} for ${budget.category}.';
    } else if (progress >= 0.9) {
      return '⚠️ Danger! You have used ${(progress * 100).toStringAsFixed(0)}% of your ₹${budget.amountLimit.toStringAsFixed(0)} budget for ${budget.category}.';
    } else if (progress >= 0.8) {
      return '📝 Alert: You have used ${(progress * 100).toStringAsFixed(0)}% of your ₹${budget.amountLimit.toStringAsFixed(0)} budget for ${budget.category}.';
    }
    return null;
  }

  Future<void> setBudget(String category, double amountLimit) async {
    final now = DateTime.now();
    
    // Check if budget already exists for this category and month
    final existing = _budgets.firstWhere(
      (b) => b.category.toLowerCase() == category.toLowerCase() && b.month == now.month && b.year == now.year,
      orElse: () => BudgetModel(
        id: const Uuid().v4(),
        category: category,
        amountLimit: amountLimit,
        month: now.month,
        year: now.year,
        lastUpdated: DateTime.now(),
      ),
    );

    final toSave = existing.copyWith(
      amountLimit: amountLimit,
      lastUpdated: DateTime.now(),
    );

    await repository.saveBudget(toSave);
    loadBudgets();
  }

  Future<void> deleteBudget(String id) async {
    await repository.deleteBudget(id);
    loadBudgets();
  }
}
