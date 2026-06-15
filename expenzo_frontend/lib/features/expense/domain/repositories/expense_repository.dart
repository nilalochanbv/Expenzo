import '../../data/models/expense_model.dart';
import '../../../budget/data/models/budget_model.dart';
import '../../data/models/recurring_rule_model.dart';

abstract class ExpenseRepository {
  // Expense operations
  List<ExpenseModel> getExpenses();
  Future<void> saveExpense(ExpenseModel expense);
  Future<void> deleteExpense(String id);
  List<ExpenseModel> searchExpenses(String query);

  // Budget operations
  List<BudgetModel> getBudgets();
  Future<void> saveBudget(BudgetModel budget);
  Future<void> deleteBudget(String id);

  // Recurring rules
  List<RecurringRuleModel> getRecurringRules();
  Future<void> saveRecurringRule(RecurringRuleModel rule);
  Future<void> deleteRecurringRule(String id);

  // Sync operation
  Future<void> syncWithServer();
}
