import 'package:flutter/material.dart';
import '../data/shop_categories.dart';
import '../widgets/pill_picker.dart';

/// Single-select category list: the shop's own categories (see
/// [ShopCategories]) first, then the general ones. Pops the chosen category
/// as a one-item `List<String>` (empty when cleared).
class CategoryScreen extends StatelessWidget {
  const CategoryScreen({super.key, this.initial});

  final String? initial;

  static const categories = [
    'خدمات منزل',
    'حمل‌ونقل',
    'تعمیر و نگهداری',
    'زیبایی و مراقبت شخصی',
    'خدمات بهداشتی و درمانی',
    'آموزش و تدریس خصوصی',
    'خدمات مراسم و عروسی',
    'خدمات نظافت',
    'پشتیبانی فنی و IT',
    'مشاوره',
  ];

  @override
  Widget build(BuildContext context) {
    return PillPickerScreen(
      title: 'دسته‌بندی',
      options: [
        ...{...ShopCategories.all.value, ...categories},
      ],
      initial: [?initial],
    );
  }
}
