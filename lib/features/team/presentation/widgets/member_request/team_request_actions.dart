import 'package:flutter/material.dart';
import 'package:nini/shared/widgets/app_button/app_button.dart';

class TeamRequestActions extends StatelessWidget {
  const TeamRequestActions({
    super.key,
    required this.onRequest,
    required this.onCancel,
  });

  final VoidCallback onRequest, onCancel;

  @override
  Widget build(BuildContext context) => Row(
    textDirection: TextDirection.ltr,
    children: [
      Expanded(
        child: AppButton(
          label: 'Cancel',
          variant: AppButtonVariant.outlined,
          onPressed: onCancel,
        ),
      ),
      const SizedBox(width: 16),
      Expanded(
        child: AppButton(label: 'Request', onPressed: onRequest),
      ),
    ],
  );
}
