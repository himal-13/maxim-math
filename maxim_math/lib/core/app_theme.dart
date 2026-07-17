import 'package:flutter/material.dart';

class AppTheme {
  // Ultra-dark sophisticated background
  static const Color background = Color(
    0xFF05050A,
  ); // Almost black with slight blue tint
  static const Color cardBackground = Color(0xFF0D0D1A); // Deep dark navy
  static const Color surfaceDark = Color(0xFF12121F); // Slightly lighter dark

  // Premium text colors - glowing
  static const Color textPrimary = Color(
    0xFFF0F0FF,
  ); // Pure white with slight blue
  static const Color textSecondary = Color(0xFF8888AA); // Muted lavender gray
  static const Color textHint = Color(0xFF555577); // Darker muted

  // Game Rewards - vibrant but elegant
  static const Color gold = Color(0xFFFFD700); // Classic gold
  static const Color gem = Color(0xFF00D4FF); // Bright cyan

  // Neon-inspired accent colors - pop against dark background
  static const Color accentTeal = Color(0xFF00FFC8); // Neon teal
  static const Color accentViolet = Color(0xFFB388FF); // Soft neon purple
  static const Color accentAmber = Color(0xFFFFAB00); // Warm neon amber
  static const Color accentCoral = Color(0xFFFF5252); // Bright neon coral
  static const Color accentMint = Color(0xFF69F0AE); // Soft neon mint
  static const Color accentBlue = Color(0xFF4488FF); // Neon blue

  // Additional premium accents
  static const Color accentPink = Color(0xFFFF80AB); // Neon pink
  static const Color accentOrange = Color(0xFFFF9100); // Neon orange
  static const Color accentLime = Color(0xFFC6FF00); // Neon lime

  // Gradients - deep and dramatic
  static LinearGradient get backgroundGradient => const LinearGradient(
    colors: [
      Color(0xFF05050A), // Almost black
      Color(0xFF0A0A1A), // Deep navy
      Color(0xFF050510), // Darkest
    ],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    stops: [0.0, 0.5, 1.0],
  );

  static LinearGradient tealGradient() => const LinearGradient(
    colors: [Color(0xFF00FFC8), Color(0xFF00BFA5)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient violetGradient() => const LinearGradient(
    colors: [Color(0xFFB388FF), Color(0xFF7C4DFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient goldGradient() => const LinearGradient(
    colors: [Color(0xFFFFD700), Color(0xFFFF8F00)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient gemGradient() => const LinearGradient(
    colors: [Color(0xFF00D4FF), Color(0xFF0091EA)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient coralGradient() => const LinearGradient(
    colors: [Color(0xFFFF5252), Color(0xFFD50000)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient pinkGradient() => const LinearGradient(
    colors: [Color(0xFFFF80AB), Color(0xFFF50057)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient orangeGradient() => const LinearGradient(
    colors: [Color(0xFFFF9100), Color(0xFFE65100)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient limeGradient() => const LinearGradient(
    colors: [Color(0xFFC6FF00), Color(0xFF76FF03)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Glassmorphic card decoration - dark and premium
  static BoxDecoration glassCard({Color? borderColor, double radius = 16}) {
    return BoxDecoration(
      color: cardBackground.withOpacity(0.85),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: borderColor?.withOpacity(0.2) ?? textSecondary.withOpacity(0.1),
        width: 1.0,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.5),
          blurRadius: 20,
          offset: const Offset(0, 8),
          spreadRadius: 2,
        ),
        BoxShadow(
          color: (borderColor ?? Colors.transparent).withOpacity(0.05),
          blurRadius: 30,
          offset: const Offset(0, 0),
          spreadRadius: 5,
        ),
      ],
    );
  }

  // Dark glowing decoration
  static BoxDecoration glowDecoration({
    required Color color,
    double radius = 16,
    double spread = 4,
    double blur = 15,
  }) {
    return BoxDecoration(
      color: color.withOpacity(0.05),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: color.withOpacity(0.2), width: 1.5),
      boxShadow: [
        BoxShadow(
          color: color.withOpacity(0.1),
          blurRadius: blur,
          spreadRadius: spread,
        ),
        BoxShadow(
          color: color.withOpacity(0.05),
          blurRadius: blur * 2,
          spreadRadius: spread * 2,
        ),
      ],
    );
  }

  // Progress bar colors - smooth transition
  static Color progressColor(double progress) {
    if (progress < 0.25) return accentCoral;
    if (progress < 0.5) return accentAmber;
    if (progress < 0.75) return accentTeal;
    return accentMint;
  }

  // Dark surface with subtle border
  static BoxDecoration darkSurface({Color? borderColor, double radius = 12}) {
    return BoxDecoration(
      color: surfaceDark,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: borderColor?.withOpacity(0.15) ?? textHint.withOpacity(0.1),
        width: 1.0,
      ),
    );
  }
}
