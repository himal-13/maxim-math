import 'package:flutter/material.dart';

class AppTheme {
  // Vibrant dark background colors - more depth and richness
  static const Color background = Color(0xFF0A0E27); // Deep navy-blue
  static const Color cardBackground = Color(
    0xFF141B3D,
  ); // Rich dark blue-purple

  // Bright, clear text colors
  static const Color textPrimary = Color(0xFFF0F4FF); // Crisp off-white
  static const Color textSecondary = Color(0xFFA8B5E0); // Soft lavender-gray
  static const Color textHint = Color(0xFF6B7AA8); // Muted blue-gray

  // Game Rewards - brighter and more distinct
  static const Color gold = Color(0xFFFFD700); // Bright gold
  static const Color gem = Color(0xFF00E5FF); // Cyan gem

  // Vivid, high-energy accent colors for better engagement
  static const Color accentTeal = Color(0xFF00D4AA); // Bright teal
  static const Color accentViolet = Color(0xFF9D4EDD); // Vibrant purple
  static const Color accentAmber = Color(0xFFFFB703); // Warm golden-amber
  static const Color accentCoral = Color(0xFFFF6B6B); // Bright coral red
  static const Color accentMint = Color(0xFF00E676); // Vibrant mint green
  static const Color accentBlue = Color(0xFF4488FF); // Bright blue

  // Additional vibrant accent colors
  static const Color accentPink = Color(0xFFFF6BD6); // Hot pink
  static const Color accentOrange = Color(0xFFFF8C42); // Vivid orange
  static const Color accentLime = Color(0xFFB2FF59); // Neon lime

  // Gradients - more dynamic and visually interesting
  static LinearGradient get backgroundGradient => const LinearGradient(
    colors: [Color(0xFF0A0E27), Color(0xFF1A1A3E), Color(0xFF0D1F3C)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    stops: [0.0, 0.5, 1.0],
  );

  static LinearGradient tealGradient() => const LinearGradient(
    colors: [Color(0xFF00D4AA), Color(0xFF00B894)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient violetGradient() => const LinearGradient(
    colors: [Color(0xFF9D4EDD), Color(0xFF7B2FBE)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient goldGradient() => const LinearGradient(
    colors: [Color(0xFFFFD700), Color(0xFFF5A623)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient gemGradient() => const LinearGradient(
    colors: [Color(0xFF00E5FF), Color(0xFF00B8D4)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient coralGradient() => const LinearGradient(
    colors: [Color(0xFFFF6B6B), Color(0xFFE53935)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient pinkGradient() => const LinearGradient(
    colors: [Color(0xFFFF6BD6), Color(0xFFE040A0)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient orangeGradient() => const LinearGradient(
    colors: [Color(0xFFFF8C42), Color(0xFFF57C00)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient limeGradient() => const LinearGradient(
    colors: [Color(0xFFB2FF59), Color(0xFF76FF03)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Glassmorphic card decoration - more premium feel
  static BoxDecoration glassCard({Color? borderColor, double radius = 16}) {
    return BoxDecoration(
      color: cardBackground.withOpacity(0.75),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: borderColor ?? textSecondary.withOpacity(0.2),
        width: 1.5,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.3),
          blurRadius: 15,
          offset: const Offset(0, 6),
          spreadRadius: 1,
        ),
        BoxShadow(
          color: (borderColor ?? Colors.transparent).withOpacity(0.1),
          blurRadius: 20,
          offset: const Offset(0, 0),
        ),
      ],
    );
  }

  // Helper method for glowing effects
  static BoxDecoration glowDecoration({
    required Color color,
    double radius = 16,
    double spread = 8,
    double blur = 20,
  }) {
    return BoxDecoration(
      color: color.withOpacity(0.08),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: color.withOpacity(0.4), width: 2),
      boxShadow: [
        BoxShadow(
          color: color.withOpacity(0.25),
          blurRadius: blur,
          spreadRadius: spread,
        ),
      ],
    );
  }

  // Progress bar colors
  static Color progressColor(double progress) {
    if (progress < 0.3) return accentCoral;
    if (progress < 0.6) return accentAmber;
    if (progress < 0.8) return accentTeal;
    return accentMint;
  }
}
