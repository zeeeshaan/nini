import 'package:flutter/material.dart';
import 'package:nini/core/icons/app_icons.dart';
import 'package:nini/core/localization/strings/create_post_strings.dart';
import 'package:nini/core/theme/app_text_styles.dart';
import 'package:nini/features/create_post/data/iran_address_catalog.dart';
import 'package:nini/shared/widgets/app_icons/app_icon.dart';
import 'package:nini/shared/widgets/app_textfield/app_text_field.dart';

class IranLocationPicker extends StatefulWidget {
  const IranLocationPicker({
    super.key,
    required this.cities,
    this.province = '',
  });

  final bool cities;
  final String province;

  @override
  State<IranLocationPicker> createState() => _IranLocationPickerState();
}

class _IranLocationPickerState extends State<IranLocationPicker> {
  final _search = TextEditingController();
  late final _choices = [
    for (final province in IranAddressCatalog.provinces.entries)
      if (!widget.cities ||
          widget.province.isEmpty ||
          province.key == widget.province)
        if (widget.cities)
          for (final city in province.value.cities.entries)
            (province: province.key, city: city.key, englishName: city.value)
        else
          (
            province: province.key,
            city: '',
            englishName: province.value.englishName,
          ),
  ];

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final available =
        media.size.height - media.viewInsets.bottom - media.padding.top;
    return SizedBox(
      height: available * .88,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              textDirection: TextDirection.ltr,
              children: [
                Expanded(
                  child: Text(
                    widget.cities
                        ? CreatePostStrings.city
                        : CreatePostStrings.province,
                    textAlign: TextAlign.right,
                    style: AppTextStyles.heading,
                    textDirection: TextDirection.ltr,
                  ),
                ),
                IconButton(
                  tooltip: CreatePostStrings.close,
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const AppIcon(AppIcons.backRight, size: 22),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: AppTextField(
              controller: _search,
              hint: widget.cities
                  ? CreatePostStrings.searchCities
                  : CreatePostStrings.searchProvinces,
              textDirection: TextDirection.ltr,
              suffixIcon: const Center(
                widthFactor: 1,
                heightFactor: 1,
                child: AppIcon(AppIcons.search, size: 18),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ValueListenableBuilder<TextEditingValue>(
              valueListenable: _search,
              builder: (context, value, child) {
                final query = IranAddressCatalog.normalize(value.text);
                final choices = _choices.where((choice) {
                  final text =
                      '${choice.city} ${choice.province} ${choice.englishName} ${IranAddressCatalog.provinceLabel(choice.province)}';
                  return IranAddressCatalog.normalize(text).contains(query);
                }).toList();
                if (choices.isEmpty) {
                  return const Center(
                    child: Text(
                      CreatePostStrings.noLocationsFound,
                      textDirection: TextDirection.ltr,
                      textAlign: TextAlign.right,
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 16),
                  itemCount: choices.length,
                  itemBuilder: (context, index) {
                    final choice = choices[index];
                    return ListTile(
                      title: Text(
                        widget.cities ? choice.city : choice.province,
                        textDirection: TextDirection.ltr,
                        textAlign: TextAlign.right,
                        style: AppTextStyles.body,
                      ),
                      subtitle: widget.cities
                          ? Text(
                              IranAddressCatalog.provinceLabel(choice.province),
                              textDirection: TextDirection.ltr,
                              textAlign: TextAlign.right,
                            )
                          : null,
                      onTap: () {
                        FocusScope.of(context).unfocus();
                        Navigator.of(
                          context,
                        ).pop((province: choice.province, city: choice.city));
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
