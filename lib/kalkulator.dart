// DEATHTR4SH V1 GEN 2 - KALKULATOR

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'constants.dart';

void main() {
  runApp(const KalkulatorApp());
}

class KalkulatorApp extends StatelessWidget {
  const KalkulatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DEATHTR4SH Kalkulator',
      theme: ThemeData.dark().copyWith(
        primaryColor: kDeathRed,
        scaffoldBackgroundColor: kDeathDarkBg,
      ),
      debugShowCheckedModeBanner: false,
      home: const KalkulatorPage(),
    );
  }
}

class KalkulatorPage extends StatefulWidget {
  const KalkulatorPage({super.key});

  @override
  State<KalkulatorPage> createState() => _KalkulatorPageState();
}

class _KalkulatorPageState extends State<KalkulatorPage>
    with SingleTickerProviderStateMixin {
  String _display = "0";
  String _expression = "";
  String _lastResult = "";
  bool _isNewCalculation = true;

  final List<Map<String, dynamic>> _history = [];
  final ScrollController _scrollController = ScrollController();

  bool _isTyping = false;
  String _currentTypingResult = "";
  Timer? _typingTimer;
  int _typingIndex = 0;

  late AnimationController _mainController;
  late Animation<double> _fadeIn;
  late Animation<double> _scaleIn;
  late Animation<Offset> _slideUp;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _loadHistory();
    _mainController.forward();
  }

  void _initAnimations() {
    _mainController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeIn = CurvedAnimation(parent: _mainController, curve: Curves.easeOut);
    _scaleIn = Tween<double>(begin: 0.96, end: 1.0)
        .animate(CurvedAnimation(parent: _mainController, curve: Curves.easeOutBack));
    _slideUp = Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero)
        .animate(CurvedAnimation(parent: _mainController, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    _scrollController.dispose();
    _mainController.dispose();
    super.dispose();
  }

  void _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getStringList('kalkulator_history');
    if (historyJson != null) {
      setState(() {
        _history.clear();
        for (var json in historyJson) {
          try {
            _history.add(jsonDecode(json));
          } catch (e) {}
        }
      });
    }
  }

  void _saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = _history.map((item) => jsonEncode(item)).toList();
    await prefs.setStringList('kalkulator_history', historyJson);
  }

  void _addToHistory(String expression, String result) {
    setState(() {
      _history.insert(0, {
        'expression': expression,
        'result': result,
        'timestamp': DateTime.now().toIso8601String(),
      });
      if (_history.length > 50) _history.removeLast();
    });
    _saveHistory();
  }

  void _buttonPressed(String value) {
    setState(() {
      if (_isTyping) {
        _typingTimer?.cancel();
        _isTyping = false;
      }

      if (_isNewCalculation && _isNumber(value)) {
        _display = value;
        _expression = value;
        _isNewCalculation = false;
      } else if (value == "C") {
        _clear();
      } else if (value == "⌫") {
        _backspace();
      } else if (value == "=") {
        _calculate();
      } else if (value == "±") {
        _toggleSign();
      } else if (value == "%") {
        _percentage();
      } else {
        _addToExpression(value);
      }
    });
  }

  bool _isNumber(String value) {
    return RegExp(r'^[0-9.]$').hasMatch(value);
  }

  void _clear() {
    _display = "0";
    _expression = "";
    _isNewCalculation = true;
    _lastResult = "";
  }

  void _backspace() {
    if (_expression.isNotEmpty) {
      _expression = _expression.substring(0, _expression.length - 1);
      _display = _expression.isEmpty ? "0" : _expression;
      _isNewCalculation = false;
    } else if (_display != "0") {
      _display = "0";
      _isNewCalculation = true;
    }
  }

  void _toggleSign() {
    double current = double.parse(_display);
    current = -current;
    if (current == current.toInt()) {
      _display = current.toInt().toString();
    } else {
      _display = current.toString();
    }
    _expression = _display;
    _isNewCalculation = false;
  }

  void _percentage() {
    double current = double.parse(_display);
    current = current / 100;
    if (current == current.toInt()) {
      _display = current.toInt().toString();
    } else {
      _display = current.toString();
    }
    _expression = _display;
    _isNewCalculation = false;
  }

  void _addToExpression(String value) {
    if (_expression.isEmpty && (value == "×" || value == "÷" || value == "+" || value == "-")) {
      return;
    }
    _expression += _convertOperator(value);
    _display = _expression;
    _isNewCalculation = false;
  }

  String _convertOperator(String op) {
    switch(op) {
      case "×": return "*";
      case "÷": return "/";
      default: return op;
    }
  }

  String _displayOperator(String op) {
    switch(op) {
      case "*": return "×";
      case "/": return "÷";
      default: return op;
    }
  }

  void _calculate() {
    if (_expression.isEmpty) return;

    try {
      String expr = _expression.replaceAll("×", "*").replaceAll("÷", "/");
      double result = _evaluateExpression(expr);

      String resultStr;
      if (result == result.toInt()) {
        resultStr = result.toInt().toString();
      } else {
        resultStr = result.toStringAsFixed(8).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
      }

      _startTypingAnimation(resultStr);
      _addToHistory(_expression, resultStr);
      _lastResult = resultStr;
      _expression = resultStr;

    } catch (e) {
      _display = "Error";
      _expression = "";
      _isNewCalculation = true;

      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          setState(() {
            _display = "0";
          });
        }
      });
    }
  }

  double _evaluateExpression(String expression) {
    List<String> tokens = _tokenize(expression);
    List<double> numbers = [];
    List<String> operators = [];

    for (var token in tokens) {
      if (token == "+" || token == "-" || token == "*" || token == "/") {
        operators.add(token);
      } else {
        numbers.add(double.parse(token));
      }
    }

    for (int i = 0; i < operators.length; i++) {
      if (operators[i] == "*" || operators[i] == "/") {
        double result;
        if (operators[i] == "*") {
          result = numbers[i] * numbers[i + 1];
        } else {
          if (numbers[i + 1] == 0) throw Exception("Division by zero");
          result = numbers[i] / numbers[i + 1];
        }
        numbers[i] = result;
        numbers.removeAt(i + 1);
        operators.removeAt(i);
        i--;
      }
    }

    double result = numbers[0];
    for (int i = 0; i < operators.length; i++) {
      if (operators[i] == "+") {
        result += numbers[i + 1];
      } else if (operators[i] == "-") {
        result -= numbers[i + 1];
      }
    }

    return result;
  }

  List<String> _tokenize(String expression) {
    List<String> tokens = [];
    String currentNumber = "";

    for (int i = 0; i < expression.length; i++) {
      String char = expression[i];
      if (char == "+" || char == "-" || char == "*" || char == "/") {
        if (currentNumber.isNotEmpty) {
          tokens.add(currentNumber);
          currentNumber = "";
        }
        tokens.add(char);
      } else {
        currentNumber += char;
      }
    }

    if (currentNumber.isNotEmpty) {
      tokens.add(currentNumber);
    }

    return tokens;
  }

  void _startTypingAnimation(String result) {
    setState(() {
      _isTyping = true;
      _currentTypingResult = "";
      _typingIndex = 0;
    });

    _typingTimer?.cancel();
    _typingTimer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
      if (_typingIndex < result.length) {
        setState(() {
          _currentTypingResult = result.substring(0, _typingIndex + 1);
          _display = _currentTypingResult;
          _typingIndex++;
        });
      } else {
        timer.cancel();
        setState(() {
          _isTyping = false;
          _display = result;
          _expression = result;
          _isNewCalculation = true;
        });
      }
    });
  }

  void _clearHistory() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: kDeathCardBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: kDeathRed.withOpacity(0.2), width: 1),
        ),
        title: Text(
          'Clear History',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontFamily: 'FontX',
            letterSpacing: 1,
          ),
        ),
        content: Text(
          'Are you sure you want to clear all calculation history?',
          style: TextStyle(
            color: Colors.white.withOpacity(0.3),
            fontSize: 13,
            fontFamily: 'ShareTechMono',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              backgroundColor: kDeathCardBg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(color: kDeathBorder),
              ),
            ),
            child: Text(
              'CANCEL',
              style: TextStyle(
                color: Colors.white.withOpacity(0.2),
                fontSize: 10,
                fontWeight: FontWeight.w700,
                fontFamily: 'FontX',
                letterSpacing: 1,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              setState(() {
                _history.clear();
              });
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('kalkulator_history');
            },
            style: TextButton.styleFrom(
              backgroundColor: kDeathRed.withOpacity(0.04),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(color: kDeathRed.withOpacity(0.04)),
              ),
            ),
            child: Text(
              'CLEAR',
              style: TextStyle(
                color: kDeathRed.withOpacity(0.3),
                fontSize: 10,
                fontWeight: FontWeight.w700,
                fontFamily: 'FontX',
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kDeathDarkBg,
      appBar: _buildAppBar(),
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topRight,
            radius: 1.8,
            colors: [
              kDeathRed.withOpacity(0.04),
              kDeathDarkBg,
            ],
          ),
        ),
        child: FadeTransition(
          opacity: _fadeIn,
          child: ScaleTransition(
            scale: _scaleIn,
            child: SlideTransition(
              position: _slideUp,
              child: Column(
                children: [
                  _buildDisplay(),
                  _buildHistoryPanel(),
                  const SizedBox(height: 8),
                  _buildButtons(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // APP BAR
  // ============================================================
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [kDeathRed.withOpacity(0.15), kDeathRedDark.withOpacity(0.08)],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: kDeathRed.withOpacity(0.15),
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [kDeathRed, kDeathRedDark],
                ),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: kDeathRed.withOpacity(0.2),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Icon(
                Icons.calculate_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
            const SizedBox(width: 8),
            ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: [kDeathRed, kDeathGold],
              ).createShader(bounds),
              child: Text(
                'KALKULATOR',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'FontX',
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: kDeathCardBg.withOpacity(0.3),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: kDeathBorder),
          ),
          child: Icon(
            Icons.arrow_back_ios_new,
            color: kDeathRed,
            size: 16,
          ),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        if (_history.isNotEmpty)
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: kDeathCardBg.withOpacity(0.3),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: kDeathBorder),
              ),
              child: Icon(
                Icons.delete_sweep_rounded,
                color: kDeathRed.withOpacity(0.3),
                size: 18,
              ),
            ),
            onPressed: _clearHistory,
          ),
      ],
    );
  }

  // ============================================================
  // DISPLAY
  // ============================================================
  Widget _buildDisplay() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kDeathCardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kDeathBorder),
        boxShadow: [
          BoxShadow(
            color: kDeathRed.withOpacity(0.02),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (_expression.isNotEmpty && !_isNewCalculation)
            Text(
              _expression.replaceAll("*", "×").replaceAll("/", "÷"),
              style: TextStyle(
                fontSize: 18,
                color: Colors.white.withOpacity(0.1),
                fontFamily: 'ShareTechMono',
                fontWeight: FontWeight.w300,
                letterSpacing: 0.5,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          const SizedBox(height: 4),
          Text(
            _display,
            style: TextStyle(
              fontSize: _display.length > 10 ? 36 : 48,
              fontWeight: FontWeight.w900,
              fontFamily: 'FontX',
              color: kDeathRed,
              letterSpacing: 1.5,
              shadows: [
                Shadow(
                  color: kDeathRed.withOpacity(0.1),
                  blurRadius: 20,
                ),
              ],
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // HISTORY
  // ============================================================
  Widget _buildHistoryPanel() {
    if (_history.isEmpty) return const SizedBox(height: 8);

    return Container(
      height: 90,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'RIWAYAT',
            style: TextStyle(
              color: Colors.white.withOpacity(0.06),
              fontSize: 9,
              fontWeight: FontWeight.w700,
              fontFamily: 'FontX',
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              itemCount: _history.length,
              itemBuilder: (context, index) {
                final item = _history[index];
                return Container(
                  margin: const EdgeInsets.only(right: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: kDeathDarkBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: kDeathBorder),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        item['expression'].replaceAll("*", "×").replaceAll("/", "÷"),
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.15),
                          fontSize: 11,
                          fontFamily: 'ShareTechMono',
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "= ${item['result']}",
                        style: TextStyle(
                          color: kDeathRed.withOpacity(0.3),
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          fontFamily: 'FontX',
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BUTTONS
  // ============================================================
  Widget _buildButtons() {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            _buildButtonRow(["C", "⌫", "%", "÷"]),
            _buildButtonRow(["7", "8", "9", "×"]),
            _buildButtonRow(["4", "5", "6", "-"]),
            _buildButtonRow(["1", "2", "3", "+"]),
            _buildButtonRow(["±", "0", ".", "="]),
          ],
        ),
      ),
    );
  }

  Widget _buildButtonRow(List<String> values) {
    return Expanded(
      child: Row(
        children: values.map((value) {
          return _buildButton(value);
        }).toList(),
      ),
    );
  }

  Widget _buildButton(String text) {
    bool isOperator = text == "+" || text == "-" || text == "×" || text == "÷";
    bool isEqual = text == "=";
    bool isClear = text == "C" || text == "⌫";
    bool isSpecial = text == "%" || text == "±";

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(5),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              HapticFeedback.mediumImpact();
              _buttonPressed(text);
            },
            borderRadius: BorderRadius.circular(60),
            child: Container(
              height: 68,
              decoration: BoxDecoration(
                gradient: isEqual
                    ? LinearGradient(
                        colors: [kDeathRed, kDeathRedDark],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: isEqual
                    ? null
                    : isOperator || isSpecial
                        ? kDeathCardBg
                        : kDeathDarkBg,
                shape: BoxShape.circle,
                boxShadow: [
                  if (!isEqual)
                    BoxShadow(
                      color: kDeathRed.withOpacity(0.02),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  if (isEqual)
                    BoxShadow(
                      color: kDeathRed.withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                ],
                border: isEqual
                    ? null
                    : Border.all(
                        color: kDeathBorder,
                        width: 0.5,
                      ),
              ),
              child: Center(
                child: Text(
                  text,
                  style: TextStyle(
                    fontSize: isOperator || isEqual ? 26 : 24,
                    fontWeight: isEqual ? FontWeight.w900 : FontWeight.w500,
                    fontFamily: isOperator || isEqual || isClear ? 'FontX' : 'ShareTechMono',
                    color: isOperator || isSpecial
                        ? kDeathRed
                        : isClear
                            ? kDeathGold.withOpacity(0.3)
                            : isEqual
                                ? Colors.white
                                : Colors.white,
                    letterSpacing: isEqual ? 1 : 0,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}