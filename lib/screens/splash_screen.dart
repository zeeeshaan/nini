import 'package:flutter/material.dart';
import '../app_colors.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  static const _bg = AppColors.deepBlack;
  static const _onPrimary = AppColors.pureWhite;
  static const _secondary = AppColors.midGray;
  static const _onPrimaryContainer = AppColors.midGray;
  static const _primaryContainer = AppColors.surfaceOnDark;

  late final AnimationController _shimmerController;
  final bool _visible = true;

  @override
  void initState() {
    super.initState();

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    Future.delayed(const Duration(milliseconds: 2200), _goToLogin);
  }

  void _goToLogin() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (context, animation, secondaryAnimation) =>
            FadeTransition(opacity: animation, child: const LoginScreen()),
      ),
    );
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const Spacer(flex: 3),
              AnimatedOpacity(
                opacity: _visible ? 1 : 0,
                duration: const Duration(milliseconds: 900),
                curve: Curves.easeOutCubic,
                child: AnimatedSlide(
                  offset: _visible ? Offset.zero : const Offset(0, 0.02),
                  duration: const Duration(milliseconds: 900),
                  curve: Curves.easeOutCubic,
                  child: AnimatedScale(
                    scale: _visible ? 1 : 0.98,
                    duration: const Duration(milliseconds: 900),
                    curve: Curves.easeOutCubic,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildLogo(),
                        const SizedBox(height: 24),
                        Text(
                          'های‌ورک',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _onPrimary,
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'سیستم عامل نیروی کار',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _onPrimaryContainer,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const Spacer(flex: 4),
              _buildProgressBar(),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'حلقه‌ی بی‌پایان',
                    style: TextStyle(
                      color: _secondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'نسخه ۱٫۰',
                    style: TextStyle(
                      color: _secondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 112,
      height: 112,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: _onPrimary.withValues(alpha: 0.1),
            blurRadius: 40,
            spreadRadius: 6,
          ),
        ],
      ),
      child: ClipOval(
        child: Image.asset(
          'assets/images/logo.png',
          fit: BoxFit.contain,
          cacheWidth: 448,
          errorBuilder: (context, error, stackTrace) => Container(
            color: _primaryContainer,
            alignment: Alignment.center,
            child: const Text(
              'ه',
              style: TextStyle(
                color: _onPrimary,
                fontSize: 40,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    return Center(
      child: SizedBox(
        width: 96,
        height: 2,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: Container(
            color: _primaryContainer,
            child: AnimatedBuilder(
              animation: _shimmerController,
              builder: (context, child) {
                return Align(
                  alignment: Alignment(_shimmerController.value * 2.6 - 1.3, 0),
                  child: FractionallySizedBox(
                    widthFactor: 1 / 3,
                    child: Container(color: _onPrimary),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
