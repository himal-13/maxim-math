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
                          Expanded(child: _buildSmallTopicItem(advanceTopics[0])),
                          const SizedBox(width: 10),
                          Expanded(child: _buildSmallTopicItem(advanceTopics[1])),
                          const SizedBox(width: 10),
                          Expanded(child: _buildSmallTopicItem(advanceTopics[2])),
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

  Widget _buildSmallTopicItem(_TopicInfo topic) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MaximMath(topicId: topic.id),
          ),
        );
      },
      child: Container(
        height: 110,
        decoration: AppTheme.glassCard(
          borderColor: topic.color.withOpacity(0.2),
          radius: 20,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: topic.color.withOpacity(0.12),
                shape: BoxShape.circle,
                border: Border.all(
                  color: topic.color.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Icon(
                topic.icon,
                color: topic.color,
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
          ],
        ),
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
  final IconData icon;
  final Color color;

  _TopicInfo({
    required this.id,
    required this.title,
    required this.icon,
    required this.color,
  });
}
