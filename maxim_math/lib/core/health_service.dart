import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class HealthService extends ChangeNotifier {
  static const int maxAttempts = 5;
  late Box _box;
  
  // Rewarded Ad state
  RewardedAd? _rewardedAd;
  bool _isAdLoading = false;

  bool get isAdReady => _rewardedAd != null;
  bool get isAdLoading => _isAdLoading;

  Future<void> init() async {
    _box = await Hive.openBox('health');
    loadRewardedAd();
  }

  int getAttempts(String topicId) {
    return _box.get('attempts_$topicId', defaultValue: maxAttempts) as int;
  }

  Future<void> setAttempts(String topicId, int attempts) async {
    final clampedAttempts = attempts.clamp(0, maxAttempts);
    await _box.put('attempts_$topicId', clampedAttempts);
    notifyListeners();
  }

  Future<void> decrementAttempts(String topicId) async {
    final current = getAttempts(topicId);
    if (current > 0) {
      await setAttempts(topicId, current - 1);
    }
  }

  Future<void> refillHealth(String topicId) async {
    await setAttempts(topicId, maxAttempts);
  }

  // Google Mobile Ads integration
  void loadRewardedAd() {
    if (Platform.environment.containsKey('FLUTTER_TEST')) return;
    if (_isAdLoading || _rewardedAd != null) return;
    
    _isAdLoading = true;
    notifyListeners();

    final String adUnitId = Platform.isAndroid
        ? 'ca-app-pub-3940256099942544/5224354917' // Android Test Rewarded Ad Unit ID
        : 'ca-app-pub-3940256099942544/1712485313'; // iOS Test Rewarded Ad Unit ID

    RewardedAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isAdLoading = false;
          notifyListeners();
        },
        onAdFailedToLoad: (error) {
          _rewardedAd = null;
          _isAdLoading = false;
          notifyListeners();
          // Try reloading after a delay
          Future.delayed(const Duration(seconds: 10), () {
            loadRewardedAd();
          });
        },
      ),
    );
  }

  void showRewardedAd({
    required String topicId,
    required VoidCallback onRewardEarned,
    required VoidCallback onAdFailed,
  }) {
    if (_rewardedAd == null) {
      onAdFailed();
      loadRewardedAd();
      return;
    }

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _rewardedAd = null;
        loadRewardedAd(); // Load the next ad
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _rewardedAd = null;
        loadRewardedAd();
        onAdFailed();
      },
    );

    _rewardedAd!.show(
      onUserEarnedReward: (ad, rewardItem) {
        refillHealth(topicId);
        onRewardEarned();
      },
    );
  }
}
