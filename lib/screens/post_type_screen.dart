import 'package:flutter/material.dart';
import '../app_colors.dart';
import '../widgets/pill_picker.dart';

/// "Post type": a group dropdown (physical / digital / handmade / services)
/// over a centered list of that group's types. Tapping a type selects it;
/// the check pops it as a `String`. "+" adds whatever is in the search box.
class PostTypeScreen extends StatefulWidget {
  const PostTypeScreen({super.key, this.initial});

  final String? initial;

  static const groups = {
    'محصولات فیزیکی': [
      'موبایل، تبلت، لپ‌تاپ',
      'پوشاک، کفش، اکسسوری',
      'لوازم خانگی',
      'لوازم آشپزخانه',
      'تجهیزات ورزشی',
      'زیبایی و مراقبت شخصی',
      'قطعات خودرو',
      'ابزار و یراق',
      'اسباب‌بازی',
      'غذای آماده',
    ],
    'محصولات دیجیتال': [
      'کتاب الکترونیکی',
      'لایسنس نرم‌افزار',
      'قالب‌ها و فایل‌های گرافیکی',
      'فایل‌های موسیقی / ویدیو / صوتی',
      'دوره‌های قابل دانلود',
    ],
    'دست‌ساز / صنایع دستی': [
      'زیورآلات دست‌ساز',
      'هنر و نقاشی',
      'سرامیک',
      'بافتنی',
    ],
    'خدمات شخصی': [
      'آرایشگری',
      'ماساژ',
      'خدمات زیبایی',
      'مراقبت از سالمند / کودک',
    ],
    'خدمات منزل و تعمیرات': [
      'برق‌کاری',
      'لوله‌کشی',
      'نظافت',
      'نقاشی ساختمان',
      'تعمیر لوازم خانگی',
    ],
    'خدمات تخصصی': [
      'برنامه‌نویسی',
      'طراحی گرافیک',
      'ترجمه',
      'حسابداری',
      'مشاوره (آنلاین / حضوری)',
    ],
    'خدمات رسانه‌ای': ['عکاسی', 'فیلم‌برداری', 'تدوین ویدیو'],
  };

  @override
  State<PostTypeScreen> createState() => _PostTypeScreenState();
}

class _PostTypeScreenState extends State<PostTypeScreen> {
  static const _ink = AppColors.deepBlack;

  final _search = TextEditingController();
  final Map<String, List<String>> _groups = {
    for (final e in PostTypeScreen.groups.entries) e.key: List.of(e.value),
  };
  late String _group = _groupOf(widget.initial) ?? _groups.keys.first;
  late String? _selected = widget.initial;
  String _query = '';

  String? _groupOf(String? type) {
    if (type == null) return null;
    for (final e in _groups.entries) {
      if (e.value.contains(type)) return e.key;
    }
    // A custom type from an earlier visit: keep it in the first group.
    _groups.values.first.insert(0, type);
    return _groups.keys.first;
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _add() {
    final value = _search.text.trim();
    if (value.isEmpty) return;
    _search.clear();
    setState(() {
      _query = '';
      final items = _groups[_group]!;
      if (!items.contains(value)) items.insert(0, value);
      _selected = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final q = _query.trim();
    // Searching looks across every group, not just the open one.
    final items = q.isEmpty
        ? _groups[_group]!
        : [
            for (final list in _groups.values)
              ...list.where((t) => t.contains(q)),
          ];
    return Scaffold(
      backgroundColor: AppColors.pureWhite,
      body: SafeArea(
        child: Column(
          children: [
            PickerHeader(
              title: 'نوع پست',
              onDone: () => Navigator.of(context).pop(_selected),
            ),
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(6, 0, 16, 14),
              child: PickerSearchBar(
                controller: _search,
                onChanged: (v) => setState(() => _query = v),
                onAdd: _add,
              ),
            ),
            if (q.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: _GroupDropdown(
                  groups: _groups.keys.toList(),
                  value: _group,
                  onChanged: (g) => setState(() => _group = g),
                ),
              ),
            Expanded(
              child: items.isEmpty
                  ? const Center(
                      child: Text(
                        'موردی پیدا نشد',
                        style: TextStyle(color: AppColors.midGray),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
                      itemCount: items.length,
                      itemBuilder: (_, i) {
                        final type = items[i];
                        final selected = type == _selected;
                        return Center(
                          child: Material(
                            color: selected ? _ink : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            child: InkWell(
                              onTap: () => setState(
                                () => _selected = selected ? null : type,
                              ),
                              borderRadius: BorderRadius.circular(8),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 7,
                                ),
                                child: Text(
                                  type,
                                  style: TextStyle(
                                    color: selected
                                        ? AppColors.pureWhite
                                        : _ink,
                                    fontSize: 13.5,
                                    fontWeight: selected
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                  ),
                                ),
                              ),
                            ),
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

/// Bordered pill showing the open group; tapping it lists every group.
class _GroupDropdown extends StatelessWidget {
  const _GroupDropdown({
    required this.groups,
    required this.value,
    required this.onChanged,
  });

  final List<String> groups;
  final String value;
  final ValueChanged<String> onChanged;

  static const _ink = AppColors.deepBlack;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: onChanged,
      color: AppColors.pureWhite,
      position: PopupMenuPosition.under,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      itemBuilder: (_) => [
        for (final g in groups)
          PopupMenuItem(
            value: g,
            child: Text(
              g,
              style: TextStyle(
                color: _ink,
                fontSize: 13.5,
                fontWeight: g == value ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ),
      ],
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          border: Border.all(color: _ink),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                value,
                style: const TextStyle(
                  color: _ink,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Icon(Icons.keyboard_arrow_down, color: _ink, size: 22),
          ],
        ),
      ),
    );
  }
}
