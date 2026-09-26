import 'package:flutter/material.dart';
import '../app_colors.dart';
import '../theme_controller.dart';
import 'mode_screen.dart';

class AccessibilityScreen extends StatefulWidget {
  const AccessibilityScreen({super.key});

  @override
  State<AccessibilityScreen> createState() => _AccessibilityScreenState();
}

class _AccessibilityScreenState extends State<AccessibilityScreen> {
  bool _reduceMotion = false;
  bool _boldText = false;
  bool _largerText = false;

  static const _modeLabels = {
    ThemeMode.dark: 'تیره',
    ThemeMode.light: 'روشن',
    ThemeMode.system: 'پیش‌فرض سیستم',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pureWhite,
      body: SafeArea(
        child: Column(
          children: [
            _Header(
              title: 'دسترس‌پذیری',
              onSave: () => ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('تنظیمات ذخیره شد'))),
            ),
            Expanded(
              child: ValueListenableBuilder<ThemeMode>(
                valueListenable: ThemeController.mode,
                builder: (context, mode, _) {
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(22, 8, 22, 28),
                    children: [
                      _LinkRow(
                        label: 'حالت نمایش',
                        value: _modeLabels[mode]!,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const ModeScreen()),
                        ),
                      ),
                      const Divider(height: 28, color: AppColors.divider),
                      _ToggleRow(
                        label: 'کاهش حرکت',
                        value: _reduceMotion,
                        onChanged: (v) => setState(() => _reduceMotion = v),
                      ),
                      _ToggleRow(
                        label: 'متن پررنگ',
                        value: _boldText,
                        onChanged: (v) => setState(() => _boldText = v),
                      ),
                      _ToggleRow(
                        label: 'متن بزرگ‌تر',
                        value: _largerText,
                        onChanged: (v) => setState(() => _largerText = v),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.title, required this.onSave});
  final String title;
  final VoidCallback onSave;

  static const _ink = AppColors.deepBlack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(6, 10, 18, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.chevron_left, color: _ink, size: 30),
          ),
          Text(
            title,
            style: const TextStyle(
              color: _ink,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const Spacer(),
          InkWell(
            onTap: onSave,
            customBorder: const CircleBorder(),
            child: const Padding(
              padding: EdgeInsets.all(8),
              child: Icon(Icons.check, color: _ink, size: 24),
            ),
          ),
        ],
      ),
    );
  }
}

class _LinkRow extends StatelessWidget {
  const _LinkRow({
    required this.label,
    required this.value,
    required this.onTap,
  });
  final String label;
  final String value;
  final VoidCallback onTap;

  static const _ink = AppColors.deepBlack;
  static const _muted = AppColors.midGray;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: _ink,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              value,
              style: TextStyle(
                color: _muted.withValues(alpha: 0.9),
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              Icons.chevron_right,
              size: 18,
              color: _muted.withValues(alpha: 0.7),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  static const _ink = AppColors.deepBlack;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: _ink,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Switch.adaptive(
              value: value,
              onChanged: onChanged,
              activeThumbColor: AppColors.pureWhite,
              activeTrackColor: _ink,
              inactiveThumbColor: AppColors.pureWhite,
              inactiveTrackColor: AppColors.divider,
              trackOutlineColor: const WidgetStatePropertyAll(
                Colors.transparent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
