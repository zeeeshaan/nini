import 'package:flutter/material.dart';
import '../app_colors.dart';
import '../data/countries.dart';
import '../widgets/country_picker_sheet.dart';
import '../utils/fa.dart';
import '../widgets/flag_chip.dart';
import 'location_permission_screen.dart';

class PhoneScreen extends StatefulWidget {
  const PhoneScreen({super.key});

  @override
  State<PhoneScreen> createState() => _PhoneScreenState();
}

class _PhoneScreenState extends State<PhoneScreen> {
  static const _bg = AppColors.deepBlack;
  static const _onPrimary = AppColors.pureWhite;
  static const _secondary = AppColors.midGray;
  static const _onPrimaryContainer = AppColors.midGray;
  static const _primaryContainer = AppColors.surfaceOnDark;
  static const _outline = AppColors.midGray;

  CountryInfo _country = kCountries.firstWhere((c) => c.iso2 == 'IR');
  final _phoneController = TextEditingController();

  Future<void> _pickCountry() async {
    final result = await CountryPickerSheet.show(context);
    if (result != null && mounted) {
      setState(() => _country = result);
    }
  }

  void _continue() {
    if (_phoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لطفاً شماره تلفن خود را وارد کنید')),
      );
      return;
    }
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const LocationPermissionScreen()));
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back, color: _onPrimary),
                    padding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'شماره تلفن شما چیست؟',
                    style: TextStyle(
                      color: _onPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'برای تأیید هویت، یک کد تأیید برای شما ارسال می‌کنیم.',
                    style: TextStyle(
                      color: _onPrimaryContainer,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 36),
                  Row(
                    children: [
                      InkWell(
                        onTap: _pickCountry,
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          height: 52,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: _primaryContainer,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: _outline.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              FlagChip(iso2: _country.iso2),
                              const SizedBox(width: 8),
                              Text(
                                faDigits(_country.dialCode),
                                textDirection: TextDirection.ltr,
                                style: const TextStyle(
                                  color: _onPrimary,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.keyboard_arrow_down,
                                color: _secondary,
                                size: 18,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          style: const TextStyle(
                            color: _onPrimary,
                            fontSize: 15,
                          ),
                          cursorColor: _onPrimary,
                          decoration: InputDecoration(
                            hintText: 'شماره تلفن',
                            hintStyle: TextStyle(
                              color: _secondary.withValues(alpha: 0.7),
                            ),
                            filled: true,
                            fillColor: _primaryContainer,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: _outline.withValues(alpha: 0.3),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: _outline.withValues(alpha: 0.3),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                color: _onPrimary,
                                width: 1.4,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _continue,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _onPrimary,
                        foregroundColor: AppColors.deepBlack,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'ادامه',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
