import 'package:flutter/material.dart';

class AppTheme {
  // Low-stress dark background colors
  static const Color background = Color(0xFF0F172A); // Deep slate
  static const Color cardBackground = Color(0xFF1E293B); // Muted dark slate
  
  // Neutral Text colors
  static const Color textPrimary = Color(0xFFF8FAFC); // Very soft off-white
  static const Color textSecondary = Color(0xFF94A3B8); // Muted slate gray
  static const Color textHint = Color(0xFF64748B); // Darker slate gray
  
  // Game Rewards
  static const Color gold = Color(0xFFEAB308); // Soft golden yellow
  static const Color gem = Color(0xFF06B6D4); // Soft crystal cyan/cyan gem
  
  // Desaturated low eye-strain accent colors
  static const Color accentTeal = Color(0xFF0D9488); // Soft teal
  static const Color accentViolet = Color(0xFF7C3AED); // Muted violet
  static const Color accentAmber = Color(0xFFD97706); // Warm amber
  static const Color accentCoral = Color(0xFFE11D48); // Soft rose/coral red
  static const Color accentMint = Color(0xFF059669); // Soft mint green
  static const Color accentBlue = Color(0xFF2563EB); // Soft blue
  
  // Gradients
  static LinearGradient get backgroundGradient => const LinearGradient(
        colors: [Color(0xFF0F172A), Color(0xFF1E1E2F)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      );

  static LinearGradient tealGradient() => const LinearGradient(
        colors: [accentTeal, Color(0xFF0F766E)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static LinearGradient violetGradient() => const LinearGradient(
        colors: [accentViolet, Color(0xFF6D28D9)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static LinearGradient goldGradient() => const LinearGradient(
        colors: [gold, Color(0xFFCA8A04)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static LinearGradient gemGradient() => const LinearGradient(
        colors: [gem, Color(0xFF0891B2)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static LinearGradient coralGradient() => const LinearGradient(
        colors: [accentCoral, Color(0xFFBE123C)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  // Glassmorphic card decoration
  static BoxDecoration glassCard({
    Color? borderColor,
    double radius = 16,
  }) {
    return BoxDecoration(
      color: cardBackground.withOpacity(0.7),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: borderColor ?? textSecondary.withOpacity(0.15),
        width: 1.5,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.2),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }
}
