import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nini/core/icons/app_icons.dart';
import 'package:nini/core/localization/strings/profile_settings_strings.dart';
import 'package:nini/core/responsiveness/app_responsiveness/app_responsiveness.dart';
import 'package:nini/features/posts/presentation/widgets/media/post_media_view.dart';
import 'package:nini/shared/models/post/post_item.dart';

import '../../../domain/settings_media_item.dart';
import '../../cubit/settings_query_cubit.dart';
import '../../helpers/open_settings_media.dart';
import '../common/settings_empty_state.dart';
import '../common/settings_notice.dart';
import 'media_actions_sheet.dart';

class MyMediaGrid extends StatelessWidget {
  const MyMediaGrid({super.key, required this.posts});
  final List<PostItem> posts;
  @override
  Widget build(BuildContext context) => BlocBuilder<SettingsQueryCubit, String>(
    builder: (context, query) {
      final media = SettingsMediaItem.fromPosts(posts)
          .where(
            (item) => '${item.media.name} ${item.post.title}'
                .toLowerCase()
                .contains(query),
          )
          .toList();
      if (media.isEmpty) {
        return SettingsEmptyState(
          title: query.isEmpty
              ? ProfileSettingsStrings.noMedia
              : ProfileSettingsStrings.noResults,
          message: query.isEmpty
              ? ProfileSettingsStrings.mediaHelp
              : ProfileSettingsStrings.tryAnotherSearch,
          icon: AppIcons.imageUnavailable,
        );
      }
      return AppResponsiveBuilder(
        builder: (context, responsive) {
          final textScale = (MediaQuery.textScalerOf(context).scale(14) / 14)
              .clamp(1.0, double.infinity);
          final columns = (responsive.width / (100 * textScale)).floor().clamp(
            1,
            responsive.gridColumns,
          );
          final direction = Directionality.of(context);
          return Directionality(
            textDirection: TextDirection.ltr,
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Directionality(
                    textDirection: direction,
                    child: const SettingsNotice(
                      text: ProfileSettingsStrings.mediaNotice,
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.all(12),
                  sliver: SliverGrid.builder(
                    itemCount: media.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      crossAxisSpacing: 2,
                      mainAxisSpacing: 2,
                    ),
                    itemBuilder: (context, index) => Semantics(
                      button: true,
                      label: media[index].media.name,
                      child: InkWell(
                        onTap: () => openSettingsMedia(context, media[index]),
                        onLongPress: () =>
                            showSettingsMediaActions(context, media[index]),
                        child: PostMediaView(media: media[index].media),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}
