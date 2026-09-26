import 'package:flutter/material.dart';
import '../app_colors.dart';
import '../utils/fa.dart';
import 'withdraw_success_screen.dart';

class TopUpScreen extends StatefulWidget {
  const TopUpScreen({super.key});

  @override
  State<TopUpScreen> createState() => _TopUpScreenState();
}

class _PaymentMethod {
  const _PaymentMethod({required this.label, required this.color});
  final String label;
  final Color color;
}

class _TopUpScreenState extends State<TopUpScreen> {
  static const _presets = [800000, 600000, 400000, 200000];

  static const _methods = [
    _PaymentMethod(label: 'بانک ملی', color: Color(0xFFC9A24B)),
    _PaymentMethod(label: 'بانک ملت', color: Color(0xFFE0435C)),
    _PaymentMethod(label: 'بانک سامان', color: Color(0xFF2E8AE0)),
  ];

  final _amountController = TextEditingController(text: faAmount(35000000));
  int _selectedPreset = 200000;
  int _selectedMethod = 1;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _selectPreset(int value) {
    setState(() {
      _selectedPreset = value;
      _amountController.text = faAmount(value);
    });
  }

  void _pay() {
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
            const _Header(title: 'افزایش موجودی'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(22, 12, 22, 28),
                children: [
                  const _BalanceCard(),
                  const SizedBox(height: 28),
                  const _StartLabel('مبلغ شارژ (تومان)'),
                  const SizedBox(height: 8),
                  _AmountField(controller: _amountController),
                  const SizedBox(height: 14),
                  _PresetRow(
                    selected: _selectedPreset,
                    onSelect: _selectPreset,
                  ),
                  const SizedBox(height: 26),
                  const _StartLabel('روش پرداخت'),
                  const SizedBox(height: 10),
                  for (var i = 0; i < _methods.length; i++) ...[
                    _PaymentMethodRow(
                      method: _methods[i],
                      selected: i == _selectedMethod,
                      onTap: () => setState(() => _selectedMethod = i),
                    ),
                    if (i != _methods.length - 1) const SizedBox(height: 12),
                  ],
                  const SizedBox(height: 30),
                  _PayButton(onTap: _pay),
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

class _StartLabel extends StatelessWidget {
  const _StartLabel(this.label);
  final String label;

  static const _ink = AppColors.deepBlack;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Text(
        label,
        style: const TextStyle(
          color: _ink,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
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
          const Icon(Icons.payments_outlined, size: 18, color: _muted),
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
        for (final value in _TopUpScreenState._presets) ...[
          Expanded(
            child: _PresetChip(
              value: value,
              selected: value == selected,
              onTap: () => onSelect(value),
            ),
          ),
          if (value != _TopUpScreenState._presets.last)
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

class _PaymentMethodRow extends StatelessWidget {
  const _PaymentMethodRow({
    required this.method,
    required this.selected,
    required this.onTap,
  });
  final _PaymentMethod method;
  final bool selected;
  final VoidCallback onTap;

  static const _ink = AppColors.deepBlack;
  static const _muted = AppColors.midGray;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 58,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? _ink : AppColors.divider,
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: method.color.withValues(alpha: 0.15),
              ),
              child: Icon(Icons.account_balance, size: 16, color: method.color),
            ),
            const SizedBox(width: 10),
            Text(
              method.label,
              style: const TextStyle(
                color: _ink,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Container(
              width: 20,
              height: 20,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: selected ? _ink : _muted, width: 1.6),
              ),
              child: selected
                  ? Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: _ink,
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _PayButton extends StatelessWidget {
  const _PayButton({required this.onTap});
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
              'پرداخت',
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
