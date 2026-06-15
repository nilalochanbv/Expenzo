import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/nlp/local_nlp_parser.dart';
import '../../../expense/presentation/viewmodels/expense_viewmodel.dart';
import '../../../budget/presentation/viewmodels/budget_viewmodel.dart';

class QuickAddScreen extends StatefulWidget {
  const QuickAddScreen({super.key});

  @override
  State<QuickAddScreen> createState() => _QuickAddScreenState();
}

class _QuickAddScreenState extends State<QuickAddScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  
  late stt.SpeechToText _speech;
  bool _isSpeechAvailable = false;
  bool _isListening = false;
  
  bool _isSuccess = false;
  
  String _detectedCategory = 'Others';
  double _detectedAmount = 0.0;
  String _detectedEmoji = '💰';

  final List<String> _suggestions = [
    'petrol 1000',
    'milk 100',
    'movie 350',
    'rent 15000',
    'dinner 1200',
    'shopping 2500'
  ];

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _initSpeech();
    
    _textController.addListener(_onTextChanged);
    
    // Auto focus the input field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_focusNode);
    });
  }

  @override
  void dispose() {
    _textController.removeListener(_onTextChanged);
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _initSpeech() async {
    try {
      _isSpeechAvailable = await _speech.initialize(
        onError: (val) => print('Speech init error: $val'),
        onStatus: (val) => print('Speech status: $val'),
      );
      if (mounted) setState(() {});
    } catch (e) {
      print('Speech initialization failed: $e');
    }
  }

  void _onTextChanged() {
    final text = _textController.text;
    final parsed = LocalNlpParser.parse(text);
    setState(() {
      _detectedCategory = parsed.category;
      _detectedAmount = parsed.amount;
      _detectedEmoji = LocalNlpParser.getCategoryEmoji(parsed.category);
    });
  }

  void _startListening() async {
    if (_isSpeechAvailable && !_isListening) {
      setState(() => _isListening = true);
      HapticFeedback.lightImpact();
      await _speech.listen(
        onResult: (val) {
          setState(() {
            _textController.text = val.recognizedWords;
            // Place cursor at the end
            _textController.selection = TextSelection.fromPosition(
              TextPosition(offset: _textController.text.length),
            );
          });
        },
      );
    }
  }

  void _stopListening() async {
    if (_isListening) {
      await _speech.stop();
      setState(() => _isListening = false);
      HapticFeedback.mediumImpact();
    }
  }

  Future<void> _scanReceipt() async {
    final picker = ImagePicker();
    // Prompt option: camera or gallery
    final ImageSource? source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded, color: AppTheme.accentColor),
              title: const Text('Take Photo of Receipt'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded, color: AppTheme.accentColor),
              title: const Text('Choose from Gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    try {
      final XFile? image = await picker.pickImage(source: source);
      if (image == null) return;

      // Show loader
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: AppTheme.accentColor),
        ),
      );

      final inputImage = InputImage.fromFilePath(image.path);
      final textRecognizer = TextRecognizer();
      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
      await textRecognizer.close();

      // Close loader
      if (mounted) Navigator.pop(context);

      // Simple OCR Heuristics:
      // Try to find the lines with numbers (totals, item prices)
      // and look for keywords to guess the main item.
      double maxAmount = 0.0;
      String matchedCategory = "";

      final RegExp moneyRegex = RegExp(r'(?:rs\.?|inr|₹)?\s?(\d+(?:\.\d{1,2})?)', caseSensitive: false);

      for (TextBlock block in recognizedText.blocks) {
        for (TextLine line in block.lines) {
          final text = line.text.toLowerCase();
          
          // Parse potential amounts
          final match = moneyRegex.firstMatch(text);
          if (match != null) {
            double? parsedVal = double.tryParse(match.group(1) ?? "");
            if (parsedVal != null && parsedVal > maxAmount) {
              maxAmount = parsedVal;
            }
          }

          // Scan for category keywords
          if (matchedCategory.isEmpty) {
            final parsed = LocalNlpParser.parse(text);
            if (parsed.category != 'Others') {
              matchedCategory = parsed.description;
            }
          }
        }
      }

      if (maxAmount > 0) {
        final description = matchedCategory.isNotEmpty ? matchedCategory : "Receipt";
        setState(() {
          _textController.text = "$description ${maxAmount.toStringAsFixed(0)}";
          _textController.selection = TextSelection.fromPosition(
            TextPosition(offset: _textController.text.length),
          );
        });
        HapticFeedback.heavyImpact();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not extract any amount from receipt.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        // Close loader if open
        if (Navigator.canPop(context)) Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Receipt scan failed: $e')),
        );
      }
    }
  }

  void _saveExpense() async {
    if (_textController.text.trim().isEmpty) return;

    final expenseViewModel = Provider.of<ExpenseViewModel>(context, listen: false);
    final budgetViewModel = Provider.of<BudgetViewModel>(context, listen: false);

    // Save transaction
    final savedExpense = await expenseViewModel.quickAdd(_textController.text);

    // Trigger Haptic Feedback
    HapticFeedback.mediumImpact();

    // Trigger Success State for Animation
    setState(() {
      _isSuccess = true;
    });

    // Check budget warnings
    final budgets = budgetViewModel.budgets;
    for (var b in budgets) {
      if (b.category.toLowerCase() == savedExpense.category.toLowerCase() &&
          b.month == savedExpense.createdAt.month &&
          b.year == savedExpense.createdAt.year) {
        
        final warning = budgetViewModel.getBudgetWarningMessage(b, expenseViewModel.expenses);
        if (warning != null) {
          // Display a brief snackbar with warning
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(warning),
                backgroundColor: AppTheme.warningColor,
                duration: const Duration(seconds: 4),
              ),
            );
          }
        }
      }
    }

    // Dismiss screen after animation completes
    Future.delayed(const Duration(milliseconds: 1400), () {
      if (mounted) {
        Navigator.pop(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Quick Add Expense', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.receipt_long_rounded),
            tooltip: 'Scan Receipt (OCR)',
            onPressed: _scanReceipt,
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: _isSuccess 
              ? _buildSuccessView() 
              : _buildInputView(),
        ),
      ),
    );
  }

  Widget _buildSuccessView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: AppTheme.successColor,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
              size: 72,
              color: Colors.white,
            ),
          ).animate().scale(
            duration: 600.ms,
            curve: Curves.elasticOut,
          ),
          const SizedBox(height: 24),
          Text(
            'Saved!',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: AppTheme.successColor,
              fontWeight: FontWeight.bold,
            ),
          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0),
          const SizedBox(height: 12),
          Text(
            '$_detectedEmoji $_detectedCategory • ₹${_detectedAmount.toStringAsFixed(0)}',
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2, end: 0),
        ],
      ),
    );
  }

  Widget _buildInputView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Real-time Detection Badge
              if (_textController.text.isNotEmpty && _detectedAmount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.accentColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: AppTheme.accentColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _detectedEmoji,
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _detectedCategory,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(width: 1, height: 14, color: Colors.white24),
                      const SizedBox(width: 8),
                      Text(
                        '₹${_detectedAmount.toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: AppTheme.accentColor,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn().scale(alignment: Alignment.centerLeft)
              else
                const SizedBox(height: 38),

              const SizedBox(height: 20),

              // Big Input field
              TextField(
                controller: _textController,
                focusNode: _focusNode,
                style: GoogleFonts.outfit(
                  fontSize: 28,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
                maxLines: 2,
                minLines: 1,
                keyboardType: TextInputType.text,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _saveExpense(),
                decoration: const InputDecoration(
                  hintText: 'Type naturally...',
                  contentPadding: EdgeInsets.zero,
                  fillColor: Colors.transparent,
                  border: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ),
              ),

              const SizedBox(height: 30),

              // Suggestions title
              const Text(
                'Suggestions',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),

              // Suggestions chips
              Wrap(
                spacing: 8,
                runSpacing: 10,
                children: _suggestions.map((sug) {
                  final parsed = LocalNlpParser.parse(sug);
                  final emoji = LocalNlpParser.getCategoryEmoji(parsed.category);
                  return ActionChip(
                    avatar: Text(emoji),
                    label: Text(sug),
                    backgroundColor: AppTheme.cardColor,
                    side: BorderSide(color: Colors.white.withOpacity(0.05)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    labelStyle: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      setState(() {
                        _textController.text = sug;
                        _textController.selection = TextSelection.fromPosition(
                          TextPosition(offset: sug.length),
                        );
                      });
                    },
                  );
                }).toList(),
              ),
            ],
          ),
        ),

        // Controls bar (Voice input and Save button)
        Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Row(
            children: [
              // Voice Input Button
              if (_isSpeechAvailable)
                GestureDetector(
                  onTapDown: (_) => _startListening(),
                  onTapUp: (_) => _stopListening(),
                  onTapCancel: _stopListening,
                  child: AnimatedContainer(
                    duration: 200.ms,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _isListening ? AppTheme.dangerColor.withOpacity(0.2) : AppTheme.cardColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _isListening ? AppTheme.dangerColor : Colors.white.withOpacity(0.05),
                        width: 1.5,
                      ),
                    ),
                    child: Icon(
                      _isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
                      color: _isListening ? AppTheme.dangerColor : Colors.white,
                      size: 28,
                    ),
                  ),
                )
              else
                const SizedBox.shrink(),

              const SizedBox(width: 16),

              // Save Button
              Expanded(
                child: ElevatedButton(
                  onPressed: _textController.text.trim().isEmpty ? null : _saveExpense,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    disabledBackgroundColor: AppTheme.cardColor.withOpacity(0.5),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Save Expense'),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward_rounded, size: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
