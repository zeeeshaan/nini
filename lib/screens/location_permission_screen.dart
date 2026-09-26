import 'package:flutter/material.dart';
import '../app_colors.dart';
import 'verification_screen.dart';

class LocationPermissionScreen extends StatelessWidget {
  const LocationPermissionScreen({super.key});

  static const _bg = AppColors.deepBlack;
  static const _sheet = AppColors.surfaceOnDark;
  static const _onPrimary = AppColors.pureWhite;

  void _continue(BuildContext context, {bool denied = false}) {
    if (denied) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'می‌توانید بعداً دسترسی به موقعیت مکانی را از تنظیمات فعال کنید',
          ),
        ),
      );
    }
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const VerificationScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  child: Row(
                    children: [
                      _BackButton(
                        onTap: () => Navigator.of(context).maybePop(),
                      ),
                      const Expanded(
                        child: Text(
                          'ورود',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _onPrimary,
                            fontSize: 19,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 40),
                    ],
                  ),
                ),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _sheet,
                          Color.lerp(_sheet, Colors.black, 0.4)!,
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(28),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.5),
                          blurRadius: 24,
                          offset: const Offset(0, -4),
                        ),
                      ],
                    ),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return SingleChildScrollView(
                          physics: const ClampingScrollPhysics(),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: constraints.maxHeight,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const SizedBox(height: 14),
                                Container(
                                  width: 40,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: _onPrimary.withValues(alpha: 0.3),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                ),
                                const SizedBox(height: 28),
                                const _MapIllustration(),
                                const SizedBox(height: 32),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 32,
                                  ),
                                  child: Text(
                                    'به «های‌ورک» اجازه دسترسی به\nموقعیت مکانی این دستگاه داده شود؟',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: _onPrimary,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      height: 1.6,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 26),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                  ),
                                  child: Column(
                                    children: [
                                      _PermissionButton(
                                        label: 'فقط این بار',
                                        onTap: () => _continue(context),
                                      ),
                                      const SizedBox(height: 12),
                                      _PermissionButton(
                                        label: 'هنگام استفاده از برنامه',
                                        onTap: () => _continue(context),
                                      ),
                                      const SizedBox(height: 12),
                                      _PermissionButton(
                                        label: 'همیشه مجاز باشد',
                                        onTap: () => _continue(context),
                                      ),
                                      const SizedBox(height: 12),
                                      _PermissionButton(
                                        label: 'اجازه نده',
                                        onTap: () =>
                                            _continue(context, denied: true),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 28),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.pureWhite.withValues(alpha: 0.08),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: const SizedBox(
          width: 40,
          height: 40,
          child: Icon(Icons.arrow_back, color: AppColors.pureWhite, size: 20),
        ),
      ),
    );
  }
}

class _PermissionButton extends StatelessWidget {
  const _PermissionButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: Material(
        color: AppColors.pureWhite,
        borderRadius: BorderRadius.circular(999),
        elevation: 3,
        shadowColor: AppColors.deepBlack.withValues(alpha: 0.4),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          splashColor: AppColors.deepBlack.withValues(alpha: 0.06),
          highlightColor: AppColors.deepBlack.withValues(alpha: 0.04),
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.deepBlack,
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Location-access illustration, shipped as a real image asset.
class _MapIllustration extends StatelessWidget {
  const _MapIllustration();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      height: 180,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // soft glow for depth
          Container(
            width: 200,
            height: 90,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.midGray.withValues(alpha: 0.22),
                  AppColors.midGray.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
          Image.asset(
            'assets/images/location.png',
            width: 260,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => const Icon(
              Icons.location_on,
              size: 78,
              color: AppColors.pureWhite,
            ),
          ),
        ],
      ),
    );
  }
}
