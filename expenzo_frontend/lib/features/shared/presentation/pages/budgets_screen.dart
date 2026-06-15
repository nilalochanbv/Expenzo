import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/nlp/local_nlp_parser.dart';
import '../../../expense/presentation/viewmodels/expense_viewmodel.dart';
import '../../../budget/presentation/viewmodels/budget_viewmodel.dart';
import 'package:expenzo_frontend/features/budget/data/models/budget_model.dart';

class BudgetsScreen extends StatelessWidget {
  const BudgetsScreen({super.key});

  void _showSetBudgetSheet(BuildContext context) {
    final categoryController = TextEditingController();
    final limitController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final List<String> commonCategories = [
      'Petrol',
      'Groceries',
      'Food',
      'Entertainment',
      'Rent',
      'Bills',
      'Shopping',
      'Education',
      'Health',
    ];

    String selectedCategory = commonCategories.first;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                top: 24,
                left: 24,
                right: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Set Category Budget',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 20),
                    // Category Dropdown
                    DropdownButtonFormField<String>(
                      initialValue: selectedCategory,
                      decoration: const InputDecoration(labelText: 'Category'),
                      items: commonCategories.map((cat) {
                        return DropdownMenuItem(
                          value: cat,
                          child: Row(
                            children: [
                              Text(LocalNlpParser.getCategoryEmoji(cat)),
                              const SizedBox(width: 10),
                              Text(cat),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setModalState(() {
                            selectedCategory = val;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    // Limit Input
                    TextFormField(
                      controller: limitController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        labelText: 'Monthly Limit (₹)',
                        hintText: 'e.g. 5000',
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return 'Please enter an amount';
                        final num = double.tryParse(val);
                        if (num == null || num <= 0) return 'Please enter a valid positive amount';
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        if (formKey.currentState!.validate()) {
                          final limit = double.parse(limitController.text);
                          Provider.of<BudgetViewModel>(context, listen: false)
                              .setBudget(selectedCategory, limit);
                          HapticFeedback.mediumImpact();
                          Navigator.pop(context);
                        }
                      },
                      child: const Text('Save Budget'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final expenseViewModel = Provider.of<ExpenseViewModel>(context);
    final budgetViewModel = Provider.of<BudgetViewModel>(context);

    final budgets = budgetViewModel.budgets;
    final expenses = expenseViewModel.expenses;

    final numberFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Budgets', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, size: 28),
            onPressed: () => _showSetBudgetSheet(context),
          ),
        ],
      ),
      body: budgets.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.account_balance_wallet_outlined, size: 64, color: AppTheme.textSecondary.withOpacity(0.5)),
                  const SizedBox(height: 16),
                  const Text('No budgets configured yet.', style: TextStyle(color: AppTheme.textSecondary, fontSize: 16)),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => _showSetBudgetSheet(context),
                    child: const Text('Create Budget'),
                  ),
                ],
              ),
            ).animate().fadeIn()
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: budgets.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final budget = budgets[index];
                final spent = budgetViewModel.getSpentForBudget(budget, expenses);
                final progress = budgetViewModel.getBudgetProgress(budget, expenses);
                final emoji = LocalNlpParser.getCategoryEmoji(budget.category);
                
                // Color configuration based on progress
                Color progressColor = AppTheme.successColor;
                if (progress >= 1.0) {
                  progressColor = AppTheme.dangerColor;
                } else if (progress >= 0.9) {
                  progressColor = AppTheme.warningColor;
                } else if (progress >= 0.8) {
                  progressColor = Colors.orange;
                }

                return GestureDetector(
                  onLongPress: () {
                    HapticFeedback.heavyImpact();
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: AppTheme.cardColor,
                        title: const Text('Delete Budget?'),
                        content: Text('Are you sure you want to remove the budget for ${budget.category}?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
                          ),
                          TextButton(
                            onPressed: () {
                              budgetViewModel.deleteBudget(budget.id);
                              Navigator.pop(context);
                            },
                            child: const Text('Delete', style: TextStyle(color: AppTheme.dangerColor)),
                          ),
                        ],
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.05)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Text(emoji, style: const TextStyle(fontSize: 22)),
                                const SizedBox(width: 12),
                                Text(
                                  budget.category,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                                ),
                              ],
                            ),
                            Text(
                              '${(progress * 100).toStringAsFixed(0)}%',
                              style: TextStyle(color: progressColor, fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Custom progress bar
                        Stack(
                          children: [
                            Container(
                              height: 8,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            FractionallySizedBox(
                              widthFactor: progress > 1.0 ? 1.0 : progress,
                              child: Container(
                                height: 8,
                                decoration: BoxDecoration(
                                  color: progressColor,
                                  borderRadius: BorderRadius.circular(4),
                                  boxShadow: [
                                    BoxShadow(
                                      color: progressColor.withOpacity(0.3),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Spent: ${numberFormat.format(spent)}',
                              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                            ),
                            Text(
                              'Limit: ${numberFormat.format(budget.amountLimit)}',
                              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ).animate().fadeIn(delay: (index * 50).ms).slideY(begin: 0.05, end: 0);
              },
            ),
    );
  }
}
