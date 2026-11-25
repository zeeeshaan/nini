import 'package:flutter/material.dart';
import 'package:nini/core/theme/app_text_styles/app_text_styles.dart';

class SettingsNotice extends StatelessWidget {
  const SettingsNotice({super.key, required this.text});
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
    child: Text(
      text,
      textAlign: TextAlign.right,
      style: AppTextStyles.helper,
      textDirection: TextDirection.ltr,
    ),
  );
}
