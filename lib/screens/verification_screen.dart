import 'package:flutter/material.dart';
import '../app_colors.dart';
import '../utils/fa.dart';
import 'root_screen.dart';

class VerificationScreen extends StatefulWidget {
  const VerificationScreen({super.key});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  static const _codeLength = 4;
  static const _bg = AppColors.pureWhite;
  static const _ink = AppColors.deepBlack;
  static const _muted = AppColors.midGray;

  String _code = '';
  bool _loading = false;

  void _addDigit(String d) {
    if (_code.length >= _codeLength) return;
    setState(() => _code += d);
  }

  void _backspace() {
    if (_code.isEmpty) return;
    setState(() => _code = _code.substring(0, _code.length - 1));
  }

  Future<void> _submit() async {
    if (_code.length != _codeLength) return;
    setState(() => _loading = true);
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() => _loading = false);
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const RootScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(8, 4, 20, 0),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: const Icon(Icons.arrow_back, color: _ink),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'کد تأیید',
                  style: TextStyle(
                    color: _ink,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'کد ۴ رقمی ارسال‌شده به شماره تلفن\nخود را وارد کنید',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: _muted, fontSize: 13, height: 1.6),
                ),
                const SizedBox(height: 32),
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _codeLength,
                      (i) => _OtpBox(
                        digit: i < _code.length ? faDigits(_code[i]) : '',
                        filled: i < _code.length,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('کد تأیید دوباره ارسال شد')),
                    );
                  },
                  child: const Text(
                    'کد را دریافت نکردید؟ ارسال دوباره',
                    style: TextStyle(color: _muted, fontSize: 12.5),
                  ),
                ),
                const Spacer(),
                _Keypad(onDigit: _addDigit, onBackspace: _backspace),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: (_code.length == _codeLength && !_loading)
                          ? _submit
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _ink,
                        foregroundColor: AppColors.pureWhite,
                        disabledBackgroundColor: _ink.withValues(alpha: 0.3),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                        elevation: 0,
                      ),
                      child: _loading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                valueColor: AlwaysStoppedAnimation(
                                  AppColors.pureWhite,
                                ),
                              ),
                            )
                          : const Text(
                              'ادامه',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OtpBox extends StatelessWidget {
  const _OtpBox({required this.digit, required this.filled});
  final String digit;
  final bool filled;

  static const _ink = AppColors.deepBlack;
  static const _field = AppColors.surfaceOnLight;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 60,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: filled ? _ink : _field,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        digit,
        style: TextStyle(
          color: filled ? AppColors.pureWhite : _ink,
          fontSize: 22,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _Keypad extends StatelessWidget {
  const _Keypad({required this.onDigit, required this.onBackspace});
  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;

  static const _rows = [
    ['1', '2', '3'],
    ['4', '5', '6'],
    ['7', '8', '9'],
    ['*', '0', '⌫'],
  ];

  @override
  Widget build(BuildContext context) {
    // Phone keypads keep the 1-2-3 order left-to-right in Persian too.
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Column(
        children: _rows.map((row) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: row.map((key) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: _KeypadButton(
                    label: key,
                    onTap: () {
                      if (key == '⌫') {
                        onBackspace();
                      } else if (key == '*') {
                        // decorative, not used for numeric entry
                      } else {
                        onDigit(key);
                      }
                    },
                  ),
                );
              }).toList(),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _KeypadButton extends StatelessWidget {
  const _KeypadButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  static const _ink = AppColors.deepBlack;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: SizedBox(
        width: 56,
        height: 56,
        child: Center(
          child: Text(
            faDigits(label),
            style: const TextStyle(
              color: _ink,
              fontSize: 22,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
