import 'package:flutter/material.dart';

import 'package:nini/core/constants/app_icons/app_icons.dart';
import 'package:nini/core/localization/strings/search_strings.dart';
import 'package:nini/core/theme/app_text_styles/app_text_styles.dart';
import 'package:nini/shared/widgets/app_button/app_button.dart';
import 'package:nini/shared/widgets/app_icons/app_icon.dart';
import 'package:nini/shared/widgets/app_logo/app_logo.dart';

class SearchEmptyState extends StatelessWidget {
  const SearchEmptyState({
    super.key,
    required this.onReset,
    this.textAlign = TextAlign.right,
  });

  final VoidCallback onReset;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ExcludeSemantics(
                child: SizedBox.square(
                  dimension: 104,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: colors.surfaceContainerLow,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: AppLogo(size: 52, color: colors.onSurface),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: colors.primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: colors.surface, width: 3),
                          ),
                          child: AppIcon(
                            AppIcons.search,
                            size: 20,
                            color: colors.onPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: Text(
                  SearchStrings.noResults,
                  textDirection: TextDirection.ltr,
                  textAlign: textAlign,
                  style: AppTextStyles.heading.copyWith(
                    fontWeight: AppTextStyles.semiBold,
                    color: colors.onSurface,
                    height: 1.3,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: Text(
                  SearchStrings.tryAnotherQuery,
                  textDirection: TextDirection.ltr,
                  textAlign: textAlign,
                  style: AppTextStyles.body.copyWith(
                    color: colors.onSurface.withValues(alpha: .6),
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 240),
                child: AppButton(
                  label: SearchStrings.showAll,
                  onPressed: onReset,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
