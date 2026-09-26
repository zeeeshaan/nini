import 'package:flutter/material.dart';
import '../app_colors.dart';
import 'withdraw_screen.dart';
import 'top_up_screen.dart';
import '../utils/fa.dart';

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  static const _ink = AppColors.deepBlack;

  // Semantic accents for transaction state — scoped to this screen only,
  // the shared AppColors palette stays strictly black/white/gray.
  static const _green = Color(0xFF22C55E);
  static const _red = Color(0xFFEF4444);
  static const _orange = Color(0xFFF59E0B);

  static const _date = '۱۴۰۳/۰۷/۱۲  ساعت ۱۸:۳۰';

  static const _today = [
    _Transaction(
      amount: 230000,
      state: _TxState.done,
      title: 'نظافت منزل',
      date: _date,
    ),
    _Transaction(
      amount: 230000,
      state: _TxState.done,
      title: 'نظافت منزل',
      date: _date,
    ),
    _Transaction(
      amount: 230000,
      state: _TxState.done,
      title: 'نظافت منزل',
      date: _date,
    ),
    _Transaction(
      amount: 230000,
      state: _TxState.done,
      title: 'نظافت منزل',
      date: _date,
    ),
  ];

  static const _yesterday = [
    _Transaction(
      amount: 190000,
      state: _TxState.negative,
      title: 'نظافت منزل',
      date: _date,
    ),
    _Transaction(
      amount: 230000,
      state: _TxState.done,
      title: 'نظافت منزل',
      date: _date,
    ),
    _Transaction(
      amount: 230000,
      state: _TxState.pending,
      title: 'نظافت منزل',
      date: _date,
    ),
    _Transaction(
      amount: 230000,
      state: _TxState.done,
      title: 'نظافت منزل',
      date: _date,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pureWhite,
      body: SafeArea(
        child: Column(
          children: [
            _Header(
              title: 'کیف پول',
              onSave: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('کیف پول به‌روزرسانی شد')),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(22, 12, 22, 28),
                children: [
                  const _BalanceCard(),
                  const SizedBox(height: 26),
                  const _ActionRow(),
                  const SizedBox(height: 34),
                  const Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(
                      'تراکنش‌ها',
                      style: TextStyle(
                        color: _ink,
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const _DayHeader(label: 'امروز'),
                  for (final tx in _today) _TransactionRow(tx: tx),
                  const SizedBox(height: 14),
                  const _DayHeader(label: 'دیروز'),
                  for (final tx in _yesterday) _TransactionRow(tx: tx),
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

class _BalanceCard extends StatelessWidget {
  const _BalanceCard();

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        // A second card peeking out above the top edge — the "stack" cue.
        Positioned(
          top: -12,
          left: 20,
          right: 20,
          child: Container(
            height: 30,
            decoration: BoxDecoration(
              color: AppColors.surfaceOnLight,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              border: Border.all(color: AppColors.divider),
            ),
          ),
        ),
        Container(
          width: double.infinity,
          height: 188,
          padding: const EdgeInsets.fromLTRB(26, 24, 26, 22),
          decoration: BoxDecoration(
            color: AppColors.deepBlack,
            borderRadius: BorderRadius.circular(26),
            boxShadow: [
              BoxShadow(
                color: AppColors.deepBlack.withValues(alpha: 0.22),
                blurRadius: 28,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'موجودی (تومان)',
                style: TextStyle(
                  color: AppColors.pureWhite.withValues(alpha: 0.6),
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                '۵۰٬۰۰۰٬۰۰۰',
                style: TextStyle(
                  color: AppColors.pureWhite,
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              Text(
                'مجتبی ز.',
                style: TextStyle(
                  color: AppColors.pureWhite.withValues(alpha: 0.7),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _WalletAction {
  const _WalletAction({required this.icon, required this.label});
  final IconData icon;
  final String label;
}

class _ActionRow extends StatelessWidget {
  const _ActionRow();

  static const _actions = [
    _WalletAction(
      icon: Icons.system_update_alt_rounded,
      label: 'افزایش موجودی',
    ),
    _WalletAction(icon: Icons.swap_horiz_rounded, label: 'انتقال'),
    _WalletAction(icon: Icons.front_hand_outlined, label: 'درخواست'),
    _WalletAction(icon: Icons.ios_share_rounded, label: 'برداشت'),
    _WalletAction(icon: Icons.credit_card_rounded, label: 'پرداخت'),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final a in _actions) ...[
          Expanded(child: _WalletActionChip(action: a)),
          if (a != _actions.last) const SizedBox(width: 10),
        ],
      ],
    );
  }
}

class _WalletActionChip extends StatelessWidget {
  const _WalletActionChip({required this.action});
  final _WalletAction action;

  static const _ink = AppColors.deepBlack;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        if (action.label == 'برداشت') {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const WithdrawScreen()));
          return;
        }
        if (action.label == 'افزایش موجودی') {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const TopUpScreen()));
          return;
        }
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(action.label)));
      },
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 2),
        decoration: BoxDecoration(
          color: AppColors.surfaceOnLight,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: AppColors.deepBlack.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(action.icon, size: 22, color: _ink),
            const SizedBox(height: 8),
            Text(
              action.label,
              textAlign: TextAlign.center,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.fade,
              style: const TextStyle(
                color: _ink,
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DayHeader extends StatelessWidget {
  const _DayHeader({required this.label});
  final String label;

  static const _muted = AppColors.midGray;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: Text(
          label,
          style: TextStyle(
            color: _muted.withValues(alpha: 0.9),
            fontSize: 14.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

enum _TxState { done, negative, pending }

class _Transaction {
  const _Transaction({
    required this.amount,
    required this.state,
    required this.title,
    required this.date,
  });

  final int amount;
  final _TxState state;
  final String title;
  final String date;
}

class _TransactionRow extends StatelessWidget {
  const _TransactionRow({required this.tx});
  final _Transaction tx;

  static const _ink = AppColors.deepBlack;
  static const _muted = AppColors.midGray;

  @override
  Widget build(BuildContext context) {
    final Color color;
    final String sign;
    switch (tx.state) {
      case _TxState.done:
        color = WalletScreen._green;
        sign = '+';
      case _TxState.negative:
        color = WalletScreen._red;
        sign = '-';
      case _TxState.pending:
        color = WalletScreen._orange;
        sign = '';
    }

    final formatted = faAmount(tx.amount);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 13),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surfaceOnLight,
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tx.title,
                style: const TextStyle(
                  color: _ink,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                tx.date,
                style: TextStyle(
                  color: _muted.withValues(alpha: 0.85),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            '$sign$formatted',
            textDirection: TextDirection.ltr,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
