import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../expense/presentation/viewmodels/expense_viewmodel.dart';
import '../../../insight/presentation/viewmodels/insight_viewmodel.dart';

class MonthComparisonScreen extends StatelessWidget {
  const MonthComparisonScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final expenseViewModel = Provider.of<ExpenseViewModel>(context);
    final insightViewModel = Provider.of<InsightViewModel>(context);

    final currentTotal = expenseViewModel.monthlyTotal;
    final lastTotal = expenseViewModel.lastMonthTotal;
    final diffPct = expenseViewModel.percentageChange;
    final comparisons = insightViewModel.comparisons;

    final now = DateTime.now();
    final currentMonthName = DateFormat('MMMM').format(now);
    final lastMonthName = DateFormat('MMMM').format(DateTime(now.year, now.month - 1));

    final numberFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Spending Trends', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Month Header Summary
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(lastMonthName, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
                          const SizedBox(height: 4),
                          Text(numberFormat.format(lastTotal), style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const Icon(Icons.compare_arrows_rounded, color: AppTheme.accentColor, size: 28),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(currentMonthName, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
                          const SizedBox(height: 4),
                          Text(numberFormat.format(currentTotal), style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                  const Divider(height: 30, color: Colors.white10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        diffPct >= 0 ? 'Increase of ' : 'Decrease of ',
                        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 15),
                      ),
                      Text(
                        '${diffPct >= 0 ? '+' : ''}${diffPct.toStringAsFixed(1)}%',
                        style: TextStyle(
                          color: diffPct >= 0 ? AppTheme.dangerColor : AppTheme.successColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 30),

            // Animated Bar Chart of Category Comparison
            Text('Category Comparison Chart', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            if (comparisons.isEmpty)
              const Center(child: Text('Not enough data to display comparison chart.', style: TextStyle(color: AppTheme.textSecondary)))
            else
              Container(
                height: 220,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                ),
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: comparisons.map((c) => c.julyAmount > c.juneAmount ? c.julyAmount : c.juneAmount).reduce((a, b) => a > b ? a : b) * 1.1,
                    barTouchData: BarTouchData(enabled: true),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (double value, TitleMeta meta) {
                            int idx = value.toInt();
                            if (idx >= 0 && idx < comparisons.length) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  comparisons[idx].category.substring(0, Math.min(4, comparisons[idx].category.length)),
                                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10),
                                ),
                              );
                            }
                            return const Text('');
                          },
                        ),
                      ),
                      leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(show: false),
                    gridData: const FlGridData(show: false),
                    barGroups: List.generate(comparisons.length, (index) {
                      final item = comparisons[index];
                      return BarChartGroupData(
                        x: index,
                        barRods: [
                          BarChartRodData(
                            toY: item.juneAmount,
                            color: AppTheme.textSecondary.withOpacity(0.4),
                            width: 10,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          BarChartRodData(
                            toY: item.julyAmount,
                            color: AppTheme.accentColor,
                            width: 10,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ],
                      );
                    }),
                  ),
                ),
              ),

            const SizedBox(height: 30),

            // Category Comparison List
            Text('Category Details', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            if (comparisons.isEmpty)
              const Center(child: Text('No transactions recorded for comparison.', style: TextStyle(color: AppTheme.textSecondary)))
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: comparisons.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final comp = comparisons[index];
                  final diffColor = comp.difference >= 0 ? AppTheme.dangerColor : AppTheme.successColor;
                  final diffSign = comp.difference >= 0 ? '+' : '';

                  return Container(
                    padding: const EdgeInsets.all(16),
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
                            Text(
                              comp.category,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                            ),
                            Text(
                              '$diffSign${numberFormat.format(comp.difference)}',
                              style: TextStyle(color: diffColor, fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '$lastMonthName: ${numberFormat.format(comp.juneAmount)}',
                              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                            ),
                            Text(
                              '$currentMonthName: ${numberFormat.format(comp.julyAmount)}',
                              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

// Quick helper to avoid dart:math dependency import
class Math {
  static int min(int a, int b) => a < b ? a : b;
}
