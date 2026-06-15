import 'package:flutter/material.dart';
import '../../../expense/data/models/expense_model.dart';
import '../../../expense/domain/repositories/expense_repository.dart';

class CategoryComparison {
  final String category;
  final double juneAmount;
  final double julyAmount;
  final double difference;
  final double percentageChange;

  CategoryComparison({
    required this.category,
    required this.juneAmount,
    required this.julyAmount,
    required this.difference,
    required this.percentageChange,
  });
}

class InsightViewModel extends ChangeNotifier {
  final ExpenseRepository repository;

  List<String> _insights = [];
  List<String> _recurringSuggestions = [];
  List<CategoryComparison> _comparisons = [];

  List<String> get insights => _insights;
  List<String> get recurringSuggestions => _recurringSuggestions;
  List<CategoryComparison> get comparisons => _comparisons;

  InsightViewModel({required this.repository});

  void generateInsightsAndComparisons(List<ExpenseModel> allExpenses) {
    final now = DateTime.now();
    final currentMonth = now.month;
    final currentYear = now.year;

    final prevMonth = currentMonth == 1 ? 12 : currentMonth - 1;
    final prevYear = currentMonth == 1 ? currentYear - 1 : currentYear;

    // 1. Calculate Category Comparisons
    final Map<String, double> currentTotals = {};
    final Map<String, double> prevTotals = {};

    for (var e in allExpenses) {
      if (e.isDeleted) continue;
      if (e.createdAt.year == currentYear && e.createdAt.month == currentMonth) {
        currentTotals[e.category] = (currentTotals[e.category] ?? 0.0) + e.amount;
      } else if (e.createdAt.year == prevYear && e.createdAt.month == prevMonth) {
        prevTotals[e.category] = (prevTotals[e.category] ?? 0.0) + e.amount;
      }
    }

    final Set<String> allCategories = {...currentTotals.keys, ...prevTotals.keys};
    final List<CategoryComparison> tempComparisons = [];

    for (var cat in allCategories) {
      final curr = currentTotals[cat] ?? 0.0;
      final prev = prevTotals[cat] ?? 0.0;
      final diff = curr - prev;
      final pct = prev > 0.0 ? (diff / prev) * 100 : 0.0;

      tempComparisons.add(CategoryComparison(
        category: cat,
        juneAmount: prev, // Named june/july representatively in prompt
        julyAmount: curr,
        difference: diff,
        percentageChange: pct,
      ));
    }
    
    // Sort comparison by absolute difference descending
    tempComparisons.sort((a, b) => b.difference.abs().compareTo(a.difference.abs()));
    _comparisons = tempComparisons;

    // 2. Generate Natural Language Insights
    final List<String> tempInsights = [];
    
    // Total change
    final double totalCurrent = currentTotals.values.fold(0, (sum, val) => sum + val);
    final double totalPrev = prevTotals.values.fold(0, (sum, val) => sum + val);
    if (totalPrev > 0) {
      final pct = ((totalCurrent - totalPrev) / totalPrev) * 100;
      if (pct.abs() > 5) {
        tempInsights.add("Total spending ${pct > 0 ? 'increased' : 'reduced'} by ${pct.abs().toStringAsFixed(1)}% compared to last month.");
      } else {
        tempInsights.add("Total spending remains stable compared to last month.");
      }
    }

    // Category changes
    for (var comp in _comparisons) {
      if (comp.juneAmount > 0) {
        if (comp.percentageChange >= 20) {
          tempInsights.add("${comp.category} spending increased by ${comp.percentageChange.toStringAsFixed(0)}%.");
        } else if (comp.percentageChange <= -20) {
          tempInsights.add("${comp.category} expenses reduced by ${comp.percentageChange.abs().toStringAsFixed(0)}%.");
        }
      } else if (comp.julyAmount > 500) {
        tempInsights.add("New spending of ₹${comp.julyAmount.toStringAsFixed(0)} detected in ${comp.category}.");
      }
    }

    // Default insight if none
    if (tempInsights.isEmpty) {
      tempInsights.add("No major spending fluctuations detected this month. Good job!");
    }
    _insights = tempInsights;

    // 3. Detect Recurring Expenses
    final Map<String, List<ExpenseModel>> grouped = {};
    for (var e in allExpenses) {
      if (e.isDeleted) continue;
      final key = '${e.description.toLowerCase().trim()}|${e.amount}';
      grouped.putIfAbsent(key, () => []).add(e);
    }

    final List<String> tempRecurring = [];
    grouped.forEach((key, list) {
      if (list.length >= 3) {
        list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        bool fitsMonthlyPattern = true;
        for (int i = 1; i < list.length; i++) {
          final daysBetween = list[i].createdAt.difference(list[i - 1].createdAt).inDays;
          if (daysBetween < 25 || daysBetween > 35) {
            fitsMonthlyPattern = false;
            break;
          }
        }
        if (fitsMonthlyPattern) {
          final sample = list.first;
          tempRecurring.add("Recurring expense detected: \"${sample.description} ${sample.amount.toStringAsFixed(0)}\"");
        }
      }
    });
    _recurringSuggestions = tempRecurring;

    notifyListeners();
  }
}
