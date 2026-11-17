import 'package:flutter/material.dart';
import 'package:nini/core/theme/app_text_styles.dart';
import 'package:nini/core/icons/app_icons.dart';
import 'package:nini/core/localization/app_string/app_string.dart';
import 'package:nini/core/localization/strings/profile_edit_strings.dart';
import 'package:nini/shared/widgets/app_icons/app_icon.dart';

class ProfileBirthField extends StatefulWidget {
  const ProfileBirthField({
    super.key,
    this.initialDate,
    this.onChanged,
    this.enabled = true,
  });
  final DateTime? initialDate;
  final ValueChanged<DateTime?>? onChanged;
  final bool enabled;
  @override
  State<ProfileBirthField> createState() => _ProfileBirthFieldState();
}

class _ProfileBirthFieldState extends State<ProfileBirthField> {
  final _controller = TextEditingController();
  late DateTime? _date = widget.initialDate;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _displayDate();
  }

  @override
  void didUpdateWidget(covariant ProfileBirthField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!DateUtils.isSameDay(oldWidget.initialDate, widget.initialDate)) {
      _date = widget.initialDate;
      _displayDate();
    }
  }

  void _displayDate() {
    final date = _date;
    _controller.text = date == null
        ? ''
        : AppStrings.persianDigits(
            MaterialLocalizations.of(context).formatMediumDate(date),
          );
  }

  void _changeDate(DateTime? date) {
    if (!widget.enabled) return;
    _date = date;
    _displayDate();
    widget.onChanged?.call(date);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _chooseDate() async {
    if (!widget.enabled) return;
    final today = DateUtils.dateOnly(DateTime.now());
    final firstDate = DateTime(1900);
    var initialDate = _date ?? today;
    if (initialDate.isBefore(firstDate)) initialDate = firstDate;
    if (initialDate.isAfter(today)) initialDate = today;
    final date = await showDatePicker(
      context: context,
      locale: const Locale('en'),
      textDirection: TextDirection.ltr,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: today,
    );
    if (date != null && mounted) {
      _changeDate(date);
    }
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: TextFormField(
      controller: _controller,
      enabled: widget.enabled,
      readOnly: true,
      onTap: _chooseDate,
      contextMenuBuilder: (context, editableText) =>
          AdaptiveTextSelectionToolbar.buttonItems(
            anchors: editableText.contextMenuAnchors,
            buttonItems: [
              ...editableText.contextMenuButtonItems,
              if (_date != null && widget.enabled)
                ContextMenuButtonItem(
                  label: ProfileEditStrings.clearBirthDate,
                  onPressed: () {
                    editableText.hideToolbar();
                    _changeDate(null);
                  },
                ),
            ],
          ),
      textAlign: TextAlign.right,
      textDirection: TextDirection.ltr,
      style: AppTextStyles.caption,
      decoration: InputDecoration(
        hintText: ProfileEditStrings.birth,
        hintTextDirection: TextDirection.ltr,
        hintStyle: AppTextStyles.caption.copyWith(
          color: Theme.of(context).colorScheme.onSurface,
        ),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        prefixIconConstraints: const BoxConstraints(
          minWidth: 40,
          minHeight: 40,
        ),
        prefixIcon: const Padding(
          padding: EdgeInsets.all(11),
          child: AppIcon(AppIcons.calendar, size: 17),
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(9)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.outline),
        ),
      ),
    ),
  );
}
