import 'package:hive_flutter/hive_flutter.dart';
import '../../features/expense/data/models/expense_model.dart';
import '../../features/budget/data/models/budget_model.dart';
import '../../features/expense/data/models/recurring_rule_model.dart';

class HiveDatabase {
  static const String expensesBoxName = 'expenses';
  static const String budgetsBoxName = 'budgets';
  static const String recurringRulesBoxName = 'recurring_rules';
  static const String settingsBoxName = 'settings';

  static Future<void> init() async {
    await Hive.initFlutter();

    // Register Hive adapters
    Hive.registerAdapter(ExpenseModelAdapter());
    Hive.registerAdapter(BudgetModelAdapter());
    Hive.registerAdapter(RecurringRuleModelAdapter());

    // Open boxes
    await Hive.openBox<ExpenseModel>(expensesBoxName);
    await Hive.openBox<BudgetModel>(budgetsBoxName);
    await Hive.openBox<RecurringRuleModel>(recurringRulesBoxName);
    await Hive.openBox(settingsBoxName);
  }

  static Box<ExpenseModel> get expensesBox => Hive.box<ExpenseModel>(expensesBoxName);
  static Box<BudgetModel> get budgetsBox => Hive.box<BudgetModel>(budgetsBoxName);
  static Box<RecurringRuleModel> get recurringRulesBox => Hive.box<RecurringRuleModel>(recurringRulesBoxName);
  static Box get settingsBox => Hive.box(settingsBoxName);
}
