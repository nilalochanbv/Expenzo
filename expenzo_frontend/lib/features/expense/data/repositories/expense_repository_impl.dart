import 'dart:convert';
import '../../../../core/database/hive_database.dart';
import '../../../../core/network/api_client.dart';
import '../../../budget/data/models/budget_model.dart';
import '../../domain/repositories/expense_repository.dart';
import '../models/expense_model.dart';
import '../models/recurring_rule_model.dart';

class ExpenseRepositoryImpl implements ExpenseRepository {
  
  // Helper to trigger sync in the background
  void _triggerBackgroundSync() {
    syncWithServer().catchError((error) {
      print('Background sync failed: $error');
    });
  }

  // --- Expense Operations ---

  @override
  List<ExpenseModel> getExpenses() {
    return HiveDatabase.expensesBox.values
        .where((e) => !e.isDeleted)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt)); // Newest first
  }

  @override
  Future<void> saveExpense(ExpenseModel expense) async {
    final updated = expense.copyWith(
      lastUpdated: DateTime.now(),
      isSynced: false,
    );
    await HiveDatabase.expensesBox.put(updated.id, updated);
    _triggerBackgroundSync();
  }

  @override
  Future<void> deleteExpense(String id) async {
    final existing = HiveDatabase.expensesBox.get(id);
    if (existing != null) {
      final updated = existing.copyWith(
        isDeleted: true,
        lastUpdated: DateTime.now(),
        isSynced: false,
      );
      await HiveDatabase.expensesBox.put(id, updated);
      _triggerBackgroundSync();
    }
  }

  @override
  List<ExpenseModel> searchExpenses(String query) {
    if (query.isEmpty) return getExpenses();
    final lowercaseQuery = query.toLowerCase();
    return HiveDatabase.expensesBox.values
        .where((e) => !e.isDeleted && e.description.toLowerCase().contains(lowercaseQuery))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  // --- Budget Operations ---

  @override
  List<BudgetModel> getBudgets() {
    return HiveDatabase.budgetsBox.values
        .where((b) => !b.isDeleted)
        .toList();
  }

  @override
  Future<void> saveBudget(BudgetModel budget) async {
    final updated = budget.copyWith(
      lastUpdated: DateTime.now(),
      isSynced: false,
    );
    await HiveDatabase.budgetsBox.put(updated.id, updated);
    _triggerBackgroundSync();
  }

  @override
  Future<void> deleteBudget(String id) async {
    final existing = HiveDatabase.budgetsBox.get(id);
    if (existing != null) {
      final updated = existing.copyWith(
        isDeleted: true,
        lastUpdated: DateTime.now(),
        isSynced: false,
      );
      await HiveDatabase.budgetsBox.put(id, updated);
      _triggerBackgroundSync();
    }
  }

  // --- Recurring Rule Operations ---

  @override
  List<RecurringRuleModel> getRecurringRules() {
    return HiveDatabase.recurringRulesBox.values
        .where((r) => !r.isDeleted)
        .toList();
  }

  @override
  Future<void> saveRecurringRule(RecurringRuleModel rule) async {
    final updated = rule.copyWith(
      lastUpdated: DateTime.now(),
      isSynced: false,
    );
    await HiveDatabase.recurringRulesBox.put(updated.id, updated);
    _triggerBackgroundSync();
  }

  @override
  Future<void> deleteRecurringRule(String id) async {
    final existing = HiveDatabase.recurringRulesBox.get(id);
    if (existing != null) {
      final updated = existing.copyWith(
        isDeleted: true,
        lastUpdated: DateTime.now(),
        isSynced: false,
      );
      await HiveDatabase.recurringRulesBox.put(id, updated);
      _triggerBackgroundSync();
    }
  }

  // --- Sync Engine ---

  @override
  Future<void> syncWithServer() async {
    // 1. Gather all unsynced items
    final unsyncedExpenses = HiveDatabase.expensesBox.values.where((e) => !e.isSynced).toList();
    final unsyncedBudgets = HiveDatabase.budgetsBox.values.where((b) => !b.isSynced).toList();
    final unsyncedRules = HiveDatabase.recurringRulesBox.values.where((r) => !r.isSynced).toList();

    // If there is no token (user is guest/offline), skip syncing
    final token = HiveDatabase.settingsBox.get('token');
    if (token == null) return;

    // Retrieve last sync timestamp
    final lastSyncStr = HiveDatabase.settingsBox.get('last_sync_time') as String?;
    final lastSyncTime = lastSyncStr != null ? DateTime.parse(lastSyncStr) : null;

    final requestBody = {
      'lastSyncTime': lastSyncTime?.toIso8601String(),
      'expenses': unsyncedExpenses.map((e) => e.toJson()).toList(),
      'budgets': unsyncedBudgets.map((b) => b.toJson()).toList(),
      'recurringRules': unsyncedRules.map((r) => r.toJson()).toList(),
    };

    try {
      final response = await ApiClient.post('/sync', requestBody);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        
        // Update local sync timestamp
        final serverSyncTime = data['serverSyncTime'] as String;
        await HiveDatabase.settingsBox.put('last_sync_time', serverSyncTime);

        // Process incoming expenses from server
        final serverExpenses = (data['expenses'] as List)
            .map((e) => ExpenseModel.fromJson(e as Map<String, dynamic>))
            .toList();
        for (var expense in serverExpenses) {
          final local = HiveDatabase.expensesBox.get(expense.id);
          if (local == null || expense.lastUpdated.isAfter(local.lastUpdated)) {
            await HiveDatabase.expensesBox.put(expense.id, expense);
          }
        }

        // Process incoming budgets from server
        final serverBudgets = (data['budgets'] as List)
            .map((b) => BudgetModel.fromJson(b as Map<String, dynamic>))
            .toList();
        for (var budget in serverBudgets) {
          final local = HiveDatabase.budgetsBox.get(budget.id);
          if (local == null || budget.lastUpdated.isAfter(local.lastUpdated)) {
            await HiveDatabase.budgetsBox.put(budget.id, budget);
          }
        }

        // Process incoming recurring rules from server
        final serverRules = (data['recurringRules'] as List)
            .map((r) => RecurringRuleModel.fromJson(r as Map<String, dynamic>))
            .toList();
        for (var rule in serverRules) {
          final local = HiveDatabase.recurringRulesBox.get(rule.id);
          if (local == null || rule.lastUpdated.isAfter(local.lastUpdated)) {
            await HiveDatabase.recurringRulesBox.put(rule.id, rule);
          }
        }

        // Mark previously unsynced items as synced
        for (var e in unsyncedExpenses) {
          final current = HiveDatabase.expensesBox.get(e.id);
          if (current != null && !current.isSynced) {
            await HiveDatabase.expensesBox.put(e.id, current.copyWith(isSynced: true));
          }
        }
        for (var b in unsyncedBudgets) {
          final current = HiveDatabase.budgetsBox.get(b.id);
          if (current != null && !current.isSynced) {
            await HiveDatabase.budgetsBox.put(b.id, current.copyWith(isSynced: true));
          }
        }
        for (var r in unsyncedRules) {
          final current = HiveDatabase.recurringRulesBox.get(r.id);
          if (current != null && !current.isSynced) {
            await HiveDatabase.recurringRulesBox.put(r.id, current.copyWith(isSynced: true));
          }
        }
      } else {
        throw Exception('Server returned status code ${response.statusCode}');
      }
    } catch (e) {
      // Offline or network error; fail silently for background sync
      rethrow;
    }
  }
}
