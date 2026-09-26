import 'package:flutter/material.dart';
import '../app_colors.dart';
import '../data/countries.dart';
import '../utils/fa.dart';
import 'flag_chip.dart';

/// Searchable country + dial-code picker, shown as a full-height sheet.
class CountryPickerSheet extends StatefulWidget {
  const CountryPickerSheet({super.key});

  static Future<CountryInfo?> show(BuildContext context) {
    return Navigator.of(context).push<CountryInfo>(
      PageRouteBuilder(
        opaque: true,
        transitionDuration: const Duration(milliseconds: 260),
        pageBuilder: (context, animation, secondaryAnimation) =>
            const CountryPickerSheet(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween(begin: const Offset(0, 1), end: Offset.zero)
                .animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                ),
            child: child,
          );
        },
      ),
    );
  }

  @override
  State<CountryPickerSheet> createState() => _CountryPickerSheetState();
}

class _CountryPickerSheetState extends State<CountryPickerSheet> {
  static const _bg = AppColors.deepBlack;
  static const _onPrimary = AppColors.pureWhite;

  final _searchController = TextEditingController();
  late List<CountryInfo> _filtered;

  @override
  void initState() {
    super.initState();
    _filtered = kCountries;
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    final q = _searchController.text.trim();
    setState(() {
      _filtered = q.isEmpty
          ? kCountries
          : kCountries
                .where(
                  (c) =>
                      c.name.contains(q) ||
                      c.dialCode.contains(q) ||
                      faDigits(c.dialCode).contains(q),
                )
                .toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(4, 8, 16, 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back, color: _onPrimary),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      autofocus: false,
                      style: const TextStyle(
                        color: AppColors.deepBlack,
                        fontSize: 15,
                      ),
                      cursorColor: AppColors.deepBlack,
                      decoration: InputDecoration(
                        hintText: 'جستجوی کشور یا کد',
                        hintStyle: const TextStyle(
                          color: AppColors.midGray,
                          fontSize: 15,
                        ),
                        prefixIcon: const Icon(
                          Icons.search,
                          color: AppColors.deepBlack,
                        ),
                        filled: true,
                        fillColor: AppColors.pureWhite,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 14,
                          horizontal: 20,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(999),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _filtered.isEmpty
                  ? const Center(
                      child: Text(
                        'کشوری پیدا نشد',
                        style: TextStyle(
                          color: AppColors.midGray,
                          fontSize: 14,
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      itemCount: _filtered.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 14),
                      itemBuilder: (context, i) {
                        final c = _filtered[i];
                        return InkWell(
                          onTap: () => Navigator.of(context).pop(c),
                          child: Row(
                            children: [
                              FlagChip(iso2: c.iso2, size: 26),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  c.name,
                                  style: const TextStyle(
                                    color: _onPrimary,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 64,
                                child: Text(
                                  faDigits(c.dialCode),
                                  textDirection: TextDirection.ltr,
                                  textAlign: TextAlign.left,
                                  style: const TextStyle(
                                    color: _onPrimary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
