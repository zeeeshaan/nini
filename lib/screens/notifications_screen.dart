import 'package:flutter/material.dart';
import '../app_colors.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _Group {
  const _Group(this.title, this.items);
  final String title;
  final List<String> items;
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  static const _groups = [
    _Group('اعلان‌های فعالیت', [
      'نظرات و پاسخ‌ها',
      'هشدار پیام جدید',
      'پسندها و واکنش‌ها',
      'به‌روزرسانی سفارش و رزرو',
      'نقدها و امتیازها',
    ]),
    _Group('اعلان‌های تبلیغاتی', [
      'پیشنهادها و تخفیف‌ها',
      'اخبار و به‌روزرسانی‌ها',
      'از کاربرانی که دنبال می‌کنید',
    ]),
    _Group('اعلان‌های سیستمی و یادآوری', [
      'یادآوری‌ها',
      'هشدارهای سیستم',
      'اعلان‌های ایمیلی',
    ]),
  ];

  final Map<String, bool> _state = {
    for (final g in _groups)
      for (final item in g.items) item: true,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pureWhite,
      body: SafeArea(
        child: Column(
          children: [
            _Header(
              title: 'اعلان‌ها',
              onSave: () => ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('تنظیمات ذخیره شد'))),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(22, 8, 22, 28),
                children: [
                  for (final g in _groups) ...[
                    _GroupHeader(title: g.title),
                    for (final item in g.items)
                      _ToggleRow(
                        label: item,
                        value: _state[item]!,
                        onChanged: (v) => setState(() => _state[item] = v),
                      ),
                    const SizedBox(height: 18),
                  ],
                ],
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

class _GroupHeader extends StatelessWidget {
  const _GroupHeader({required this.title});
  final String title;

  static const _ink = AppColors.deepBlack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 4),
      child: Text(
        title,
        style: const TextStyle(
          color: _ink,
          fontSize: 15,
          fontWeight: FontWeight.w800,
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
                  fontSize: 14.5,
                  fontWeight: FontWeight.w500,
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
