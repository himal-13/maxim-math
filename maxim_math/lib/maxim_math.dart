import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'core/audio_manager.dart';
import 'core/reward_provider.dart';
import 'core/score_provider.dart';
import 'core/app_theme.dart';
import 'core/health_service.dart';
import 'main.dart';

class MaximMath extends StatefulWidget {
  final String topicId;
  const MaximMath({super.key, required this.topicId});

  @override
  State<MaximMath> createState() => _MaximMathState();
}

class _MaximMathState extends State<MaximMath>
    with SingleTickerProviderStateMixin {
  bool _isGameActive = false;
  bool _isGameOver = false;
  bool _levelCompleted = false;
  bool _showBuyAttemptsDialog = false;
  int? _selectedIndex;

  int _score = 0;
  int _attemptsLeft = 5;
  int _streak = 0;
  int _timeLeft = 10;
  int _correctAnswersLevel = 0; // resets each level
  int _correctAnswersTotal = 0;
  int _numOptions = 2;
  int _currentLevel = 1;

  List<String> _numbers = [];
  List<double> _values = [];
  int _correctIndex = -1;
  String? _feedback;
  bool _feedbackCorrect = true;

  Timer? _timer;
  Timer? _feedbackTimer;
  int _highScore = 0;

  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  final math.Random _random = math.Random();

  bool get _isInfinityMode => widget.topicId == GameId.infinity;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _pulseAnim = Tween(
      begin: 1.0,
      end: 1.04,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _loadHighScoreAndLevel();
    _startGame();
  }

  void _loadHighScoreAndLevel() {
    final sp = Provider.of<ScoreProvider>(context, listen: false);
    final rp = Provider.of<RewardProvider>(context, listen: false);
    setState(() {
      _highScore = sp.getHighScore(widget.topicId);
      if (!_isInfinityMode) {
        _currentLevel = rp.getTopicLevel(widget.topicId);
      } else {
        _currentLevel = 1;
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _feedbackTimer?.cancel();
    _pulseCtrl.dispose();
    super.dispose();
  }

  void _startGame() {
    final hs = Provider.of<HealthService>(context, listen: false);
    setState(() {
      _isGameActive = true;
      _isGameOver = false;
      _levelCompleted = false;
      _showBuyAttemptsDialog = false;
      _score = 0;
      _attemptsLeft = hs.getAttempts(widget.topicId);
      _streak = 0;
      _correctAnswersLevel = 0;
      _correctAnswersTotal = 0;
      _timeLeft = 10;
      _feedback = null;
      _selectedIndex = null;
      if (!_isInfinityMode) {
        final rp = Provider.of<RewardProvider>(context, listen: false);
        _currentLevel = rp.getTopicLevel(widget.topicId);
      } else {
        _currentLevel = 1;
      }
    });
    _generateQuestion();
    _startTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Provider.of<RewardProvider>(context, listen: false).recordGamePlayed();
      }
    });
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted ||
          !_isGameActive ||
          _isGameOver ||
          _levelCompleted ||
          _showBuyAttemptsDialog) {
        t.cancel();
        return;
      }
      setState(() {
        _timeLeft--;
        if (_timeLeft <= 0) {
          _handleTimeout();
        }
      });
    });
  }

  void _stopAllTimers() {
    _timer?.cancel();
    _feedbackTimer?.cancel();
  }

  void _handleTimeout() {
    _stopAllTimers();
    AudioManager.playWrong();
    final hs = Provider.of<HealthService>(context, listen: false);
    setState(() {
      _attemptsLeft--;
      hs.setAttempts(widget.topicId, _attemptsLeft);
      _streak = 0;
      _feedback = 'Too slow!';
      _feedbackCorrect = false;
      _selectedIndex = null;

      if (_attemptsLeft <= 0) {
        _showBuyAttemptsDialog = true;
        return;
      }
    });

    _feedbackTimer = Timer(const Duration(milliseconds: 1000), () {
      if (mounted && _isGameActive && !_isGameOver && !_showBuyAttemptsDialog) {
        setState(() {
          _feedback = null;
          _selectedIndex = null;
          _timeLeft = 10;
        });
        _generateQuestion();
        _startTimer();
      }
    });
  }

  void _generateQuestion() {
    _numbers.clear();
    _values.clear();

    // Determine current level
    // In Level-based modes, level is _currentLevel.
    // In Infinity mode, level increases every 5 correct answers.
    int level = _isInfinityMode
        ? (_correctAnswersTotal ~/ 5) + 1
        : _currentLevel;

    // Constraints: 2 numbers in level 1, 3 in level 2, 4 in rest
    _numOptions = level == 1 ? 2 : (level == 2 ? 3 : 4);

    // Pick topic
    String currentTopic = widget.topicId;
    if (_isInfinityMode) {
      final topics = [
        GameId.basicOps,
        GameId.fractions,
        GameId.percentages,
        GameId.powersRoots,
        GameId.decimalsArithmetic,
      ];
      currentTopic = topics[_random.nextInt(topics.length)];
    }

    // Generate options with distinct values
    double targetVal = 10.0 + _random.nextDouble() * 90.0;
    String measCategory = '';
    List<String> selectedUnits = [];

    if (currentTopic == GameId.fractions) {
      targetVal = 0.2 + _random.nextDouble() * 2.5;
    } else if (currentTopic == GameId.basicOps) {
      targetVal = 10.0 + _random.nextDouble() * 90.0;
    } else if (currentTopic == GameId.measurement) {
      final cats = ['length', 'mass', 'volume', 'time'];
      measCategory = cats[_random.nextInt(cats.length)];
      
      List<String> units = [];
      if (measCategory == 'length') {
        units = ['m', 'cm', 'mm', 'km'];
        targetVal = 50.0 + _random.nextDouble() * 1950.0;
      } else if (measCategory == 'mass') {
        units = ['t', 'kg', 'g', 'mg'];
        targetVal = 10000.0 + _random.nextDouble() * 990000.0;
      } else if (measCategory == 'volume') {
        units = ['kL', 'L', 'dL', 'mL'];
        targetVal = 10.0 + _random.nextDouble() * 990.0;
      } else { // time
        units = ['days', 'hours', 'mins', 'secs'];
        targetVal = 60.0 + _random.nextDouble() * 2820.0;
      }
      
      units.shuffle(_random);
      selectedUnits = units.sublist(0, _numOptions);
    } else if (currentTopic == GameId.decimalsArithmetic) {
      targetVal = 5.0 + _random.nextDouble() * 45.0;
    } else if (currentTopic == GameId.powersRoots) {
      targetVal = 4.0 + _random.nextDouble() * 120.0;
    }

    for (int i = 0; i < _numOptions; i++) {
      String expr = '';
      double val = 0;
      int attempts = 0;

      do {
        final varianceFactor =
            0.70 + _random.nextDouble() * 0.60; // 70% to 130% of target
        final optionTarget = targetVal * varianceFactor;

        if (currentTopic == GameId.measurement) {
          expr = _genMeasurementWithUnit(measCategory, selectedUnits[i], optionTarget);
        } else {
          expr = _generateExpressionForTopic(currentTopic, optionTarget);
        }
        val = _evaluateExpression(currentTopic, expr);
        attempts++;
      } while ((_values.any((v) => (v - val).abs() < 0.005) || val <= 0) &&
          attempts < 40);

      _numbers.add(expr);
      _values.add(val);
    }

    // Find correct index (largest value)
    double maxVal = -double.infinity;
    int maxIdx = 0;
    for (int i = 0; i < _values.length; i++) {
      if (_values[i] > maxVal) {
        maxVal = _values[i];
        maxIdx = i;
      }
    }
    _correctIndex = maxIdx;

    setState(() {
      _timeLeft = 10;
    });
  }

  String _generateExpressionForTopic(String topic, double target) {
    switch (topic) {
      case GameId.basicOps:
        return _genBasicOps(target);
      case GameId.fractions:
        return _genFraction(target);
      case GameId.percentages:
        return _genPercent(target);
      case GameId.powersRoots:
        return _random.nextBool() ? _genPower(target) : _genRoot(target);
      case GameId.measurement:
        final cats = ['length', 'mass', 'volume', 'time'];
        final cat = cats[_random.nextInt(cats.length)];
        return _genMeasurement(cat, target);
      case GameId.decimalsArithmetic:
        return _genArithmetic(target);
      default:
        return _formatDouble(target);
    }
  }

  double _evaluateExpression(String topic, String expr) {
    switch (topic) {
      case GameId.basicOps:
        return _evaluateArithmetic(expr);
      case GameId.fractions:
        return _evaluateFraction(expr);
      case GameId.percentages:
        return _evaluatePercent(expr);
      case GameId.powersRoots:
        if (expr.contains('√')) {
          return _evaluateRoot(expr);
        } else {
          return _evaluatePower(expr);
        }
      case GameId.measurement:
        return _evaluateMeasurement(expr);
      case GameId.decimalsArithmetic:
        return _evaluateArithmetic(expr);
      default:
        return double.tryParse(expr) ?? 0;
    }
  }

  // Topic generators
  String _genFraction(double target) {
    for (int attempts = 0; attempts < 30; attempts++) {
      final den = 2 + _random.nextInt(12);
      final num = (target * den).round();
      if (num > 0 && num != den) {
        return '$num/$den';
      }
    }
    return '${1 + _random.nextInt(5)}/${2 + _random.nextInt(4)}';
  }

  double _evaluateFraction(String s) {
    final parts = s.split('/');
    if (parts.length < 2) return double.tryParse(s) ?? 0;
    final num = double.tryParse(parts[0]) ?? 0;
    final den = double.tryParse(parts[1]) ?? 1;
    return den != 0 ? num / den : 0;
  }

  String _genPercent(double target) {
    for (int attempts = 0; attempts < 30; attempts++) {
      final base = 10 * (1 + _random.nextInt(20)); // multiples of 10
      final pctVal = (target / base * 100).round();
      if (pctVal > 5) {
        return '$pctVal% of $base';
      }
    }
    return '50% of 100';
  }

  double _evaluatePercent(String s) {
    final parts = s.split(' ');
    if (parts.length < 3) return 0;
    final pct = double.tryParse(parts[0].replaceAll('%', '')) ?? 0;
    final base = double.tryParse(parts[2]) ?? 0;
    return (pct / 100) * base;
  }

  String _genPower(double target) {
    final exp = _random.nextDouble() < 0.75 ? 2 : 3;
    final base = math.pow(target, 1 / exp).round();
    final finalBase = base.clamp(2, 12);
    return '$finalBase^$exp';
  }

  double _evaluatePower(String s) {
    final parts = s.split('^');
    if (parts.length < 2) return double.tryParse(s) ?? 0;
    final b = double.tryParse(parts[0]) ?? 0;
    final e = double.tryParse(parts[1]) ?? 1;
    return math.pow(b, e).toDouble();
  }

  String _genRoot(double target) {
    final coef = _random.nextDouble() < 0.6 ? 1 : (1 + _random.nextInt(3));
    final insideTarget = math.pow(target / coef, 2);
    final inside = insideTarget.round().clamp(2, 200);
    return '$coef√$inside';
  }

  double _evaluateRoot(String s) {
    final idx = s.indexOf('√');
    if (idx == -1) return double.tryParse(s) ?? 0;
    final coefStr = s.substring(0, idx);
    final insideStr = s.substring(idx + 1);
    final coef = coefStr.isEmpty ? 1.0 : (double.tryParse(coefStr) ?? 1.0);
    final inside = double.tryParse(insideStr) ?? 0;
    return coef * math.sqrt(inside);
  }

  String _genMeasurement(String cat, double targetVal) {
    switch (cat) {
      case 'length':
        final units = ['m', 'cm', 'mm', 'km'];
        final unit = units[_random.nextInt(units.length)];
        switch (unit) {
          case 'km':
            final val = targetVal / 1000.0;
            return '${_formatDouble(val)} km';
          case 'cm':
            final val = targetVal * 100.0;
            return '${_formatDouble(val)} cm';
          case 'mm':
            final val = targetVal * 1000.0;
            return '${_formatDouble(val)} mm';
          default:
            return '${_formatDouble(targetVal)} m';
        }
      case 'mass':
        final units = ['kg', 'g', 'mg'];
        final unit = units[_random.nextInt(units.length)];
        switch (unit) {
          case 'kg':
            final val = targetVal / 1000.0;
            return '${_formatDouble(val)} kg';
          case 'mg':
            final val = targetVal * 1000.0;
            return '${_formatDouble(val)} mg';
          default:
            return '${_formatDouble(targetVal)} g';
        }
      case 'volume':
        final units = ['L', 'mL'];
        final unit = units[_random.nextInt(units.length)];
        switch (unit) {
          case 'mL':
            final val = targetVal * 1000.0;
            return '${_formatDouble(val)} mL';
          default:
            return '${_formatDouble(targetVal)} L';
        }
      case 'time':
        final units = ['hours', 'mins', 'secs'];
        final unit = units[_random.nextInt(units.length)];
        switch (unit) {
          case 'hours':
            final val = targetVal / 60.0;
            return '${_formatDouble(val)} hours';
          case 'secs':
            final val = targetVal * 60.0;
            return '${_formatDouble(val)} secs';
          default:
            return '${_formatDouble(targetVal)} mins';
        }
      default:
        return '${_formatDouble(targetVal)} units';
    }
  }

  String _genMeasurementWithUnit(String cat, String unit, double targetVal) {
    double val = targetVal;
    switch (unit) {
      // Length
      case 'km':
        val = targetVal / 1000.0;
        break;
      case 'cm':
        val = targetVal * 100.0;
        break;
      case 'mm':
        val = targetVal * 1000.0;
        break;
      case 'm':
        val = targetVal;
        break;

      // Mass
      case 't':
        val = targetVal / 1000000.0;
        break;
      case 'kg':
        val = targetVal / 1000.0;
        break;
      case 'g':
        val = targetVal;
        break;
      case 'mg':
        val = targetVal * 1000.0;
        break;

      // Volume
      case 'kL':
        val = targetVal / 1000.0;
        break;
      case 'L':
        val = targetVal;
        break;
      case 'dL':
        val = targetVal * 10.0;
        break;
      case 'mL':
        val = targetVal * 1000.0;
        break;

      // Time
      case 'days':
        val = targetVal / 1440.0;
        break;
      case 'hours':
        val = targetVal / 60.0;
        break;
      case 'mins':
        val = targetVal;
        break;
      case 'secs':
        val = targetVal * 60.0;
        break;
    }
    return '${_formatDouble(val)} $unit';
  }

  double _evaluateMeasurement(String s) {
    final parts = s.split(' ');
    if (parts.length < 2) return 0;
    final val = double.tryParse(parts[0]) ?? 0;
    final unit = parts[1];
    switch (unit) {
      case 'km':
        return val * 1000.0;
      case 'm':
        return val;
      case 'cm':
        return val / 100.0;
      case 'mm':
        return val / 1000.0;
      case 't':
        return val * 1000000.0;
      case 'kg':
        return val * 1000.0;
      case 'g':
        return val;
      case 'mg':
        return val / 1000.0;
      case 'kL':
        return val * 1000.0;
      case 'L':
        return val;
      case 'dL':
        return val / 10.0;
      case 'mL':
        return val / 1000.0;
      case 'days':
        return val * 1440.0;
      case 'hours':
        return val * 60.0;
      case 'mins':
        return val;
      case 'secs':
        return val / 60.0;
      default:
        return val;
    }
  }

  String _genArithmetic(double targetVal) {
    final ops = ['+', '-', '*', '/'];
    final op = ops[_random.nextInt(ops.length)];
    switch (op) {
      case '+':
        final a = targetVal * (0.2 + 0.6 * _random.nextDouble());
        final b = targetVal - a;
        return '${_formatDouble(a)} + ${_formatDouble(b)}';
      case '-':
        final b = targetVal * (0.2 + 0.6 * _random.nextDouble());
        final a = targetVal + b;
        return '${_formatDouble(a)} - ${_formatDouble(b)}';
      case '*':
        final b = 1.5 + _random.nextInt(4) + _random.nextDouble();
        final a = targetVal / b;
        return '${_formatDouble(a)} * ${_formatDouble(b)}';
      case '/':
        final double b = (2 + _random.nextInt(3)).toDouble();
        final a = targetVal * b;
        return '${_formatDouble(a)} / ${_formatDouble(b)}';
      default:
        return _formatDouble(targetVal);
    }
  }

  String _genBasicOps(double targetVal) {
    final target = targetVal.round().clamp(5, 100);
    final ops = ['+', '-', '*', '/'];
    final op = ops[_random.nextInt(ops.length)];
    switch (op) {
      case '+':
        final a = 1 + _random.nextInt(target - 1);
        final b = target - a;
        return '$a + $b';
      case '-':
        final b = 2 + _random.nextInt(50);
        final a = target + b;
        return '$a - $b';
      case '*':
        final maxA = target > 50 ? 12 : 9;
        final a = 2 + _random.nextInt(maxA - 1);
        final b = (target / a).round().clamp(2, 20);
        return '$a * $b';
      case '/':
        final b = 2 + _random.nextInt(9);
        final a = target * b;
        return '$a / $b';
      default:
        return '$target';
    }
  }

  double _evaluateArithmetic(String s) {
    if (s.contains('+')) {
      final parts = s.split('+');
      return (double.tryParse(parts[0].trim()) ?? 0) +
          (double.tryParse(parts[1].trim()) ?? 0);
    }
    if (s.contains('-')) {
      final parts = s.split('-');
      return (double.tryParse(parts[0].trim()) ?? 0) -
          (double.tryParse(parts[1].trim()) ?? 0);
    }
    if (s.contains('*')) {
      final parts = s.split('*');
      return (double.tryParse(parts[0].trim()) ?? 0) *
          (double.tryParse(parts[1].trim()) ?? 0);
    }
    if (s.contains('/')) {
      final parts = s.split('/');
      final b = double.tryParse(parts[1].trim()) ?? 1;
      return b != 0 ? (double.tryParse(parts[0].trim()) ?? 0) / b : 0;
    }
    return double.tryParse(s) ?? 0;
  }

  String _formatDouble(double d) {
    if (d == d.toInt()) return d.toInt().toString();
    return d.toStringAsFixed(2).replaceAll(RegExp(r'\.?0+$'), '');
  }

  void _handleChoice(int index) {
    if (!_isGameActive ||
        _isGameOver ||
        _levelCompleted ||
        _showBuyAttemptsDialog ||
        _selectedIndex != null)
      return;
    _stopAllTimers();

    setState(() {
      _selectedIndex = index;
    });

    if (index == _correctIndex) {
      AudioManager.playCorrect();
      if (_streak > 0 && _streak % 3 == 0) {
        AudioManager.playStreak();
      }

      setState(() {
        _streak++;
        _correctAnswersLevel++;
        _correctAnswersTotal++;

        final pts = 10 + (_streak ~/ 3) * 5;
        _score += pts;
        _feedback = '+$pts';
        _feedbackCorrect = true;

        // Check level completion for level mode
        if (!_isInfinityMode && _correctAnswersLevel >= _currentLevel + 2) {
          _triggerLevelCompletion();
          return;
        }
      });
    } else {
      AudioManager.playWrong();
      final hs = Provider.of<HealthService>(context, listen: false);
      setState(() {
        _attemptsLeft--;
        hs.setAttempts(widget.topicId, _attemptsLeft);
        _streak = 0;
        _feedback = 'Wrong!';
        _feedbackCorrect = false;

        if (_attemptsLeft <= 0) {
          _showBuyAttemptsDialog = true;
          return;
        }
      });
    }

    _feedbackTimer = Timer(const Duration(milliseconds: 900), () {
      if (mounted &&
          _isGameActive &&
          !_isGameOver &&
          !_levelCompleted &&
          !_showBuyAttemptsDialog) {
        setState(() {
          _feedback = null;
          _selectedIndex = null;
          _timeLeft = 10;
        });
        _generateQuestion();
        _startTimer();
      }
    });
  }

  void _triggerLevelCompletion() {
    _stopAllTimers();
    AudioManager.playLevelUp();

    // Save progression
    final rp = Provider.of<RewardProvider>(context, listen: false);
    rp.saveTopicLevel(widget.topicId, _currentLevel + 1);

    setState(() {
      _levelCompleted = true;
    });
  }

  bool _isRefillingAd = false;
  void _watchRefillAd() {
    final hs = Provider.of<HealthService>(context, listen: false);
    if (!hs.isAdReady) {
      setState(() {
        _isRefillingAd = true;
      });
      hs.loadRewardedAd();
      Future.delayed(const Duration(seconds: 2), () {
        if (!mounted) return;
        if (hs.isAdReady) {
          setState(() {
            _isRefillingAd = false;
          });
          _showRefillAd(hs);
        } else {
          setState(() {
            _isRefillingAd = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to load rewarded ad. Please try again later.'),
              backgroundColor: AppTheme.accentCoral,
            ),
          );
        }
      });
    } else {
      _showRefillAd(hs);
    }
  }

  void _showRefillAd(HealthService hs) {
    hs.showRewardedAd(
      topicId: widget.topicId,
      onRewardEarned: () {
        if (!mounted) return;
        AudioManager.playCoin();
        setState(() {
          _attemptsLeft = 5;
          _showBuyAttemptsDialog = false;
          _feedback = null;
          _selectedIndex = null;
          _timeLeft = 10;
        });
        _generateQuestion();
        _startTimer();
      },
      onAdFailed: () {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to play rewarded ad. Please try again.'),
            backgroundColor: AppTheme.accentCoral,
          ),
        );
      },
    );
  }

  void _gameOver() {
    _stopAllTimers();
    AudioManager.playGameOver();

    final sp = Provider.of<ScoreProvider>(context, listen: false);
    sp.submitScore(widget.topicId, _score);

    if (_score > _highScore) {
      _highScore = _score;
    }

    setState(() {
      _isGameActive = false;
      _isGameOver = true;
      _showBuyAttemptsDialog = false;
    });
  }

  void _nextLevel() {
    setState(() {
      _currentLevel++;
      _correctAnswersLevel = 0;
      _levelCompleted = false;
      _feedback = null;
      _timeLeft = 10;
    });
    _generateQuestion();
    _startTimer();
  }

  void _backToMenu() {
    _stopAllTimers();
    Navigator.pop(context);
  }

  void _showGameOverRefillDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return RefillHealthDialog(
          topicId: widget.topicId,
          topicTitle: _getTopicTitle(widget.topicId),
        );
      },
    ).then((_) {
      if (!mounted) return;
      final hs = Provider.of<HealthService>(context, listen: false);
      if (hs.getAttempts(widget.topicId) > 0) {
        _startGame();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final title = _isInfinityMode
        ? 'Infinity Mode'
        : _getTopicTitle(widget.topicId);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppTheme.textPrimary,
          ),
          onPressed: _backToMenu,
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        actions: null,
      ),
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: Stack(
          children: [
            Column(
              children: [
                _buildStatsBar(),
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildQuestion(),
                          const SizedBox(height: 24),
                          if (_feedback != null) _buildFeedback(),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (_levelCompleted) _buildLevelCompletedOverlay(),
            if (_showBuyAttemptsDialog) _buildBuyAttemptsOverlay(),
            if (_isGameOver) _buildGameOverOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsBar() {
    // Current level displays
    final currentLvl = _isInfinityMode
        ? (_correctAnswersTotal ~/ 5) + 1
        : _currentLevel;
    final levelColor = _numOptions == 4
        ? AppTheme.accentCoral
        : _numOptions == 3
        ? AppTheme.accentAmber
        : AppTheme.accentMint;

    final timerColor = _timeLeft <= 3
        ? AppTheme.accentCoral
        : AppTheme.accentMint;
    final progress = _isInfinityMode
        ? 0.0
        : (_correctAnswersLevel / (_currentLevel + 2)).clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: AppTheme.glassCard(radius: 20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Attempts Display
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.accentCoral.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.accentCoral.withOpacity(0.25)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.favorite_rounded,
                      color: AppTheme.accentCoral,
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$_attemptsLeft LIFE',
                      style: const TextStyle(
                        color: AppTheme.accentCoral,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              // Timer Display
              Row(
                children: [
                  Icon(Icons.timer_rounded, color: timerColor, size: 18),
                  const SizedBox(width: 4),
                  Text(
                    '${_timeLeft}s',
                    style: TextStyle(
                      color: timerColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              // Level Tag
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: levelColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: levelColor.withOpacity(0.4)),
                ),
                child: Text(
                  'Level $currentLvl',
                  style: TextStyle(
                    color: levelColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          if (!_isInfinityMode) ...[
            const SizedBox(height: 12),
            // Progress to next level
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: AppTheme.textHint.withOpacity(0.15),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppTheme.accentMint,
                      ),
                      minHeight: 8,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '$_correctAnswersLevel/${_currentLevel + 2}',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ] else ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Score: $_score',
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Streak: $_streak',
                  style: const TextStyle(
                    color: AppTheme.accentAmber,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuestion() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          const Text(
            'Tap the LARGEST value:',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 24),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: _numOptions == 3 ? 3 : 2,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: _numOptions == 3 ? 0.85 : 1.15,
            ),
            itemCount: _numOptions,
            itemBuilder: (_, i) => _buildCard(i),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(int i) {
    if (i >= _numbers.length) return const SizedBox();

    final colors = [
      AppTheme.accentTeal,
      AppTheme.accentViolet,
      AppTheme.accentAmber,
      AppTheme.accentMint,
    ];
    final color = colors[i % colors.length];

    return MathOptionCard(
      expr: _numbers[i],
      color: color,
      onTap: () => _handleChoice(i),
      isSelected: _selectedIndex == i,
      isCorrect: _selectedIndex == null ? null : (i == _correctIndex),
    );
  }

  Widget _buildFeedback() {
    final color = _feedbackCorrect ? AppTheme.accentMint : AppTheme.accentCoral;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Text(
        _feedback ?? '',
        style: TextStyle(
          color: color,
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildLevelCompletedOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.85),
      child: Center(
        child: ScaleTransition(
          scale: _pulseAnim,
          child: Container(
            width: 320,
            padding: const EdgeInsets.all(28),
            decoration: AppTheme.glassCard(
              borderColor: AppTheme.accentMint.withOpacity(0.4),
              radius: 28,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.stars_rounded,
                  color: AppTheme.accentMint,
                  size: 64,
                ),
                const SizedBox(height: 20),
                const Text(
                  'LEVEL COMPLETED!',
                  style: TextStyle(
                    color: AppTheme.accentMint,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Topic Level $_currentLevel Passed',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 32),
                GestureDetector(
                  onTap: _nextLevel,
                  child: Container(
                    height: 50,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: AppTheme.tealGradient(),
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.accentTeal.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text(
                        'CONTINUE TO NEXT LEVEL',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBuyAttemptsOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.85),
      child: Center(
        child: Container(
          width: 320,
          padding: const EdgeInsets.all(28),
          decoration: AppTheme.glassCard(
            borderColor: AppTheme.accentCoral.withOpacity(0.4),
            radius: 28,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.favorite_rounded,
                color: AppTheme.accentCoral,
                size: 64,
              ),
              const SizedBox(height: 20),
              const Text(
                'OUT OF LIVES!',
                style: TextStyle(
                  color: AppTheme.accentCoral,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Watch a rewarded ad to fully restore health (5 lives) and continue playing this level without losing progress.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 28),
              GestureDetector(
                onTap: _watchRefillAd,
                child: Container(
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: AppTheme.tealGradient(),
                    borderRadius: BorderRadius.circular(26),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.accentTeal.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_isRefillingAd)
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      else ...[
                        const Icon(
                          Icons.play_circle_fill_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'WATCH AD TO REFILL',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              GestureDetector(
                onTap: _gameOver,
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppTheme.cardBackground,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: AppTheme.textHint.withOpacity(0.3),
                    ),
                  ),
                  child: const Center(
                    child: Text(
                      'NO, END RUN',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGameOverOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.85),
      child: Center(
        child: Container(
          width: 320,
          padding: const EdgeInsets.all(28),
          decoration: AppTheme.glassCard(
            borderColor: AppTheme.accentCoral.withOpacity(0.4),
            radius: 28,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.sentiment_very_dissatisfied_rounded,
                color: AppTheme.accentCoral,
                size: 64,
              ),
              const SizedBox(height: 18),
              const Text(
                'GAME OVER',
                style: TextStyle(
                  color: AppTheme.accentCoral,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                '$_score',
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 54,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Text(
                'FINAL SCORE',
                style: TextStyle(
                  color: AppTheme.textHint,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Best Record: $_highScore',
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '$_correctAnswersTotal correct answers',
                style: const TextStyle(color: AppTheme.textHint, fontSize: 13),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: _backToMenu,
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppTheme.cardBackground,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: AppTheme.textHint.withOpacity(0.3),
                          ),
                        ),
                        child: const Center(
                          child: Text(
                            'MENU',
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        final hs = Provider.of<HealthService>(context, listen: false);
                        if (hs.getAttempts(widget.topicId) == 0) {
                          _showGameOverRefillDialog();
                        } else {
                          _startGame();
                        }
                      },
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: AppTheme.tealGradient(),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: const Center(
                          child: Text(
                            'REPLAY',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getTopicTitle(String topicId) {
    switch (topicId) {
      case GameId.basicOps:
        return 'Basic Ops';
      case GameId.fractions:
        return 'Fractions Duel';
      case GameId.percentages:
        return 'Percentages Duel';
      case GameId.powersRoots:
        return 'Powers & Roots';
      case GameId.measurement:
        return 'Measurement';
      case GameId.decimalsArithmetic:
        return 'Decimals & Arithmetic';
      default:
        return 'Math Duel';
    }
  }
}

class MathOptionCard extends StatefulWidget {
  final String expr;
  final Color color;
  final VoidCallback onTap;
  final bool isSelected;
  final bool? isCorrect;

  const MathOptionCard({
    super.key,
    required this.expr,
    required this.color,
    required this.onTap,
    required this.isSelected,
    this.isCorrect,
  });

  @override
  State<MathOptionCard> createState() => _MathOptionCardState();
}

class _MathOptionCardState extends State<MathOptionCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _shakeAnim;

  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _shakeAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 8.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 8.0, end: -8.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: -8.0, end: 6.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 6.0, end: -4.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: -4.0, end: 0.0), weight: 20),
    ]).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.linear));
  }

  @override
  void didUpdateWidget(covariant MathOptionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected && !oldWidget.isSelected) {
      _animCtrl.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isWrong = widget.isSelected && widget.isCorrect == false;
    final isRight = widget.isCorrect == true;

    Color cardBgColor = widget.color.withOpacity(0.08);
    Color borderColor = widget.color.withOpacity(0.4);

    if (widget.isCorrect != null) {
      if (isRight) {
        cardBgColor = AppTheme.accentMint.withOpacity(0.12);
        borderColor = AppTheme.accentMint;
      } else if (isWrong) {
        cardBgColor = AppTheme.accentCoral.withOpacity(0.12);
        borderColor = AppTheme.accentCoral;
      }
    }

    return GestureDetector(
      onTapDown: (_) {
        setState(() {
          _isPressed = true;
        });
      },
      onTapUp: (_) {
        setState(() {
          _isPressed = false;
        });
        widget.onTap();
      },
      onTapCancel: () {
        setState(() {
          _isPressed = false;
        });
      },
      child: AnimatedBuilder(
        animation: _animCtrl,
        builder: (context, child) {
          double offsetX = isWrong ? _shakeAnim.value : 0.0;
          double scale = 1.0;

          if (_isPressed) {
            scale = 0.94;
          } else if (widget.isSelected && isRight) {
            scale = 1.0 + (math.sin(_animCtrl.value * math.pi) * 0.06);
          }

          return Transform.translate(
            offset: Offset(offsetX, 0.0),
            child: Transform.scale(
              scale: scale,
              child: child,
            ),
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: cardBgColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: borderColor,
              width: widget.isSelected ? 2.5 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: (widget.isCorrect != null
                        ? (isRight ? AppTheme.accentMint : AppTheme.accentCoral)
                        : widget.color)
                    .withOpacity(widget.isSelected ? 0.2 : 0.05),
                blurRadius: widget.isSelected ? 14 : 8,
              ),
            ],
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: _buildNumberText(widget.expr, widget.color),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNumberText(String expr, Color color) {
    final ts = const TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.w800,
      color: AppTheme.textPrimary,
    );

    if (expr.contains('/')) {
      final p = expr.split('/');
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(p[0], style: ts),
          Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            width: 32,
            height: 2,
            color: AppTheme.textPrimary,
          ),
          Text(p[1], style: ts),
        ],
      );
    }

    if (expr.contains('^')) {
      final p = expr.split('^');
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(p[0], style: ts),
              Transform.translate(
                offset: const Offset(1, -10),
                child: Text(p[1], style: ts.copyWith(fontSize: 15)),
              ),
            ],
          ),
        ],
      );
    }

    if (expr.contains('%')) {
      final p = expr.split(' ');
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(p[0], style: ts.copyWith(fontSize: 20)),
          Text('of ${p[2]}', style: ts.copyWith(fontSize: 14)),
        ],
      );
    }

    if (expr.contains('√')) {
      final idx = expr.indexOf('√');
      final coef = expr.substring(0, idx);
      final inside = expr.substring(idx + 1);
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (coef != '1') Text(coef, style: ts),
              Text('√', style: ts.copyWith(fontSize: 28)),
              Text(inside, style: ts),
            ],
          ),
        ],
      );
    }

    final measUnits = [
      'km', 'm', 'cm', 'mm', 't', 'kg', 'g', 'mg',
      'kL', 'L', 'dL', 'mL', 'days', 'hours', 'mins', 'secs'
    ];
    if (measUnits.any((u) => expr.endsWith(' $u'))) {
      final parts = expr.split(' ');
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(parts[0], style: ts),
          Text(
            parts.sublist(1).join(' '),
            style: ts.copyWith(fontSize: 16, color: color),
          ),
        ],
      );
    }

    if (expr.contains('+') ||
        expr.contains('-') ||
        expr.contains('*') ||
        expr.contains('/')) {
      final parts = expr.split(' ');
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(parts[0], style: ts.copyWith(fontSize: 18)),
          Text(parts[1], style: ts.copyWith(fontSize: 20, color: color)),
          Text(parts[2], style: ts.copyWith(fontSize: 18)),
        ],
      );
    }

    return Text(expr, style: ts);
  }
}
