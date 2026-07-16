import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

class RewardProvider extends ChangeNotifier {
  late Box _box;
  int _gamesPlayed = 0;

  Future<void> init() async {
    _box = await Hive.openBox('rewards');
    _gamesPlayed = _box.get('games_played', defaultValue: 0) as int;
    notifyListeners();
  }

  int get gamesPlayed => _gamesPlayed;

  void recordGamePlayed() {
    _gamesPlayed++;
    _box.put('games_played', _gamesPlayed);
    notifyListeners();
  }

  int getTopicLevel(String topicId) {
    return _box.get('level_$topicId', defaultValue: 1) as int;
  }

  Future<void> saveTopicLevel(String topicId, int level) async {
    final currentLevel = getTopicLevel(topicId);
    if (level > currentLevel) {
      await _box.put('level_$topicId', level);
      notifyListeners();
    }
  }

  static int coinsForScore(int score) {
    return score ~/ 10;
  }
}
