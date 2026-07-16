import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'core/audio_manager.dart';
import 'core/reward_provider.dart';
import 'core/score_provider.dart';
import 'core/app_theme.dart';
import 'core/coin_service.dart';

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
    setState(() {
      _isGameActive = true;
      _isGameOver = false;
      _levelCompleted = false;
      _showBuyAttemptsDialog = false;
      _score = 0;
      _attemptsLeft = _isInfinityMode ? 5 : 5;
      _streak = 0;
      _correctAnswersLevel = 0;
      _correctAnswersTotal = 0;
      _timeLeft = 10;
      _feedback = null;
      if (!_isInfinityMode) {
        final rp = Provider.of<RewardProvider>(context, listen: false);
        _currentLevel = rp.getTopicLevel(widget.topicId);
      } else {
        _currentLevel = 1;
      }
    });
    _generateQuestion();
    _startTimer();
    Provider.of<RewardProvider>(context, listen: false).recordGamePlayed();
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
    setState(() {
      _attemptsLeft--;
      _streak = 0;
      _feedback = 'Too slow!';
      _feedbackCorrect = false;

      if (_attemptsLeft <= 0) {
        _showBuyAttemptsDialog = true;
        return;
      }
    });

    _feedbackTimer = Timer(const Duration(milliseconds: 1000), () {
      if (mounted && _isGameActive && !_isGameOver && !_showBuyAttemptsDialog) {
        setState(() {
          _feedback = null;
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
        GameId.fractions,
        GameId.percentages,
        GameId.powersRoots,
        GameId.measurement,
        GameId.decimalsArithmetic,
      ];
      currentTopic = topics[_random.nextInt(topics.length)];
    }

    // Generate options with distinct values
    double targetVal = 10.0 + _random.nextDouble() * 90.0;
    if (currentTopic == GameId.fractions) {
      targetVal = 0.2 + _random.nextDouble() * 2.5;
    } else if (currentTopic == GameId.measurement) {
      targetVal = 5.0 + _random.nextDouble() * 1500.0;
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

        expr = _generateExpressionForTopic(currentTopic, optionTarget);
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
      case 'kg':
        return val * 1000.0;
      case 'g':
        return val;
      case 'mg':
        return val / 1000.0;
      case 'L':
        return val;
      case 'mL':
        return val / 1000.0;
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
        _showBuyAttemptsDialog)
      return;
    _stopAllTimers();

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
      setState(() {
        _attemptsLeft--;
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

    // Give coins and gems as reward
    final coinsReward = _currentLevel * 10;
    final gemsReward = _currentLevel * 2;

    final cs = Provider.of<CoinService>(context, listen: false);
    cs.addCoins(coinsReward);
    cs.addGems(gemsReward);

    // Save progression
    final rp = Provider.of<RewardProvider>(context, listen: false);
    rp.saveTopicLevel(widget.topicId, _currentLevel + 1);

    setState(() {
      _levelCompleted = true;
    });
  }

  void _buyAttempts() {
    final cs = Provider.of<CoinService>(context, listen: false);

    // Cost: 10 Gems for 3 Attempts
    if (cs.useGems(10)) {
      AudioManager.playCoin();
      setState(() {
        _attemptsLeft = 3;
        _showBuyAttemptsDialog = false;
        _feedback = null;
        _timeLeft = 10;
      });
      _generateQuestion();
      _startTimer();
    } else {
      // Show failure prompt
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Not enough gems! Go to exchange coins in Menu or play levels.',
          ),
          backgroundColor: AppTheme.accentCoral,
        ),
      );
    }
  }

  void _gameOver() {
    _stopAllTimers();
    AudioManager.playGameOver();

    final sp = Provider.of<ScoreProvider>(context, listen: false);
    final cs = Provider.of<CoinService>(context, listen: false);

    sp.submitScore(widget.topicId, _score);
    final earned = CoinService.coinsForScore(_score);
    if (earned > 0) {
      cs.addCoins(earned);
      AudioManager.playCoin();
    }

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
      _attemptsLeft = 5;
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
        actions: [_buildCoinAndGemBadge()],
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

  Widget _buildCoinAndGemBadge() {
    return Consumer<CoinService>(
      builder: (ctx, cs, _) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: AppTheme.glassCard(
              borderColor: AppTheme.gold.withOpacity(0.3),
              radius: 20,
            ),
            child: Row(
              children: [
                const Icon(Icons.toll_rounded, color: AppTheme.gold, size: 16),
                const SizedBox(width: 4),
                Text(
                  '${cs.coins}',
                  style: const TextStyle(
                    color: AppTheme.gold,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: AppTheme.glassCard(
              borderColor: AppTheme.gem.withOpacity(0.3),
              radius: 20,
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.diamond_rounded,
                  color: AppTheme.gem,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  '${cs.gems}',
                  style: const TextStyle(
                    color: AppTheme.gem,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
        ],
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
              Row(
                children: List.generate(5, (index) {
                  return Icon(
                    index < _attemptsLeft
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    color: AppTheme.accentCoral,
                    size: 20,
                  );
                }),
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

    // Choose beautiful eye-pleasing topic-specific colors
    final colors = [
      AppTheme.accentTeal,
      AppTheme.accentViolet,
      AppTheme.accentAmber,
      AppTheme.accentMint,
    ];
    final color = colors[i % colors.length];

    return GestureDetector(
      onTap: () => _handleChoice(i),
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.4), width: 1.5),
          boxShadow: [
            BoxShadow(color: color.withOpacity(0.08), blurRadius: 10),
          ],
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: _buildNumberText(_numbers[i], color),
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
    final sub = TextStyle(
      color: color.withOpacity(0.8),
      fontSize: 11,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.8,
    );

    // Fractions
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
          const SizedBox(height: 6),
          Text('FRACTION', style: sub),
        ],
      );
    }

    // Powers
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
          const SizedBox(height: 8),
          Text('POWER', style: sub),
        ],
      );
    }

    // Percentages
    if (expr.contains('%')) {
      final p = expr.split(' ');
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(p[0], style: ts.copyWith(fontSize: 20)),
          Text('of ${p[2]}', style: ts.copyWith(fontSize: 14)),
          const SizedBox(height: 8),
          Text('PERCENT', style: sub),
        ],
      );
    }

    // Roots
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
          const SizedBox(height: 8),
          Text('ROOT', style: sub),
        ],
      );
    }

    // Measurement
    if (expr.contains(' km') ||
        expr.contains(' m') ||
        expr.contains(' cm') ||
        expr.contains(' mm') ||
        expr.contains(' kg') ||
        expr.contains(' g') ||
        expr.contains(' mg') ||
        expr.contains(' L') ||
        expr.contains(' mL') ||
        expr.contains(' hours') ||
        expr.contains(' mins') ||
        expr.contains(' secs')) {
      final parts = expr.split(' ');
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(parts[0], style: ts),
          Text(
            parts.sublist(1).join(' '),
            style: ts.copyWith(fontSize: 16, color: color),
          ),
          const SizedBox(height: 8),
          Text('MEASURE', style: sub),
        ],
      );
    }

    // Arithmetic / Equations
    if (expr.contains('+') ||
        expr.contains('-') ||
        expr.contains('*') ||
        expr.contains('/')) {
      // Split into parts to display beautifully
      final parts = expr.split(' ');
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(parts[0], style: ts.copyWith(fontSize: 18)),
          Text(parts[1], style: ts.copyWith(fontSize: 20, color: color)),
          Text(parts[2], style: ts.copyWith(fontSize: 18)),
          const SizedBox(height: 6),
          Text('EXPRESSION', style: sub),
        ],
      );
    }

    return Text(expr, style: ts);
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
    final coinsReward = _currentLevel * 10;
    final gemsReward = _currentLevel * 2;

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
                const SizedBox(height: 24),
                const Text(
                  'REWARDS RECEIVED',
                  style: TextStyle(
                    color: AppTheme.textHint,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.gold.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppTheme.gold.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.toll_rounded,
                            color: AppTheme.gold,
                            size: 20,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '+$coinsReward',
                            style: const TextStyle(
                              color: AppTheme.gold,
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.gem.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppTheme.gem.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.diamond_rounded,
                            color: AppTheme.gem,
                            size: 20,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '+$gemsReward',
                            style: const TextStyle(
                              color: AppTheme.gem,
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
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
                'OUT OF ATTEMPTS!',
                style: TextStyle(
                  color: AppTheme.accentCoral,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Buy 3 more attempts to continue playing this level without losing progress.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 28),
              GestureDetector(
                onTap: _buyAttempts,
                child: Container(
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: AppTheme.gemGradient(),
                    borderRadius: BorderRadius.circular(26),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.gem.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.diamond_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'BUY ATTEMPTS FOR 10 GEMS',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          letterSpacing: 0.5,
                        ),
                      ),
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
    final earned = CoinService.coinsForScore(_score);

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
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.toll_rounded,
                    color: AppTheme.gold,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '+$earned coins',
                    style: const TextStyle(
                      color: AppTheme.gold,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
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
                      onTap: _startGame,
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
