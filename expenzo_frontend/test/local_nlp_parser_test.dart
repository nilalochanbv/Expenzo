import 'package:flutter_test/flutter_test.dart';
import 'package:expenzo_frontend/core/nlp/local_nlp_parser.dart';

void main() {
  group('LocalNlpParser Tests', () {
    test('should parse petrol and amount correctly', () {
      final result = LocalNlpParser.parse('petrol 1000');
      expect(result.amount, 1000.0);
      expect(result.category, 'Petrol');
      expect(result.description, 'Petrol');
    });

    test('should parse milk and amount correctly', () {
      final result = LocalNlpParser.parse('milk 120');
      expect(result.amount, 120.0);
      expect(result.category, 'Groceries');
      expect(result.description, 'Milk');
    });

    test('should handle prepositions like "spent" and "on"', () {
      final result = LocalNlpParser.parse('spent 15000 on rent');
      expect(result.amount, 15000.0);
      expect(result.category, 'Rent');
      expect(result.description, 'Rent');
    });

    test('should parse relative dates like "yesterday"', () {
      final result = LocalNlpParser.parse('movie 350 yesterday');
      expect(result.amount, 350.0);
      expect(result.category, 'Entertainment');
      expect(result.description, 'Movie');
      
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      expect(result.createdAt.day, yesterday.day);
      expect(result.createdAt.month, yesterday.month);
      expect(result.createdAt.year, yesterday.year);
    });

    test('should fallback gracefully for empty or invalid text', () {
      final result = LocalNlpParser.parse('');
      expect(result.amount, 0.0);
      expect(result.category, 'Others');
      expect(result.description, 'Expense');
    });
  });
}
