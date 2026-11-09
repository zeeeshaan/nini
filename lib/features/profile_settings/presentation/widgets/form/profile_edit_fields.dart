import 'package:flutter/material.dart';
import 'package:nini/core/localization/profile_edit_strings.dart';
import 'package:nini/core/theme/app_text_styles.dart';
import 'package:nini/features/profile_settings/domain/profile_limits.dart';

import 'profile_birth_field.dart';
import 'profile_edit_field.dart';

class ProfileEditFields extends StatelessWidget {
  const ProfileEditFields({
    super.key,
    this.controllers = const {},
    this.birthDate,
    this.onBirthDateChanged,
    this.enabled = true,
  });

  final Map<String, TextEditingController> controllers;
  final DateTime? birthDate;
  final ValueChanged<DateTime>? onBirthDateChanged;
  final bool enabled;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      ProfileEditField(
        label: ProfileEditStrings.name,
        keyboardType: TextInputType.name,
        maxLength: ProfileLimits.profileName,
        textStyle: AppTextStyles.profileName,
        controller: controllers['firstName'],
        enabled: enabled,
        validator: (value) => value == null || value.trim().isEmpty
            ? ProfileEditStrings.nameRequired
            : null,
      ),
      ProfileEditField(
        label: ProfileEditStrings.lastName,
        keyboardType: TextInputType.name,
        controller: controllers['lastName'],
        enabled: enabled,
      ),
      ProfileEditField(
        label: ProfileEditStrings.businessType,
        controller: controllers['businessType'],
        maxLength: ProfileLimits.businessType,
        enabled: enabled,
      ),
      ProfileEditField(
        label: ProfileEditStrings.nationality,
        controller: controllers['nationality'],
        enabled: enabled,
      ),
      ProfileEditField(
        label: ProfileEditStrings.username,
        maxLength: ProfileLimits.username,
        textStyle: AppTextStyles.username,
        controller: controllers['username'],
        enabled: enabled,
      ),
      ProfileEditField(
        label: ProfileEditStrings.email,
        keyboardType: TextInputType.emailAddress,
        controller: controllers['email'],
        enabled: enabled,
      ),
      ProfileBirthField(
        initialDate: birthDate,
        onChanged: onBirthDateChanged,
        enabled: enabled,
      ),
      ProfileEditField(
        label: ProfileEditStrings.gender,
        controller: controllers['gender'],
        enabled: enabled,
      ),
      ProfileEditField(
        label: ProfileEditStrings.bio,
        maxLines: 5,
        keyboardType: TextInputType.multiline,
        maxLength: ProfileLimits.bio,
        textStyle: AppTextStyles.bio,
        controller: controllers['bio'],
        enabled: enabled,
      ),
    ],
  );
}
