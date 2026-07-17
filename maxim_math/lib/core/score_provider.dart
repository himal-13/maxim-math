import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

class GameId {
  static const String numberDuel = 'number_duel'; // Compatibility with old code
  static const String infinity = 'infinity';
  static const String fractions = 'fractions';
  static const String percentages = 'percentages';
  static const String powersRoots = 'powers_roots';
  static const String measurement = 'measurement';
  static const String decimalsArithmetic = 'decimals_arithmetic';
  static const String basicOps = 'basic_ops';
}

class ScoreProvider extends ChangeNotifier {
  late Box _box;
  final Map<String, int> _highScores = {};

  Future<void> init() async {
    _box = await Hive.openBox('scores');
    for (final key in _box.keys) {
      if (key is String) {
        final val = _box.get(key);
        if (val is int) {
          _highScores[key] = val;
        }
      }
    }
    notifyListeners();
  }

  int getHighScore(String gameId) {
    return _highScores[gameId] ?? 0;
  }

  Future<void> submitScore(String gameId, int score) async {
    final currentHS = getHighScore(gameId);
    if (score > currentHS) {
      _highScores[gameId] = score;
      await _box.put(gameId, score);
      notifyListeners();
    }
  }
}
