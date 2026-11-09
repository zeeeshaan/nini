import 'package:nini/shared/models/post/post_item.dart';
import 'package:nini/shared/models/post/post_seller.dart';

class SavedPost {
  const SavedPost({
    required this.post,
    required this.savedAt,
    this.seller,
    this.isLocalPost = false,
  });

  final PostItem post;
  final PostSeller? seller;
  final DateTime savedAt;

  /// A post in the existing local Posts repository, not a remote seller record.
  final bool isLocalPost;

  SavedPost withPost(PostItem value) => SavedPost(
    post: value,
    seller: seller,
    savedAt: savedAt,
    isLocalPost: isLocalPost,
  );

  Map<String, dynamic> toJson() => {
    'post': post.toJson(),
    if (seller != null) 'seller': seller!.toJson(),
    'savedAt': savedAt.toUtc().toIso8601String(),
    'isLocalPost': isLocalPost,
  };

  factory SavedPost.fromJson(Map<String, dynamic> json) => SavedPost(
    post: PostItem.fromJson(Map<String, dynamic>.from(json['post'] as Map)),
    seller: json['seller'] == null
        ? null
        : PostSeller.fromJson(Map<String, dynamic>.from(json['seller'] as Map)),
    savedAt: DateTime.parse(json['savedAt'] as String).toLocal(),
    isLocalPost: json['isLocalPost'] as bool? ?? false,
  );
}
