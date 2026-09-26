import 'package:flutter/material.dart';
import '../app_colors.dart';
import 'profile_setting_screen.dart';
import 'locations_screen.dart';
import 'wallet_screen.dart';
import 'saved_screen.dart';
import 'notifications_screen.dart';
import 'trending_screen.dart';
import 'insights_screen.dart';
import 'scheduled_content_screen.dart';
import 'blocked_screen.dart';
import 'language_screen.dart';
import 'device_permissions_screen.dart';
import 'accessibility_screen.dart';
import 'my_media_screen.dart';
import 'tags_keywords_screen.dart';
import 'archive_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const _ink = AppColors.deepBlack;
  static const _divider = AppColors.divider;

  static const _generalItems = [
    'تنظیمات پروفایل',
    'مکان‌ها',
    'کیف پول',
    'ذخیره‌شده‌ها',
    'اعلان‌ها',
    'پرطرفدارها',
    'آمار و تحلیل',
    'محتوای زمان‌بندی‌شده',
    'مسدودشده‌ها',
    'نظرات',
    'زبان',
    'مجوزهای دستگاه',
    'دسترس‌پذیری',
    'پست‌ها',
    'رسانه‌های من',
    'برچسب‌ها و کلیدواژه‌ها',
    'بایگانی',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pureWhite,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(8, 8, 16, 4),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.chevron_left, color: _ink, size: 26),
                  ),
                  const Expanded(
                    child: Text(
                      'تنظیمات',
                      style: TextStyle(
                        color: _ink,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const Icon(Icons.check, color: _ink, size: 20),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _buildAvatar(),
            const SizedBox(height: 24),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Text(
                        'عمومی',
                        style: TextStyle(
                          color: _ink,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  for (final item in _generalItems) ...[
                    _SettingsRow(
                      label: item,
                      onTap: () => _openItem(context, item),
                    ),
                    const Divider(
                      height: 1,
                      color: _divider,
                      indent: 20,
                      endIndent: 20,
                    ),
                  ],
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openItem(BuildContext context, String item) {
    final Widget? screen = switch (item) {
      'تنظیمات پروفایل' => const ProfileSettingScreen(),
      'مکان‌ها' => const LocationsScreen(),
      'کیف پول' => const WalletScreen(),
      'ذخیره‌شده‌ها' => const SavedScreen(),
      'اعلان‌ها' => const NotificationsScreen(),
      'پرطرفدارها' => const TrendingScreen(),
      'آمار و تحلیل' => const InsightsScreen(),
      'محتوای زمان‌بندی‌شده' => const ScheduledContentScreen(),
      'مسدودشده‌ها' => const BlockedScreen(),
      'زبان' => const LanguageScreen(),
      'مجوزهای دستگاه' => const DevicePermissionsScreen(),
      'دسترس‌پذیری' => const AccessibilityScreen(),
      'رسانه‌های من' => const MyMediaScreen(),
      'برچسب‌ها و کلیدواژه‌ها' => const TagsKeywordsScreen(),
      'بایگانی' => const ArchiveScreen(),
      _ => null,
    };
    if (screen != null) {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(item)));
  }

  Widget _buildAvatar() {
    return Center(
      child: Container(
        width: 60,
        height: 60,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [AppColors.midGray, AppColors.deepBlack],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: AppColors.pureWhite, width: 3),
          boxShadow: [
            BoxShadow(
              color: AppColors.deepBlack.withValues(alpha: 0.12),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(Icons.person, color: AppColors.pureWhite, size: 26),
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  static const _ink = AppColors.deepBlack;
  static const _muted = AppColors.midGray;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: _ink,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: _muted, size: 18),
          ],
        ),
      ),
    );
  }
}
