import 'dart:async';

import 'package:flutter/material.dart';
import '../app_colors.dart';
import '../utils/fa.dart';
import 'withdraw_success_screen.dart';

String _formatCountdown(int seconds) {
  final m = (seconds ~/ 60).toString().padLeft(2, '0');
  final s = (seconds % 60).toString().padLeft(2, '0');
  return faDigits('$m:$s');
}

class WithdrawScreen extends StatefulWidget {
  const WithdrawScreen({super.key});

  @override
  State<WithdrawScreen> createState() => _WithdrawScreenState();
}

class _WithdrawScreenState extends State<WithdrawScreen> {
  static const _presets = [800000, 600000, 400000, 200000];

  final _amountController = TextEditingController(text: faAmount(15000000));
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();

  int _selectedPreset = 200000;
  bool _otpSent = false;
  int _resendSeconds = 0;
  Timer? _resendTimer;

  @override
  void dispose() {
    _amountController.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    _resendTimer?.cancel();
    super.dispose();
  }

  void _selectPreset(int value) {
    setState(() {
      _selectedPreset = value;
      _amountController.text = faAmount(value);
    });
  }

  void _sendOtp() {
    if (_phoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ابتدا شماره تلفن را وارد کنید')),
      );
      return;
    }
    _resendTimer?.cancel();
    setState(() {
      _otpSent = true;
      _resendSeconds = 59;
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('رمز یک‌بار مصرف ارسال شد')));
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendSeconds <= 1) {
        timer.cancel();
        setState(() => _resendSeconds = 0);
        return;
      }
      setState(() => _resendSeconds--);
    });
  }

  void _done() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const WithdrawSuccessScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pureWhite,
      body: SafeArea(
        child: Column(
          children: [
            const _Header(title: 'برداشت'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(22, 12, 22, 28),
                children: [
                  const _BalanceCard(),
                  const SizedBox(height: 28),
                  const _FieldLabel('مبلغ در انتظار برداشت (تومان)'),
                  const SizedBox(height: 8),
                  _AmountField(controller: _amountController),
                  const SizedBox(height: 14),
                  _PresetRow(
                    selected: _selectedPreset,
                    onSelect: _selectPreset,
                  ),
                  const SizedBox(height: 26),
                  const _FieldLabel('شماره حساب'),
                  const SizedBox(height: 8),
                  const _InputBox(
                    hint: '۱۲۳۴-۵۶۷۸-۹۰۱۲-۳۴۵۶',
                    icon: Icons.credit_card_outlined,
                    enabled: false,
                    ltr: true,
                  ),
                  const SizedBox(height: 26),
                  const _FieldLabel('رمز یک‌بار مصرف'),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: _InputBox(
                          controller: _phoneController,
                          hint: 'شماره تلفن',
                        ),
                      ),
                      const SizedBox(width: 10),
                      _PillButton(label: 'دریافت رمز', onTap: _sendOtp),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'برای امنیت حساب شما، این برداشت باید تأیید شود.',
                    style: TextStyle(
                      color: AppColors.midGray.withValues(alpha: 0.9),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: _InputBox(
                          controller: _otpController,
                          hint: 'کد را وارد کنید',
                          enabled: _otpSent,
                        ),
                      ),
                      const SizedBox(width: 10),
                      _resendSeconds > 0
                          ? _PillButton(
                              label: _formatCountdown(_resendSeconds),
                              onTap: null,
                              dark: true,
                            )
                          : _PillButton(
                              label: _otpSent ? 'ارسال دوباره' : 'ارسال',
                              onTap: _sendOtp,
                            ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  _DoneButton(onTap: _done),
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
              const SizedBox(height: 22),
              Container(
                height: 1,
                color: AppColors.pureWhite.withValues(alpha: 0.1),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '۴۵٬۰۰۰٬۰۰۰',
                          style: TextStyle(
                            color: AppColors.pureWhite,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'مبلغ برداشت (تومان)',
                          style: TextStyle(
                            color: AppColors.pureWhite.withValues(alpha: 0.55),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 34,
                    height: 34,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.pureWhite.withValues(alpha: 0.1),
                    ),
                    child: const Icon(
                      Icons.credit_card,
                      size: 16,
                      color: AppColors.pureWhite,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label);
  final String label;

  static const _ink = AppColors.deepBlack;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: _ink,
        fontSize: 14,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _AmountField extends StatelessWidget {
  const _AmountField({required this.controller});
  final TextEditingController controller;

  static const _ink = AppColors.deepBlack;
  static const _muted = AppColors.midGray;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              style: const TextStyle(
                color: _ink,
                fontSize: 15.5,
                fontWeight: FontWeight.w700,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          const Icon(Icons.edit_outlined, size: 18, color: _muted),
        ],
      ),
    );
  }
}

class _PresetRow extends StatelessWidget {
  const _PresetRow({required this.selected, required this.onSelect});
  final int selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final value in _WithdrawScreenState._presets) ...[
          Expanded(
            child: _PresetChip(
              value: value,
              selected: value == selected,
              onTap: () => onSelect(value),
            ),
          ),
          if (value != _WithdrawScreenState._presets.last)
            const SizedBox(width: 8),
        ],
      ],
    );
  }
}

class _PresetChip extends StatelessWidget {
  const _PresetChip({
    required this.value,
    required this.selected,
    required this.onTap,
  });
  final int value;
  final bool selected;
  final VoidCallback onTap;

  static const _ink = AppColors.deepBlack;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? _ink : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: selected ? _ink : AppColors.divider),
        ),
        child: Text(
          faAmount(value),
          style: TextStyle(
            color: selected ? AppColors.pureWhite : _ink,
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _InputBox extends StatelessWidget {
  const _InputBox({
    this.controller,
    required this.hint,
    this.icon,
    this.enabled = true,
    this.ltr = false,
  });
  final TextEditingController? controller;
  final String hint;
  final IconData? icon;
  final bool enabled;

  /// Card/account numbers keep their digit groups in left-to-right order.
  final bool ltr;

  static const _ink = AppColors.deepBlack;
  static const _muted = AppColors.midGray;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
        color: enabled ? AppColors.pureWhite : AppColors.surfaceOnLight,
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              enabled: enabled,
              textDirection: ltr ? TextDirection.ltr : null,
              textAlign: ltr ? TextAlign.right : TextAlign.start,
              style: const TextStyle(
                color: _ink,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintTextDirection: ltr ? TextDirection.ltr : null,
                hintStyle: TextStyle(
                  color: _muted.withValues(alpha: 0.85),
                  fontWeight: FontWeight.w500,
                ),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          if (icon != null) Icon(icon, size: 18, color: _muted),
        ],
      ),
    );
  }
}

class _PillButton extends StatelessWidget {
  const _PillButton({
    required this.label,
    required this.onTap,
    this.dark = false,
  });
  final String label;
  final VoidCallback? onTap;
  final bool dark;

  static const _ink = AppColors.deepBlack;
  static const _muted = AppColors.midGray;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null || dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: enabled ? _ink : AppColors.surfaceOnLight,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: enabled ? AppColors.pureWhite : _muted,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
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
              'تأیید برداشت',
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
