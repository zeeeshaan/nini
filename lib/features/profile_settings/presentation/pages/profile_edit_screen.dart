import 'package:flutter/material.dart';
import 'package:nini/core/localization/persian_feature.dart';
import 'package:nini/core/localization/profile_edit_strings.dart';
import 'package:nini/shared/widgets/settings_detail_header/settings_detail_header.dart';

import '../widgets/profile_edit_fields/profile_edit_fields.dart';
import '../widgets/profile_photo_picker/profile_photo_picker.dart';

/// UI preview: inputs stay local to this screen; Done returns to settings.
class ProfileEditScreen extends StatelessWidget {
  const ProfileEditScreen({super.key});
  @override
  Widget build(BuildContext context) => PersianFeature(
    child: Scaffold(
      appBar: const SettingsDetailHeader(title: ProfileEditStrings.title),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: const SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.fromLTRB(12, 24, 12, 24),
              child: Column(
                children: [
                  ProfilePhotoPicker(),
                  SizedBox(height: 44),
                  ProfileEditFields(),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
