import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../budget/presentation/viewmodels/budget_viewmodel.dart';
import '../../../expense/presentation/viewmodels/expense_viewmodel.dart';
import '../../../insight/presentation/viewmodels/insight_viewmodel.dart';
import 'home_dashboard.dart';
import 'month_comparison_screen.dart';
import 'budgets_screen.dart';
import 'insights_screen.dart';
import 'quick_add_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const HomeDashboard(),
    const MonthComparisonScreen(),
    const BudgetsScreen(),
    const InsightsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final expenseViewModel = Provider.of<ExpenseViewModel>(context);
    final budgetViewModel = Provider.of<BudgetViewModel>(context);
    final insightViewModel = Provider.of<InsightViewModel>(context);

    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: _currentIndex,
          children: _pages,
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          border: Border(
            top: BorderSide(color: Colors.white.withOpacity(0.05), width: 1),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
            // Refresh insights on navigating
            if (index == 1 || index == 3) {
              insightViewModel.generateInsightsAndComparisons(expenseViewModel.expenses);
            }
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppTheme.cardColor,
          selectedItemColor: AppTheme.accentColor,
          unselectedItemColor: AppTheme.textSecondary,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart_outlined),
              activeIcon: Icon(Icons.bar_chart_rounded),
              label: 'Trends',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.account_balance_wallet_outlined),
              activeIcon: Icon(Icons.account_balance_wallet),
              label: 'Budgets',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.lightbulb_outline),
              activeIcon: Icon(Icons.lightbulb),
              label: 'Insights',
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) => const QuickAddScreen(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                const begin = Offset(0.0, 1.0);
                const end = Offset.zero;
                const curve = Curves.fastOutSlowIn;
                var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                return SlideTransition(position: animation.drive(tween), child: child);
              },
            ),
          );
        },
        backgroundColor: AppTheme.accentColor,
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.add_rounded, size: 28),
        label: const Text(
          "Quick Add",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
