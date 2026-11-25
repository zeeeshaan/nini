import 'package:nini/features/profile_settings/presentation/cubit/profile_photo_cubit.dart';
import 'package:nini/features/profile_settings/presentation/helpers/crop_profile_photo.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:nini/core/constants/app_icons/app_icons.dart';
import 'package:nini/core/localization/strings/profile_edit_strings.dart';
import 'package:nini/shared/widgets/app_icons/app_icon.dart';
import 'package:nini/shared/widgets/app_images/profile_image_provider.dart';

/// Previews an image locally; the editor commits it only when Done is pressed.
class ProfilePhotoPicker extends StatefulWidget {
  const ProfilePhotoPicker({
    super.key,
    this.initialImage,
    this.onChanged,
    this.onPickingChanged,
    this.enabled = true,
  });
  final String? initialImage;
  final ValueChanged<Uint8List>? onChanged;
  final ValueChanged<bool>? onPickingChanged;
  final bool enabled;
  @override
  State<ProfilePhotoPicker> createState() => _ProfilePhotoPickerState();
}

class _ProfilePhotoPickerState extends State<ProfilePhotoPicker> {
  final _photo = ProfilePhotoCubit();
  bool _picking = false;
  Future<void> _pick() async {
    if (_picking || !widget.enabled) return;
    setState(() => _picking = true);
    widget.onPickingChanged?.call(true);
    final bool succeeded;
    final previous = _photo.state;
    try {
      succeeded = await _photo.pick(
        cropPhoto: (path) => cropProfilePhoto(context, path),
      );
      if (mounted &&
          succeeded &&
          _photo.state != null &&
          _photo.state != previous) {
        widget.onChanged?.call(_photo.state!);
      }
    } finally {
      if (mounted) {
        setState(() => _picking = false);
        widget.onPickingChanged?.call(false);
      }
    }
    if (!mounted || succeeded) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          ProfileEditStrings.photoError,
          textAlign: TextAlign.right,
          textDirection: TextDirection.ltr,
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
          final image = state != null
              ? MemoryImage(state)
              : widget.initialImage == null
              ? null
              : profileImageProvider(widget.initialImage!);
          return SizedBox.square(
            dimension: 106,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: CircleAvatar(
                    backgroundColor: colors.surfaceContainerHighest,
                    child: image == null
                        ? AppIcon(
                            AppIcons.profile,
                            size: 58,
                            color: colors.onSurface.withValues(alpha: .3),
                          )
                        : ClipOval(
                            child: Image(
                              image: image,
                              width: 106,
                              height: 106,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => AppIcon(
                                AppIcons.profile,
                                size: 58,
                                color: colors.onSurface.withValues(alpha: .3),
                              ),
                            ),
                          ),
                  ),
                ),
                Positioned(
                  right: -2,
                  bottom: -2,
                  child: IconButton.filled(
                    tooltip: ProfileEditStrings.choosePhoto,
                    onPressed: widget.enabled && !_picking ? _pick : null,
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
