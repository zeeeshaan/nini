import 'package:flutter/material.dart';
import 'package:nini/core/localization/strings/profile_post_strings.dart';

class PostEditorActions extends StatelessWidget {
  const PostEditorActions({
    super.key,
    required this.saving,
    required this.onCancel,
    required this.onSave,
  });
  final bool saving;
  final VoidCallback onCancel, onSave;
  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Center(
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: saving ? null : onCancel,
                  child: const Text(
                    ProfilePostStrings.cancel,
                    textDirection: TextDirection.ltr,
                    textAlign: TextAlign.right,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: saving ? null : onSave,
                  child: Text(
                    saving
                        ? ProfilePostStrings.saving
                        : ProfilePostStrings.saveChanges,
                    textDirection: TextDirection.ltr,
                    textAlign: TextAlign.right,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
