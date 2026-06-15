import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/nlp/local_nlp_parser.dart';
import '../../../expense/presentation/viewmodels/expense_viewmodel.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    // Clear search query in ViewModel on open
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ExpenseViewModel>(context, listen: false).search('');
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    Provider.of<ExpenseViewModel>(context, listen: false).search(_searchController.text);
  }

  @override
  Widget build(BuildContext context) {
    final expenseViewModel = Provider.of<ExpenseViewModel>(context);
    final results = expenseViewModel.expenses.where((e) {
      if (_selectedCategory.isEmpty) return true;
      return e.category.toLowerCase() == _selectedCategory.toLowerCase();
    }).toList();

    final total = results.fold(0.0, (sum, e) => sum + e.amount);
    final numberFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    final List<String> categories = [
      'Petrol', 'Groceries', 'Food', 'Entertainment', 'Rent', 'Bills', 'Shopping', 'Education', 'Health'
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Search Transactions', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Search Box
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              decoration: InputDecoration(
                hintText: 'Search "petrol", "milk", etc...',
                prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.textSecondary),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, color: AppTheme.textSecondary),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
              ),
            ),
          ),

          // Filter Chips
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final cat = categories[index];
                final isSelected = _selectedCategory.toLowerCase() == cat.toLowerCase();
                final emoji = LocalNlpParser.getCategoryEmoji(cat);

                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: FilterChip(
                    avatar: Text(emoji),
                    label: Text(cat),
                    selected: isSelected,
                    selectedColor: AppTheme.accentColor.withOpacity(0.3),
                    checkmarkColor: AppTheme.accentColor,
                    backgroundColor: AppTheme.cardColor,
                    side: BorderSide(color: isSelected ? AppTheme.accentColor : Colors.white.withOpacity(0.05)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedCategory = cat;
                        } else {
                          _selectedCategory = '';
                        }
                      });
                    },
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 16),

          // Total Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total matching:',
                    style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    numberFormat.format(total),
                    style: const TextStyle(color: AppTheme.accentColor, fontWeight: FontWeight.w800, fontSize: 18),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Search Results List
          Expanded(
            child: results.isEmpty
                ? Center(
                    child: Text(
                      _searchController.text.isEmpty && _selectedCategory.isEmpty
                          ? 'Start typing to search...'
                          : 'No matching transactions found.',
                      style: const TextStyle(color: AppTheme.textSecondary),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: results.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = results[index];
                      final emoji = LocalNlpParser.getCategoryEmoji(item.category);
                      final formattedDate = DateFormat('dd MMM yyyy, hh:mm a').format(item.createdAt);

                      return Container(
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
                                  Text(
                                    formattedDate,
                                    style: const TextStyle(
                                      color: AppTheme.textSecondary,
                                      fontSize: 12,
                                    ),
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
                      ).animate().fadeIn(delay: (index * 30).ms).slideY(begin: 0.05, end: 0);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
