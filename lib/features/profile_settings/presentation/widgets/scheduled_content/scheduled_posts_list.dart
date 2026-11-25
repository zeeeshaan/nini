import 'package:flutter/material.dart';
import 'package:nini/core/constants/app_icons/app_icons.dart';
import 'package:nini/core/localization/strings/profile_settings_strings.dart';
import 'package:nini/core/theme/app_text_styles/app_text_styles.dart';
import 'package:nini/features/posts/presentation/widgets/media/post_media_view.dart';
import 'package:nini/features/post_detail/presentation/widgets/post_image_carousel/post_carousel_image.dart';
import 'package:nini/shared/models/post/post_item.dart';
import 'package:nini/shared/widgets/app_icons/app_icon.dart';

import '../../helpers/open_settings_post.dart';
import '../common/settings_empty_state.dart';
import '../common/settings_notice.dart';

class ScheduledPostsList extends StatelessWidget {
  const ScheduledPostsList({super.key, required this.posts});
  final List<PostItem> posts;
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final scheduled =
        posts
            .where((post) => post.details.schedule?.endsAt.isAfter(now) == true)
            .toList()
          ..sort(
            (a, b) => a.details.schedule!.startsAt.compareTo(
              b.details.schedule!.startsAt,
            ),
          );
    if (scheduled.isEmpty) {
      return const SettingsEmptyState(
        textAlign: TextAlign.center,
        title: ProfileSettingsStrings.noScheduled,
        message: ProfileSettingsStrings.scheduledHelp,
        icon: AppIcons.calendar,
      );
    }
    return Column(
      children: [
        const SettingsNotice(text: ProfileSettingsStrings.scheduleNotice),
        Expanded(
          child: ListView.separated(
            itemCount: scheduled.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final post = scheduled[index];
              final date = post.details.schedule!.startsAt;
              final locale = MaterialLocalizations.of(context);
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                leading: PopupMenuButton<bool>(
                  icon: const AppIcon(AppIcons.more, size: 22),
                  onSelected: (edit) =>
                      openSettingsPost(context, post, edit: edit),
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: false,
                      child: Text(
                        ProfileSettingsStrings.viewPost,
                        textDirection: TextDirection.ltr,
                        textAlign: TextAlign.right,
                      ),
                    ),
                    PopupMenuItem(
                      value: true,
                      child: Text(
                        ProfileSettingsStrings.editPost,
                        textDirection: TextDirection.ltr,
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
                trailing: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: SizedBox.square(
                    dimension: 64,
                    child: post.media.isEmpty
                        ? PostCarouselImage(path: post.imageAsset)
                        : PostMediaView(media: post.media.first),
                  ),
                ),
                title: Text(
                  '${locale.formatCompactDate(date)}\n${locale.formatTimeOfDay(TimeOfDay.fromDateTime(date))}',
                  textAlign: TextAlign.right,
                  style: AppTextStyles.body,
                  textDirection: TextDirection.ltr,
                ),
                subtitle: Text(
                  post.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: AppTextStyles.helper,
                  textDirection: TextDirection.ltr,
                ),
                onTap: () => openSettingsPost(context, post),
              );
            },
          ),
        ),
      ],
    );
  }
}
