import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

class CoinService extends ChangeNotifier {
  int _coins = 100; // Start with 100 coins
  int _gems = 15;   // Start with 15 gems so they can test attempt buying

  int get coins => _coins;
  int get gems => _gems;

  late Box _box;

  Future<void> init() async {
    _box = await Hive.openBox('wallet');
    _coins = _box.get('coins', defaultValue: 100);
    _gems = _box.get('gems', defaultValue: 15);
    notifyListeners();
  }

  void addCoins(int count) {
    if (count <= 0) return;
    _coins += count;
    _box.put('coins', _coins);
    notifyListeners();
  }

  void addGems(int count) {
    if (count <= 0) return;
    _gems += count;
    _box.put('gems', _gems);
    notifyListeners();
  }

  bool useGems(int count) {
    if (_gems >= count) {
      _gems -= count;
      _box.put('gems', _gems);
      notifyListeners();
      return true;
    }
    return false;
  }

  bool exchangeCoinsForGems(int coinCost, int gemAmount) {
    if (_coins >= coinCost) {
      _coins -= coinCost;
      _gems += gemAmount;
      _box.put('coins', _coins);
      _box.put('gems', _gems);
      notifyListeners();
      return true;
    }
    return false;
  }

  static int coinsForScore(int score) {
    return score ~/ 10;
  }
}
