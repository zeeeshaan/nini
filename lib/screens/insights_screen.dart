import 'package:flutter/material.dart';
import '../app_colors.dart';

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _Group {
  const _Group(this.title, this.items);
  final String title;
  final List<String> items;
}

class _InsightsScreenState extends State<InsightsScreen> {
  static const _groups = [
    _Group('آمار پست‌ها و خدمات', [
      'کل پست‌ها',
      'بازدیدها',
      'تعامل‌ها',
      'رزروها',
      'فروش‌ها',
      'خدمات پرطرفدار',
    ]),
    _Group('آمار کاربران و مشتریان', [
      'دنبال‌کنندگان جدید',
      'مشتریان برتر',
      'بازخوردها',
    ]),
    _Group('هشدارها و یادآوری‌ها', ['یادآوری سقف مصرف', 'پیام‌های بی‌پاسخ']),
  ];

  String _selected = _groups.first.items.first;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pureWhite,
      body: SafeArea(
        child: Column(
          children: [
            _Header(
              title: 'آمار و تحلیل',
              onSave: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('آمار به‌روزرسانی شد')),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(22, 8, 22, 28),
                children: [
                  for (final g in _groups) ...[
                    _GroupHeader(title: g.title),
                    for (final item in g.items)
                      _InsightRow(
                        label: item,
                        selected: item == _selected,
                        onTap: () => setState(() => _selected = item),
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

class _InsightRow extends StatelessWidget {
  const _InsightRow({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  static const _ink = AppColors.deepBlack;
  static const _muted = AppColors.midGray;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 9),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? _ink : Colors.transparent,
                border: Border.all(color: selected ? _ink : _muted, width: 1.4),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: _ink,
                  fontSize: 14.5,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
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
