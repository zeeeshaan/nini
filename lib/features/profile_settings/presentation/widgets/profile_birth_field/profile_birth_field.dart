import 'package:flutter/material.dart';
import 'package:nini/core/theme/app_text_styles.dart';
import 'package:nini/core/icons/app_icons.dart';
import 'package:nini/core/localization/app_strings.dart';
import 'package:nini/core/localization/profile_edit_strings.dart';
import 'package:nini/shared/widgets/app_icons/app_icon.dart';

class ProfileBirthField extends StatefulWidget {
  const ProfileBirthField({super.key});
  @override
  State<ProfileBirthField> createState() => _ProfileBirthFieldState();
}

class _ProfileBirthFieldState extends State<ProfileBirthField> {
  final _controller = TextEditingController();
  DateTime? _date;
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _chooseDate() async {
    final date = await showDatePicker(
      context: context,
      locale: const Locale('en'),
      initialDate: _date ?? DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (date != null && mounted) {
      _date = date;
      _controller.text = AppStrings.persianDigits(
        MaterialLocalizations.of(context).formatMediumDate(date),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: TextFormField(
      controller: _controller,
      readOnly: true,
      onTap: _chooseDate,
      textAlign: TextAlign.right,
      textDirection: TextDirection.rtl,
      style: AppTextStyles.caption,
      decoration: InputDecoration(
        hintText: ProfileEditStrings.birth,
        hintTextDirection: TextDirection.rtl,
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
