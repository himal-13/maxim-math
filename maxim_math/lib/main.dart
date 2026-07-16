import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'core/coin_service.dart';
import 'core/score_provider.dart';
import 'core/reward_provider.dart';
import 'core/audio_manager.dart';
import 'core/app_theme.dart';
import 'maxim_math.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  final coinService = CoinService();
  await coinService.init();

  final scoreProvider = ScoreProvider();
  await scoreProvider.init();

  final rewardProvider = RewardProvider();
  await rewardProvider.init();

  await AudioManager.load();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: coinService),
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
  void _openExchangeDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return const GemExchangeDialog();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
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
                      const SizedBox(height: 24),
                      _buildInfinityCard(),
                      const SizedBox(height: 32),
                      const Text(
                        'TOPIC CHAMPIONSHIPS',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildTopicGrid(),
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
    return Consumer<CoinService>(
      builder: (ctx, cs, _) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),

        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.school_rounded,
                  color: AppTheme.accentTeal,
                  size: 26,
                ),
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
            Row(
              children: [
                // Coins
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: AppTheme.glassCard(
                    borderColor: AppTheme.gold.withOpacity(0.3),
                    radius: 20,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.toll_rounded,
                        color: AppTheme.gold,
                        size: 16,
                      ),
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
                // Gems
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
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
                const SizedBox(width: 8),
                // Exchange
                IconButton(
                  onPressed: _openExchangeDialog,
                  icon: const Icon(Icons.swap_horizontal_circle_outlined),
                  color: AppTheme.accentTeal,
                  tooltip: 'Exchange Coins for Gems',
                ),
              ],
            ),
          ],
        ),
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

  Widget _buildInfinityCard() {
    final sp = Provider.of<ScoreProvider>(context);
    final highscore = sp.getHighScore(GameId.infinity);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.accentViolet.withOpacity(0.18),
            AppTheme.accentTeal.withOpacity(0.18),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppTheme.accentViolet.withOpacity(0.35),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.accentViolet.withOpacity(0.1),
            blurRadius: 15,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.accentViolet.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.accentViolet.withOpacity(0.4),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.all_inclusive_rounded,
                      color: AppTheme.accentViolet,
                      size: 16,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'ENDLESS MODE',
                      style: TextStyle(
                        color: AppTheme.accentViolet,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  const Icon(
                    Icons.emoji_events_rounded,
                    color: AppTheme.gold,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Best Score: $highscore',
                    style: const TextStyle(
                      color: AppTheme.gold,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Text(
            'INFINITY DUEL',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Combine all math topics (Fractions, Decimals, Measurements, Percentages, and Powers) into a single ultimate challenge. Level up as you progress!',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      const MaximMath(topicId: GameId.infinity),
                ),
              );
            },
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
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.play_arrow_rounded, color: Colors.white),
                  SizedBox(width: 6),
                  Text(
                    'PLAY INFINITY DUEL',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopicGrid() {
    final topics = [
      _TopicInfo(
        id: GameId.fractions,
        title: 'Fractions Duel',
        desc: 'Compare and rank fractions.',
        icon: Icons.pie_chart_rounded,
        color: AppTheme.accentViolet,
      ),
      _TopicInfo(
        id: GameId.percentages,
        title: 'Percentages',
        desc: 'Calculate percentages of bases.',
        icon: Icons.percent_rounded,
        color: AppTheme.accentTeal,
      ),
      _TopicInfo(
        id: GameId.powersRoots,
        title: 'Powers & Roots',
        desc: 'Evaluate exponents & square roots.',
        icon: Icons.superscript_rounded,
        color: AppTheme.accentMint,
      ),
      _TopicInfo(
        id: GameId.measurement,
        title: 'Measurement',
        desc: 'Compare Length, Weight, & Time.',
        icon: Icons.square_foot_rounded,
        color: AppTheme.accentAmber,
      ),
      _TopicInfo(
        id: GameId.decimalsArithmetic,
        title: 'Decimals & Ops',
        desc: 'Solve simple math expressions.',
        icon: Icons.calculate_rounded,
        color: AppTheme.accentCoral,
      ),
    ];

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: topics.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        return _buildTopicCard(topics[index]);
      },
    );
  }

  Widget _buildTopicCard(_TopicInfo topic) {
    final rp = Provider.of<RewardProvider>(context);
    final sp = Provider.of<ScoreProvider>(context);

    final level = rp.getTopicLevel(topic.id);
    final bestScore = sp.getHighScore(topic.id);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: AppTheme.glassCard(
        borderColor: topic.color.withOpacity(0.2),
        radius: 20,
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: topic.color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: topic.color.withOpacity(0.35)),
            ),
            child: Icon(topic.icon, color: topic.color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      topic.title,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: topic.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: topic.color.withOpacity(0.3)),
                      ),
                      child: Text(
                        'Level $level',
                        style: TextStyle(
                          color: topic.color,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  topic.desc,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Best Score: $bestScore',
                      style: const TextStyle(
                        color: AppTheme.textHint,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MaximMath(topicId: topic.id),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: topic.color,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 14,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'PLAY',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class GemExchangeDialog extends StatefulWidget {
  const GemExchangeDialog({super.key});

  @override
  State<GemExchangeDialog> createState() => _GemExchangeDialogState();
}

class _GemExchangeDialogState extends State<GemExchangeDialog> {
  void _exchange(int coins, int gems) {
    final cs = Provider.of<CoinService>(context, listen: false);
    if (cs.exchangeCoinsForGems(coins, gems)) {
      AudioManager.playCoin();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully exchanged $coins Coins for $gems Gems!'),
          backgroundColor: AppTheme.accentMint,
        ),
      );
      Navigator.pop(context);
    } else {
      AudioManager.playWrong();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Not enough coins to exchange!'),
          backgroundColor: AppTheme.accentCoral,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: AppTheme.glassCard(
          borderColor: AppTheme.gem.withOpacity(0.3),
          radius: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.swap_horizontal_circle_rounded,
              color: AppTheme.gem,
              size: 48,
            ),
            const SizedBox(height: 14),
            const Text(
              'GEM EXCHANGE',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Exchange your hard-earned level coins to buy gems for attempts!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 13,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 24),
            _exchangeOption(100, 10),
            const SizedBox(height: 12),
            _exchangeOption(250, 30),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Text(
                'CLOSE',
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

  Widget _exchangeOption(int coins, int gems) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.textSecondary.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(
                '$coins',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppTheme.gold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.toll_rounded, color: AppTheme.gold, size: 16),
              const SizedBox(width: 10),
              const Icon(
                Icons.arrow_forward_rounded,
                color: AppTheme.textSecondary,
                size: 14,
              ),
              const SizedBox(width: 10),
              Text(
                '$gems',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppTheme.gem,
                  fontSize: 16,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.diamond_rounded, color: AppTheme.gem, size: 16),
            ],
          ),
          GestureDetector(
            onTap: () => _exchange(coins, gems),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                gradient: AppTheme.gemGradient(),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'EXCHANGE',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopicInfo {
  final String id;
  final String title;
  final String desc;
  final IconData icon;
  final Color color;

  _TopicInfo({
    required this.id,
    required this.title,
    required this.desc,
    required this.icon,
    required this.color,
  });
}
