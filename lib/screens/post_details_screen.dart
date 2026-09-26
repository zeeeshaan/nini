import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app_colors.dart';
import '../data/product_info.dart';
import '../utils/fa.dart';
import '../widgets/schedule_sheet.dart';
import '../widgets/variants_editor.dart';
import 'category_screen.dart';
import 'create_post_screen.dart';
import 'information_screen.dart';
import 'post_type_screen.dart';
import 'tags_keywords_screen.dart';

/// Everything collected by [PostDetailsScreen], popped back when the user
/// taps "Next".
class PostDraft {
  const PostDraft({
    required this.media,
    required this.type,
    required this.category,
    required this.title,
    required this.caption,
    required this.altTexts,
    required this.scheduledAt,
    required this.tags,
    required this.location,
    required this.information,
    required this.variants,
  });

  final List<PickedMedia> media;
  final String? type;
  final String? category;
  final String title;

  /// Markdown produced by the caption toolbar.
  final String caption;

  /// Alt text per [PickedMedia.id].
  final Map<String, String> altTexts;
  final DateTime? scheduledAt;
  final List<String> tags;
  final String location;
  final List<ProductAttribute> information;
  final List<ProductVariant> variants;
}

/// "Create post": the picked media on top, then type, title, a formatted
/// caption, alt text, category, schedule, tags, location and extra
/// information rows.
class PostDetailsScreen extends StatefulWidget {
  const PostDetailsScreen({super.key, required this.media});

  final List<PickedMedia> media;

  @override
  State<PostDetailsScreen> createState() => _PostDetailsScreenState();
}

class _PostDetailsScreenState extends State<PostDetailsScreen> {
  final _title = TextEditingController();
  final _caption = TextEditingController();
  final _location = TextEditingController();

  String? _type;
  String? _category;
  Map<String, String> _altTexts = {};
  DateTime? _scheduledAt;
  List<String> _tags = [];
  List<ProductAttribute> _information = [];
  List<ProductVariant> _variants = [const ProductVariant()];

  final _scroll = ScrollController();

  /// Media ids being picked as downloadable files; see
  /// [VariantsEditor.downloadPicker].
  final _downloadPicker = ValueNotifier<Set<String>?>(null);

  @override
  void initState() {
    super.initState();
    _downloadPicker.addListener(_onDownloadPicking);
  }

  /// Picking starts: bring the media grid into view above the sheet.
  void _onDownloadPicking() {
    if (_downloadPicker.value == null || !_scroll.hasClients) return;
    if (_scroll.offset == 0) return;
    _scroll.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  void _toggleDownload(String id) {
    final picked = {...?_downloadPicker.value};
    if (!picked.remove(id)) picked.add(id);
    _downloadPicker.value = picked;
  }

  @override
  void dispose() {
    _title.dispose();
    _caption.dispose();
    _location.dispose();
    _scroll.dispose();
    _downloadPicker.dispose();
    super.dispose();
  }

  Future<T?> _open<T>(Widget page) =>
      Navigator.of(context).push<T>(MaterialPageRoute(builder: (_) => page));

  Future<void> _pickType() async {
    final v = await _open<String>(PostTypeScreen(initial: _type));
    if (v != null) setState(() => _type = v);
  }

  Future<void> _pickCategory() async {
    final v = await _open<List<String>>(CategoryScreen(initial: _category));
    if (v != null) setState(() => _category = v.firstOrNull);
  }

  Future<void> _editAltTexts() async {
    final result = await showModalBottomSheet<Map<String, String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.deepBlack,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _AltTextSheet(media: widget.media, initial: _altTexts),
    );
    if (result != null) setState(() => _altTexts = result);
  }

  Future<void> _pickSchedule() async {
    final at = await showScheduleSheet(context, initial: _scheduledAt);
    if (at != null) setState(() => _scheduledAt = at);
  }

  Future<void> _editTags() async {
    final v = await _open<List<String>>(TagsKeywordsScreen(initial: _tags));
    if (v != null) setState(() => _tags = v);
  }

  Future<void> _editInformation() async {
    final result = await openInformation(context, _information);
    if (result == null) return;
    setState(() {
      _information = result;
      _variants = syncVariants(_variants, result);
    });
  }

  void _next() {
    if (_title.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('عنوان پست را وارد کنید')));
      return;
    }
    final badDiscount = _variants.any(
      (v) =>
          v.price != null &&
          v.discountPrice != null &&
          v.discountPrice! >= v.price!,
    );
    if (badDiscount) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('قیمت با تخفیف باید کمتر از قیمت اصلی باشد'),
        ),
      );
      return;
    }
    Navigator.of(context).pop(
      PostDraft(
        media: widget.media,
        type: _type,
        category: _category,
        title: _title.text.trim(),
        caption: _caption.text.trim(),
        altTexts: _altTexts,
        scheduledAt: _scheduledAt,
        tags: _tags,
        location: _location.text.trim(),
        information: _information,
        variants: _variants,
      ),
    );
  }

  String get _scheduleLabel {
    final at = _scheduledAt;
    if (at == null) return 'پست‌های زمان‌بندی‌شده';
    final hh = at.hour.toString().padLeft(2, '0');
    final mm = at.minute.toString().padLeft(2, '0');
    return '${faDateLong(at)} - ساعت ${faDigits('$hh:$mm')}';
  }

  @override
  Widget build(BuildContext context) {
    final altCount = _altTexts.values.where((t) => t.trim().isNotEmpty).length;
    return Scaffold(
      backgroundColor: AppColors.pureWhite,
      body: SafeArea(
        child: Column(
          children: [
            _Header(onNext: _next),
            Expanded(
              child: ListView(
                controller: _scroll,
                padding: const EdgeInsets.only(bottom: 32),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                children: [
                  ValueListenableBuilder<Set<String>?>(
                    valueListenable: _downloadPicker,
                    builder: (_, picked, _) => _MediaGrid(
                      media: widget.media,
                      picked: picked,
                      onToggle: _toggleDownload,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 18),
                        if (_type != null) const _FieldLabel('نوع پست'),
                        _SelectRow(text: _type ?? 'نوع پست', onTap: _pickType),
                        const _FieldLabel('عنوان'),
                        _TextBox(controller: _title),
                        const _FieldLabel('کپشن'),
                        _CaptionEditor(controller: _caption),
                        const SizedBox(height: 20),
                        _SelectRow(
                          text: altCount == 0
                              ? 'متن جایگزین'
                              : 'متن جایگزین (${faDigits(altCount)})',
                          icon: Icons.adjust,
                          onTap: _editAltTexts,
                        ),
                        const Padding(
                          padding: EdgeInsets.fromLTRB(4, 6, 4, 0),
                          child: Text(
                            'به‌طور خلاصه محتوای تصویر را توضیح دهید. متن '
                            'جایگزین برای دسترس‌پذیری و رتبه‌بندی بهتر مفید است.',
                            style: TextStyle(
                              color: AppColors.midGray,
                              fontSize: 10.5,
                              height: 1.6,
                            ),
                          ),
                        ),
                        const SizedBox(height: 22),
                        _SelectRow(
                          text: _category ?? 'دسته‌بندی',
                          onTap: _pickCategory,
                        ),
                        const SizedBox(height: 10),
                        _SelectRow(
                          text: _scheduleLabel,
                          icon: Icons.calendar_month_outlined,
                          onTap: _pickSchedule,
                          onClear: _scheduledAt == null
                              ? null
                              : () => setState(() => _scheduledAt = null),
                        ),
                        const SizedBox(height: 10),
                        _SelectRow(
                          text: _tags.isEmpty
                              ? 'برچسب و کلیدواژه'
                              : _tags.map((t) => '#$t').join(' '),
                          icon: Icons.tag,
                          onTap: _editTags,
                        ),
                        const SizedBox(height: 10),
                        _LocationField(controller: _location),
                        const SizedBox(height: 10),
                        _SelectRow(
                          text: _information.isEmpty
                              ? 'اطلاعات'
                              : 'اطلاعات (${faDigits(_information.length)})',
                          icon: Icons.layers_outlined,
                          onTap: _editInformation,
                        ),
                        const _FieldLabel('قیمت و موجودی'),
                        VariantsEditor(
                          attributes: _information,
                          variants: _variants,
                          onChanged: (v) => setState(() => _variants = v),
                          downloadPicker: widget.media.isEmpty
                              ? null
                              : _downloadPicker,
                        ),
                      ],
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

class _Header extends StatelessWidget {
  const _Header({required this.onNext});

  final VoidCallback onNext;

  static const _ink = AppColors.deepBlack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(4, 8, 8, 4),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.chevron_left, color: _ink, size: 28),
          ),
          const Expanded(
            child: Text(
              'ایجاد پست',
              style: TextStyle(
                color: _ink,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          FilledButton(
            onPressed: onNext,
            style: FilledButton.styleFrom(
              backgroundColor: _ink,
              foregroundColor: AppColors.pureWhite,
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              shape: const StadiumBorder(),
            ),
            child: const Text(
              'انتشار',
              style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

/// The post's media, 3 across. While downloadable files are being picked
/// ([picked] non-null) each tile carries a selection circle and a tap
/// toggles it.
class _MediaGrid extends StatelessWidget {
  const _MediaGrid({
    required this.media,
    required this.picked,
    required this.onToggle,
  });

  final List<PickedMedia> media;
  final Set<String>? picked;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    final picked = this.picked;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 1,
        crossAxisSpacing: 1,
      ),
      itemCount: media.length,
      itemBuilder: (_, i) {
        final item = media[i];
        final tile = ColoredBox(
          color: AppColors.surfaceOnLight,
          child: PickedMediaView(item: item, size: 360, fit: BoxFit.cover),
        );
        if (picked == null) return tile;
        final on = picked.contains(item.id);
        return GestureDetector(
          onTap: () => onToggle(item.id),
          child: Stack(
            fit: StackFit.expand,
            children: [
              tile,
              PositionedDirectional(top: 6, end: 6, child: _PickCircle(on: on)),
            ],
          ),
        );
      },
    );
  }
}

/// Black selection circle; a white check when picked.
class _PickCircle extends StatelessWidget {
  const _PickCircle({required this.on});

  final bool on;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: AppColors.deepBlack,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.pureWhite, width: 1.5),
      ),
      child: on
          ? const Icon(Icons.check, color: AppColors.pureWhite, size: 12)
          : null,
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 14, 2, 6),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.deepBlack,
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

BoxDecoration _boxDecoration() => BoxDecoration(
  color: AppColors.pureWhite,
  border: Border.all(color: AppColors.deepBlack.withValues(alpha: 0.75)),
  borderRadius: BorderRadius.circular(6),
);

/// Bordered tappable row: optional leading icon, label and a chevron (or a
/// clear button once it has a value that can be removed).
class _SelectRow extends StatelessWidget {
  const _SelectRow({
    required this.text,
    required this.onTap,
    this.icon,
    this.onClear,
  });

  final String text;
  final VoidCallback onTap;
  final IconData? icon;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    const color = AppColors.deepBlack;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Ink(
          height: 40,
          decoration: _boxDecoration(),
          padding: const EdgeInsetsDirectional.only(start: 10, end: 4),
          child: Row(
            children: [
              if (icon != null) ...[
                Icon(icon, color: color, size: 19),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: color, fontSize: 13),
                ),
              ),
              if (onClear != null)
                IconButton(
                  onPressed: onClear,
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(
                    Icons.close,
                    color: AppColors.deepBlack,
                    size: 18,
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.all(6),
                  child: Icon(Icons.chevron_left, color: color, size: 20),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

InputDecoration _bareInput(String? hint) => InputDecoration(
  isDense: true,
  border: InputBorder.none,
  hintText: hint,
  hintStyle: const TextStyle(color: AppColors.midGray, fontSize: 12.5),
);

class _TextBox extends StatelessWidget {
  const _TextBox({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: _boxDecoration(),
      child: TextField(
        controller: controller,
        textInputAction: TextInputAction.next,
        style: const TextStyle(color: AppColors.deepBlack, fontSize: 13.5),
        cursorColor: AppColors.deepBlack,
        decoration: _bareInput(null),
      ),
    );
  }
}

class _LocationField extends StatelessWidget {
  const _LocationField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsetsDirectional.only(start: 10, end: 10),
      decoration: _boxDecoration(),
      child: Row(
        children: [
          const Icon(
            Icons.add_location_alt_outlined,
            color: AppColors.deepBlack,
            size: 19,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              style: const TextStyle(color: AppColors.deepBlack, fontSize: 13),
              cursorColor: AppColors.deepBlack,
              decoration: _bareInput('خیابان، شهر، کد پستی، کشور'),
            ),
          ),
          const Icon(Icons.chevron_left, color: AppColors.deepBlack, size: 20),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Caption editor: a markdown toolbar over a plain multi-line field, with a
// drag handle in the bottom corner to resize it.
// ---------------------------------------------------------------------------

enum _Heading { normal, h1, h2, h3 }

class _CaptionEditor extends StatefulWidget {
  const _CaptionEditor({required this.controller});

  final TextEditingController controller;

  @override
  State<_CaptionEditor> createState() => _CaptionEditorState();
}

class _CaptionEditorState extends State<_CaptionEditor> {
  static final _linePrefix = RegExp(
    r'^(#{1,3} |- \[ \] |- |\d+\. |[a-z]\. |> )',
  );

  static const _headingLabels = {
    _Heading.normal: 'متن عادی',
    _Heading.h1: 'تیتر ۱',
    _Heading.h2: 'تیتر ۲',
    _Heading.h3: 'تیتر ۳',
  };

  double _height = 150;

  TextEditingController get _c => widget.controller;

  @override
  void initState() {
    super.initState();
    _c.addListener(_onChanged);
  }

  @override
  void dispose() {
    _c.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() => setState(() {});

  TextSelection get _selection {
    final sel = _c.selection;
    return sel.isValid ? sel : TextSelection.collapsed(offset: _c.text.length);
  }

  (int, int) _lineBounds(int offset) {
    final text = _c.text;
    final start = offset <= 0 ? 0 : text.lastIndexOf('\n', offset - 1) + 1;
    final end = text.indexOf('\n', offset);
    return (start, end == -1 ? text.length : end);
  }

  String get _currentLine {
    final (start, end) = _lineBounds(_selection.start);
    return _c.text.substring(start, end);
  }

  _Heading get _currentHeading {
    final line = _currentLine;
    if (line.startsWith('### ')) return _Heading.h3;
    if (line.startsWith('## ')) return _Heading.h2;
    if (line.startsWith('# ')) return _Heading.h1;
    return _Heading.normal;
  }

  /// Replaces the current line's block prefix (heading, list, quote) with
  /// [prefix], or removes it when the line already has that exact prefix.
  void _toggleLinePrefix(String prefix) {
    final sel = _selection;
    final (start, end) = _lineBounds(sel.start);
    final line = _c.text.substring(start, end);
    final old = _linePrefix.firstMatch(line)?.group(0) ?? '';
    final next = old == prefix ? '' : prefix;
    final delta = next.length - old.length;
    _c.value = TextEditingValue(
      text: _c.text.replaceRange(start, end, next + line.substring(old.length)),
      selection: TextSelection(
        baseOffset: math.max(start, sel.baseOffset + delta),
        extentOffset: math.max(start, sel.extentOffset + delta),
      ),
    );
  }

  /// Wraps the selection in inline markers, or inserts an empty pair with
  /// the cursor between them.
  void _wrap(String left, [String? right]) {
    right ??= left;
    final sel = _selection;
    final inner = sel.textInside(_c.text);
    _c.value = TextEditingValue(
      text: _c.text.replaceRange(sel.start, sel.end, '$left$inner$right'),
      selection: TextSelection(
        baseOffset: sel.start + left.length,
        extentOffset: sel.start + left.length + inner.length,
      ),
    );
  }

  void _setHeading(_Heading h) {
    final current = _currentHeading;
    if (h == current) return;
    // Re-applying the current prefix removes it; any other one replaces it.
    final level = h == _Heading.normal ? current.index : h.index;
    _toggleLinePrefix('${'#' * level} ');
  }

  Future<void> _insertLink() async {
    final sel = _selection;
    final url = await showDialog<String>(
      context: context,
      builder: (_) => const _LinkDialog(),
    );
    if (url == null || url.isEmpty) return;
    final label = sel.textInside(_c.text);
    final md = '[${label.isEmpty ? url : label}]($url)';
    _c.value = TextEditingValue(
      text: _c.text.replaceRange(sel.start, sel.end, md),
      selection: TextSelection.collapsed(offset: sel.start + md.length),
    );
  }

  void _clearFormatting() {
    final sel = _selection;
    final (start, end) = sel.isCollapsed
        ? _lineBounds(sel.start)
        : (sel.start, sel.end);
    var chunk = _c.text.substring(start, end);
    if (sel.isCollapsed) chunk = chunk.replaceFirst(_linePrefix, '');
    chunk = chunk.replaceAll(RegExp(r'\*\*|~~|`|_'), '');
    _c.value = TextEditingValue(
      text: _c.text.replaceRange(start, end, chunk),
      selection: TextSelection.collapsed(offset: start + chunk.length),
    );
  }

  void _onMore(String action) {
    switch (action) {
      case 'strike':
        _wrap('~~');
      case 'quote':
        _toggleLinePrefix('> ');
      case 'code':
        _wrap('`');
      case 'clear':
        _clearFormatting();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: _height,
      decoration: _boxDecoration(),
      child: Stack(
        children: [
          Column(
            children: [
              _toolbar(),
              Expanded(
                child: TextField(
                  controller: _c,
                  maxLines: null,
                  expands: true,
                  keyboardType: TextInputType.multiline,
                  textAlignVertical: TextAlignVertical.top,
                  cursorColor: AppColors.deepBlack,
                  style: const TextStyle(
                    color: AppColors.deepBlack,
                    fontSize: 13.5,
                    height: 1.6,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.fromLTRB(10, 8, 10, 18),
                  ),
                ),
              ),
            ],
          ),
          PositionedDirectional(
            end: 0,
            bottom: 0,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onVerticalDragUpdate: (d) => setState(
                () => _height = (_height + d.delta.dy).clamp(110, 460),
              ),
              child: const SizedBox(
                width: 26,
                height: 26,
                child: CustomPaint(painter: _ResizeHandlePainter()),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _toolbar() {
    const ink = AppColors.deepBlack;
    Widget button(IconData icon, VoidCallback onTap, {String? tooltip}) =>
        IconButton(
          onPressed: onTap,
          tooltip: tooltip,
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 30, minHeight: 34),
          icon: Icon(icon, color: ink, size: 18),
        );

    return SizedBox(
      height: 36,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Row(
          children: [
            PopupMenuButton<_Heading>(
              tooltip: 'سبک متن',
              onSelected: _setHeading,
              color: AppColors.pureWhite,
              itemBuilder: (_) => [
                for (final e in _headingLabels.entries)
                  CheckedPopupMenuItem(
                    value: e.key,
                    checked: e.key == _currentHeading,
                    child: Text(e.value),
                  ),
              ],
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Row(
                  children: [
                    Text(
                      _headingLabels[_currentHeading]!,
                      style: const TextStyle(color: ink, fontSize: 12),
                    ),
                    const SizedBox(width: 18),
                    const Icon(Icons.keyboard_arrow_down, color: ink, size: 18),
                  ],
                ),
              ),
            ),
            const _ToolbarDivider(),
            button(Icons.format_bold, () => _wrap('**'), tooltip: 'پررنگ'),
            button(Icons.format_italic, () => _wrap('_'), tooltip: 'مورب'),
            button(Icons.link, _insertLink, tooltip: 'پیوند'),
            _ListMenu(
              icon: Icons.format_list_bulleted,
              options: const {'- ': 'فهرست نقطه‌ای', '- [ ] ': 'فهرست تیک‌دار'},
              onSelected: _toggleLinePrefix,
            ),
            _ListMenu(
              icon: Icons.format_list_numbered,
              options: const {'1. ': 'فهرست عددی', 'a. ': 'فهرست حروفی'},
              onSelected: _toggleLinePrefix,
            ),
            const _ToolbarDivider(),
            PopupMenuButton<String>(
              tooltip: 'بیشتر',
              onSelected: _onMore,
              color: AppColors.pureWhite,
              icon: const Icon(Icons.more_vert, color: ink, size: 18),
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'strike', child: Text('خط‌خورده')),
                PopupMenuItem(value: 'quote', child: Text('نقل‌قول')),
                PopupMenuItem(value: 'code', child: Text('کد')),
                PopupMenuItem(value: 'clear', child: Text('پاک کردن قالب')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ListMenu extends StatelessWidget {
  const _ListMenu({
    required this.icon,
    required this.options,
    required this.onSelected,
  });

  final IconData icon;
  final Map<String, String> options;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: onSelected,
      color: AppColors.pureWhite,
      itemBuilder: (_) => [
        for (final e in options.entries)
          PopupMenuItem(value: e.key, child: Text(e.value)),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Row(
          children: [
            Icon(icon, color: AppColors.deepBlack, size: 18),
            const Icon(
              Icons.keyboard_arrow_down,
              color: AppColors.deepBlack,
              size: 14,
            ),
          ],
        ),
      ),
    );
  }
}

class _ToolbarDivider extends StatelessWidget {
  const _ToolbarDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 16,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: AppColors.divider,
    );
  }
}

/// Two diagonal strokes in the bottom corner, like a textarea grip.
class _ResizeHandlePainter extends CustomPainter {
  const _ResizeHandlePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.deepBlack
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    // Mirrors for RTL: the grip sits in the bottom-left corner.
    canvas.drawLine(
      Offset(6, size.height - 14),
      Offset(14, size.height - 6),
      paint,
    );
    canvas.drawLine(
      Offset(6, size.height - 9),
      Offset(9, size.height - 6),
      paint,
    );
  }

  @override
  bool shouldRepaint(_ResizeHandlePainter oldDelegate) => false;
}

class _LinkDialog extends StatefulWidget {
  const _LinkDialog();

  @override
  State<_LinkDialog> createState() => _LinkDialogState();
}

class _LinkDialogState extends State<_LinkDialog> {
  final _url = TextEditingController();

  @override
  void dispose() {
    _url.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.pureWhite,
      title: const Text('افزودن پیوند', style: TextStyle(fontSize: 16)),
      content: TextField(
        controller: _url,
        autofocus: true,
        keyboardType: TextInputType.url,
        textDirection: TextDirection.ltr,
        cursorColor: AppColors.deepBlack,
        decoration: const InputDecoration(hintText: 'https://'),
        onSubmitted: (v) => Navigator.of(context).pop(v.trim()),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(foregroundColor: AppColors.midGray),
          child: const Text('انصراف'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(_url.text.trim()),
          style: TextButton.styleFrom(foregroundColor: AppColors.deepBlack),
          child: const Text('افزودن'),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Bottom sheets
// ---------------------------------------------------------------------------

class _SheetHandle extends StatelessWidget {
  const _SheetHandle({this.color = AppColors.divider});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        margin: const EdgeInsets.only(top: 10, bottom: 14),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

/// Dark sheet with one "write..." field per picked item, next to its
/// thumbnail, and Cancel / Done at the bottom.
class _AltTextSheet extends StatefulWidget {
  const _AltTextSheet({required this.media, required this.initial});

  final List<PickedMedia> media;
  final Map<String, String> initial;

  @override
  State<_AltTextSheet> createState() => _AltTextSheetState();
}

class _AltTextSheetState extends State<_AltTextSheet> {
  late final Map<String, TextEditingController> _fields = {
    for (final m in widget.media)
      m.id: TextEditingController(text: widget.initial[m.id] ?? ''),
  };

  @override
  void dispose() {
    for (final c in _fields.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _done() {
    Navigator.of(context).pop({
      for (final e in _fields.entries)
        if (e.value.text.trim().isNotEmpty) e.key: e.value.text.trim(),
    });
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height * 0.82;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SizedBox(
        height: height,
        child: SafeArea(
          top: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _SheetHandle(color: AppColors.midGray),
              const Padding(
                padding: EdgeInsets.fromLTRB(18, 4, 18, 18),
                child: Row(
                  children: [
                    Icon(Icons.adjust, color: AppColors.pureWhite, size: 18),
                    SizedBox(width: 6),
                    Text(
                      'متن جایگزین',
                      style: TextStyle(
                        color: AppColors.pureWhite,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  itemCount: widget.media.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 6),
                  itemBuilder: (_, i) {
                    final item = widget.media[i];
                    return SizedBox(
                      height: 76,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(
                            width: 66,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(2),
                              child: ColoredBox(
                                color: AppColors.surfaceOnLight,
                                child: PickedMediaView(
                                  item: item,
                                  size: 200,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: _DarkField(controller: _fields[item.id]!),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 12, 10, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        onPressed: _done,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.pureWhite,
                          foregroundColor: AppColors.deepBlack,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
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
                          foregroundColor: AppColors.pureWhite,
                          side: const BorderSide(color: AppColors.pureWhite),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('انصراف'),
                      ),
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

class _DarkField extends StatelessWidget {
  const _DarkField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: null,
      expands: true,
      textAlignVertical: TextAlignVertical.top,
      cursorColor: AppColors.pureWhite,
      style: const TextStyle(color: AppColors.pureWhite, fontSize: 12.5),
      decoration: InputDecoration(
        hintText: 'بنویسید...',
        hintStyle: const TextStyle(color: AppColors.midGray, fontSize: 11),
        contentPadding: const EdgeInsets.all(8),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: AppColors.dividerOnDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: AppColors.midGray),
        ),
      ),
    );
  }
}
