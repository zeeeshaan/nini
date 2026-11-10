
import 'package:flutter/material.dart';

import 'package:nini/core/responsiveness/app_responsiveness/app_responsiveness.dart';
import 'package:nini/core/theme/app_text_styles.dart';
import 'package:nini/shared/widgets/app_textfield/app_text_field.dart';

import 'create_team.dart';

class MyTeamsScreen extends StatelessWidget {
  const MyTeamsScreen({
    super.key,
    this.onCreateTeam,
    this.onSearchChanged,
    this.emptyImageAsset = 'assets/teamimg.png',
  });

  final VoidCallback? onCreateTeam;
  final ValueChanged<String>? onSearchChanged;
  final String emptyImageAsset;

  void _openCreateTeam(BuildContext context) {
    if (onCreateTeam != null) {
      onCreateTeam!();
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const CreateTeamScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          tooltip: 'Create team',
          onPressed: () => _openCreateTeam(context),
          icon: const Icon(Icons.add, size: 28),
        ),
        title: Align(
          alignment: Alignment.centerRight,
          child: Text(
            'MyTeam',
            textAlign: TextAlign.right,
            style: AppTextStyles.bodyText.copyWith(
              color: theme.colorScheme.onSurface,
              fontSize: 24,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Back',
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
      body: AppResponsiveBuilder(
        builder: (context, responsive) {
          final imageWidth = responsive.adaptive(
            compact: 210.0,
            medium: 250.0,
            expanded: 280.0,
          );

          return SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: responsive.isCompact
                      ? double.infinity
                      : 720,
                ),
                child: ListView(
                  padding: EdgeInsets.symmetric(
                    horizontal: responsive.horizontalPadding,
                  ),
                  children: [
                    const SizedBox(height: 16),

                    // Search field.
                    AppTextField(
                      hint: 'Search',
                      textAlign: TextAlign.right,
                      textDirection: TextDirection.rtl,
                      textStyle: AppTextStyles.bodyText.copyWith(
                        color: theme.colorScheme.onSurface,
                      ),
                      onChanged: onSearchChanged,
                      suffixIcon: Icon(
                        Icons.search,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),

                    const SizedBox(height: 48),

                    // Empty team illustration.
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset(
                            emptyImageAsset,
                            width: imageWidth,
                            fit: BoxFit.contain,
                          ),

                          const SizedBox(height: 12),

                          Text(
                            "You don't have a team yet",
                            textAlign: TextAlign.center,
                            style: AppTextStyles.bodyText.copyWith(
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
