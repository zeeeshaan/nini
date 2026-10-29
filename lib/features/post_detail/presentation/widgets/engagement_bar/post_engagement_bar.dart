import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:nini/core/icons/app_icons.dart';
import 'package:nini/core/localization/app_strings.dart';
import 'package:nini/features/post_detail/presentation/cubit/post_detail_cubit.dart';
import 'package:nini/shared/widgets/app_icons/app_icon.dart';

class PostEngagementBar extends StatelessWidget {
  const PostEngagementBar({
    super.key,
    this.onCommentsPressed,
    this.onSharePressed,
    this.showSampleMetrics = true,
  });

  final VoidCallback? onCommentsPressed;
  final VoidCallback? onSharePressed;
  final bool showSampleMetrics;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PostDetailCubit, PostDetailState>(
      buildWhen: (previous, current) =>
          previous.isLiked != current.isLiked ||
          previous.isBookmarked != current.isBookmarked,
      builder: (context, state) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 370;

            final iconSize = compact ? 25.0 : 29.0;
            final textSize = compact ? 12.0 : 12.0;
            final itemSpacing = compact ? 9.0 : 12.0;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: SizedBox(
                height: 48,
                child: Row(
                  children: [
                    // Keep the rating on the left, as in the original design.
                    if (showSampleMetrics)
                      Semantics(
                        label: AppStrings.rating,
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.star, size: 30),
                            SizedBox(width: 3),
                            Text(
                              '۴٫۵',
                              textDirection: TextDirection.rtl,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Critical: creates the large empty
                    // space shown in the Figma design.
                    const Spacer(),

                    // Actions stay grouped at the trailing edge.
                    Flexible(
                      fit: FlexFit.loose,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _PostAction(
                              label: state.isBookmarked
                                  ? AppStrings.removeBookmark
                                  : AppStrings.bookmark,
                              icon: AppIcon(
                                AppIcons.bookmark,
                                size: iconSize,
                                selected: state.isBookmarked,
                              ),
                              isToggled: state.isBookmarked,
                              count: showSampleMetrics
                                  ? '782'
                                  : state.isBookmarked
                                  ? '1'
                                  : '0',
                              textSize: textSize,
                              onTap: () {
                                context
                                    .read<PostDetailCubit>()
                                    .toggleBookmark();
                              },
                            ),

                            SizedBox(width: itemSpacing),

                            _PostAction(
                              label: AppStrings.comments,
                              icon: Icon(
                                CupertinoIcons.chat_bubble,
                                size: iconSize,
                              ),
                              count: showSampleMetrics ? '886' : '0',
                              textSize: textSize,
                              onTap: onCommentsPressed,
                            ),

                            SizedBox(width: itemSpacing),

                            _PostAction(
                              label: AppStrings.share,
                              icon: AppIcon(AppIcons.share, size: iconSize),
                              count: showSampleMetrics ? '350' : '0',
                              textSize: textSize,
                              onTap: onSharePressed,
                            ),

                            SizedBox(width: itemSpacing),

                            _PostAction(
                              label: state.isLiked
                                  ? AppStrings.unlike
                                  : AppStrings.like,
                              icon: AppIcon(
                                AppIcons.heart,
                                size: iconSize,
                                selected: state.isLiked,
                              ),
                              isToggled: state.isLiked,
                              count: showSampleMetrics
                                  ? '۴۵ هزار'
                                  : state.isLiked
                                  ? '1'
                                  : '0',
                              textSize: textSize,
                              onTap: () {
                                context.read<PostDetailCubit>().toggleLike();
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _PostAction extends StatelessWidget {
  const _PostAction({
    required this.label,
    required this.icon,
    required this.count,
    required this.textSize,
    this.onTap,
    this.isToggled,
  });

  final String label;
  final Widget icon;
  final String count;
  final double textSize;
  final VoidCallback? onTap;
  final bool? isToggled;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      toggled: isToggled,
      child: Tooltip(
        message: label,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                icon,
                const SizedBox(width: 4),
                Text(
                  AppStrings.persianDigits(count),
                  textDirection: TextDirection.rtl,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: textSize,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
