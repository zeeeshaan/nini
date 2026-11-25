import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:nini/core/theme/app_text_styles/app_text_styles.dart';
import 'package:flutter/material.dart';

import 'package:nini/core/localization/app_string/app_string.dart';

/// The picker uses the device's emoji glyphs; the OS keyboard remains available.
class ChatEmojiPanel extends StatelessWidget {
  const ChatEmojiPanel({
    super.key,
    required this.controller,
    required this.height,
  });
  final TextEditingController controller;
  final double height;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SafeArea(
      top: false,
      child: EmojiPicker(
        textEditingController: controller,
        config: Config(
          height: height,
          locale: const Locale('en'),
          emojiTextStyle: AppTextStyles.emoji,
          emojiViewConfig: EmojiViewConfig(
            columns: 7,
            emojiSizeMax: AppTextStyles.emojiSize,
            backgroundColor: colors.surface,
            noRecents: const Text(
              AppStrings.noRecentEmoji,
              textDirection: TextDirection.ltr,
              textAlign: TextAlign.right,
            ),
          ),
          categoryViewConfig: CategoryViewConfig(
            initCategory: Category.SMILEYS,
            backgroundColor: colors.surface,
            iconColor: colors.onSurface.withValues(alpha: .5),
            iconColorSelected: colors.onSurface,
            indicatorColor: colors.onSurface,
            backspaceColor: colors.onSurface,
            dividerColor: Theme.of(context).dividerColor,
          ),
          bottomActionBarConfig: BottomActionBarConfig(
            showSearchViewButton: false,
            backgroundColor: colors.surface,
            buttonColor: colors.surface,
            buttonIconColor: colors.onSurface,
          ),
        ),
      ),
    );
  }
}
