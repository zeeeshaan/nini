import 'package:flutter/material.dart';
import 'package:nini/core/icons/app_icons.dart';
import 'package:nini/core/localization/strings/create_post_strings.dart';
import 'package:nini/core/responsiveness/app_responsiveness/app_responsiveness.dart';
import 'package:nini/core/theme/app_text_styles.dart';
import 'package:nini/features/create_post/data/iran_address_catalog.dart';
import 'package:nini/shared/models/post/post_attributes.dart';
import 'package:nini/shared/widgets/app_icons/app_icon.dart';
import 'package:nini/shared/widgets/app_textfield/app_text_field.dart';

import 'iran_location_picker.dart';
import 'post_dialog.dart';

class ManualAddressDialog extends StatefulWidget {
  const ManualAddressDialog({super.key, this.initial});

  final PostAddress? initial;

  @override
  State<ManualAddressDialog> createState() => _ManualAddressDialogState();
}

class _ManualAddressDialogState extends State<ManualAddressDialog> {
  final _form = GlobalKey<FormState>();
  late final _address = TextEditingController(
    text: widget.initial?.address ?? '',
  );
  late final _city = TextEditingController(
    text: IranAddressCatalog.cityLabel(
      widget.initial?.city ?? '',
      widget.initial?.province ?? '',
    ),
  );
  late final _province = TextEditingController(
    text: IranAddressCatalog.provinceLabel(widget.initial?.province ?? ''),
  );
  late final _number = TextEditingController(
    text: widget.initial?.buildingNumber ?? '',
  );
  late final _unit = TextEditingController(
    text: widget.initial?.unitNumber ?? '',
  );
  late final _postalCode = TextEditingController(
    text: widget.initial?.postalCode ?? '',
  );

  @override
  void dispose() {
    for (final controller in [
      _address,
      _city,
      _province,
      _number,
      _unit,
      _postalCode,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _chooseLocation({required bool cities}) async {
    final key = IranAddressCatalog.provinceKey(_province.text);
    final province = IranAddressCatalog.provinces.containsKey(key) ? key : '';
    final choice = await showPostDialog<({String province, String city})>(
      context,
      IranLocationPicker(cities: cities, province: province),
    );
    if (!mounted || choice == null) return;
    if (cities) {
      _city.text = IranAddressCatalog.cityLabel(choice.city, choice.province);
    } else if (!IranAddressCatalog.provinces[choice.province]!.cities
        .containsKey(IranAddressCatalog.cityKey(_city.text, choice.province))) {
      _city.clear();
    }
    _province.text = IranAddressCatalog.provinceLabel(choice.province);
  }

  void _done() {
    if (!_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    Navigator.of(context).pop(
      PostAddress(
        address: _address.text.trim(),
        city: IranAddressCatalog.cityKey(_city.text.trim(), _province.text),
        province: IranAddressCatalog.provinceKey(_province.text.trim()),
        buildingNumber: _number.text.trim(),
        unitNumber: _unit.text.trim(),
        postalCode: _postalCode.text.trim(),
        latitude: widget.initial?.latitude,
        longitude: widget.initial?.longitude,
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController controller, {
    VoidCallback? onTap,
    TextInputType? keyboardType,
    int maxLines = 1,
    bool required = true,
    bool last = false,
  }) => AppTextField(
    controller: controller,
    hint: label,
    readOnly: onTap != null,
    onTap: onTap,
    suffixIcon: onTap != null
        ? const Center(
            widthFactor: 1,
            heightFactor: 1,
            child: AppIcon(AppIcons.back, size: 18),
          )
        : null,
    keyboardType: keyboardType,
    maxLines: maxLines,
    textInputAction: last ? TextInputAction.done : TextInputAction.next,
    onSubmitted: last ? (_) => _done() : null,
    validator: required
        ? (value) => value == null || value.trim().isEmpty
              ? CreatePostStrings.addressFieldRequired
              : null
        : null,
  );

  @override
  Widget build(BuildContext context) => AppResponsiveBuilder(
    builder: (context, responsive) {
      final media = MediaQuery.of(context);
      final height =
          (media.size.height - media.viewInsets.bottom - media.padding.top) *
          .92;
      final theme = Theme.of(context);
      final border = OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: theme.colorScheme.onSurface.withValues(alpha: .55),
        ),
      );
      return SizedBox(
        height: height,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                textDirection: TextDirection.ltr,
                children: [
                  IconButton(
                    tooltip: CreatePostStrings.done,
                    onPressed: _done,
                    icon: const AppIcon(AppIcons.check, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      CreatePostStrings.address,
                      textAlign: TextAlign.right,
                      style: AppTextStyles.heading,
                    ),
                  ),
                  IconButton(
                    tooltip: CreatePostStrings.close,
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const RotatedBox(
                      quarterTurns: 2,
                      child: AppIcon(AppIcons.back, size: 24),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  responsive.horizontalPadding,
                  24,
                  responsive.horizontalPadding,
                  24,
                ),
                child: Theme(
                  data: theme.copyWith(
                    inputDecorationTheme: theme.inputDecorationTheme.copyWith(
                      border: border,
                      enabledBorder: border,
                      focusedBorder: border.copyWith(
                        borderSide: BorderSide(
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 18,
                      ),
                      hintStyle: AppTextStyles.body.copyWith(
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                  child: Form(
                    key: _form,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _field(
                          CreatePostStrings.city,
                          _city,
                          onTap: () => _chooseLocation(cities: true),
                        ),
                        const SizedBox(height: 12),
                        _field(
                          CreatePostStrings.province,
                          _province,
                          onTap: () => _chooseLocation(cities: false),
                        ),
                        const SizedBox(height: 12),
                        _field(
                          CreatePostStrings.address,
                          _address,
                          keyboardType: TextInputType.streetAddress,
                          maxLines: 3,
                        ),
                        const SizedBox(height: 12),
                        _field(
                          CreatePostStrings.buildingNumber,
                          _number,
                          keyboardType: TextInputType.number,
                          required: false,
                        ),
                        const SizedBox(height: 12),
                        _field(
                          CreatePostStrings.unit,
                          _unit,
                          keyboardType: TextInputType.number,
                          required: false,
                        ),
                        const SizedBox(height: 12),
                        _field(
                          CreatePostStrings.postalCode,
                          _postalCode,
                          last: true,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}
