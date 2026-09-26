import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../app_colors.dart';
import '../data/post_store.dart';
import '../data/product_info.dart';
import '../data/shop_categories.dart';
import '../utils/fa.dart';
import 'create_post_screen.dart';
import 'post_details_screen.dart';
import 'post_screen.dart';
import 'settings_screen.dart';

/// Profile images live in `assets/images/profile/`. Until they are added,
/// each slot falls back to a neutral placeholder.
class ProfileImages {
  ProfileImages._();

  static const avatar = 'assets/images/profile/avatar.png';
  static const works = [
    'assets/images/profile/work_1.jpg',
    'assets/images/profile/work_2.jpg',
    'assets/images/profile/work_3.jpg',
    'assets/images/profile/work_4.jpg',
  ];
}

class UserScreen extends StatefulWidget {
  const UserScreen({super.key});

  @override
  State<UserScreen> createState() => _UserScreenState();
}

class _UserScreenState extends State<UserScreen> {
  static const _all = 'همه';
  static const _sampleCount = 12;

  /// The picked category chip; [_all] shows everything.
  String _category = _all;

  Future<void> _addCategory() async {
    final name = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.deepBlack,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => const _AddCategorySheet(),
    );
    if (name == null || !mounted) return;
    final added = ShopCategories.add(name);
    setState(() => _category = added ?? name.trim());
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<String>>(
      valueListenable: ShopCategories.all,
      builder: (context, categories, _) =>
          ValueListenableBuilder<List<PostDraft>>(
            valueListenable: PostStore.posts,
            builder: (context, posts, _) => _build(context, categories, posts),
          ),
    );
  }

  Widget _build(
    BuildContext context,
    List<String> categories,
    List<PostDraft> allPosts,
  ) {
    final showAll = _category == _all;
    // A category shows only this session's posts filed under it; the
    // sample products belong to "all".
    final posts = showAll
        ? allPosts
        : [
            for (final p in allPosts)
              if (p.category == _category) p,
          ];
    final samples = showAll ? _sampleCount : 0;
    return ColoredBox(
      color: AppColors.pureWhite,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _TopBar(
              onMenu: () => Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const SettingsScreen())),
            ),
          ),
          SliverToBoxAdapter(
            child: _ProfileHeader(postCount: 385 + allPosts.length),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 14)),
          SliverToBoxAdapter(
            child: _CategoryChips(
              labels: [_all, ...categories],
              selected: _category,
              onSelected: (c) => setState(() => _category = c),
              onAdd: _addCategory,
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 14)),
          SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 4,
              crossAxisSpacing: 3,
              childAspectRatio: 0.56,
            ),
            // Posts published this session come first, then the samples.
            delegate: SliverChildBuilderDelegate((_, i) {
              if (i < posts.length) return _MyPostCard(post: posts[i]);
              final j = i - posts.length;
              return _ProductCard(
                image: ProfileImages.works[j % ProfileImages.works.length],
              );
            }, childCount: posts.length + samples),
          ),
          if (posts.length + samples == 0)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: Center(
                  child: Text(
                    'هنوز پستی در این دسته‌بندی نیست.',
                    style: TextStyle(color: AppColors.midGray, fontSize: 12),
                  ),
                ),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onMenu});
  final VoidCallback onMenu;

  static const _ink = AppColors.deepBlack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(8, 6, 8, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: onMenu,
            icon: const Icon(Icons.more_vert, color: _ink, size: 24),
          ),
          IconButton(
            onPressed: () {},
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const PaperPlaneIcon(size: 22),
                const PositionedDirectional(
                  top: -2,
                  end: -4,
                  child: CountBadge(count: 1),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Paper plane pointing up-right, as in the design, whatever the text
/// direction.
class PaperPlaneIcon extends StatelessWidget {
  const PaperPlaneIcon({super.key, this.size = 22});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -math.pi / 4,
      child: Icon(
        Icons.send_outlined,
        color: AppColors.deepBlack,
        size: size,
        textDirection: TextDirection.ltr,
      ),
    );
  }
}

/// Small red notification badge with a Persian count.
class CountBadge extends StatelessWidget {
  const CountBadge({super.key, required this.count});
  final int count;

  static const _red = Color(0xFFEF4444);

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 13),
      height: 13,
      padding: const EdgeInsets.symmetric(horizontal: 3),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: _red,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.pureWhite, width: 1),
      ),
      child: Text(
        faDigits(count),
        style: const TextStyle(
          color: AppColors.pureWhite,
          fontSize: 8,
          height: 1.1,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.postCount});

  final int postCount;

  static const _ink = AppColors.deepBlack;
  static const _muted = AppColors.midGray;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const ProfileAvatar(size: 86, ring: true),
              const SizedBox(width: 8),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    const _StatItem(value: '۱٫۵ هزار', label: 'مشتری'),
                    const _StatItem(value: '۱٬۰۵۱', label: 'فروش'),
                    _StatItem(value: faAmount(postCount), label: 'پست'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'موجی',
            style: TextStyle(
              color: _ink,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            'فروشگاه و خدمات',
            style: TextStyle(
              color: _muted.withValues(alpha: 0.6),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'طراح خلاقی که عاشق تبدیل ایده‌ها\nبه داستان‌های بصری است.',
            style: TextStyle(color: _ink, fontSize: 12.5, height: 1.6),
          ),
        ],
      ),
    );
  }
}

/// Round profile picture; [ring] adds the green "active" ring from the design.
class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({super.key, required this.size, this.ring = false});
  final double size;
  final bool ring;

  static const _green = Color(0xFF22C55E);

  @override
  Widget build(BuildContext context) {
    final picture = ClipOval(
      child: Image.asset(
        ProfileImages.avatar,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          width: size,
          height: size,
          color: AppColors.deepBlack,
          padding: EdgeInsets.all(size * 0.2),
          child: Image.asset('assets/images/logo.png', cacheWidth: 256),
        ),
      ),
    );
    if (!ring) return picture;
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: const BoxDecoration(shape: BoxShape.circle, color: _green),
      child: Container(
        padding: const EdgeInsets.all(2.5),
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.pureWhite,
        ),
        child: picture,
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.value, required this.label});
  final String value;
  final String label;

  static const _ink = AppColors.deepBlack;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: _ink,
            fontSize: 19,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: _ink, fontSize: 11.5)),
      ],
    );
  }
}

class _CategoryChips extends StatelessWidget {
  const _CategoryChips({
    required this.labels,
    required this.selected,
    required this.onSelected,
    required this.onAdd,
  });

  final List<String> labels;
  final String selected;
  final ValueChanged<String> onSelected;
  final VoidCallback onAdd;

  static const _ink = AppColors.deepBlack;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 30,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: labels.length + 1,
        separatorBuilder: (_, _) => const SizedBox(width: 6),
        itemBuilder: (context, i) {
          if (i == 0) {
            return InkWell(
              onTap: onAdd,
              customBorder: const CircleBorder(),
              child: const Tooltip(
                message: 'افزودن دسته‌بندی',
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(Icons.add, color: _ink, size: 22),
                ),
              ),
            );
          }
          final label = labels[i - 1];
          return _Chip(
            label: label,
            selected: label == selected,
            onTap: () => onSelected(label),
          );
        },
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.deepBlack : null,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? AppColors.deepBlack : AppColors.divider,
            width: 1.2,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppColors.pureWhite : AppColors.midGray,
            fontSize: 11.5,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

/// Dark "Add category" sheet: one name field, Done / Cancel. Pops the typed
/// name, or null when cancelled.
class _AddCategorySheet extends StatefulWidget {
  const _AddCategorySheet();

  @override
  State<_AddCategorySheet> createState() => _AddCategorySheetState();
}

class _AddCategorySheetState extends State<_AddCategorySheet> {
  final _name = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _done() {
    final name = _name.text.trim();
    if (name.isEmpty) return;
    Navigator.of(context).pop(name);
  }

  @override
  Widget build(BuildContext context) {
    const white = AppColors.pureWhite;
    const ink = AppColors.deepBlack;
    final buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
    );
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  margin: const EdgeInsets.only(top: 10, bottom: 18),
                  decoration: BoxDecoration(
                    color: white,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Text(
                'افزودن دسته‌بندی',
                style: TextStyle(
                  color: white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'دسته‌بندی جدید روی پروفایل شما نمایش داده می‌شود و هنگام '
                'ساخت پست قابل انتخاب است.',
                style: TextStyle(
                  color: AppColors.midGray,
                  fontSize: 10.5,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 14),
              Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  border: Border.all(color: white),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: TextField(
                  controller: _name,
                  autofocus: true,
                  onSubmitted: (_) => _done(),
                  cursorColor: white,
                  style: const TextStyle(color: white, fontSize: 13),
                  decoration: const InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    hintText: 'نام دسته‌بندی',
                    hintStyle: TextStyle(
                      color: AppColors.midGray,
                      fontSize: 12.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      onPressed: _done,
                      style: FilledButton.styleFrom(
                        backgroundColor: white,
                        foregroundColor: ink,
                        minimumSize: const Size.fromHeight(42),
                        shape: buttonShape,
                      ),
                      child: const Text('تأیید'),
                    ),
                  ),
                  const SizedBox(width: 60),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: white,
                        side: const BorderSide(color: white),
                        minimumSize: const Size.fromHeight(42),
                        shape: buttonShape,
                      ),
                      child: const Text('انصراف'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.image});
  final String image;

  static const _ink = AppColors.deepBlack;
  static const _muted = AppColors.midGray;
  static const _red = Color(0xFFEF4444);

  @override
  Widget build(BuildContext context) {
    const textPadding = EdgeInsetsDirectional.only(start: 6, end: 4);
    return InkWell(
      onTap: () => Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const PostScreen())),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: 0.95,
            child: Image.asset(
              image,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                color: AppColors.surfaceOnLight,
                child: Icon(
                  Icons.image_outlined,
                  size: 26,
                  color: _muted.withValues(alpha: 0.7),
                ),
              ),
            ),
          ),
          const SizedBox(height: 5),
          const Padding(
            padding: textPadding,
            child: Text(
              'هدفون بی‌سیم بلوتوثی',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: _ink, fontSize: 11, height: 1.35),
            ),
          ),
          Padding(
            padding: textPadding,
            child: Text(
              'موبایل',
              style: TextStyle(
                color: _muted.withValues(alpha: 0.8),
                fontSize: 8.5,
              ),
            ),
          ),
          const Padding(
            padding: textPadding,
            child: Text(
              '۲ عدد در انبار',
              style: TextStyle(color: _red, fontSize: 8.5),
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '۱۵٬۰۰۰',
                        style: TextStyle(
                          color: _muted.withValues(alpha: 0.7),
                          fontSize: 8.5,
                          decoration: TextDecoration.lineThrough,
                          decorationColor: _muted.withValues(alpha: 0.7),
                        ),
                      ),
                      Text.rich(
                        TextSpan(
                          children: [
                            const TextSpan(
                              text: '۱۲٬۰۰۰ ',
                              style: TextStyle(
                                color: _ink,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            TextSpan(
                              text: 'تومان',
                              style: TextStyle(
                                color: _muted.withValues(alpha: 0.9),
                                fontSize: 8.5,
                              ),
                            ),
                          ],
                        ),
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(bottom: 2),
                  child: Icon(Icons.local_mall, size: 14, color: _ink),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
        ],
      ),
    );
  }
}

/// A post published this session, drawn from its draft: first media item,
/// title, category, stock and the cheapest variant's price.
class _MyPostCard extends StatelessWidget {
  const _MyPostCard({required this.post});
  final PostDraft post;

  static const _ink = AppColors.deepBlack;
  static const _muted = AppColors.midGray;
  static const _red = Color(0xFFEF4444);
  static const _shadow = [Shadow(blurRadius: 3, color: Color(0x99000000))];

  ProductVariant get _cheapest {
    final priced = post.variants.where((v) => v.effectivePrice != null);
    if (priced.isEmpty) return post.variants.first;
    return priced.reduce(
      (a, b) => a.effectivePrice! <= b.effectivePrice! ? a : b,
    );
  }

  String get _stockText {
    final v = _cheapest;
    if (v.status != InventoryStatus.inStock) return v.status.label;
    if (v.preOrder) return 'پیش‌فروش';
    final total = post.variants.fold(0, (sum, v) => sum + v.stock);
    return '${faDigits(total)} ${v.unit ?? 'عدد'} در انبار';
  }

  bool get _lowStock =>
      _cheapest.status != InventoryStatus.inStock ||
      post.variants.every((v) => v.stock <= v.threshold);

  @override
  Widget build(BuildContext context) {
    const textPadding = EdgeInsetsDirectional.only(start: 6, end: 4);
    final v = _cheapest;
    final price = v.effectivePrice;
    final struck = price != null && price != v.price ? v.price : null;
    final subtitle = post.category ?? post.type;
    final scheduled =
        post.scheduledAt != null && post.scheduledAt!.isAfter(DateTime.now());
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AspectRatio(
          aspectRatio: 0.95,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ColoredBox(
                color: AppColors.surfaceOnLight,
                child: post.media.isEmpty
                    ? Icon(
                        Icons.image_outlined,
                        size: 26,
                        color: _muted.withValues(alpha: 0.7),
                      )
                    : PickedMediaView(
                        item: post.media.first,
                        size: 360,
                        fit: BoxFit.cover,
                      ),
              ),
              if (post.media.length > 1)
                const PositionedDirectional(
                  top: 5,
                  end: 5,
                  child: Icon(
                    Icons.filter_none,
                    size: 14,
                    color: AppColors.pureWhite,
                    shadows: _shadow,
                  ),
                ),
              if (scheduled)
                const PositionedDirectional(
                  top: 5,
                  start: 5,
                  child: Icon(
                    Icons.schedule,
                    size: 15,
                    color: AppColors.pureWhite,
                    shadows: _shadow,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 5),
        Padding(
          padding: textPadding,
          child: Text(
            post.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: _ink, fontSize: 11, height: 1.35),
          ),
        ),
        if (subtitle != null)
          Padding(
            padding: textPadding,
            child: Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: _muted.withValues(alpha: 0.8),
                fontSize: 8.5,
              ),
            ),
          ),
        Padding(
          padding: textPadding,
          child: Text(
            _stockText,
            style: TextStyle(color: _lowStock ? _red : _muted, fontSize: 8.5),
          ),
        ),
        const Spacer(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (struck != null)
                      Text(
                        faAmount(struck),
                        style: TextStyle(
                          color: _muted.withValues(alpha: 0.7),
                          fontSize: 8.5,
                          decoration: TextDecoration.lineThrough,
                          decorationColor: _muted.withValues(alpha: 0.7),
                        ),
                      ),
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: price == null
                                ? 'بدون قیمت'
                                : '${faAmount(price)} ',
                            style: const TextStyle(
                              color: _ink,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (price != null)
                            TextSpan(
                              text: 'تومان',
                              style: TextStyle(
                                color: _muted.withValues(alpha: 0.9),
                                fontSize: 8.5,
                              ),
                            ),
                        ],
                      ),
                      maxLines: 1,
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(bottom: 2),
                child: Icon(Icons.local_mall, size: 14, color: _ink),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
      ],
    );
  }
}
