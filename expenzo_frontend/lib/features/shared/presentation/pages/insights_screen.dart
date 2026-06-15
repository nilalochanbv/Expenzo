import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/export_helper.dart';
import '../../../expense/presentation/viewmodels/expense_viewmodel.dart';
import '../../../insight/presentation/viewmodels/insight_viewmodel.dart';

class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  void _showRestoreDialog(BuildContext context, ExpenseViewModel expenseViewModel) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        title: const Text('Restore Backup'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Paste the backup code below to restore your data. Warning: This will overwrite current data.',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: 'Paste backup JSON string here...',
                hintStyle: TextStyle(color: Colors.white24, fontSize: 12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              final success = await ExportHelper.restoreFromBackupString(controller.text);
              if (success) {
                expenseViewModel.loadExpenses();
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Backup restored successfully!')),
                  );
                }
              } else {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Failed to restore. Invalid backup data.')),
                  );
                }
              }
            },
            child: const Text('Restore', style: TextStyle(color: AppTheme.accentColor)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final expenseViewModel = Provider.of<ExpenseViewModel>(context);
    final insightViewModel = Provider.of<InsightViewModel>(context);

    final insights = insightViewModel.insights;
    final recurring = insightViewModel.recurringSuggestions;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Smart Insights', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section: Insights List
            const Text('Insights', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 12),
            if (insights.isEmpty)
              const Text('No insights generated yet. Add more expenses first.', style: TextStyle(color: AppTheme.textSecondary))
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: insights.length,
                separatorBuilder: (context, index) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final isWarning = insights[index].contains('🚨') || insights[index].contains('⚠️');
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isWarning ? AppTheme.warningColor.withOpacity(0.3) : Colors.white.withOpacity(0.05),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          isWarning ? Icons.warning_amber_rounded : Icons.lightbulb_outline,
                          color: isWarning ? AppTheme.warningColor : AppTheme.accentColor,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            insights[index],
                            style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ).animate().fadeIn(),

            const SizedBox(height: 30),

            // Section: Recurring Detection
            if (recurring.isNotEmpty) ...[
              const Text('Recurring Expenses', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 12),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: recurring.length,
                separatorBuilder: (context, index) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
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
                          child: Text(
                            recurring[index],
                            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Recurring rule registered!')),
                            );
                          },
                          icon: const Icon(Icons.check, size: 16, color: AppTheme.successColor),
                          label: const Text('Add Rule', style: TextStyle(color: AppTheme.successColor, fontSize: 12)),
                        ),
                      ],
                    ),
                  );
                },
              ).animate().fadeIn(),
              const SizedBox(height: 30),
            ],

            // Section: Data & Utilities (Premium Tools)
            const Text('Data Utilities', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: Column(
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
                    title: const Text('Export PDF Statement', style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: const Text('Generate and share a clean PDF summary', style: TextStyle(fontSize: 12)),
                    onTap: () async {
                      HapticFeedback.lightImpact();
                      await ExportHelper.exportPdf(expenseViewModel.expenses);
                    },
                  ),
                  const Divider(color: Colors.white10),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.table_view_rounded, color: Colors.green),
                    title: const Text('Export Excel Sheet', style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: const Text('Download transaction history to spreadsheet', style: TextStyle(fontSize: 12)),
                    onTap: () async {
                      HapticFeedback.lightImpact();
                      await ExportHelper.exportExcel(expenseViewModel.expenses);
                    },
                  ),
                  const Divider(color: Colors.white10),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.backup_rounded, color: AppTheme.accentColor),
                    title: const Text('Backup Data', style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: const Text('Copy JSON backup to your clipboard', style: TextStyle(fontSize: 12)),
                    onTap: () {
                      HapticFeedback.lightImpact();
                      final backup = ExportHelper.generateBackupString();
                      Clipboard.setData(ClipboardData(text: backup));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Backup code copied to clipboard!')),
                      );
                    },
                  ),
                  const Divider(color: Colors.white10),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.restore_rounded, color: Colors.cyan),
                    title: const Text('Restore Backup', style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: const Text('Restore data from clipboard backup code', style: TextStyle(fontSize: 12)),
                    onTap: () => _showRestoreDialog(context, expenseViewModel),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 100.ms),
          ],
        ),
      ),
    );
  }
}
