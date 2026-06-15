class LocalNlpResult {
  final String description;
  final double amount;
  final String category;
  final DateTime createdAt;

  LocalNlpResult({
    required this.description,
    required this.amount,
    required this.category,
    required this.createdAt,
  });
}

class LocalNlpParser {
  static final Map<String, String> _keywordToCategory = {
    // Petrol / Transport
    'petrol': 'Petrol',
    'diesel': 'Petrol',
    'fuel': 'Petrol',
    'gas': 'Petrol',
    'cab': 'Petrol',
    'cabs': 'Petrol',
    'uber': 'Petrol',
    'ola': 'Petrol',
    'auto': 'Petrol',
    'bus': 'Petrol',
    'train': 'Petrol',
    'metro': 'Petrol',
    'flight': 'Petrol',
    'ticket': 'Petrol',
    'travel': 'Petrol',

    // Groceries
    'milk': 'Groceries',
    'vegetables': 'Groceries',
    'vegetable': 'Groceries',
    'fruits': 'Groceries',
    'fruit': 'Groceries',
    'grocery': 'Groceries',
    'groceries': 'Groceries',
    'supermarket': 'Groceries',
    'mart': 'Groceries',
    'egg': 'Groceries',
    'eggs': 'Groceries',
    'bread': 'Groceries',
    'butter': 'Groceries',
    'cheese': 'Groceries',
    'paneer': 'Groceries',

    // Food
    'food': 'Food',
    'restaurant': 'Food',
    'dinner': 'Food',
    'lunch': 'Food',
    'breakfast': 'Food',
    'cafe': 'Food',
    'coffee': 'Food',
    'tea': 'Food',
    'starbucks': 'Food',
    'pizza': 'Food',
    'burger': 'Food',
    'swiggy': 'Food',
    'zomato': 'Food',
    'snacks': 'Food',

    // Entertainment
    'movie': 'Entertainment',
    'movies': 'Entertainment',
    'cinema': 'Entertainment',
    'theater': 'Entertainment',
    'netflix': 'Entertainment',
    'spotify': 'Entertainment',
    'game': 'Entertainment',
    'gaming': 'Entertainment',
    'concert': 'Entertainment',
    'show': 'Entertainment',
    'bookmyshow': 'Entertainment',

    // Rent
    'rent': 'Rent',
    'house rent': 'Rent',
    'maintenance': 'Rent',
    'pg': 'Rent',
    'hostel': 'Rent',

    // Bills
    'electricity': 'Bills',
    'water': 'Bills',
    'wifi': 'Bills',
    'internet': 'Bills',
    'broadband': 'Bills',
    'recharge': 'Bills',
    'mobile bill': 'Bills',
    'phone bill': 'Bills',
    'insurance': 'Bills',
    'subscription': 'Bills',

    // Shopping
    'shopping': 'Shopping',
    'clothes': 'Shopping',
    'shirt': 'Shopping',
    'pant': 'Shopping',
    'shoes': 'Shopping',
    'dress': 'Shopping',
    'amazon': 'Shopping',
    'flipkart': 'Shopping',
    'myntra': 'Shopping',

    // Education
    'book': 'Education',
    'books': 'Education',
    'course': 'Education',
    'udemy': 'Education',
    'fees': 'Education',
    'school': 'Education',
    'college': 'Education',
    'tuition': 'Education',

    // Health
    'doctor': 'Health',
    'medicine': 'Health',
    'medicines': 'Health',
    'pharmacy': 'Health',
    'hospital': 'Health',
    'clinic': 'Health',
    'gym': 'Health',
    'workout': 'Health',
  };

  static LocalNlpResult parse(String text) {
    if (text.trim().isEmpty) {
      return LocalNlpResult(
        description: 'Expense',
        amount: 0.0,
        category: 'Others',
        createdAt: DateTime.now(),
      );
    }

    String cleaned = text.trim();

    // 1. Extract amount (first number match)
    final RegExp numberRegex = RegExp(r'(?<!\d)\d+(?:\.\d+)?(?!\d)');
    final Match? match = numberRegex.firstMatch(cleaned);

    double amount = 0.0;
    String amountStr = '';
    if (match != null) {
      amountStr = match.group(0)!;
      amount = double.tryParse(amountStr) ?? 0.0;
    }

    // 2. Remove amount and currency terms
    String textWithoutAmount = cleaned.replaceFirst(amountStr, '');
    textWithoutAmount = textWithoutAmount.replaceAll(
        RegExp(r'\b(rs|rupees|inr|usd|eur|\$|₹|spent|paid|for|at|on)\b', caseSensitive: false),
        '');
    textWithoutAmount = textWithoutAmount.replaceAll(RegExp(r'\s+'), ' ').trim();

    // 3. Parse Date
    DateTime createdAt = DateTime.now();
    String lowercaseText = textWithoutAmount.toLowerCase();

    if (lowercaseText.contains('yesterday')) {
      createdAt = DateTime.now().subtract(const Duration(days: 1));
      textWithoutAmount = textWithoutAmount.replaceAll(
          RegExp(r'\byesterday\b', caseSensitive: false), '');
    } else if (lowercaseText.contains('today')) {
      textWithoutAmount = textWithoutAmount.replaceAll(
          RegExp(r'\btoday\b', caseSensitive: false), '');
    }
    
    textWithoutAmount = textWithoutAmount.replaceAll(RegExp(r'\s+'), ' ').trim();

    // 4. Extract Category and Description
    String description = textWithoutAmount;
    if (description.isEmpty) {
      description = 'Expense';
    }

    String category = 'Others';
    List<String> words = description.toLowerCase().split(RegExp(r'\s+'));
    for (var word in words) {
      if (_keywordToCategory.containsKey(word)) {
        category = _keywordToCategory[word]!;
        break;
      }
    }

    // Fallback search inside description
    if (category == 'Others') {
      for (var key in _keywordToCategory.keys) {
        if (description.toLowerCase().contains(key)) {
          category = _keywordToCategory[key]!;
          break;
        }
      }
    }

    // Capitalize first letter of description
    if (description.isNotEmpty) {
      description = description[0].toUpperCase() + description.substring(1);
    }

    return LocalNlpResult(
      description: description,
      amount: amount,
      category: category,
      createdAt: createdAt,
    );
  }

  static String getCategoryEmoji(String category) {
    switch (category.toLowerCase()) {
      case 'petrol':
        return '⛽';
      case 'groceries':
        return '🥬';
      case 'food':
        return '🍔';
      case 'entertainment':
        return '🎬';
      case 'rent':
        return '🏠';
      case 'bills':
        return '📱';
      case 'shopping':
        return '🛍️';
      case 'education':
        return '📚';
      case 'health':
        return '🏥';
      default:
        return '💰';
    }
  }
}
