
import 'package:flutter/material.dart';

void main() {
  runApp(const CalculatorApp());
}

const Color backgroundColor = Color(0xFF101827);
const Color panelColor = Color(0xFF1D2A40);
const Color buttonColor = Color(0xFF283449);
const Color accentColor = Color(0xFFE59B48);
const Color utilityColor = Color(0xFF566780);

class CalculatorApp extends StatefulWidget {
  const CalculatorApp({super.key});

  @override
  State<CalculatorApp> createState() => _CalculatorAppState();
}

class _CalculatorAppState extends State<CalculatorApp> {
  String currentOperand = '0';
  String displayText = '0';
  String? pendingOperator;
  double? accumulator;

  bool awaitingOperand = false;
  bool justEvaluated = false;
  String? errorMessage;

  final List<Map<String, String>> history = [];

  String formatNumber(double value) {
    if (!value.isFinite) return 'Error';
    if (value == 0) return '0';

    String result = value.toStringAsFixed(10);
    result = result.replaceFirst(RegExp(r'0+$'), '');
    result = result.replaceFirst(RegExp(r'\.$'), '');
    return result;
  }

  void resetCalculation() {
    currentOperand = '0';
    displayText = '0';
    pendingOperator = null;
    accumulator = null;
    awaitingOperand = false;
    justEvaluated = false;
    errorMessage = null;
  }

  void showError(String message) {
    setState(() {
      errorMessage = message;
      displayText = 'Error';
      currentOperand = '0';
      pendingOperator = null;
      accumulator = null;
      awaitingOperand = false;
      justEvaluated = false;
    });
  }

  void pressDigit(String digit) {
    setState(() {
      if (errorMessage != null || justEvaluated) {
        resetCalculation();
      }

      if (awaitingOperand) {
        currentOperand = digit;
        awaitingOperand = false;
      } else if (currentOperand == '0') {
        currentOperand = digit;
      } else {
        currentOperand += digit;
      }

      displayText = currentOperand;
    });
  }

  void pressDecimal() {
    setState(() {
      if (errorMessage != null || justEvaluated) {
        resetCalculation();
      }

      if (awaitingOperand) {
        currentOperand = '0.';
        awaitingOperand = false;
      } else if (!currentOperand.contains('.')) {
        currentOperand += '.';
      }

      displayText = currentOperand;
    });
  }

  double? calculate(double left, double right, String op) {
    switch (op) {
      case '+':
        return left + right;
      case '-':
        return left - right;
      case '*':
        return left * right;
      case '/':
        if (right == 0) return null;
        return left / right;
      default:
        return null;
    }
  }

  void pressOperator(String op) {
    if (errorMessage != null) return;

    // Replace the pending operator if another operator is pressed.
    if (pendingOperator != null && awaitingOperand) {
      setState(() {
        pendingOperator = op;
      });
      return;
    }

    final double? entered = double.tryParse(currentOperand);
    if (entered == null) return;

    double value = entered;

    if (pendingOperator != null && accumulator != null) {
      final result = calculate(
        accumulator!,
        entered,
        pendingOperator!,
      );

      if (result == null) {
        showError('Cannot divide by zero. Enter a new number.');
        return;
      }

      if (!result.isFinite) {
        showError('Result is outside the supported range.');
        return;
      }

      value = result;
    }

    setState(() {
      accumulator = value;
      pendingOperator = op;
      currentOperand = '';
      awaitingOperand = true;
      justEvaluated = false;
      displayText = formatNumber(value);
    });
  }

  void pressEquals() {
    if (errorMessage != null ||
        pendingOperator == null ||
        awaitingOperand ||
        accumulator == null) {
      return;
    }

    final double? right = double.tryParse(currentOperand);
    if (right == null) return;

    final String expression =
        '${formatNumber(accumulator!)} '
        '$pendingOperator ${formatNumber(right)}';

    final result = calculate(
      accumulator!,
      right,
      pendingOperator!,
    );

    if (pendingOperator == '/' && right == 0) {
      showError('Cannot divide by zero. Enter a new number.');
      return;
    }

    if (result == null || !result.isFinite) {
      showError('Result is outside the supported range.');
      return;
    }

    setState(() {
      final String formatted = formatNumber(result);

      history.insert(0, {
        'expression': expression,
        'result': formatted,
      });

      // Temporary diagnostic message for the history test.
      debugPrint('Saved calculation: $expression = $formatted');

      currentOperand = formatted;
      displayText = formatted;
      accumulator = null;
      pendingOperator = null;
      awaitingOperand = true;
      justEvaluated = true;
    });
  }

  void pressBackspace() {
    setState(() {
      if (errorMessage != null) {
        resetCalculation();
        return;
      }

      if (justEvaluated || awaitingOperand) return;

      if (currentOperand.length <= 1 ||
          (currentOperand.length == 2 &&
              currentOperand.startsWith('-'))) {
        currentOperand = '0';
      } else {
        currentOperand =
            currentOperand.substring(0, currentOperand.length - 1);
      }

      displayText = currentOperand;
    });
  }

  void useHistoryResult(String result) {
    setState(() {
      resetCalculation();
      currentOperand = result;
      displayText = result;
    });
  }

  void clearHistory() {
    setState(() {
      history.clear();
    });
  }

  Future<void> openHistory() async {
    debugPrint('Opening history. Entries: ${history.length}');
    debugPrint('History data: $history');

    final String? selectedResult = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => HistoryScreen(
          history: history,
          onClear: clearHistory,
        ),
      ),
    );

    if (selectedResult != null && mounted) {
      useHistoryResult(selectedResult);
    }
  }

  Widget calculatorButton(
    String label, {
    required VoidCallback onTap,
    Color? color,
    String? keyName,
    VoidCallback? onLongPress,
  }) {
    return ElevatedButton(
      key: keyName == null ? null : ValueKey(keyName),
      onPressed: onTap,
      onLongPress: onLongPress,
      style: ElevatedButton.styleFrom(
        backgroundColor: color ?? buttonColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        padding: const EdgeInsets.all(8),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 21,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Calculator State Lab',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: backgroundColor,
        colorScheme: ColorScheme.fromSeed(
          seedColor: accentColor,
          brightness: Brightness.dark,
        ),
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Calculator'),
          backgroundColor: backgroundColor,
          actions: [
            IconButton(
              key: const ValueKey('open_history'),
              tooltip: 'View history',
              icon: const Icon(Icons.history),
              onPressed: openHistory,
            ),
          ],
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: panelColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        pendingOperator == null
                            ? 'Calculator display'
                            : 'Running total $pendingOperator',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        reverse: true,
                        child: Text(
                          displayText,
                          key: const ValueKey('display'),
                          maxLines: 1,
                          style: const TextStyle(
                            fontSize: 42,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (errorMessage != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          errorMessage!,
                          key: const ValueKey('error_message'),
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            color: Colors.orangeAccent,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 4,
                    mainAxisSpacing: 9,
                    crossAxisSpacing: 9,
                    childAspectRatio: 1.18,
                    children: [
                      calculatorButton(
                        'AC',
                        keyName: 'clear',
                        color: utilityColor,
                        onTap: () => setState(resetCalculation),
                      ),
                      calculatorButton(
                        'DEL',
                        keyName: 'backspace',
                        color: utilityColor,
                        onTap: pressBackspace,
                        onLongPress: () =>
                            setState(resetCalculation),
                      ),
                      calculatorButton(
                        '÷',
                        keyName: 'op_divide',
                        color: accentColor,
                        onTap: () => pressOperator('/'),
                      ),
                      calculatorButton(
                        '×',
                        keyName: 'op_multiply',
                        color: accentColor,
                        onTap: () => pressOperator('*'),
                      ),
                      ...['7', '8', '9'].map(
                        (digit) => calculatorButton(
                          digit,
                          keyName: 'digit_$digit',
                          onTap: () => pressDigit(digit),
                        ),
                      ),
                      calculatorButton(
                        '−',
                        keyName: 'op_subtract',
                        color: accentColor,
                        onTap: () => pressOperator('-'),
                      ),
                      ...['4', '5', '6'].map(
                        (digit) => calculatorButton(
                          digit,
                          keyName: 'digit_$digit',
                          onTap: () => pressDigit(digit),
                        ),
                      ),
                      calculatorButton(
                        '+',
                        keyName: 'op_add',
                        color: accentColor,
                        onTap: () => pressOperator('+'),
                      ),
                      ...['1', '2', '3'].map(
                        (digit) => calculatorButton(
                          digit,
                          keyName: 'digit_$digit',
                          onTap: () => pressDigit(digit),
                        ),
                      ),
                      calculatorButton(
                        '.',
                        keyName: 'decimal',
                        color: utilityColor,
                        onTap: pressDecimal,
                      ),
                      calculatorButton(
                        '0',
                        keyName: 'digit_0',
                        onTap: () => pressDigit('0'),
                      ),
                      calculatorButton(
                        '=',
                        keyName: 'equals',
                        color: accentColor,
                        onTap: pressEquals,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class HistoryScreen extends StatefulWidget {
  final List<Map<String, String>> history;
  final VoidCallback onClear;

  const HistoryScreen({
    super.key,
    required this.history,
    required this.onClear,
  });

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calculation History'),
        backgroundColor: backgroundColor,
        actions: [
          IconButton(
            key: const ValueKey('clear_history'),
            tooltip: 'Clear history',
            icon: const Icon(Icons.delete_outline),
            onPressed: () {
              widget.onClear();
              setState(() {});
            },
          ),
        ],
      ),
      body: widget.history.isEmpty
          ? const Center(
              child: Text(
                'No calculations yet.',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
            )
          : ListView.separated(
              key: const ValueKey('history_list'),
              padding: const EdgeInsets.all(16),
              itemCount: widget.history.length,
              separatorBuilder: (context, index) =>
                  const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final item = widget.history[index];

                return Card(
                  color: panelColor,
                  child: ListTile(
                    leading: const Icon(
                      Icons.calculate_outlined,
                      color: accentColor,
                    ),
                    title: Text(
                      '${item['expression']} = ${item['result']}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: const Text('Tap to reuse result'),
                    onTap: () {
                      Navigator.pop(context, item['result']);
                    },
                  ),
                );
              },
            ),
    );
  }
}
