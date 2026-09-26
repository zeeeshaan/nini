import 'package:flutter/foundation.dart';

import '../screens/post_details_screen.dart';

/// Posts published during this session, newest first. Held in memory only
/// for front-end testing: nothing is saved, so they disappear when the app
/// restarts.
class PostStore {
  PostStore._();

  static final ValueNotifier<List<PostDraft>> posts = ValueNotifier(const []);

  static void add(PostDraft post) => posts.value = [post, ...posts.value];
}
