import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/nlp/local_nlp_parser.dart';
import '../../../auth/presentation/viewmodels/auth_viewmodel.dart';
import '../../../expense/presentation/viewmodels/expense_viewmodel.dart';
import 'category_details_screen.dart';
import 'search_screen.dart';

class HomeDashboard extends StatelessWidget {
  const HomeDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final expenseViewModel = Provider.of<ExpenseViewModel>(context);
    final authViewModel = Provider.of<AuthViewModel>(context);

    final String name = authViewModel.userName ?? "Guest";
    final double total = expenseViewModel.monthlyTotal;
    final double change = expenseViewModel.percentageChange;
    final Map<String, double> topCats = expenseViewModel.topCategories;
    final recent = expenseViewModel.recentExpenses;

    final numberFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppTheme.accentColor.withOpacity(0.2),
              child: Text(
                name[0].toUpperCase(),
                style: const TextStyle(color: AppTheme.accentColor, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hello, $name',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18),
                ),
                Text(
                  'Manage your expenses easily',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SearchScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () {
              authViewModel.logout();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await expenseViewModel.sync();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Monthly Total Card
              Card(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.cardColor,
                        AppTheme.accentColor.withOpacity(0.08),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(color: Colors.white.withOpacity(0.05)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Monthly Total',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0, end: total),
                        duration: 1.seconds,
                        curve: Curves.easeOutCubic,
                        builder: (context, value, child) {
                          return Text(
                            numberFormat.format(value),
                            style: Theme.of(context).textTheme.displayLarge?.copyWith(
                              color: AppTheme.textPrimary,
                              letterSpacing: -0.5,
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            change >= 0 ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                            size: 16,
                            color: change >= 0 ? AppTheme.dangerColor : AppTheme.successColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${change >= 0 ? '+' : ''}${change.toStringAsFixed(1)}%',
                            style: TextStyle(
                              color: change >= 0 ? AppTheme.dangerColor : AppTheme.successColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'compared to last month',
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),
              
              const SizedBox(height: 30),

              // Top Categories Section
              if (topCats.isNotEmpty) ...[
                Text(
                  'Top Categories',
                  style: Theme.of(context).textTheme.titleLarge,
                ).animate().fadeIn(delay: 100.ms),
                const SizedBox(height: 12),
                SizedBox(
                  height: 110,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: topCats.length,
                    itemBuilder: (context, index) {
                      final category = topCats.keys.elementAt(index);
                      final amount = topCats[category]!;
                      final emoji = LocalNlpParser.getCategoryEmoji(category);
                      
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CategoryDetailsScreen(categoryName: category),
                            ),
                          );
                        },
                        child: Container(
                          width: 120,
                          margin: const EdgeInsets.only(right: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.cardColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white.withOpacity(0.05)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                emoji,
                                style: const TextStyle(fontSize: 24),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                category,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                numberFormat.format(amount),
                                style: const TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ).animate().fadeIn(delay: 200.ms).slideX(begin: 0.05, end: 0),
                const SizedBox(height: 30),
              ],

              // Recent Expenses Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent Expenses',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  if (recent.isNotEmpty)
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const SearchScreen()),
                        );
                      },
                      child: const Text('View All', style: TextStyle(color: AppTheme.accentColor)),
                    ),
                ],
              ).animate().fadeIn(delay: 200.ms),
              const SizedBox(height: 12),

              if (recent.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(30),
                  alignment: Alignment.center,
                  child: Column(
                    children: [
                      Icon(Icons.receipt_long_outlined, size: 48, color: AppTheme.textSecondary.withOpacity(0.5)),
                      const SizedBox(height: 12),
                      const Text(
                        'No expenses logged yet.',
                        style: TextStyle(color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 300.ms)
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: recent.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final item = recent[index];
                    final emoji = LocalNlpParser.getCategoryEmoji(item.category);
                    final formattedDate = DateFormat('dd MMM').format(item.createdAt);

                    return Dismissible(
                      key: Key(item.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        decoration: BoxDecoration(
                          color: AppTheme.dangerColor,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.delete_outline, color: Colors.white),
                      ),
                      onDismissed: (direction) async {
                        await expenseViewModel.deleteExpense(item.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Expense deleted')),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withOpacity(0.05)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.05),
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                emoji,
                                style: const TextStyle(fontSize: 20),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.description,
                                    style: const TextStyle(
                                      color: AppTheme.textPrimary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Text(
                                        item.category,
                                        style: const TextStyle(
                                          color: AppTheme.textSecondary,
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        width: 4,
                                        height: 4,
                                        decoration: const BoxDecoration(
                                          color: AppTheme.textSecondary,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        formattedDate,
                                        style: const TextStyle(
                                          color: AppTheme.textSecondary,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              numberFormat.format(item.amount),
                              style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.05, end: 0),
            ],
          ),
        ),
      ),
    );
  }
}
