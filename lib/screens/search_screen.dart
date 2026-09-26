import 'package:flutter/material.dart';
import '../app_colors.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  static const _ink = AppColors.deepBlack;
  static const _muted = AppColors.midGray;
  static const _field = AppColors.surfaceOnLight;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'جستجو',
            style: TextStyle(
              color: _ink,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            style: const TextStyle(fontSize: 15),
            decoration: InputDecoration(
              hintText: 'جستجوی افراد، پست‌ها، محصولات...',
              hintStyle: const TextStyle(color: _muted, fontSize: 14),
              prefixIcon: const Icon(Icons.search, color: _muted),
              filled: true,
              fillColor: _field,
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 88,
                    height: 88,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: _field,
                    ),
                    child: const Icon(
                      Icons.travel_explore,
                      size: 36,
                      color: _muted,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'هر چیزی را جستجو کنید',
                    style: TextStyle(
                      color: _ink,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'نتایج جستجو اینجا نمایش داده می‌شود.',
                    style: TextStyle(color: _muted, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
