import 'package:flutter/material.dart';
import '../app_colors.dart';
import '../utils/fa.dart';

class SavedScreen extends StatelessWidget {
  const SavedScreen({super.key});

  static const _products = [
    _Product(
      icon: Icons.water_drop_outlined,
      tint: Color(0xFFDCEEF5),
      name: 'بطری آب استیل ضدزنگ',
      price: 99000,
    ),
    _Product(
      icon: Icons.tv_outlined,
      tint: Color(0xFFFBE9DC),
      name: 'تلویزیون هوشمند ۵۵ اینچ',
      price: 57000,
    ),
    _Product(
      icon: Icons.headphones_outlined,
      tint: Color(0xFFEAE3F7),
      name: 'هدفون بی‌سیم بلوتوثی',
      price: 12000,
    ),
    _Product(
      icon: Icons.checkroom_outlined,
      tint: Color(0xFFE1F3E0),
      name: 'تی‌شرت نخی (مردانه و زنانه)',
      price: 91000,
    ),
    _Product(
      icon: Icons.battery_charging_full_outlined,
      tint: Color(0xFFFBF3D6),
      name: 'پاوربانک ۱۰۰۰۰ میلی‌آمپر',
      price: 64000,
    ),
    _Product(
      icon: Icons.chair_outlined,
      tint: Color(0xFFFCE1E6),
      name: 'صندلی اداری ارگونومیک',
      price: 82000,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pureWhite,
      body: SafeArea(
        child: Column(
          children: [
            _Header(
              title: 'ذخیره‌شده‌ها',
              onSave: () => ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('تغییرات ذخیره شد'))),
            ),
            Expanded(
              child: CustomScrollView(
                slivers: [
                  const SliverPadding(
                    padding: EdgeInsets.fromLTRB(20, 4, 20, 8),
                    sliver: SliverToBoxAdapter(
                      child: _DayHeader(label: 'امروز'),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                    sliver: _productGrid(),
                  ),
                  const SliverPadding(
                    padding: EdgeInsets.fromLTRB(20, 8, 20, 8),
                    sliver: SliverToBoxAdapter(
                      child: _DayHeader(label: 'دیروز'),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    sliver: _productGrid(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  SliverGrid _productGrid() {
    return SliverGrid(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 14,
        crossAxisSpacing: 12,
        childAspectRatio: 0.72,
      ),
      delegate: SliverChildBuilderDelegate(
        (_, i) => _ProductCard(product: _products[i]),
        childCount: _products.length,
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

class _DayHeader extends StatelessWidget {
  const _DayHeader({required this.label});
  final String label;

  static const _muted = AppColors.midGray;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        color: _muted.withValues(alpha: 0.9),
        fontSize: 12.5,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _Product {
  const _Product({
    required this.icon,
    required this.tint,
    required this.name,
    required this.price,
  });
  final IconData icon;
  final Color tint;
  final String name;
  final int price;
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.product});
  final _Product product;

  static const _ink = AppColors.deepBlack;

  @override
  Widget build(BuildContext context) {
    final formatted = '${faAmount(product.price)} تومان';

    return InkWell(
      onTap: () => ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(product.name))),
      borderRadius: BorderRadius.circular(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: product.tint,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      product.icon,
                      size: 30,
                      color: _ink.withValues(alpha: 0.55),
                    ),
                  ),
                ),
                PositionedDirectional(
                  end: 6,
                  top: 6,
                  child: Container(
                    width: 22,
                    height: 22,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.deepBlack,
                    ),
                    child: const Icon(
                      Icons.bookmark,
                      size: 11,
                      color: AppColors.pureWhite,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            product.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _ink,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            formatted,
            style: const TextStyle(
              color: _ink,
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
