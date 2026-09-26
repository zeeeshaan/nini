import 'package:flutter/material.dart';

import '../app_colors.dart';
import '../data/post_store.dart';
import '../data/product_info.dart';
import '../utils/fa.dart';
import '../widgets/pill_picker.dart';
import 'create_post_screen.dart';
import 'post_details_screen.dart';

const _ink = AppColors.deepBlack;
const _white = AppColors.pureWhite;
const _muted = AppColors.midGray;

/// Opens the product "Information" flow and resolves to the edited
/// attributes, or null when the user backs out. With nothing set yet it
/// starts on the empty [InformationScreen]; otherwise straight on
/// [AttributesScreen].
Future<List<ProductAttribute>?> openInformation(
  BuildContext context,
  List<ProductAttribute> initial,
) {
  return Navigator.of(context).push<List<ProductAttribute>>(
    MaterialPageRoute(
      builder: (_) => initial.isEmpty
          ? const InformationScreen()
          : AttributesScreen(initial: initial),
    ),
  );
}

/// Picks feature keys on the numbered Feature page and returns them in
/// pick order, or null when cancelled.
Future<List<String>?> _pickFeatures(
  BuildContext context,
  List<String> current,
) {
  return Navigator.of(context).push<List<String>>(
    MaterialPageRoute(
      builder: (_) => PillPickerScreen(
        title: 'ویژگی',
        options: kSuggestedFeatures,
        initial: current,
        multi: true,
        numbered: true,
        searchHint: 'کلید',
        helper: 'یک ویژگی موجود را جستجو کنید یا ویژگی جدید بسازید',
      ),
    ),
  );
}

/// "Information" page for a post with nothing described yet. "+" (or the
/// search field) opens the Feature page; the chosen features continue on
/// [AttributesScreen], whose result is popped straight back. Products
/// published earlier are listed as cards, one per variant; tapping one
/// starts from that product's features and values.
class InformationScreen extends StatelessWidget {
  const InformationScreen({super.key});

  Future<void> _reuse(BuildContext context, PostDraft post) async {
    final navigator = Navigator.of(context);
    final attrs = await navigator.push<List<ProductAttribute>>(
      MaterialPageRoute(
        builder: (_) => AttributesScreen(initial: post.information),
      ),
    );
    if (attrs != null) navigator.pop(attrs);
  }

  Future<void> _start(BuildContext context) async {
    final navigator = Navigator.of(context);
    final features = await _pickFeatures(context, const []);
    if (features == null || features.isEmpty) return;
    final attrs = await navigator.push<List<ProductAttribute>>(
      MaterialPageRoute(
        builder: (_) => AttributesScreen(
          initial: [for (final f in features) ProductAttribute(f)],
        ),
      ),
    );
    if (attrs != null) navigator.pop(attrs);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(6, 10, 10, 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.chevron_left, color: _ink, size: 30),
                  ),
                  const Expanded(
                    child: Text(
                      'اطلاعات',
                      style: TextStyle(
                        color: _ink,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => _start(context),
                    tooltip: 'افزودن ویژگی',
                    icon: const Icon(Icons.add, color: _ink, size: 28),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _SearchBox(
                hint: 'جستجوی ویژگی',
                onTap: () => _start(context),
              ),
            ),
            Expanded(
              child: ValueListenableBuilder<List<PostDraft>>(
                valueListenable: PostStore.posts,
                builder: (context, posts, _) {
                  final products = [
                    for (final p in posts)
                      if (p.information.isNotEmpty)
                        for (final v in p.variants) (p, v),
                  ];
                  if (products.isEmpty) return const _EmptyState();
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
                    itemCount: products.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final (post, variant) = products[i];
                      return _ProductCard(
                        post: post,
                        variant: variant,
                        onTap: () => _reuse(context, post),
                      );
                    },
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

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 80),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 170,
            height: 110,
            child: CustomPaint(painter: _DesertPainter()),
          ),
          const SizedBox(height: 14),
          const Text(
            'در حال حاضر محصولی برای نمایش وجود ندارد.',
            style: TextStyle(color: _muted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

/// Empty-state illustration from the design: a desert with two cacti, a
/// rock, a sun and a cloud, in the app's grays.
class _DesertPainter extends CustomPainter {
  const _DesertPainter();

  static const _light = AppColors.surfaceOnLight;
  static const _mid = AppColors.divider;
  static const _dark = AppColors.midGray;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final fill = Paint()..style = PaintingStyle.fill;

    // Sun and cloud.
    canvas.drawCircle(Offset(w * 0.8, h * 0.2), h * 0.11, fill..color = _mid);
    fill.color = _light;
    for (final (dx, dy, r) in [
      (0.26, 0.2, 0.08),
      (0.33, 0.16, 0.1),
      (0.4, 0.21, 0.07),
    ]) {
      canvas.drawCircle(Offset(w * dx, h * dy), h * r, fill);
    }
    canvas.drawRRect(
      RRect.fromLTRBR(
        w * 0.22,
        h * 0.2,
        w * 0.45,
        h * 0.28,
        Radius.circular(h * 0.04),
      ),
      fill,
    );

    // Dunes.
    final back = Path()
      ..moveTo(0, h * 0.78)
      ..quadraticBezierTo(w * 0.3, h * 0.6, w * 0.6, h * 0.74)
      ..quadraticBezierTo(w * 0.8, h * 0.82, w, h * 0.7)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(back, fill..color = _light);
    final front = Path()
      ..moveTo(0, h * 0.9)
      ..quadraticBezierTo(w * 0.5, h * 0.8, w, h * 0.92)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(front, fill..color = _mid);

    // Cacti: a trunk with two arms, and a smaller one.
    _cactus(canvas, Offset(w * 0.36, h * 0.86), h * 0.62, fill..color = _dark);
    _cactus(canvas, Offset(w * 0.68, h * 0.88), h * 0.36, fill);

    // Rock.
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.52, h * 0.9),
        width: w * 0.1,
        height: h * 0.07,
      ),
      fill..color = _dark.withValues(alpha: 0.6),
    );
  }

  /// [base] is the bottom-centre of the trunk; [height] its full height.
  void _cactus(Canvas canvas, Offset base, double height, Paint paint) {
    final t = height * 0.2; // trunk thickness
    final r = Radius.circular(t / 2);
    canvas.drawRRect(
      RRect.fromLTRBR(
        base.dx - t / 2,
        base.dy - height,
        base.dx + t / 2,
        base.dy,
        r,
      ),
      paint,
    );
    final a = t * 0.75; // arm thickness
    final ar = Radius.circular(a / 2);
    // Left arm: out, then up.
    final ly = base.dy - height * 0.45;
    canvas.drawRRect(
      RRect.fromLTRBR(base.dx - t * 1.6, ly - a, base.dx, ly, ar),
      paint,
    );
    canvas.drawRRect(
      RRect.fromLTRBR(
        base.dx - t * 1.6,
        ly - height * 0.35,
        base.dx - t * 1.6 + a,
        ly,
        ar,
      ),
      paint,
    );
    // Right arm, a little higher.
    final ry = base.dy - height * 0.6;
    canvas.drawRRect(
      RRect.fromLTRBR(base.dx, ry - a, base.dx + t * 1.5, ry, ar),
      paint,
    );
    canvas.drawRRect(
      RRect.fromLTRBR(
        base.dx + t * 1.5 - a,
        ry - height * 0.28,
        base.dx + t * 1.5,
        ry,
        ar,
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(_DesertPainter oldDelegate) => false;
}

/// A published product variant: title, each feature with this variant's
/// value, the price per unit and the post's first image.
class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.post,
    required this.variant,
    required this.onTap,
  });

  final PostDraft post;
  final ProductVariant variant;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final price = variant.effectivePrice;
    return Material(
      color: _white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: _ink.withValues(alpha: 0.75)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      post.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _ink,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    for (final a in post.information)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                a.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: _muted,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              faDigits(variant.values[a.name] ?? '—'),
                              style: const TextStyle(
                                color: _ink,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 6),
                    Text(
                      price == null
                          ? 'بدون قیمت'
                          : '${faAmount(price)} تومان / ${variant.unit ?? 'عدد'}',
                      textAlign: TextAlign.end,
                      style: const TextStyle(
                        color: _ink,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: SizedBox(
                  width: 96,
                  height: 72,
                  child: post.media.isEmpty
                      ? const ColoredBox(
                          color: AppColors.surfaceOnLight,
                          child: Icon(
                            Icons.image_outlined,
                            color: _muted,
                            size: 28,
                          ),
                        )
                      : PickedMediaView(
                          item: post.media.first,
                          size: 240,
                          fit: BoxFit.cover,
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Search-looking field that opens the Feature page when tapped.
class _SearchBox extends StatelessWidget {
  const _SearchBox({required this.hint, required this.onTap});

  final String hint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 40,
        padding: const EdgeInsetsDirectional.only(start: 14, end: 10),
        decoration: BoxDecoration(
          border: Border.all(color: _ink.withValues(alpha: 0.75)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                hint,
                style: const TextStyle(color: _muted, fontSize: 12.5),
              ),
            ),
            const Icon(Icons.search, color: _ink, size: 20),
          ],
        ),
      ),
    );
  }
}

/// "Attributes": the chosen features as numbered rows. Tapping a row opens
/// the dark values sheet; picked values show as removable chips under the
/// row. "+" adds the typed feature, or with an empty box reopens the
/// Feature page. Swipe a row away to drop that feature. The check pops the
/// attributes.
class AttributesScreen extends StatefulWidget {
  const AttributesScreen({super.key, required this.initial});

  final List<ProductAttribute> initial;

  @override
  State<AttributesScreen> createState() => _AttributesScreenState();
}

class _AttributesScreenState extends State<AttributesScreen> {
  final _search = TextEditingController();
  late List<ProductAttribute> _attrs = List.of(widget.initial);
  int _active = 0;
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _addOrEditFeatures() async {
    final typed = _search.text.trim();
    if (typed.isNotEmpty) {
      _search.clear();
      setState(() {
        _query = '';
        if (!_attrs.any((a) => a.name == typed)) {
          _attrs.add(ProductAttribute(typed));
        }
        _active = _attrs.indexWhere((a) => a.name == typed);
      });
      return;
    }
    final names = await _pickFeatures(context, [
      for (final a in _attrs) a.name,
    ]);
    if (names == null || !mounted) return;
    // Keep the values already picked for features that stay.
    final byName = {for (final a in _attrs) a.name: a};
    setState(() {
      _attrs = [for (final n in names) byName[n] ?? ProductAttribute(n)];
      _active = 0;
    });
  }

  Future<void> _editValues(int index) async {
    setState(() => _active = index);
    final attr = _attrs[index];
    final values = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _ink,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => _ValuesSheet(attribute: attr),
    );
    if (values != null && mounted) {
      setState(() => _attrs[index] = attr.withValues(values));
    }
  }

  void _removeValue(int index, String value) {
    final attr = _attrs[index];
    setState(
      () => _attrs[index] = attr.withValues([
        for (final v in attr.values)
          if (v != value) v,
      ]),
    );
  }

  void _removeAttribute(ProductAttribute attr) {
    setState(() {
      _attrs.remove(attr);
      if (_active >= _attrs.length) _active = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final q = _query.trim();
    return Scaffold(
      backgroundColor: _white,
      body: SafeArea(
        child: Column(
          children: [
            PickerHeader(
              title: 'ویژگی‌ها',
              onDone: () => Navigator.of(context).pop(List.of(_attrs)),
            ),
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(6, 0, 16, 14),
              child: PickerSearchBar(
                controller: _search,
                hint: 'کلید',
                onChanged: (v) => setState(() => _query = v),
                onAdd: _addOrEditFeatures,
              ),
            ),
            Expanded(
              child: _attrs.isEmpty
                  ? const Center(
                      child: Text(
                        'هنوز ویژگی‌ای اضافه نشده است',
                        style: TextStyle(color: _muted, fontSize: 12.5),
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
                      children: [
                        for (var i = 0; i < _attrs.length; i++)
                          if (_attrs[i].name.contains(q))
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Dismissible(
                                key: ValueKey(_attrs[i].name),
                                onDismissed: (_) => _removeAttribute(_attrs[i]),
                                child: _AttributeRow(
                                  number: i + 1,
                                  attribute: _attrs[i],
                                  active: i == _active,
                                  onTap: () => _editValues(i),
                                  onRemoveValue: (v) => _removeValue(i, v),
                                ),
                              ),
                            ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Numbered feature row; its values wrap underneath as chips. The active
/// row is filled black with white chips, the others are outlined with
/// black chips.
class _AttributeRow extends StatelessWidget {
  const _AttributeRow({
    required this.number,
    required this.attribute,
    required this.active,
    required this.onTap,
    required this.onRemoveValue,
  });

  final int number;
  final ProductAttribute attribute;
  final bool active;
  final VoidCallback onTap;
  final ValueChanged<String> onRemoveValue;

  @override
  Widget build(BuildContext context) {
    final fg = active ? _white : _ink;
    return Material(
      color: active ? _ink : _white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: _ink),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(14, 0, 4, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 40,
                child: Row(
                  children: [
                    Text(
                      faDigits(number),
                      style: TextStyle(
                        color: fg,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        attribute.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: fg,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    // Mirrors under RTL, pointing to the row's far edge.
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Icon(Icons.chevron_right, color: fg, size: 20),
                    ),
                  ],
                ),
              ),
              if (attribute.values.isNotEmpty)
                Padding(
                  padding: const EdgeInsetsDirectional.only(
                    end: 10,
                    bottom: 12,
                  ),
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final v in attribute.values)
                        _ValueChip(
                          label: v,
                          inverted: active,
                          onRemove: () => onRemoveValue(v),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ValueChip extends StatelessWidget {
  const _ValueChip({
    required this.label,
    required this.inverted,
    required this.onRemove,
  });

  final String label;

  /// White chip on a black row (the active one).
  final bool inverted;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final bg = inverted ? _white : _ink;
    final fg = inverted ? _ink : _white;
    return Container(
      height: 28,
      padding: const EdgeInsetsDirectional.only(start: 12, end: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            faDigits(label),
            style: TextStyle(
              color: fg,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 2),
          InkResponse(
            onTap: onRemove,
            radius: 12,
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(Icons.close, color: fg, size: 13),
            ),
          ),
        ],
      ),
    );
  }
}

/// Dark sheet listing a feature's values (suggested ones plus anything the
/// user added). Tapping toggles a value; picked ones sit in white pills.
/// "+" adds the typed value. Done pops the picked values in list order.
class _ValuesSheet extends StatefulWidget {
  const _ValuesSheet({required this.attribute});

  final ProductAttribute attribute;

  @override
  State<_ValuesSheet> createState() => _ValuesSheetState();
}

class _ValuesSheetState extends State<_ValuesSheet> {
  final _input = TextEditingController();
  late final List<String> _options = [
    for (final v in widget.attribute.values)
      if (!suggestedValues(widget.attribute.name).contains(v)) v,
    ...suggestedValues(widget.attribute.name),
  ];
  late final Set<String> _picked = widget.attribute.values.toSet();
  String _query = '';

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  void _add() {
    final value = _input.text.trim();
    if (value.isEmpty) return;
    _input.clear();
    setState(() {
      _query = '';
      if (!_options.contains(value)) _options.insert(0, value);
      _picked.add(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.attribute.name;
    final q = _query.trim();
    final visible = _options.where((o) => o.contains(q)).toList();
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.72,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    margin: const EdgeInsets.only(top: 10, bottom: 14),
                    decoration: BoxDecoration(
                      color: _white,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  name,
                  textAlign: TextAlign.end,
                  style: const TextStyle(
                    color: _white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    IconButton(
                      onPressed: _add,
                      tooltip: 'افزودن',
                      icon: const Icon(Icons.add, color: _white, size: 26),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Container(
                        height: 40,
                        padding: const EdgeInsetsDirectional.only(
                          start: 14,
                          end: 10,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: _white),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _input,
                                onChanged: (v) => setState(() => _query = v),
                                onSubmitted: (_) => _add(),
                                cursorColor: _white,
                                style: const TextStyle(
                                  color: _white,
                                  fontSize: 13,
                                ),
                                decoration: InputDecoration(
                                  isDense: true,
                                  border: InputBorder.none,
                                  hintText: '$name جدید',
                                  hintStyle: const TextStyle(
                                    color: _muted,
                                    fontSize: 12.5,
                                  ),
                                ),
                              ),
                            ),
                            const Icon(Icons.search, color: _white, size: 20),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: visible.isEmpty
                      ? Center(
                          child: Text(
                            q.isEmpty
                                ? 'مقداری وجود ندارد؛ با «+» اضافه کنید'
                                : 'با «+» «$q» را اضافه کنید',
                            style: const TextStyle(color: _muted, fontSize: 12),
                          ),
                        )
                      : ListView.separated(
                          itemCount: visible.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 4),
                          itemBuilder: (_, i) {
                            final v = visible[i];
                            final on = _picked.contains(v);
                            return Material(
                              color: on ? _white : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(8),
                                onTap: () => setState(
                                  () => on ? _picked.remove(v) : _picked.add(v),
                                ),
                                child: SizedBox(
                                  height: 40,
                                  child: Center(
                                    child: Text(
                                      faDigits(v),
                                      style: TextStyle(
                                        color: on ? _ink : _white,
                                        fontSize: 13,
                                        fontWeight: on
                                            ? FontWeight.w700
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
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        onPressed: () => Navigator.of(context).pop([
                          for (final o in _options)
                            if (_picked.contains(o)) o,
                        ]),
                        style: FilledButton.styleFrom(
                          backgroundColor: _white,
                          foregroundColor: _ink,
                          minimumSize: const Size.fromHeight(42),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text('تأیید'),
                      ),
                    ),
                    const SizedBox(width: 60),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _white,
                          side: const BorderSide(color: _white),
                          minimumSize: const Size.fromHeight(42),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
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
      ),
    );
  }
}
