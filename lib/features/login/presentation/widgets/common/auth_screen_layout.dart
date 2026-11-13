import 'dart:math' as math;

import 'package:nini/core/theme/app_text_styles.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nini/core/animation/screen_entrance.dart';
import 'package:nini/core/animation/staggered_entrance.dart';
import 'package:nini/core/localization/persian_feature/persian_feature.dart';
import 'package:nini/core/theme/app_theme.dart';
import 'package:nini/shared/widgets/app_button/app_button.dart';

/// Common responsive composition for the phone and OTP entry screens.
class AuthScreenLayout extends StatelessWidget {
  const AuthScreenLayout({
    super.key,
    required this.illustration,
    required this.title,
    required this.content,
    required this.buttonLabel,
    required this.onContinue,
    this.illustrationScale = 1,
    this.actions,
    this.actionsBelowContent = false,
  });

  final String illustration, title, buttonLabel;
  final Widget content;
  final VoidCallback? onContinue;
  final double illustrationScale;
  final Widget? actions;
  final bool actionsBelowContent;

  @override
  Widget build(BuildContext context) => Theme(
    // The entry-screen design stays black regardless of the main app theme.
    data: AppTheme.dark,
    child: AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppTheme.dark.appBarTheme.systemOverlayStyle!,
      child: PersianFeature(
        child: ScreenEntrance(
          child: Scaffold(
            body: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final short = constraints.maxHeight < 500;
                  // Reserve space for the form and action on smaller phones.
                  final artHeight = math
                      .min(
                        constraints.maxHeight * (short ? .2 : .46),
                        math.max(64.0, constraints.maxHeight - 330),
                      )
                      .clamp(64.0, 360.0)
                      .toDouble();
                  return SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: 430,
                            minHeight: math.max(0, constraints.maxHeight - 36),
                          ),
                          child: Column(
                            mainAxisAlignment: actionsBelowContent
                                ? MainAxisAlignment.start
                                : MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  StaggeredEntrance(
                                    index: 0,
                                    child: SizedBox(
                                      height: artHeight,
                                      child: Center(
                                        child: Image.asset(
                                          illustration,
                                          height: artHeight * illustrationScale,
                                          fit: BoxFit.contain,
                                          excludeFromSemantics: true,
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: short ? 12 : 24),
                                  StaggeredEntrance(
                                    index: 1,
                                    child: Text(
                                      title,
                                      textAlign: TextAlign.right,
                                      textDirection: TextDirection.rtl,
                                      style: AppTextStyles.authTitle,
                                    ),
                                  ),
                                  SizedBox(height: short ? 20 : 36),
                                  StaggeredEntrance(index: 2, child: content),
                                ],
                              ),
                              Padding(
                                padding: EdgeInsets.only(
                                  top: actionsBelowContent || short ? 16 : 24,
                                ),
                                child: StaggeredEntrance(
                                  index: 3,
                                  child:
                                      actions ??
                                      AppButton(
                                        label: buttonLabel,
                                        onPressed: onContinue,
                                        height: 56,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
