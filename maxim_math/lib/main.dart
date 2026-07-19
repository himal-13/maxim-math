import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'core/health_service.dart';
import 'core/score_provider.dart';
import 'core/reward_provider.dart';
import 'core/audio_manager.dart';
import 'core/app_theme.dart';
import 'maxim_math.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await MobileAds.instance.initialize();
  await Hive.initFlutter();

  final healthService = HealthService();
  await healthService.init();

  final scoreProvider = ScoreProvider();
  await scoreProvider.init();

  final rewardProvider = RewardProvider();
  await rewardProvider.init();

  await AudioManager.load();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: healthService),
        ChangeNotifierProvider.value(value: scoreProvider),
        ChangeNotifierProvider.value(value: rewardProvider),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Maxim Math',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppTheme.background,
        colorScheme: const ColorScheme.dark(
          primary: AppTheme.accentTeal,
          secondary: AppTheme.accentViolet,
          surface: AppTheme.cardBackground,
        ),
      ),
      home: const MathDashboard(),
    );
  }
}

class MathDashboard extends StatefulWidget {
  const MathDashboard({super.key});

  @override
  State<MathDashboard> createState() => _MathDashboardState();
}

class _MathDashboardState extends State<MathDashboard> {
  @override
  Widget build(BuildContext context) {
    final basicTopics = [
      _TopicInfo(
        id: GameId.basicOps,
        title: 'Basic Ops',
        icon: Icons.calculate_rounded,
        color: AppTheme.accentTeal,
      ),
      _TopicInfo(
        id: GameId.fractions,
        title: 'Fractions',
        icon: Icons.pie_chart_rounded,
        color: AppTheme.accentViolet,
      ),
      _TopicInfo(
        id: GameId.decimalsArithmetic,
        title: 'Decimals',
        icon: Icons.numbers_rounded,
        color: AppTheme.accentCoral,
      ),
    ];

    final advanceTopics = [
      _TopicInfo(
        id: GameId.percentages,
        title: 'Percent',
        icon: Icons.percent_rounded,
        color: AppTheme.accentTeal,
      ),
      _TopicInfo(
        id: GameId.powersRoots,
        title: 'Powers',
        icon: Icons.superscript_rounded,
        color: AppTheme.accentMint,
      ),
      _TopicInfo(
        id: GameId.infinity,
        title: 'Infinity',
        icon: Icons.all_inclusive_rounded,
        color: AppTheme.accentPink,
      ),
    ];

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              _buildTopBar(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 32),
                      const Text(
                        'BASIC MODE',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _buildSmallTopicItem(basicTopics[0])),
                          const SizedBox(width: 10),
                          Expanded(child: _buildSmallTopicItem(basicTopics[1])),
                          const SizedBox(width: 10),
                          Expanded(child: _buildSmallTopicItem(basicTopics[2])),
                        ],
                      ),
                      const SizedBox(height: 32),
                      const Text(
                        'ADVANCE MODE',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildSmallTopicItem(advanceTopics[0]),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildSmallTopicItem(advanceTopics[1]),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildSmallTopicItem(advanceTopics[2]),
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.school_rounded, color: AppTheme.accentTeal, size: 26),
              SizedBox(width: 8),
              Text(
                'Maxim Math',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Sharpen Your Mind',
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        ShaderMask(
          shaderCallback: (bounds) => AppTheme.tealGradient().createShader(
            Rect.fromLTWH(0, 0, bounds.width, bounds.height),
          ),
          child: const Text(
            'MATH DUELS',
            style: TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSmallTopicItem(_TopicInfo topic) {
    return Consumer<HealthService>(
      builder: (context, hs, _) {
        final attempts = hs.getAttempts(topic.id);
        final hasZeroHealth = attempts == 0;

        return GestureDetector(
          onTap: () {
            if (hasZeroHealth) {
              _showRefillDialog(topic.id, topic.title);
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MaximMath(topicId: topic.id),
                ),
              );
            }
          },
          child: Container(
            height: 125,
            decoration: AppTheme.glassCard(
              borderColor: hasZeroHealth
                  ? AppTheme.accentCoral.withOpacity(0.4)
                  : topic.color.withOpacity(0.2),
              radius: 20,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: (hasZeroHealth ? AppTheme.accentCoral : topic.color)
                        .withOpacity(0.12),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color:
                          (hasZeroHealth ? AppTheme.accentCoral : topic.color)
                              .withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    hasZeroHealth ? Icons.heart_broken_rounded : topic.icon,
                    color: hasZeroHealth ? AppTheme.accentCoral : topic.color,
                    size: 22,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  topic.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 6),
                _buildHealthIndicator(attempts),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHealthIndicator(int attempts) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        return Icon(
          index < attempts
              ? Icons.favorite_rounded
              : Icons.favorite_border_rounded,
          color: AppTheme.accentCoral,
          size: 11,
        );
      }),
    );
  }

  void _showRefillDialog(String topicId, String topicTitle) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return RefillHealthDialog(topicId: topicId, topicTitle: topicTitle);
      },
    );
  }
}

class RefillHealthDialog extends StatefulWidget {
  final String topicId;
  final String topicTitle;

  const RefillHealthDialog({
    super.key,
    required this.topicId,
    required this.topicTitle,
  });

  @override
  State<RefillHealthDialog> createState() => _RefillHealthDialogState();
}

class _RefillHealthDialogState extends State<RefillHealthDialog> {
  bool _isLoadingAd = false;

  void _watchAd() {
    final hs = Provider.of<HealthService>(context, listen: false);
    if (!hs.isAdReady) {
      setState(() {
        _isLoadingAd = true;
      });
      hs.loadRewardedAd();
      // Wait to see if ad loads
      Future.delayed(const Duration(seconds: 2), () {
        if (!mounted) return;
        if (hs.isAdReady) {
          setState(() {
            _isLoadingAd = false;
          });
          _showAd(hs);
        } else {
          setState(() {
            _isLoadingAd = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Failed to load rewarded ad. Please try again later.',
              ),
              backgroundColor: AppTheme.accentCoral,
            ),
          );
        }
      });
    } else {
      _showAd(hs);
    }
  }

  void _showAd(HealthService hs) {
    hs.showRewardedAd(
      topicId: widget.topicId,
      onRewardEarned: () {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Health fully restored for ${widget.topicTitle}!'),
            backgroundColor: AppTheme.accentMint,
          ),
        );
        Navigator.pop(context); // Close dialog
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

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: AppTheme.glassCard(
          borderColor: AppTheme.accentCoral.withOpacity(0.4),
          radius: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.favorite_rounded,
              color: AppTheme.accentCoral,
              size: 48,
            ),
            const SizedBox(height: 14),
            Text(
              '${widget.topicTitle.toUpperCase()} HEALTH',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'You have run out of health for this topic. Watch a rewarded ad to fully restore health (5 lives) and play!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 13,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 24),
            if (_isLoadingAd)
              const CircularProgressIndicator(color: AppTheme.accentCoral)
            else
              GestureDetector(
                onTap: _watchAd,
                child: Container(
                  height: 50,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: AppTheme.tealGradient(),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: const Center(
                    child: Text(
                      'WATCH REWARDED AD',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 14),
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: const Text(
                'CANCEL',
                style: TextStyle(
                  color: AppTheme.textHint,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopicInfo {
  final String id;
  final String title;
  final IconData icon;
  final Color color;

  _TopicInfo({
    required this.id,
    required this.title,
    required this.icon,
    required this.color,
  });
}
