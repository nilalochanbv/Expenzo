import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/nlp/local_nlp_parser.dart';
import '../../../expense/presentation/viewmodels/expense_viewmodel.dart';
import '../../../insight/presentation/viewmodels/insight_viewmodel.dart';

class CategoryDetailsScreen extends StatelessWidget {
  final String categoryName;

  const CategoryDetailsScreen({super.key, required this.categoryName});

  @override
  Widget build(BuildContext context) {
    final expenseViewModel = Provider.of<ExpenseViewModel>(context);
    final insightViewModel = Provider.of<InsightViewModel>(context);

    final String emoji = LocalNlpParser.getCategoryEmoji(categoryName);
    final numberFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

    // Fetch transactions in this category
    final transactions = expenseViewModel.expenses
        .where((e) => e.category.toLowerCase() == categoryName.toLowerCase())
        .toList();

    // Get MoM comparison for this category
    final comp = insightViewModel.comparisons.firstWhere(
      (c) => c.category.toLowerCase() == categoryName.toLowerCase(),
      orElse: () => CategoryComparison(
        category: categoryName,
        juneAmount: 0.0,
        julyAmount: 0.0,
        difference: 0.0,
        percentageChange: 0.0,
      ),
    );

    final diffSign = comp.difference >= 0 ? '+' : '';
    final diffColor = comp.difference >= 0 ? AppTheme.dangerColor : AppTheme.successColor;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('$emoji $categoryName Breakdown'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // MoM Summary Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'This Month Spending',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    numberFormat.format(comp.julyAmount),
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 32),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Last Month', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                          const SizedBox(height: 4),
                          Text(numberFormat.format(comp.juneAmount), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('Difference', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                          const SizedBox(height: 4),
                          Text(
                            '$diffSign${numberFormat.format(comp.difference)} (${comp.percentageChange.toStringAsFixed(1)}%)',
                            style: TextStyle(color: diffColor, fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ).animate().fadeIn().slideY(begin: 0.1, end: 0),

            const SizedBox(height: 30),

            // Transaction History
            const Text(
              'Transaction History',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ).animate().fadeIn(delay: 100.ms),
            const SizedBox(height: 12),

            if (transactions.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Text('No transactions in this category.', style: TextStyle(color: AppTheme.textSecondary)),
                ),
              ).animate().fadeIn(delay: 200.ms)
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: transactions.length,
                separatorBuilder: (context, index) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final item = transactions[index];
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.05)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.description,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                dateFormat.format(item.createdAt),
                                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          numberFormat.format(item.amount),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: (index * 50).ms).slideY(begin: 0.05, end: 0);
                },
              ),
          ],
        ),
      ),
    );
  }
}
