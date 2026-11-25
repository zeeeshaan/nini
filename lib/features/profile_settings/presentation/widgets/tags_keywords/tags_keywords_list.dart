import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nini/core/constants/app_icons/app_icons.dart';
import 'package:nini/core/localization/strings/profile_settings_strings.dart';
import 'package:nini/core/theme/app_text_styles/app_text_styles.dart';
import 'package:nini/shared/models/post/post_item.dart';
import 'package:nini/shared/widgets/app_icons/app_icon.dart';

import '../../cubit/settings_query_cubit.dart';
import '../../helpers/open_settings_post.dart';
import '../../pages/posts_screen.dart';
import '../common/settings_empty_state.dart';
import '../common/settings_notice.dart';

class TagsKeywordsList extends StatelessWidget {
  const TagsKeywordsList({super.key, required this.posts});
  final List<PostItem> posts;
  @override
  Widget build(BuildContext context) => BlocBuilder<SettingsQueryCubit, String>(
    builder: (context, query) {
      final grouped = <String, List<PostItem>>{};
      for (final post in posts) {
        for (final tag in post.details.tags.toSet()) {
          if (tag.trim().isEmpty || !tag.toLowerCase().contains(query)) {
            continue;
          }
          grouped.putIfAbsent(tag, () => []).add(post);
        }
      }
      final tags = grouped.keys.toList()
        ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      if (tags.isEmpty) {
        return SettingsEmptyState(
          textAlign: TextAlign.center,
          title: query.isEmpty
              ? ProfileSettingsStrings.noTags
              : ProfileSettingsStrings.noResults,
          message: query.isEmpty
              ? ProfileSettingsStrings.tagsHelp
              : ProfileSettingsStrings.tryAnotherSearch,
          icon: AppIcons.tag,
        );
      }
      void openTag(String tag) => Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => PostsScreen(initialQuery: tag, tag: tag),
        ),
      );
      return Column(
        children: [
          const SettingsNotice(text: ProfileSettingsStrings.tagsNotice),
          Expanded(
            child: ListView.builder(
              itemCount: tags.length,
              itemBuilder: (context, index) {
                final tag = tags[index];
                return ListTile(
                  leading: IconButton(
                    tooltip: ProfileSettingsStrings.editPost,
                    icon: const AppIcon(AppIcons.edit, size: 22),
                    onPressed: () => grouped[tag]!.length == 1
                        ? openSettingsPost(
                            context,
                            grouped[tag]!.single,
                            edit: true,
                          )
                        : openTag(tag),
                  ),
                  title: Text(
                    tag,
                    textAlign: TextAlign.right,
                    style: AppTextStyles.body,
                    textDirection: TextDirection.ltr,
                  ),
                  subtitle: Text(
                    ProfileSettingsStrings.tagPosts(grouped[tag]!.length),
                    textAlign: TextAlign.right,
                    style: AppTextStyles.helper,
                    textDirection: TextDirection.ltr,
                  ),
                  onTap: () => openTag(tag),
                );
              },
            ),
          ),
        ],
      );
    },
  );
}
