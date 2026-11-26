import 'package:flutter/material.dart';
import 'package:hywork/shared/models/post/post_item.dart';

import '../common/home_post_pricing.dart';

class HomeProductPrice extends StatelessWidget {
  const HomeProductPrice({super.key, required this.post});

  final PostItem post;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      child: HomePostPricing(post: post),
    );
  }
}
