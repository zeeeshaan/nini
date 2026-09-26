import 'package:flutter/material.dart';
import '../app_colors.dart';

class ArchiveScreen extends StatelessWidget {
  const ArchiveScreen({super.key});

  static const _items = [
    'هدفون بی‌سیم بلوتوثی',
    'هدفون بی‌سیم بلوتوثی',
    'هدفون بی‌سیم بلوتوثی',
    'هدفون بی‌سیم بلوتوثی',
    'هدفون بی‌سیم بلوتوثی',
    'هدفون بی‌سیم بلوتوثی',
    'هدفون بی‌سیم بلوتوثی',
    'هدفون بی‌سیم بلوتوثی',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pureWhite,
      body: SafeArea(
        child: Column(
          children: [
            _Header(
              title: 'بایگانی',
              onSave: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('بایگانی به‌روزرسانی شد')),
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(22, 8, 22, 28),
                itemCount: _items.length,
                separatorBuilder: (_, _) =>
                    const Divider(height: 26, color: AppColors.divider),
                itemBuilder: (_, i) => _ArchiveRow(name: _items[i]),
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

class _ArchiveRow extends StatelessWidget {
  const _ArchiveRow({required this.name});
  final String name;

  static const _ink = AppColors.deepBlack;
  static const _muted = AppColors.midGray;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(name))),
      borderRadius: BorderRadius.circular(14),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: 64,
              height: 56,
              color: AppColors.surfaceOnLight,
              child: const Icon(Icons.image_outlined, size: 20, color: _muted),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'فروخته شد',
                  style: TextStyle(
                    color: _muted.withValues(alpha: 0.85),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('گزینه‌ها'))),
              child: const Padding(
                padding: EdgeInsets.all(6),
                child: Icon(Icons.more_vert, size: 18, color: _muted),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
