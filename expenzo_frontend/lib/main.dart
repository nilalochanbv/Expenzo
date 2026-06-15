import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/database/hive_database.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/pages/auth_screen.dart';
import 'features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'features/expense/data/repositories/expense_repository_impl.dart';
import 'features/expense/domain/repositories/expense_repository.dart';
import 'features/expense/presentation/viewmodels/expense_viewmodel.dart';
import 'features/budget/presentation/viewmodels/budget_viewmodel.dart';
import 'features/insight/presentation/viewmodels/insight_viewmodel.dart';
import 'features/shared/presentation/pages/main_navigation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive
  await HiveDatabase.init();

  // Create repository instance
  final ExpenseRepository expenseRepository = ExpenseRepositoryImpl();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
        ChangeNotifierProxyProvider<AuthViewModel, ExpenseViewModel>(
          create: (_) => ExpenseViewModel(repository: expenseRepository),
          update: (_, auth, expenseVm) {
            // Trigger sync automatically when user logs in
            if (auth.isLoggedIn && expenseVm != null) {
              expenseVm.sync();
            }
            return expenseVm ?? ExpenseViewModel(repository: expenseRepository);
          },
        ),
        ChangeNotifierProvider(create: (_) => BudgetViewModel(repository: expenseRepository)),
        ChangeNotifierProvider(create: (_) => InsightViewModel(repository: expenseRepository)),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Expenzo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: Consumer<AuthViewModel>(
        builder: (context, authVm, child) {
          if (authVm.isLoggedIn) {
            return const MainNavigation();
          } else {
            return const AuthScreen();
          }
        },
      ),
    );
  }
}
