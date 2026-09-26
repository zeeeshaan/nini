import 'package:flutter/material.dart';

/// The app's single source of truth for color. Every screen draws from
/// this black / white / gray palette — no other hues are introduced.
class AppColors {
  AppColors._();

  static const Color deepBlack = Color(0xFF1A1A1A);
  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color midGray = Color(0xFFA9A9A9);

  // Tints/shades derived from the three colors above, for surfaces,
  // dividers and disabled states — still strictly black/white/gray.
  static const Color surfaceOnDark = Color(0xFF262626); // deepBlack, lifted
  static const Color surfaceOnLight = Color(0xFFF2F2F2); // pureWhite, dimmed
  static const Color divider = Color(0xFFE4E4E4);
  static const Color dividerOnDark = Color(0xFF333333);
}
