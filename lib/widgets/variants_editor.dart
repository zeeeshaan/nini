import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_colors.dart';
import '../data/product_info.dart';
import '../utils/fa.dart';
import 'schedule_sheet.dart';

const _ink = AppColors.deepBlack;
const _muted = AppColors.midGray;
const _white = AppColors.pureWhite;

/// Keeps [variants] consistent with [attributes]: drops keys for removed
/// features and resets values that are no longer offered to "any". There
/// is always at least one variant, so a product without features still has
/// a price and stock.
List<ProductVariant> syncVariants(
  List<ProductVariant> variants,
  List<ProductAttribute> attributes,
) {
  final synced = [
    for (final v in variants)
      v.copyWith(
        values: {
          for (final a in attributes)
            a.name: a.values.contains(v.values[a.name])
                ? v.values[a.name]
                : null,
        },
      ),
  ];
  if (attributes.isEmpty) return [synced.firstOrNull ?? const ProductVariant()];
  return synced.isEmpty
      ? [
          ProductVariant(values: {for (final a in attributes) a.name: null}),
        ]
      : synced;
}

/// One row per variant: a chip per attribute ("any «attribute»" until a
/// value is picked from its sheet). The last row carries "+" to add another
/// variant. The open row shows that variant's price and inventory form.
class VariantsEditor extends StatefulWidget {
  const VariantsEditor({
    super.key,
    required this.attributes,
    required this.variants,
    required this.onChanged,
    this.downloadPicker,
  });

  final List<ProductAttribute> attributes;
  final List<ProductVariant> variants;
  final ValueChanged<List<ProductVariant>> onChanged;

  /// Shared with the post's media grid. While the downloadable-files sheet
  /// is open it holds the picked media ids and the grid shows selection
  /// circles; null otherwise. Without it, files can't be picked.
  final ValueNotifier<Set<String>?>? downloadPicker;

  @override
  State<VariantsEditor> createState() => _VariantsEditorState();
}

class _VariantsEditorState extends State<VariantsEditor> {
  int _open = 0;

  List<ProductVariant> get _variants => widget.variants;

  void _replace(int row, ProductVariant v) {
    widget.onChanged([
      for (var i = 0; i < _variants.length; i++) i == row ? v : _variants[i],
    ]);
  }

  void _set(int row, String attribute, String? value) => _replace(
    row,
    _variants[row].copyWith(
      values: {..._variants[row].values, attribute: value},
    ),
  );

  void _add() {
    widget.onChanged([
      ..._variants,
      // A new combination starts from the last one's price and stock.
      _variants.last.copyWith(
        values: {for (final a in widget.attributes) a.name: null},
        sku: '',
      ),
    ]);
    setState(() => _open = _variants.length);
  }

  void _rowAction(int row, _RowAction action) {
    final list = List.of(_variants);
    switch (action) {
      case _RowAction.duplicate:
        list.insert(row + 1, _variants[row].copyWith(sku: ''));
      case _RowAction.remove:
        list.removeAt(row);
    }
    setState(() {
      if (action == _RowAction.remove && _open >= row && _open > 0) _open--;
    });
    widget.onChanged(syncVariants(list, widget.attributes));
  }

  @override
  Widget build(BuildContext context) {
    final hasChips = widget.attributes.isNotEmpty;
    final open = _open.clamp(0, _variants.length - 1);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < _variants.length; i++) ...[
          if (hasChips)
            DecoratedBox(
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.divider)),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            for (final a in widget.attributes)
                              Padding(
                                padding: const EdgeInsetsDirectional.only(
                                  end: 6,
                                ),
                                child: _AttributeChip(
                                  attribute: a,
                                  value: _variants[i].values[a.name],
                                  onPicked: (v) => _set(i, a.name, v),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => setState(() => _open = i),
                      tooltip: 'قیمت و موجودی',
                      visualDensity: VisualDensity.compact,
                      icon: Icon(
                        i == open
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        color: _ink,
                        size: 22,
                      ),
                    ),
                    if (_variants.length > 1)
                      PopupMenuButton<_RowAction>(
                        tooltip: 'گزینه‌ها',
                        color: _white,
                        icon: const Icon(
                          Icons.more_vert,
                          color: _ink,
                          size: 20,
                        ),
                        onSelected: (action) => _rowAction(i, action),
                        itemBuilder: (_) => const [
                          PopupMenuItem(
                            value: _RowAction.duplicate,
                            child: Text('تکثیر'),
                          ),
                          PopupMenuItem(
                            value: _RowAction.remove,
                            child: Text('حذف'),
                          ),
                        ],
                      ),
                    if (i == _variants.length - 1)
                      IconButton(
                        onPressed: _add,
                        tooltip: 'افزودن ترکیب',
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.add, color: _ink, size: 22),
                      ),
                  ],
                ),
              ),
            ),
          if (i == open)
            VariantOfferForm(
              key: ValueKey(i),
              variant: _variants[i],
              onChanged: (v) => _replace(i, v),
              downloadPicker: widget.downloadPicker,
            ),
        ],
      ],
    );
  }
}

enum _RowAction { duplicate, remove }

/// Outlined pill: the picked value, or "any «attribute»" in gray. Tapping
/// opens the dark "Select attribute value" sheet.
class _AttributeChip extends StatelessWidget {
  const _AttributeChip({
    required this.attribute,
    required this.value,
    required this.onPicked,
  });

  final ProductAttribute attribute;
  final String? value;
  final ValueChanged<String?> onPicked;

  Future<void> _pick(BuildContext context) async {
    // A one-field record, so picking "any" (null) differs from cancelling.
    final picked = await _showDarkSheet<(String?,)>(
      context,
      _ValuePickSheet(attribute: attribute, initial: value),
      tall: true,
    );
    if (picked != null) onPicked(picked.$1);
  }

  @override
  Widget build(BuildContext context) {
    final value = this.value;
    return Semantics(
      button: true,
      label: attribute.name,
      child: InkWell(
        onTap: () => _pick(context),
        borderRadius: BorderRadius.circular(15),
        child: Container(
          height: 30,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: value == null ? null : _ink,
            border: Border.all(color: value == null ? _muted : _ink),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Text(
            value == null ? 'هر ${attribute.name}' : faDigits(value),
            style: TextStyle(
              color: value == null ? _muted : _white,
              fontSize: 12,
              fontWeight: value == null ? FontWeight.w400 : FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Price and inventory form for one variant.
// ---------------------------------------------------------------------------

BoxDecoration _box() => BoxDecoration(
  color: _white,
  border: Border.all(color: _ink.withValues(alpha: 0.75)),
  borderRadius: BorderRadius.circular(6),
);

/// Price, limited-time discount, pre-order, SKU, inventory status, stock,
/// low-stock threshold, downloadable files and unit.
class VariantOfferForm extends StatefulWidget {
  const VariantOfferForm({
    super.key,
    required this.variant,
    required this.onChanged,
    this.downloadPicker,
  });

  final ProductVariant variant;
  final ValueChanged<ProductVariant> onChanged;

  /// See [VariantsEditor.downloadPicker].
  final ValueNotifier<Set<String>?>? downloadPicker;

  @override
  State<VariantOfferForm> createState() => _VariantOfferFormState();
}

class _VariantOfferFormState extends State<VariantOfferForm> {
  late final _price = TextEditingController(
    text: _amount(widget.variant.price),
  );
  late final _discount = TextEditingController(
    text: _amount(widget.variant.discountPrice),
  );
  late final _sku = TextEditingController(text: widget.variant.sku);

  ProductVariant get _v => widget.variant;

  static String _amount(int? v) => v == null ? '' : faAmount(v);

  @override
  void didUpdateWidget(VariantOfferForm old) {
    super.didUpdateWidget(old);
    // Rows can shift after a remove; keep the fields showing this variant.
    if (parseAmount(_price.text) != _v.price) _price.text = _amount(_v.price);
    if (parseAmount(_discount.text) != _v.discountPrice) {
      _discount.text = _amount(_v.discountPrice);
    }
    if (_sku.text != _v.sku) _sku.text = _v.sku;
  }

  @override
  void dispose() {
    _price.dispose();
    _discount.dispose();
    _sku.dispose();
    super.dispose();
  }

  Future<void> _pickDiscountEnd() async {
    final at = await showScheduleSheet(
      context,
      initial: _v.discountEndsAt,
      title: 'تخفیف زمان‌دار',
    );
    if (at != null) widget.onChanged(_v.copyWith(discountEndsAt: () => at));
  }

  Future<void> _editDownloads() async {
    final picker = widget.downloadPicker;
    if (picker == null) {
      final result = await _showDarkSheet<(int, int)>(
        context,
        _DownloadsSheet(
          limit: _v.downloadLimit,
          days: _v.downloadExpiryDays,
          onDone: (limit, days) => Navigator.of(context).pop((limit, days)),
        ),
      );
      if (result == null) return;
      widget.onChanged(
        _v.copyWith(downloadLimit: result.$1, downloadExpiryDays: result.$2),
      );
      return;
    }

    // A non-modal sheet, so the media grid above stays tappable: files are
    // picked straight from the post's own media.
    picker.value = {..._v.downloadFiles};
    (int, int)? result;
    final sheet = Scaffold.of(context).showBottomSheet(
      (sheetContext) => SafeArea(
        top: false,
        child: _DownloadsSheet(
          limit: _v.downloadLimit,
          days: _v.downloadExpiryDays,
          selection: picker,
          onDone: (limit, days) {
            result = (limit, days);
            Navigator.of(sheetContext).pop();
          },
        ),
      ),
      backgroundColor: _ink,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
    );
    await sheet.closed;
    final files = picker.value;
    picker.value = null;
    final picked = result;
    if (picked == null || !mounted) return;
    widget.onChanged(
      _v.copyWith(
        downloadLimit: picked.$1,
        downloadExpiryDays: picked.$2,
        downloadFiles: files?.toList() ?? const [],
      ),
    );
  }

  Future<void> _pickUnit() async {
    final unit = await _showDarkSheet<String>(
      context,
      _UnitSheet(initial: _v.unit),
      tall: true,
    );
    if (unit != null) widget.onChanged(_v.copyWith(unit: () => unit));
  }

  String? get _discountError {
    final price = _v.price, discount = _v.discountPrice;
    if (price == null || discount == null || discount < price) return null;
    return 'قیمت با تخفیف باید کمتر از قیمت اصلی باشد';
  }

  /// "٪۵": how much the discount takes off the price, or a bare "٪".
  String get _discountPercent {
    final price = _v.price, discount = _v.discountPrice;
    if (price == null || price == 0 || discount == null || discount >= price) {
      return '٪';
    }
    return '٪${faDigits(((price - discount) * 100 / price).round())}';
  }

  String get _discountHint {
    final at = _v.discountEndsAt;
    if (at == null) {
      return 'قیمت پس از تخفیف. برای تخفیف زمان‌دار، تاریخ پایان را از '
          'تقویم انتخاب کنید.';
    }
    final hh = at.hour.toString().padLeft(2, '0');
    final mm = at.minute.toString().padLeft(2, '0');
    return 'تخفیف تا ${faDateLong(at)} ساعت ${faDigits('$hh:$mm')}';
  }

  @override
  Widget build(BuildContext context) {
    final discountError = _discountError;
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _Label('قیمت'),
          Row(
            children: [
              Expanded(
                child: _AmountField(
                  controller: _price,
                  onChanged: (v) =>
                      widget.onChanged(_v.copyWith(price: () => v)),
                ),
              ),
              const SizedBox(width: 6),
              const _SideBox(child: Text('تومان', style: _sideText)),
            ],
          ),
          const _Hint('قیمت فروش این ترکیب به تومان.'),
          const _Label('قیمت با تخفیف'),
          Row(
            children: [
              Expanded(
                child: _AmountField(
                  controller: _discount,
                  onChanged: (v) =>
                      widget.onChanged(_v.copyWith(discountPrice: () => v)),
                ),
              ),
              const SizedBox(width: 6),
              _SideBox(child: Text(_discountPercent, style: _sideText)),
              const SizedBox(width: 6),
              _SideBox(
                onTap: _pickDiscountEnd,
                filled: _v.discountEndsAt != null,
                child: Icon(
                  Icons.calendar_month_outlined,
                  size: 18,
                  color: _v.discountEndsAt != null ? _white : _ink,
                ),
              ),
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: discountError != null
                    ? _Hint(discountError, error: true)
                    : _Hint(_discountHint),
              ),
              if (_v.discountEndsAt != null)
                InkWell(
                  onTap: () =>
                      widget.onChanged(_v.copyWith(discountEndsAt: () => null)),
                  child: const Padding(
                    padding: EdgeInsets.fromLTRB(4, 6, 4, 0),
                    child: Icon(Icons.close, size: 15, color: _muted),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          _ToggleRow(
            text: 'پیش‌فروش',
            value: _v.preOrder,
            onChanged: (v) => widget.onChanged(_v.copyWith(preOrder: v)),
          ),
          const _Hint(
            'با فعال‌سازی، خریدار پیش از موجود شدن کالا سفارش می‌دهد.',
          ),
          const SizedBox(height: 12),
          Container(
            height: 40,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: _box(),
            child: TextField(
              controller: _sku,
              textDirection: TextDirection.ltr,
              style: const TextStyle(color: _ink, fontSize: 13),
              cursorColor: _ink,
              onChanged: (v) => widget.onChanged(_v.copyWith(sku: v.trim())),
              decoration: const InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: 'شناسه محصول (SKU)',
                hintTextDirection: TextDirection.rtl,
                hintStyle: TextStyle(color: _muted, fontSize: 12.5),
              ),
            ),
          ),
          const _Hint('کدی یکتا برای پیگیری این کالا در انبار و سفارش‌ها.'),
          const SizedBox(height: 12),
          PopupMenuButton<InventoryStatus>(
            color: _white,
            position: PopupMenuPosition.under,
            onSelected: (s) => widget.onChanged(_v.copyWith(status: s)),
            itemBuilder: (_) => [
              for (final s in InventoryStatus.values)
                CheckedPopupMenuItem(
                  value: s,
                  checked: s == _v.status,
                  child: Text(s.label),
                ),
            ],
            child: _RowBox(text: 'وضعیت موجودی: ${_v.status.label}'),
          ),
          const _Hint('وضعیتی که خریدار روی صفحه محصول می‌بیند.'),
          const _Label('موجودی انبار'),
          _Stepper(
            value: _v.stock,
            min: 0,
            onChanged: (n) => widget.onChanged(_v.copyWith(stock: n)),
          ),
          const _Hint('تعداد این کالا که اکنون در انبار دارید.'),
          const _Label('آستانه موجودی'),
          _Stepper(
            value: _v.threshold,
            min: 0,
            onChanged: (n) => widget.onChanged(_v.copyWith(threshold: n)),
          ),
          const _Hint(
            'وقتی موجودی به این عدد برسد، به شما هشدار «رو به اتمام» داده '
            'می‌شود.',
          ),
          const SizedBox(height: 12),
          _RowBox(
            text: [
              'فایل‌های قابل دانلود',
              if (_v.downloadFiles.isNotEmpty)
                '${faDigits(_v.downloadFiles.length)} فایل',
              '${faDigits(_v.downloadLimit)} بار، '
                  '${faDigits(_v.downloadExpiryDays)} روز',
            ].join(' · '),
            onTap: _editDownloads,
          ),
          _Hint(
            widget.downloadPicker == null
                ? 'برای محصول دیجیتال، تعداد دفعات و مهلت دانلود را تعیین کنید.'
                : 'فایل‌های قابل دانلود را از رسانه‌های همین پست انتخاب کنید؛ '
                      'خریدار پس از خرید می‌تواند آن‌ها را دانلود کند.',
          ),
          const SizedBox(height: 12),
          _RowBox(
            text: _v.unit == null ? 'واحد' : 'واحد: ${_v.unit}',
            onTap: _pickUnit,
          ),
          const _Hint('قیمت برای هر یک واحد از این مقدار محاسبه می‌شود.'),
        ],
      ),
    );
  }
}

const _sideText = TextStyle(color: _ink, fontSize: 12);

/// Accepts Persian, Arabic or Latin digits and returns the number, or null
/// when [text] has no digits.
int? parseAmount(String text) {
  final digits = text
      .replaceAllMapped(RegExp('[۰-۹٠-٩]'), (m) {
        final c = m[0]!.codeUnitAt(0);
        return '${c >= 0x06F0 ? c - 0x06F0 : c - 0x0660}';
      })
      .replaceAll(RegExp('[^0-9]'), '');
  return digits.isEmpty ? null : int.tryParse(digits);
}

/// Re-renders whatever is typed as a grouped Persian amount (۶۲۵٬۰۰۰).
class _AmountFormatter extends TextInputFormatter {
  const _AmountFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final n = parseAmount(newValue.text);
    final text = n == null ? '' : faAmount(n);
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

class _AmountField extends StatelessWidget {
  const _AmountField({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: _box(),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        inputFormatters: [
          LengthLimitingTextInputFormatter(15),
          const _AmountFormatter(),
        ],
        textAlign: TextAlign.end,
        style: const TextStyle(
          color: _ink,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        cursorColor: _ink,
        onChanged: (v) => onChanged(parseAmount(v)),
        decoration: const InputDecoration(
          isDense: true,
          border: InputBorder.none,
          hintText: '۰',
          hintStyle: TextStyle(color: _muted, fontSize: 13),
        ),
      ),
    );
  }
}

/// Small square box beside a field: a unit label or an action icon.
class _SideBox extends StatelessWidget {
  const _SideBox({required this.child, this.onTap, this.filled = false});

  final Widget child;
  final VoidCallback? onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Ink(
          width: 52,
          height: 40,
          decoration: filled
              ? BoxDecoration(
                  color: _ink,
                  borderRadius: BorderRadius.circular(6),
                )
              : _box(),
          child: Center(child: child),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 14, 2, 6),
      child: Text(
        text,
        style: const TextStyle(
          color: _ink,
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint(this.text, {this.error = false});

  final String text;
  final bool error;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 5, 4, 0),
      child: Text(
        text,
        style: TextStyle(
          color: error ? const Color(0xFFEF4444) : _muted,
          fontSize: 10.5,
          height: 1.5,
        ),
      ),
    );
  }
}

/// Bordered row with a label and a chevron.
class _RowBox extends StatelessWidget {
  const _RowBox({required this.text, this.onTap});

  final String text;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final row = Container(
      height: 40,
      padding: const EdgeInsetsDirectional.only(start: 10, end: 6),
      decoration: _box(),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: _ink, fontSize: 13),
            ),
          ),
          const Icon(Icons.chevron_left, color: _ink, size: 20),
        ],
      ),
    );
    if (onTap == null) return row;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: row,
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.text,
    required this.value,
    required this.onChanged,
  });

  final String text;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        height: 40,
        padding: const EdgeInsetsDirectional.only(start: 10, end: 2),
        decoration: _box(),
        child: Row(
          children: [
            Expanded(
              child: Text(
                text,
                style: const TextStyle(color: _ink, fontSize: 13),
              ),
            ),
            Transform.scale(
              scale: 0.75,
              child: Switch(
                value: value,
                onChanged: onChanged,
                activeThumbColor: _white,
                activeTrackColor: _ink,
                inactiveThumbColor: _muted,
                inactiveTrackColor: AppColors.surfaceOnLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// [-] [ n ] [+], light or on a dark sheet.
class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.value,
    required this.onChanged,
    this.min = 0,
    this.dark = false,
  });

  final int value;
  final ValueChanged<int> onChanged;
  final int min;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final fg = dark ? _white : _ink;
    final border = BoxDecoration(
      border: Border.all(color: dark ? AppColors.midGray : fg),
      borderRadius: BorderRadius.circular(6),
    );
    Widget button(IconData icon, VoidCallback? onTap) => InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: 40,
        height: 40,
        decoration: border,
        child: Icon(
          icon,
          size: 18,
          color: onTap == null ? AppColors.midGray : fg,
        ),
      ),
    );
    return Row(
      children: [
        // RTL: "+" sits on the right, as in the design.
        button(Icons.add, () => onChanged(value + 1)),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            height: 40,
            alignment: Alignment.center,
            decoration: border,
            child: Text(
              faDigits(value),
              style: TextStyle(
                color: fg,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        button(Icons.remove, value > min ? () => onChanged(value - 1) : null),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Dark bottom sheets: downloadable files and unit.
// ---------------------------------------------------------------------------

Future<T?> _showDarkSheet<T>(
  BuildContext context,
  Widget child, {
  bool tall = false,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: _ink,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (context) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SizedBox(
        height: tall ? MediaQuery.sizeOf(context).height * 0.85 : null,
        child: SafeArea(top: false, child: child),
      ),
    ),
  );
}

class _SheetFrame extends StatelessWidget {
  const _SheetFrame({
    required this.children,
    required this.onDone,
    this.expand = false,
  });

  final List<Widget> children;
  final VoidCallback onDone;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
      child: Column(
        mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 44,
              height: 4,
              margin: const EdgeInsets.only(top: 10, bottom: 18),
              decoration: BoxDecoration(
                color: _white,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          ...children,
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: onDone,
                  style: FilledButton.styleFrom(
                    backgroundColor: _white,
                    foregroundColor: _ink,
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
                    foregroundColor: _white,
                    side: const BorderSide(color: _white),
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
    );
  }
}

const _sheetTitle = TextStyle(
  color: _white,
  fontSize: 13,
  fontWeight: FontWeight.w600,
);

class _DownloadsSheet extends StatefulWidget {
  const _DownloadsSheet({
    required this.limit,
    required this.days,
    required this.onDone,
    this.selection,
  });

  final int limit;
  final int days;
  final void Function(int limit, int days) onDone;

  /// Media ids picked on the grid above, when files can be picked.
  final ValueListenable<Set<String>?>? selection;

  @override
  State<_DownloadsSheet> createState() => _DownloadsSheetState();
}

class _DownloadsSheetState extends State<_DownloadsSheet> {
  late int _limit = widget.limit;
  late int _days = widget.days;

  @override
  Widget build(BuildContext context) {
    const hint = TextStyle(color: _muted, fontSize: 10.5, height: 1.5);
    return _SheetFrame(
      onDone: () => widget.onDone(_limit, _days),
      children: [
        const Text('فایل‌های قابل دانلود', style: _sheetTitle),
        if (widget.selection case final selection?) ...[
          const SizedBox(height: 6),
          ValueListenableBuilder<Set<String>?>(
            valueListenable: selection,
            builder: (_, picked, _) => Text(
              picked == null || picked.isEmpty
                  ? 'فایل‌ها را از رسانه‌های بالای صفحه انتخاب کنید.'
                  : '${faDigits(picked.length)} فایل انتخاب شده',
              style: hint,
            ),
          ),
        ],
        const SizedBox(height: 22),
        const Text('محدودیت دانلود', style: _sheetTitle),
        const SizedBox(height: 8),
        _Stepper(
          value: _limit,
          min: 1,
          dark: true,
          onChanged: (n) => setState(() => _limit = n),
        ),
        const SizedBox(height: 5),
        const Text(
          'هر خریدار چند بار می‌تواند فایل را دانلود کند.',
          style: hint,
        ),
        const SizedBox(height: 20),
        const Text('انقضای دانلود (روز)', style: _sheetTitle),
        const SizedBox(height: 8),
        _Stepper(
          value: _days,
          min: 1,
          dark: true,
          onChanged: (n) => setState(() => _days = n),
        ),
        const SizedBox(height: 5),
        const Text(
          'پیوند دانلود چند روز پس از خرید معتبر می‌ماند.',
          style: hint,
        ),
      ],
    );
  }
}

class _UnitSheet extends StatefulWidget {
  const _UnitSheet({required this.initial});

  final String? initial;

  @override
  State<_UnitSheet> createState() => _UnitSheetState();
}

class _UnitSheetState extends State<_UnitSheet> {
  final _query = TextEditingController();
  late String? _picked = widget.initial;
  late final List<String> _units = [
    if (widget.initial != null && !kUnits.contains(widget.initial))
      widget.initial!,
    ...kUnits,
  ];

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  /// "+" adds whatever is typed as a custom unit.
  void _addCustom() {
    final text = _query.text.trim();
    if (text.isEmpty) return;
    setState(() {
      if (!_units.contains(text)) _units.insert(0, text);
      _picked = text;
      _query.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final q = _query.text.trim();
    final shown = q.isEmpty
        ? _units
        : _units.where((u) => u.contains(q)).toList();
    return _SheetFrame(
      expand: true,
      onDone: () => Navigator.of(context).pop(_picked),
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text('واحد', style: _sheetTitle),
            SizedBox(width: 6),
            Icon(Icons.straighten, color: _white, size: 18),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: Container(
                height: 38,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: _muted),
                  borderRadius: BorderRadius.circular(19),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _query,
                        onChanged: (_) => setState(() {}),
                        onSubmitted: (_) => _addCustom(),
                        cursorColor: _white,
                        style: const TextStyle(color: _white, fontSize: 13),
                        decoration: const InputDecoration(
                          isDense: true,
                          border: InputBorder.none,
                          hintText: 'جستجو یا افزودن واحد',
                          hintStyle: TextStyle(color: _muted, fontSize: 12),
                        ),
                      ),
                    ),
                    const Icon(Icons.search, color: _white, size: 18),
                  ],
                ),
              ),
            ),
            IconButton(
              onPressed: _addCustom,
              tooltip: 'افزودن واحد',
              icon: const Icon(Icons.add, color: _white),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Expanded(
          child: ListView.builder(
            itemCount: shown.length,
            itemBuilder: (_, i) {
              final unit = shown[i];
              final selected = unit == _picked;
              return InkWell(
                onTap: () => setState(() => _picked = unit),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 7,
                    horizontal: 8,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          unit,
                          style: TextStyle(
                            color: selected
                                ? _white
                                : _white.withValues(alpha: 0.75),
                            fontSize: 13,
                            fontWeight: selected
                                ? FontWeight.w700
                                : FontWeight.w400,
                          ),
                        ),
                      ),
                      if (selected)
                        const Icon(Icons.check, color: _white, size: 18),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// "Select attribute value": every value of [attribute], plus "any" to
/// leave it open. The picked row sits in a white pill. Done pops the pick
/// as a one-field record.
class _ValuePickSheet extends StatefulWidget {
  const _ValuePickSheet({required this.attribute, required this.initial});

  final ProductAttribute attribute;
  final String? initial;

  @override
  State<_ValuePickSheet> createState() => _ValuePickSheetState();
}

class _ValuePickSheetState extends State<_ValuePickSheet> {
  late String? _picked = widget.initial;

  @override
  Widget build(BuildContext context) {
    final name = widget.attribute.name;
    final options = <String?>[null, ...widget.attribute.values];
    return _SheetFrame(
      expand: true,
      onDone: () => Navigator.of(context).pop((_picked,)),
      children: [
        const Text(
          'انتخاب مقدار ویژگی',
          textAlign: TextAlign.center,
          style: _sheetTitle,
        ),
        const SizedBox(height: 6),
        Text(
          'یک مقدار از «$name» انتخاب کنید تا این ترکیب قیمت و موجودی خودش '
          'را داشته باشد.',
          textAlign: TextAlign.center,
          style: const TextStyle(color: _muted, fontSize: 10.5, height: 1.5),
        ),
        const SizedBox(height: 14),
        Expanded(
          child: ListView.separated(
            itemCount: options.length,
            separatorBuilder: (_, _) => const SizedBox(height: 4),
            itemBuilder: (_, i) {
              final v = options[i];
              final on = v == _picked;
              return Material(
                color: on ? _white : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => setState(() => _picked = v),
                  child: SizedBox(
                    height: 40,
                    child: Center(
                      child: Text(
                        v == null ? 'هر $name' : faDigits(v),
                        style: TextStyle(
                          color: on
                              ? _ink
                              : v == null
                              ? _muted
                              : _white,
                          fontSize: 13,
                          fontWeight: on ? FontWeight.w700 : FontWeight.w400,
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
    );
  }
}
