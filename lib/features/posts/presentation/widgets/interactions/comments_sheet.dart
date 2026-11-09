
import 'package:flutter/material.dart';

import 'package:nini/core/theme/app_colors.dart';
import 'package:nini/core/theme/app_text_styles.dart';
import 'package:nini/shared/widgets/app_textfield/app_text_field.dart';

Future<void> openPostCommentsSheet(
    BuildContext context, {
      required String postId,
    }) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
        ),
        child: FractionallySizedBox(
          heightFactor: 0.85,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: SizedBox.expand(
                child: CommentsSheet(postId: postId),
              ),
            ),
          ),
        ),
      );
    },
  );
}

class CommentsSheet extends StatefulWidget {
  const CommentsSheet({
    super.key,
    required this.postId,
  });

  final String postId;

  @override
  State<CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<CommentsSheet> {
  final TextEditingController _commentController =
  TextEditingController();

  final ValueNotifier<List<({String name, String time, String text})>>
  _comments = ValueNotifier([
    (
    name: 'david.colo',
    time: '13h',
    text: 'Amazing work! 🔥😍',
    ),
    (
    name: 'david.colo',
    time: '13h',
    text: 'This is exactly what I was looking for! 🙌',
    ),
    (
    name: 'david.colo',
    time: '13h',
    text: 'Great idea! Keep it up! 🚀',
    ),
    (
    name: 'david.colo',
    time: '13h',
    text: 'Absolutely brilliant! ✨',
    ),
    (
    name: 'david.colo',
    time: '13h',
    text: 'Such a great experience! ❤️',
    ),
    (
    name: 'david.colo',
    time: '13h',
    text: 'Well done! 👏',
    ),
    (
    name: 'david.colo',
    time: '13h',
    text: 'This deserves more attention! 🌟',
    ),
    (
    name: 'david.colo',
    time: '13h',
    text: 'Wowwww! 😍🔥',
    ),
    (
    name: 'david.colo',
    time: '13h',
    text: "That's awesome!",
    ),
  ]);

  void _addComment() {
    final text = _commentController.text.trim();

    if (text.isEmpty) return;

    // Temporary local preview. No backend connection.
    _comments.value = [
      (name: 'you', time: 'now', text: text),
      ..._comments.value,
    ];

    _commentController.clear();
    FocusScope.of(context).unfocus();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _comments.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Light app -> pure black sheet.
    // Dark app -> pure white sheet.
    final isDark = theme.brightness == Brightness.dark;

    final background =
    isDark ? AppColors.white : AppColors.black;

    final foreground =
    isDark ? AppColors.black : AppColors.white;

    return Material(
      color: background,
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(24),
      ),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            const SizedBox(height: 10),

            // Sheet handle.
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: foreground.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(10),
              ),
            ),

            const SizedBox(height: 12),

            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'comments',
                style: AppTextStyles.bodyText.copyWith(
                  color: foreground,
                ),
                textAlign: TextAlign.right,
              ),
            ),

            const SizedBox(height: 12),

            // Comments list.
            Expanded(
              child: ValueListenableBuilder(
                valueListenable: _comments,
                builder: (context, comments, _) {
                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    itemCount: comments.length,
                    separatorBuilder: (_, __) =>
                    const SizedBox(height: 14),
                    itemBuilder: (context, index) {
                      final comment = comments[index];

                      return Row(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.end,
                              children: [
                                Align(alignment: Alignment.centerRight, child: Text(
                                  '${comment.time}  ${comment.name}',
                                  textAlign: TextAlign.right,
                                  style:
                                  AppTextStyles.caption.copyWith(
                                    color: foreground.withValues(
                                      alpha: 0.55,
                                    ),
                                  ),
                                )),
                                const SizedBox(height: 3),
                                Align(alignment: Alignment.centerRight, child: Text(
                                  comment.text,
                                  textAlign: TextAlign.right,
                                  style:
                                  AppTextStyles.bodyText.copyWith(
                                    color: foreground,
                                  ),
                                )),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          CircleAvatar(
                            radius: 18,
                            backgroundColor:
                            foreground.withValues(
                              alpha: 0.85,
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),

            Divider(
              height: 1,
              color: foreground.withValues(alpha: 0.2),
            ),

            // Comment input.
            Padding(
              padding:
              const EdgeInsets.fromLTRB(16, 10, 16, 12),
              child: Theme(
                data: theme.copyWith(
                  colorScheme:
                  theme.colorScheme.copyWith(
                    surface: background,
                    onSurface: foreground,
                  ),
                  inputDecorationTheme:
                  theme.inputDecorationTheme.copyWith(
                    filled: true,
                    fillColor: foreground.withValues(
                      alpha: 0.1,
                    ),
                    hintStyle:
                    AppTextStyles.bodyText.copyWith(
                      color: foreground.withValues(
                        alpha: 0.55,
                      ),
                    ),
                    border: OutlineInputBorder(
                      borderRadius:
                      BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                child: AppTextField(
                  controller: _commentController,
                  hint: 'Add a comment...',
                  textStyle:
                  AppTextStyles.bodyText.copyWith(
                    color: foreground,
                  ),
                  textAlign: TextAlign.right,
                  textDirection: TextDirection.ltr,
                  textInputAction:
                  TextInputAction.send,
                  onSubmitted: (_) => _addComment(),
                  suffixIcon: IconButton(
                    onPressed: _addComment,
                    tooltip: 'Add comment',
                    icon: Icon(
                      Icons.send_rounded,
                      color: foreground,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
