import 'package:flutter/material.dart';
import '../app_colors.dart';
import '../utils/fa.dart';

class TrendingScreen extends StatelessWidget {
  const TrendingScreen({super.key});

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
    final items = [..._products, ..._products];

    return Scaffold(
      backgroundColor: AppColors.pureWhite,
      body: SafeArea(
        child: Column(
          children: [
            _Header(
              title: 'پرطرفدارها',
              onSave: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('فهرست پرطرفدارها به‌روزرسانی شد'),
                ),
              ),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(22, 8, 22, 28),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 14,
                  childAspectRatio: 0.72,
                ),
                itemCount: items.length,
                itemBuilder: (_, i) => _ProductCard(
                  product: items[i],
                  rank: i % _products.length + 1,
                ),
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
          const Spacer(),
          InkWell(
            onTap: onSave,
            customBorder: const CircleBorder(),
            child: const Padding(
              padding: EdgeInsets.all(8),
              child: Icon(Icons.check, color: _ink, size: 24),
            ),
          ),
        ],
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
  const _ProductCard({required this.product, required this.rank});
  final _Product product;
  final int rank;

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
                  start: 6,
                  top: 6,
                  child: Container(
                    height: 20,
                    padding: const EdgeInsets.symmetric(horizontal: 7),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.deepBlack,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.local_fire_department,
                          size: 11,
                          color: AppColors.pureWhite,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          faDigits(rank),
                          style: const TextStyle(
                            color: AppColors.pureWhite,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
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
