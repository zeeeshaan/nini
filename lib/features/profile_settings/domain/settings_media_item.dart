import 'package:hywork/shared/models/post/post_item.dart';

class SettingsMediaItem {
  const SettingsMediaItem({required this.post, required this.media});
  final PostItem post;
  final PostMedia media;

  static List<SettingsMediaItem> fromPosts(List<PostItem> posts) {
    final seen = <String>{};
    return [
      for (final post in posts)
        for (final media in post.media)
          if (seen.add('${media.source.name}:${media.path}'))
            SettingsMediaItem(post: post, media: media),
    ];
  }
}
