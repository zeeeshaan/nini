import 'package:flutter/material.dart';
import 'package:nini/core/localization/profile_edit_strings.dart';

import '../profile_birth_field/profile_birth_field.dart';
import '../profile_edit_field/profile_edit_field.dart';

class ProfileEditFields extends StatelessWidget {
  const ProfileEditFields({super.key});
  @override
  Widget build(BuildContext context) => const Column(
    children: [
      ProfileEditField(
        label: ProfileEditStrings.name,
        keyboardType: TextInputType.name,
      ),
      ProfileEditField(
        label: ProfileEditStrings.lastName,
        keyboardType: TextInputType.name,
      ),
      ProfileEditField(label: ProfileEditStrings.nationality),
      ProfileEditField(label: ProfileEditStrings.username),
      ProfileEditField(
        label: ProfileEditStrings.email,
        keyboardType: TextInputType.emailAddress,
      ),
      ProfileBirthField(),
      ProfileEditField(label: ProfileEditStrings.gender),
      ProfileEditField(
        label: ProfileEditStrings.bio,
        maxLines: 5,
        keyboardType: TextInputType.multiline,
      ),
    ],
  );
}
