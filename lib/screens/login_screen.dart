import 'package:flutter/material.dart';
import '../app_colors.dart';
import 'phone_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const _bg = AppColors.deepBlack;
  static const _onPrimary = AppColors.pureWhite;
  static const _primaryContainer = AppColors.surfaceOnDark;
  static const _outline = AppColors.midGray;

  bool _visible = false;
  bool _googleConnected = false;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Future.delayed(const Duration(milliseconds: 50), () {
        if (mounted) setState(() => _visible = true);
      });
    });
  }

  void _connectGoogle() {
    setState(() => _googleConnected = true);
  }

  Future<void> _finishAndContinue() async {
    setState(() => _loading = true);
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    setState(() => _loading = false);
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const PhoneScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: AnimatedOpacity(
              opacity: _visible ? 1 : 0,
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOutCubic,
              child: AnimatedSlide(
                offset: _visible ? Offset.zero : const Offset(0, 0.02),
                duration: const Duration(milliseconds: 900),
                curve: Curves.easeOutCubic,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Spacer(),
                      Text(
                        'های‌ورک',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _onPrimary,
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 40),
                      _buildLogo(),
                      const SizedBox(height: 48),
                      _buildGoogleButton(),
                      const Spacer(),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _finishAndContinue,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _onPrimary,
                            foregroundColor: AppColors.deepBlack,
                            disabledBackgroundColor: _onPrimary.withValues(
                              alpha: 0.6,
                            ),
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
                                      AppColors.deepBlack,
                                    ),
                                  ),
                                )
                              : const Text(
                                  'تأیید و ادامه',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 104,
      height: 104,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: _onPrimary.withValues(alpha: 0.1),
            blurRadius: 32,
            spreadRadius: 4,
          ),
        ],
      ),
      child: ClipOval(
        child: Image.asset(
          'assets/images/logo.png',
          fit: BoxFit.contain,
          cacheWidth: 416,
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

  Widget _buildGoogleButton() {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: OutlinedButton(
        onPressed: _connectGoogle,
        style: OutlinedButton.styleFrom(
          foregroundColor: _onPrimary,
          side: BorderSide(color: _outline.withValues(alpha: 0.4)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 30,
              height: 30,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.pureWhite,
              ),
              child: ClipOval(
                child: Image.network(
                  'https://developers.google.com/identity/images/g-logo.png',
                  width: 22,
                  height: 22,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const SizedBox(
                    width: 20,
                    height: 20,
                    child: CustomPaint(painter: _GoogleLogoPainter()),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Flexible(
              child: Text(
                _googleConnected
                    ? 'به حساب گوگل متصل شدید'
                    : 'ورود با حساب گوگل',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (_googleConnected) ...[
              const SizedBox(width: 8),
              const Icon(
                Icons.check_circle,
                size: 18,
                color: AppColors.pureWhite,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Renders Google's four-colour "G" mark without needing a bundled asset
/// or a network fetch — drawn as coloured ring segments plus the crossbar.
class _GoogleLogoPainter extends CustomPainter {
  const _GoogleLogoPainter();

  static const _blue = Color(0xFF4285F4);
  static const _green = Color(0xFF34A853);
  static const _yellow = Color(0xFFFBBC05);
  static const _red = Color(0xFFEA4335);

  static double _rad(double degrees) => degrees * 3.1415926535897932 / 180;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = size.width / 2;
    final strokeWidth = outerRadius * 0.42;
    final rect = Rect.fromCircle(
      center: center,
      radius: outerRadius - strokeWidth / 2,
    );

    Paint arcPaint(Color color) => Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    const gap = 0.05;

    canvas.drawArc(rect, _rad(-40), _rad(135) - gap, false, arcPaint(_blue));
    canvas.drawArc(rect, _rad(95), _rad(70) - gap, false, arcPaint(_green));
    canvas.drawArc(rect, _rad(165), _rad(55) - gap, false, arcPaint(_yellow));
    canvas.drawArc(rect, _rad(220), _rad(135) - gap, false, arcPaint(_red));

    // Crossbar of the "G", meeting the blue segment on the right.
    final barPaint = Paint()..color = _blue;
    final barHeight = strokeWidth * 0.9;
    final barRect = Rect.fromLTWH(
      center.dx - strokeWidth * 0.1,
      center.dy - barHeight / 2,
      outerRadius - strokeWidth * 0.1,
      barHeight,
    );
    canvas.drawRect(barRect, barPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
