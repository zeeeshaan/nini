import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hywork/core/animations/screen_entrance/screen_entrance.dart';
import 'package:hywork/core/theme/app_colors/app_colors.dart';
import 'package:hywork/features/login/presentation/pages/login_screen.dart';
import 'package:hywork/features/login/presentation/cubit/session_cubit.dart';
import 'package:hywork/features/dashboard/screens/dashboard_screen.dart';
import 'package:hywork/features/dashboard/cubit/dashboard_navigation_cubit.dart';

import '../widgets/common/splash_content.dart';
import '../widgets/common/splash_session_error.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer;
  bool _minimumElapsed = false;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    // Start after the first frame so the splash is visible for at least 3s.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _timer = Timer(const Duration(seconds: 3), () {
        _minimumElapsed = true;
        _openDestination(context.read<SessionCubit>().state);
      });
      context.read<SessionCubit>().restore();
    });
  }

  void _openDestination(SessionState session) {
    if (!mounted || !_minimumElapsed || _navigated) return;
    if (session.status != SessionStatus.authenticated &&
        session.status != SessionStatus.unauthenticated) {
      return;
    }
    _navigated = true;
    Navigator.of(context).pushAndRemoveUntil<void>(
      MaterialPageRoute<void>(
        builder: (_) => session.status == SessionStatus.authenticated
            ? const DashboardScreen(initialTab: DashboardTab.home)
            : const LoginScreen(),
      ),
      (_) => false,
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      BlocConsumer<SessionCubit, SessionState>(
        listener: (context, session) => _openDestination(session),
        builder: (context, session) => AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle.light.copyWith(
            statusBarColor: AppColors.transparent,
            systemNavigationBarColor: AppColors.black,
            systemNavigationBarIconBrightness: Brightness.light,
          ),
          child: ScreenEntrance(
            child: Scaffold(
              backgroundColor: AppColors.black,
              body: SafeArea(
                child: SplashContent(
                  status: session.status == SessionStatus.failure
                      ? SplashSessionError(
                          onRetry: () => context.read<SessionCubit>().restore(),
                        )
                      : null,
                ),
              ),
            ),
          ),
        ),
      );
}
