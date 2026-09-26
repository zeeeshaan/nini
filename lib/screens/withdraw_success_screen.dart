import 'package:flutter/material.dart';
import '../app_colors.dart';

class WithdrawSuccessScreen extends StatelessWidget {
  const WithdrawSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pureWhite,
      body: SafeArea(
        child: Column(
          children: [
            const _Header(title: 'برداشت موفق'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
                children: [
                  const SizedBox(height: 4),
                  Center(
                    child: Image.asset(
                      'assets/images/done.png',
                      width: 380,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.check_circle_outline,
                        size: 96,
                        color: AppColors.deepBlack,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const _InfoRow(value: '۵۰٬۰۰۰٬۰۰۰', label: 'موجودی (تومان)'),
                  const SizedBox(height: 30),
                  const _InfoRow(
                    value: '۴۵٬۰۰۰٬۰۰۰',
                    label: 'مبلغ برداشت (تومان)',
                  ),
                  const SizedBox(height: 30),
                  const _InfoRow(
                    value: '۳۵٬۰۰۰٬۰۰۰',
                    label: 'در انتظار برداشت (تومان)',
                  ),
                  const SizedBox(height: 30),
                  const _InfoRow(
                    value: '۱۲۳۴-۵۶۷۸-۹۰۱۲-۳۴۵۶',
                    label: 'شماره حساب',
                    icon: Icons.shield_outlined,
                    iconColor: Color(0xFFE08A3C),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 0, 22, 22),
              child: _DoneButton(onTap: () => Navigator.of(context).maybePop()),
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
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.value,
    required this.label,
    this.icon,
    this.iconColor,
  });
  final String value;
  final String label;
  final IconData? icon;
  final Color? iconColor;

  static const _ink = AppColors.deepBlack;
  static const _muted = AppColors.midGray;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            color: _muted.withValues(alpha: 0.75),
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        if (icon != null) ...[
          Icon(icon, size: 20, color: iconColor ?? _muted),
          const SizedBox(width: 10),
        ],
        Text(
          value,
          textDirection: TextDirection.ltr,
          style: const TextStyle(
            color: _ink,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _DoneButton extends StatelessWidget {
  const _DoneButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: Material(
        color: AppColors.deepBlack,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          splashColor: AppColors.pureWhite.withValues(alpha: 0.08),
          child: const Center(
            child: Text(
              'بازگشت',
              style: TextStyle(
                color: AppColors.pureWhite,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
