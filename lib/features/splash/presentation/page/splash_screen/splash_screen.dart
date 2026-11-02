import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nini/core/animation/screen_entrance.dart';
import 'package:nini/core/theme/app_colors.dart';
import 'package:nini/features/login/presentation/page/login_screen/login_screen.dart';

import '../../widgets/splash_screen_widgets/splash_content/splash_content.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Start after the first frame so the splash is visible for at least 3s.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _timer = Timer(const Duration(seconds: 3), _openLogin);
    });
  }

  void _openLogin() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement<void, void>(
      MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: SystemUiOverlayStyle.light.copyWith(
      statusBarColor: AppColors.transparent,
      systemNavigationBarColor: AppColors.black,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
    child: const ScreenEntrance(
      child: Scaffold(
        backgroundColor: AppColors.black,
        body: SafeArea(child: SplashContent()),
      ),
    ),
  );
}
