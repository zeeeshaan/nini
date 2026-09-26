import 'package:flutter/material.dart';
import '../app_colors.dart';
import '../utils/fa.dart';

class BlockedScreen extends StatefulWidget {
  const BlockedScreen({super.key});

  @override
  State<BlockedScreen> createState() => _BlockedScreenState();
}

class _BlockedScreenState extends State<BlockedScreen> {
  final _search = TextEditingController();
  final List<String> _blocked = List.generate(
    12,
    (i) => 'کاربر ${faDigits(i + 1)}',
  );

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _unblock(int index) {
    setState(() => _blocked.removeAt(index));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pureWhite,
      body: SafeArea(
        child: Column(
          children: [
            const _Header(title: 'مسدودشده‌ها'),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 4, 22, 12),
              child: _SearchField(controller: _search),
            ),
            Expanded(
              child: _blocked.isEmpty
                  ? const _EmptyState()
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(22, 0, 22, 28),
                      itemCount: _blocked.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 14),
                      itemBuilder: (_, i) => _BlockedRow(
                        name: _blocked[i],
                        onUnblock: () => _unblock(i),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.title});
  final String title;

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
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller});
  final TextEditingController controller;

  static const _ink = AppColors.deepBlack;
  static const _muted = AppColors.midGray;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.surfaceOnLight,
        borderRadius: BorderRadius.circular(16),
      ),
      child: TextField(
        controller: controller,
        style: const TextStyle(
          color: _ink,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: 'جستجوی کاربران مسدودشده',
          hintStyle: TextStyle(
            color: _muted.withValues(alpha: 0.85),
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: const Icon(Icons.search, color: _muted, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }
}

class _BlockedRow extends StatelessWidget {
  const _BlockedRow({required this.name, required this.onUnblock});
  final String name;
  final VoidCallback onUnblock;

  static const _ink = AppColors.deepBlack;
  static const _muted = AppColors.midGray;
  static const _outline = AppColors.divider;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.surfaceOnLight,
          ),
          child: const Icon(Icons.person_outline, size: 18, color: _muted),
        ),
        const SizedBox(width: 12),
        Text(
          name,
          style: const TextStyle(
            color: _ink,
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        const Spacer(),
        OutlinedButton(
          onPressed: onUnblock,
          style: OutlinedButton.styleFrom(
            foregroundColor: _ink,
            side: const BorderSide(color: _outline),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
            textStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          child: const Text('رفع مسدودی'),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  static const _muted = AppColors.midGray;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'هیچ کاربر مسدودشده‌ای وجود ندارد',
        style: TextStyle(
          color: _muted,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
