import 'package:flutter/material.dart';
import '../app_colors.dart';

class LocationsScreen extends StatelessWidget {
  const LocationsScreen({super.key});

  static const _outline = AppColors.divider;

  static const _saved = [
    _SavedLocation(icon: Icons.home_outlined, label: 'خانه'),
    _SavedLocation(icon: Icons.work_outline, label: 'محل کار'),
    _SavedLocation(icon: Icons.location_on_outlined, label: 'مکان ۳'),
    _SavedLocation(icon: Icons.location_on_outlined, label: 'مکان ۴'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pureWhite,
      body: SafeArea(
        child: Column(
          children: [
            _Header(
              title: 'مکان‌ها',
              onSave: () => ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('مکان‌ها ذخیره شد'))),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                children: [
                  const _MapPreview(),
                  const SizedBox(height: 16),
                  _LabelField(),
                  const SizedBox(height: 10),
                  const _AddressRow(address: 'خیابان ...، لندن، بریتانیا'),
                  const SizedBox(height: 24),
                  for (final loc in _saved) ...[
                    _LocationRow(location: loc),
                    const Divider(height: 1, color: _outline),
                  ],
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
      padding: const EdgeInsetsDirectional.fromSTEB(8, 8, 16, 4),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.chevron_left, color: _ink, size: 26),
          ),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _ink,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          InkWell(
            onTap: onSave,
            customBorder: const CircleBorder(),
            child: const Padding(
              padding: EdgeInsets.all(8),
              child: Icon(Icons.check, color: _ink, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

/// Stylized, offline map preview — no live map tiles are wired up, so this
/// draws a lightweight grayscale road network with a couple of pins.
class _MapPreview extends StatelessWidget {
  const _MapPreview();

  static const _ink = AppColors.deepBlack;
  static const _muted = AppColors.midGray;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 220,
        color: AppColors.surfaceOnLight,
        child: Stack(
          children: [
            const Positioned.fill(child: CustomPaint(painter: _RoadsPainter())),
            Positioned(left: 46, top: 60, child: _Pin(color: _muted, size: 22)),
            Positioned(
              right: 60,
              top: 110,
              child: _Pin(color: _muted, size: 22),
            ),
            Align(
              alignment: Alignment.center,
              child: _Pin(color: _ink, size: 34),
            ),
            PositionedDirectional(
              end: 12,
              bottom: 12,
              child: Material(
                color: AppColors.pureWhite,
                shape: const CircleBorder(),
                elevation: 2,
                shadowColor: AppColors.deepBlack.withValues(alpha: 0.2),
                child: const Padding(
                  padding: EdgeInsets.all(9),
                  child: Icon(Icons.my_location, size: 18, color: _ink),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Pin extends StatelessWidget {
  const _Pin({required this.color, required this.size});
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Icon(Icons.location_on, color: color, size: size);
  }
}

class _RoadsPainter extends CustomPainter {
  const _RoadsPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final road = Paint()
      ..color = AppColors.pureWhite
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    final minorRoad = Paint()
      ..color = AppColors.pureWhite.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(0, size.height * 0.3),
      Offset(size.width, size.height * 0.22),
      road,
    );
    canvas.drawLine(
      Offset(0, size.height * 0.68),
      Offset(size.width, size.height * 0.78),
      road,
    );
    canvas.drawLine(
      Offset(size.width * 0.28, 0),
      Offset(size.width * 0.2, size.height),
      minorRoad,
    );
    canvas.drawLine(
      Offset(size.width * 0.66, 0),
      Offset(size.width * 0.74, size.height),
      minorRoad,
    );
    canvas.drawLine(
      Offset(size.width * 0.1, size.height * 0.5),
      Offset(size.width * 0.9, size.height * 0.5),
      minorRoad,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _LabelField extends StatelessWidget {
  _LabelField();

  final _controller = TextEditingController();

  static const _ink = AppColors.deepBlack;
  static const _muted = AppColors.midGray;
  static const _outline = AppColors.divider;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _outline),
      ),
      child: Row(
        children: [
          const Icon(Icons.label_outline, size: 18, color: _muted),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _controller,
              style: const TextStyle(
                color: _ink,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                hintText: 'عنوان مکان',
                hintStyle: TextStyle(
                  color: _muted.withValues(alpha: 0.9),
                  fontWeight: FontWeight.w500,
                ),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          const Icon(Icons.add_circle_outline, size: 20, color: _ink),
        ],
      ),
    );
  }
}

class _AddressRow extends StatelessWidget {
  const _AddressRow({required this.address});
  final String address;

  static const _ink = AppColors.deepBlack;
  static const _muted = AppColors.midGray;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.location_on_outlined, size: 16, color: _muted),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            address,
            style: const TextStyle(
              color: _ink,
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _SavedLocation {
  const _SavedLocation({required this.icon, required this.label});
  final IconData icon;
  final String label;
}

class _LocationRow extends StatelessWidget {
  const _LocationRow({required this.location});
  final _SavedLocation location;

  static const _ink = AppColors.deepBlack;
  static const _muted = AppColors.midGray;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(location.label))),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Icon(location.icon, size: 18, color: _ink),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                location.label,
                style: const TextStyle(
                  color: _ink,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: _muted, size: 18),
          ],
        ),
      ),
    );
  }
}
