import 'package:flutter/material.dart';

/// Converts a 2-letter ISO country code into its flag emoji using the
/// Unicode regional indicator symbols (e.g. "US" -> 🇺🇸).
String flagEmoji(String iso2) {
  final codeUnits = iso2.toUpperCase().codeUnits.map(
    (c) => 0x1F1E6 + (c - 0x41),
  );
  return String.fromCharCodes(codeUnits);
}

/// Renders a country's flag as an emoji glyph.
class FlagChip extends StatelessWidget {
  const FlagChip({super.key, required this.iso2, this.size = 28});

  final String iso2;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Text(flagEmoji(iso2), style: TextStyle(fontSize: size, height: 1));
  }
}
