import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nini/core/localization/app_string/app_string.dart';
import 'package:nini/core/localization/persian_feature/persian_feature.dart';
import 'package:nini/core/localization/strings/profile_edit_strings.dart';
import 'package:nini/features/profile_settings/presentation/widgets/common/settings_detail_header.dart';
import 'package:nini/shared/widgets/app_toast/app_toast.dart';
import 'package:nini/shared/widgets/skeleton/list_tile_skeleton.dart';

import '../../domain/user_profile.dart';
import '../cubit/user_profile_cubit.dart';
import '../widgets/form/profile_edit_fields.dart';
import '../widgets/form/profile_photo_picker.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});
  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _form = GlobalKey<FormState>();
  final _controllers = <String, TextEditingController>{
    for (final field in [
      'firstName',
      'lastName',
      'businessType',
      'city',
      'username',
      'email',
      'gender',
      'bio',
    ])
      field: TextEditingController(),
  };
  UserProfile? _initial;
  DateTime? _birthDate;
  Uint8List? _photo;
  bool _choosingPhoto = false;
  Future<void>? _savePending;

  void _initialize(UserProfile profile) {
    if (_initial != null) return;
    _initial = profile;
    final fields = profile.toJson();
    for (final entry in _controllers.entries) {
      entry.value.text = fields[entry.key] as String;
    }
    _birthDate = profile.birthDate;
  }

  Future<void> _save() =>
      _savePending ??= _submit().whenComplete(() => _savePending = null);

  Future<void> _submit() async {
    if (context.read<UserProfileCubit>().state.saving) return;
    if (_initial == null || _choosingPhoto || !_form.currentState!.validate()) {
      return;
    }
    final cubit = context.read<UserProfileCubit>();
    final profile = UserProfile(
      id: _initial!.id,
      city: _controllers['city']!.text.trim(),
      firstName: _controllers['firstName']!.text.trim(),
      lastName: _controllers['lastName']!.text.trim(),
      businessType: _controllers['businessType']!.text.trim(),
      nationality: cubit.state.profile.nationality,
      username: _controllers['username']!.text.trim(),
      email: _controllers['email']!.text.trim(),
      gender: _controllers['gender']!.text.trim(),
      bio: _controllers['bio']!.text.trim(),
      birthDate: _birthDate,
      avatarPath: cubit.state.profile.avatarPath,
    );
    var saved = await cubit.save(profile, photo: _photo);
    if (!mounted) return;
    var textOnly = false;
    if (!saved && _photo != null && cubit.state.photoUploadUnavailable) {
      final proceed = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text(
            ProfileEditStrings.saveTextOnlyTitle,
            textAlign: TextAlign.right,
          ),
          content: const Text(
            ProfileEditStrings.saveTextOnlyMessage,
            textAlign: TextAlign.right,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(AppStrings.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text(ProfileEditStrings.saveTextOnly),
            ),
          ],
        ),
      );
      if (!mounted || proceed != true) return;
      textOnly = true;
      saved = await cubit.save(profile);
      if (!mounted) return;
    }
    if (saved) {
      if (textOnly) {
        _initial = cubit.state.profile;
        AppToast.show(
          context,
          message: ProfileEditStrings.textSavedPhotoPending,
        );
        return;
      }
      AppToast.success(context, ProfileEditStrings.saved);
      Navigator.of(context).pop();
    } else {
      AppToast.show(
        context,
        message: cubit.state.errorMessage ?? ProfileEditStrings.saveFailed,
        type: AppToastType.error,
      );
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<UserProfileCubit, UserProfileState>(
        builder: (context, state) {
          if (!state.loading && !state.loadFailed) _initialize(state.profile);
          return PersianFeature(
            child: PopScope(
              canPop: !state.saving,
              child: Scaffold(
                appBar: SettingsDetailHeader(
                  title: ProfileEditStrings.title,
                  enabled:
                      _initial != null &&
                      !state.loading &&
                      !state.loadFailed &&
                      !_choosingPhoto,
                  saving: state.saving,
                  onDone: _save,
                ),
                body: SafeArea(
                  top: false,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 560),
                      child: state.loading
                          ? ListView.builder(
                              itemCount: 6,
                              itemBuilder: (_, index) =>
                                  const ListTileSkeleton(showAvatar: false),
                            )
                          : state.loadFailed
                          ? Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  const Text(
                                    ProfileEditStrings.loadFailed,
                                    textAlign: TextAlign.right,
                                    textDirection: TextDirection.ltr,
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        context.read<UserProfileCubit>().load(),
                                    child: const Text(
                                      AppStrings.retry,
                                      textDirection: TextDirection.ltr,
                                      textAlign: TextAlign.right,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : SingleChildScrollView(
                              keyboardDismissBehavior:
                                  ScrollViewKeyboardDismissBehavior.onDrag,
                              padding: EdgeInsets.fromLTRB(12, 24, 12, 24),
                              child: Form(
                                key: _form,
                                child: Column(
                                  children: [
                                    ProfilePhotoPicker(
                                      initialImage: _initial!.avatarPath,
                                      enabled: !state.saving && !_choosingPhoto,
                                      onChanged: (bytes) => _photo = bytes,
                                      onPickingChanged: (value) => setState(
                                        () => _choosingPhoto = value,
                                      ),
                                    ),
                                    const SizedBox(height: 44),
                                    ProfileEditFields(
                                      controllers: _controllers,
                                      birthDate: _birthDate,
                                      onBirthDateChanged: (value) =>
                                          _birthDate = value,
                                      enabled: !state.saving,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      );
}
