import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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
  Uint8List? _photo;
  bool _picking = false;
  Future<void> _pick() async {
    if (_picking) return;
    _picking = true;
    try {
      final file = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 600,
      );
      final bytes = await file?.readAsBytes();
      if (mounted && bytes != null) setState(() => _photo = bytes);
    } catch (_) {
      if (mounted) {
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
    } finally {
      _picking = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SizedBox.square(
      dimension: 106,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: CircleAvatar(
              backgroundColor: colors.surfaceContainerHighest,
              backgroundImage: _photo == null ? null : MemoryImage(_photo!),
              child: _photo == null
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
  }
}
