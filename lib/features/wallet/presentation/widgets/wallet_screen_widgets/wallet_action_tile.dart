import 'package:flutter/material.dart';
import 'package:nini/shared/widgets/app_icons/app_icon.dart';

class WalletActionTile extends StatelessWidget {
  const WalletActionTile({
    super.key,
    required this.label,
    required this.icon,
    this.onTap,
  });
  final String label, icon;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Material(
    color: Theme.of(context).colorScheme.surfaceContainerHighest,
    borderRadius: BorderRadius.circular(14),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 9),
        child: Column(
          children: [
            AppIcon(icon, size: 23),
            const SizedBox(height: 5),
            Text(
              label,
              maxLines: 1,
              style: const TextStyle(fontSize: 9),
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
            ),
          ],
        ),
      ),
    ),
  );
}
