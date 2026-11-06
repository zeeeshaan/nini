import 'package:nini/features/profile_settings/presentation/cubit/profile_photo_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:nini/core/icons/app_icons.dart';
import 'package:nini/core/localization/profile_edit_strings.dart';
import 'package:nini/shared/widgets/app_icons/app_icon.dart';

/// Selects a local preview only. The image is never uploaded or persisted.
class ProfilePhotoPicker extends StatefulWidget {
  const ProfilePhotoPicker({super.key});
  @override
  State<ProfilePhotoPicker> createState() => _ProfilePhotoPickerState();
}

class _ProfilePhotoPickerState extends State<ProfilePhotoPicker> {
  final _photo = ProfilePhotoCubit();
  Future<void> _pick() async {
    final succeeded = await _photo.pick();
    if (!mounted || succeeded) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          ProfileEditStrings.photoError,
          textAlign: TextAlign.right,
          textDirection: TextDirection.rtl,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _photo.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<ProfilePhotoCubit, Uint8List?>(
        bloc: _photo,
        builder: (context, state) {
          final colors = Theme.of(context).colorScheme;
          return SizedBox.square(
            dimension: 106,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: CircleAvatar(
                    backgroundColor: colors.surfaceContainerHighest,
                    backgroundImage: _photo.state == null
                        ? null
                        : MemoryImage(_photo.state!),
                    child: _photo.state == null
                        ? Icon(
                            Icons.person_outline,
                            size: 58,
                            color: colors.onSurface.withValues(alpha: .3),
                          )
                        : null,
                  ),
                ),
                Positioned(
                  right: -2,
                  bottom: -2,
                  child: IconButton.filled(
                    tooltip: ProfileEditStrings.choosePhoto,
                    onPressed: _pick,
                    style: IconButton.styleFrom(
                      backgroundColor: colors.primary,
                      foregroundColor: colors.onPrimary,
                      minimumSize: const Size(32, 32),
                      padding: const EdgeInsets.all(7),
                    ),
                    icon: const AppIcon(AppIcons.camera, size: 18),
                  ),
                ),
              ],
            ),
          );
        },
      );
}
