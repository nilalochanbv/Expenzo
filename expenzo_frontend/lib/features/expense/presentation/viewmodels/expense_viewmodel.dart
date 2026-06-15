import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/nlp/local_nlp_parser.dart';
import '../../data/models/expense_model.dart';
import '../../domain/repositories/expense_repository.dart';

class ExpenseViewModel extends ChangeNotifier {
  final ExpenseRepository repository;

  List<ExpenseModel> _expenses = [];
  List<ExpenseModel> _searchResults = [];
  bool _isLoading = false;
  String _searchQuery = '';

  List<ExpenseModel> get expenses => _searchQuery.isEmpty ? _expenses : _searchResults;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;

  ExpenseViewModel({required this.repository}) {
    loadExpenses();
  }

  void loadExpenses() {
    _expenses = repository.getExpenses();
    if (_searchQuery.isNotEmpty) {
      _searchResults = repository.searchExpenses(_searchQuery);
    }
    notifyListeners();
  }

  List<ExpenseModel> get recentExpenses {
    return _expenses.take(5).toList();
  }

  double get monthlyTotal {
    final now = DateTime.now();
    return _expenses
        .where((e) => e.createdAt.month == now.month && e.createdAt.year == now.year)
        .fold(0.0, (sum, e) => sum + e.amount);
  }

  double get lastMonthTotal {
    final now = DateTime.now();
    final lastMonth = now.month == 1 ? 12 : now.month - 1;
    final year = now.month == 1 ? now.year - 1 : now.year;
    return _expenses
        .where((e) => e.createdAt.month == lastMonth && e.createdAt.year == year)
        .fold(0.0, (sum, e) => sum + e.amount);
  }

  double get percentageChange {
    final cur = monthlyTotal;
    final prev = lastMonthTotal;
    if (prev == 0.0) return cur > 0 ? 100.0 : 0.0;
    return ((cur - prev) / prev) * 100.0;
  }

  Map<String, double> get topCategories {
    final now = DateTime.now();
    final monthlyExpenses = _expenses
        .where((e) => e.createdAt.month == now.month && e.createdAt.year == now.year);
    
    final Map<String, double> map = {};
    for (var e in monthlyExpenses) {
      map[e.category] = (map[e.category] ?? 0.0) + e.amount;
    }
    
    // Sort by amount descending
    final sortedList = map.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return Map.fromEntries(sortedList);
  }

  Future<ExpenseModel> quickAdd(String text) async {
    final parsed = LocalNlpParser.parse(text);
    final expense = ExpenseModel(
      id: const Uuid().v4(),
      description: parsed.description,
      amount: parsed.amount,
      category: parsed.category,
      createdAt: parsed.createdAt,
      lastUpdated: DateTime.now(),
    );
    await repository.saveExpense(expense);
    loadExpenses();
    return expense;
  }

  Future<void> addCustomExpense(String description, double amount, String category, DateTime date) async {
    final expense = ExpenseModel(
      id: const Uuid().v4(),
      description: description,
      amount: amount,
      category: category,
      createdAt: date,
      lastUpdated: DateTime.now(),
    );
    await repository.saveExpense(expense);
    loadExpenses();
  }

  Future<void> deleteExpense(String id) async {
    await repository.deleteExpense(id);
    loadExpenses();
  }

  void search(String query) {
    _searchQuery = query;
    _searchResults = repository.searchExpenses(query);
    notifyListeners();
  }

  Future<void> sync() async {
    _isLoading = true;
    notifyListeners();
    try {
      await repository.syncWithServer();
      loadExpenses();
    } catch (e) {
      print('Sync error in ViewModel: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
