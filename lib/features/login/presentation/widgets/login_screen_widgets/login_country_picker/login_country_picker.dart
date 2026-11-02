import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter/material.dart';
import 'package:nini/core/localization/auth_strings.dart';

class LoginCountryPicker extends StatelessWidget {
  const LoginCountryPicker({super.key, required this.onChanged});

  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return CountryCodePicker(
      initialSelection: 'IR',
      favorite: const ['IR', 'PK', 'AE'],
      onChanged: (country) => onChanged(country.dialCode ?? '+98'),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      flagWidth: 22,
      textStyle: TextStyle(color: colors.onSurface, fontSize: 14),
      dialogTextStyle: TextStyle(color: colors.onSurface, fontSize: 15),
      dialogBackgroundColor: colors.surface,
      searchStyle: TextStyle(color: colors.onSurface),
      headerText: AuthStrings.selectCountry,
      headerTextStyle: TextStyle(
        color: colors.onSurface,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
      searchDecoration: const InputDecoration(
        hintText: AuthStrings.searchCountry,
        prefixIcon: Icon(Icons.search),
      ),
      emptySearchBuilder: (_) => const Center(
        child: Text(AuthStrings.noCountries, textAlign: TextAlign.center),
      ),
    );
  }
}
