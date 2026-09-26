import 'package:flutter/material.dart';
import '../app_colors.dart';
import '../utils/fa.dart';

const _ink = AppColors.deepBlack;
const _muted = AppColors.midGray;

/// Back chevron, title and a check that confirms the page.
class PickerHeader extends StatelessWidget {
  const PickerHeader({super.key, required this.title, required this.onDone});

  final String title;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(6, 10, 14, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.chevron_left, color: _ink, size: 30),
          ),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: _ink,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          InkWell(
            onTap: onDone,
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

/// "+" that adds whatever is typed, next to a rounded search field.
class PickerSearchBar extends StatelessWidget {
  const PickerSearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onAdd,
    this.hint = 'جستجو',
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onAdd;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: onAdd,
          tooltip: 'افزودن',
          icon: const Icon(Icons.add, color: _ink, size: 28),
        ),
        const SizedBox(width: 4),
        Expanded(
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
                  child: TextField(
                    controller: controller,
                    onChanged: onChanged,
                    onSubmitted: (_) => onAdd(),
                    cursorColor: _ink,
                    style: const TextStyle(color: _ink, fontSize: 13),
                    decoration: InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      hintText: hint,
                      hintStyle: const TextStyle(color: _muted, fontSize: 12.5),
                    ),
                  ),
                ),
                const Icon(Icons.search, color: _ink, size: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Full-screen list of bordered pills with a search / add bar. Tapping a
/// pill selects it (black fill); its "×" removes it from the list. With
/// [multi] off only one pill can be selected. With [numbered] each selected
/// pill shows its pick order, and the first check narrows the page to just
/// the picked rows so the order can be reviewed; back (or tapping a row)
/// returns to the full list. The check pops the selection, in pick order,
/// as a `List<String>`.
class PillPickerScreen extends StatefulWidget {
  const PillPickerScreen({
    super.key,
    required this.title,
    required this.options,
    this.initial = const [],
    this.multi = false,
    this.numbered = false,
    this.searchHint = 'جستجو',
    this.helper,
  });

  final String title;
  final List<String> options;
  final List<String> initial;
  final bool multi;
  final bool numbered;
  final String searchHint;

  /// Small hint under the search bar.
  final String? helper;

  @override
  State<PillPickerScreen> createState() => _PillPickerScreenState();
}

class _PillPickerScreenState extends State<PillPickerScreen> {
  final _search = TextEditingController();
  late final List<String> _options = [
    ...widget.options,
    for (final v in widget.initial)
      if (!widget.options.contains(v)) v,
  ];
  late final List<String> _selected = List.of(widget.initial);
  String _query = '';

  /// Numbered pickers only: showing just the picked rows before confirming.
  bool _reviewing = false;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _toggle(String option) {
    setState(() {
      if (_selected.remove(option)) return;
      if (!widget.multi) _selected.clear();
      _selected.add(option);
    });
  }

  void _remove(String option) => setState(() {
    _options.remove(option);
    _selected.remove(option);
  });

  void _add() {
    final value = _search.text.trim();
    if (value.isEmpty) return;
    _search.clear();
    setState(() {
      _query = '';
      if (!_options.contains(value)) _options.insert(0, value);
      if (!_selected.contains(value)) {
        if (!widget.multi) _selected.clear();
        _selected.add(value);
      }
    });
  }

  void _done() {
    if (widget.numbered && !_reviewing && _selected.isNotEmpty) {
      setState(() => _reviewing = true);
      return;
    }
    Navigator.of(context).pop(List.of(_selected));
  }

  @override
  Widget build(BuildContext context) {
    final q = _query.trim();
    final visible = _options.where((o) => o.contains(q)).toList();
    return PopScope(
      canPop: !_reviewing,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(() => _reviewing = false);
      },
      child: Scaffold(
        backgroundColor: AppColors.pureWhite,
        body: SafeArea(
          child: Column(
            children: [
              PickerHeader(title: widget.title, onDone: _done),
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(6, 0, 16, 14),
                child: PickerSearchBar(
                  controller: _search,
                  onChanged: (v) => setState(() {
                    _query = v;
                    _reviewing = false;
                  }),
                  onAdd: _add,
                  hint: widget.searchHint,
                ),
              ),
              if (_reviewing)
                Expanded(child: _buildReview())
              else
                ..._buildEditing(visible),
            ],
          ),
        ),
      ),
    );
  }

  /// The picked features in order: numbered rows, the first filled black.
  Widget _buildReview() {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
      itemCount: _selected.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (_, i) => _PickedRow(
        number: i + 1,
        label: _selected[i],
        active: i == 0,
        onTap: () => setState(() => _reviewing = false),
      ),
    );
  }

  List<Widget> _buildEditing(List<String> visible) {
    return [
      if (widget.helper != null)
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(62, 0, 16, 14),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              widget.helper!,
              style: const TextStyle(color: _muted, fontSize: 11),
            ),
          ),
        ),
      Expanded(
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
          itemCount: visible.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (_, i) {
            final option = visible[i];
            final order = _selected.indexOf(option);
            return _Pill(
              label: widget.numbered && order >= 0
                  ? '${faDigits(order + 1)}  $option'
                  : option,
              selected: order >= 0,
              onTap: () => _toggle(option),
              onRemove: () => _remove(option),
            );
          },
        ),
      ),
    ];
  }
}

/// Review row on a numbered picker: pick order, label and a chevron.
class _PickedRow extends StatelessWidget {
  const _PickedRow({
    required this.number,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final int number;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = active ? AppColors.pureWhite : _ink;
    return Material(
      color: active ? _ink : AppColors.pureWhite,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: _ink),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 40,
          child: Row(
            children: [
              const SizedBox(width: 14),
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
                  label,
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
                padding: const EdgeInsets.all(12),
                child: Icon(Icons.chevron_right, color: fg, size: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.onRemove,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? AppColors.pureWhite : _ink;
    return Material(
      color: selected ? _ink : AppColors.pureWhite,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: _ink),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 40,
          child: Row(
            children: [
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: fg,
                    fontSize: 13.5,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ),
              IconButton(
                onPressed: onRemove,
                tooltip: 'حذف',
                visualDensity: VisualDensity.compact,
                icon: Icon(Icons.close, color: fg, size: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
