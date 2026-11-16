import 'package:flutter/material.dart';
import 'package:nini/core/localization/persian_feature/persian_feature.dart';
import 'package:nini/core/responsiveness/app_responsiveness/app_responsiveness.dart';

import 'wallet_header.dart';

/// Keeps the card, form and bottom action aligned within the same content width.
class WalletPage extends StatelessWidget {
  const WalletPage({
    super.key,
    required this.title,
    required this.child,
    this.footer,
    this.bottomNote,
  });
  final String title;
  final Widget child;
  final Widget? footer, bottomNote;

  @override
  Widget build(BuildContext context) => PersianFeature(
    child: Scaffold(
      appBar: WalletHeader(title: title),
      body: SafeArea(
        top: false,
        bottom: footer == null,
        child: AppResponsiveBuilder(
          builder: (context, responsive) => Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: responsive.constrainedWidth.clamp(0, 430),
              ),
              child: CustomScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                    sliver: SliverToBoxAdapter(child: child),
                  ),
                  if (bottomNote != null)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(12, 24, 12, 12),
                          child: bottomNote,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: footer,
    ),
  );
}
