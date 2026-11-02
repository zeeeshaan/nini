import 'package:flutter/material.dart';
import 'package:nini/core/icons/app_icons.dart';
import 'package:nini/core/localization/notification_strings.dart';
import 'package:nini/shared/widgets/app_icons/app_icon.dart';

class NotificationSearchField extends StatefulWidget {
  const NotificationSearchField({
    super.key,
    required this.query,
    required this.onChanged,
  });
  final String query;
  final ValueChanged<String> onChanged;
  @override
  State<NotificationSearchField> createState() =>
      _NotificationSearchFieldState();
}

class _NotificationSearchFieldState extends State<NotificationSearchField> {
  late final _controller = TextEditingController(text: widget.query);
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(36),
      borderSide: BorderSide(color: colors.outline, width: .7),
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: TextField(
        controller: _controller,
        onChanged: widget.onChanged,
        textDirection: TextDirection.rtl,
        textAlign: TextAlign.right,
        textInputAction: TextInputAction.search,
        onSubmitted: (_) => FocusScope.of(context).unfocus(),
        decoration: InputDecoration(
          hintText: NotificationStrings.search,
          hintTextDirection: TextDirection.rtl,
          hintStyle: TextStyle(
            color: colors.onSurface.withValues(alpha: .35),
            fontSize: 13,
          ),
          border: border,
          enabledBorder: border,
          focusedBorder: border.copyWith(
            borderSide: BorderSide(color: colors.onSurface),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 14,
          ),
          suffixIcon: const Padding(
            padding: EdgeInsets.all(14),
            child: AppIcon(AppIcons.search, size: 21),
          ),
          prefixIcon: widget.query.isEmpty
              ? null
              : IconButton(
                  tooltip: NotificationStrings.clearSearch,
                  icon: const AppIcon(AppIcons.close, size: 18),
                  onPressed: () {
                    _controller.clear();
                    widget.onChanged('');
                  },
                ),
        ),
      ),
    );
  }
}
