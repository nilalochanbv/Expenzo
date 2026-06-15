import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:excel/excel.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../database/hive_database.dart';
import '../../features/expense/data/models/expense_model.dart';
import '../../features/budget/data/models/budget_model.dart';
import '../../features/expense/data/models/recurring_rule_model.dart';

class ExportHelper {
  static Future<void> exportPdf(List<ExpenseModel> expenses) async {
    final pdf = pw.Document();
    final numberFormat = NumberFormat.currency(locale: 'en_IN', symbol: 'Rs ', decimalDigits: 2);
    final dateFormat = DateFormat('dd-MMM-yyyy HH:mm');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Expenzo - Expense Report', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                pw.Text(DateFormat('dd-MMM-yyyy').format(DateTime.now())),
              ],
            ),
          ),
          pw.SizedBox(height: 20),
          pw.Text(
            'Total Expenses: ${numberFormat.format(expenses.fold(0.0, (sum, e) => sum + e.amount))}',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.Text('Total Transactions: ${expenses.length}', style: const pw.TextStyle(fontSize: 12)),
          pw.SizedBox(height: 20),
          pw.Table(
            border: pw.TableBorder.all(width: 0.5, color: PdfColors.grey),
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFF111827)),
                children: [
                  pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Date', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white))),
                  pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Description', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white))),
                  pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Category', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white))),
                  pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Amount', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white))),
                ],
              ),
              ...expenses.map((e) => pw.TableRow(
                children: [
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(dateFormat.format(e.createdAt))),
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(e.description)),
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(e.category)),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Container(
                      alignment: pw.Alignment.centerRight,
                      child: pw.Text(numberFormat.format(e.amount)),
                    ),
                  ),
                ],
              )),
            ],
          ),
        ],
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File('${output.path}/expenzo-report.pdf');
    await file.writeAsBytes(await pdf.save());

    await Share.shareXFiles([XFile(file.path)], text: 'Expenzo Expense Report');
  }

  static Future<void> exportExcel(List<ExpenseModel> expenses) async {
    final excel = Excel.createExcel();
    final Sheet sheet = excel['Expenses'];
    excel.delete('Sheet1'); // Remove default sheet

    // Headers
    sheet.appendRow([
      TextCellValue('Date'),
      TextCellValue('Description'),
      TextCellValue('Category'),
      TextCellValue('Amount'),
    ]);

    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');

    for (var e in expenses) {
      sheet.appendRow([
        TextCellValue(dateFormat.format(e.createdAt)),
        TextCellValue(e.description),
        TextCellValue(e.category),
        DoubleCellValue(e.amount),
      ]);
    }

    final output = await getTemporaryDirectory();
    final file = File('${output.path}/expenzo-report.xlsx');
    final bytes = excel.save();
    if (bytes != null) {
      await file.writeAsBytes(bytes);
      await Share.shareXFiles([XFile(file.path)], text: 'Expenzo Excel Report');
    }
  }

  static String generateBackupString() {
    final expenses = HiveDatabase.expensesBox.values.map((e) => e.toJson()).toList();
    final budgets = HiveDatabase.budgetsBox.values.map((b) => b.toJson()).toList();
    final rules = HiveDatabase.recurringRulesBox.values.map((r) => r.toJson()).toList();

    final backupMap = {
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'expenses': expenses,
      'budgets': budgets,
      'recurringRules': rules,
    };

    return jsonEncode(backupMap);
  }

  static Future<bool> restoreFromBackupString(String backupJson) async {
    try {
      final decoded = jsonDecode(backupJson) as Map<String, dynamic>;
      if (decoded['version'] != 1) return false;

      // Restore expenses
      final expensesList = decoded['expenses'] as List;
      await HiveDatabase.expensesBox.clear();
      for (var item in expensesList) {
        final exp = ExpenseModel.fromJson(item as Map<String, dynamic>);
        await HiveDatabase.expensesBox.put(exp.id, exp);
      }

      // Restore budgets
      final budgetsList = decoded['budgets'] as List;
      await HiveDatabase.budgetsBox.clear();
      for (var item in budgetsList) {
        final b = BudgetModel.fromJson(item as Map<String, dynamic>);
        await HiveDatabase.budgetsBox.put(b.id, b);
      }

      // Restore recurring rules
      final rulesList = decoded['recurringRules'] as List;
      await HiveDatabase.recurringRulesBox.clear();
      for (var item in rulesList) {
        final r = RecurringRuleModel.fromJson(item as Map<String, dynamic>);
        await HiveDatabase.recurringRulesBox.put(r.id, r);
      }

      return true;
    } catch (e) {
      print('Backup restore error: $e');
      return false;
    }
  }
}
