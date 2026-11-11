import 'package:nini/shared/models/post/post_item.dart';
import 'package:nini/shared/models/post/post_seller.dart';

/// The chosen service and quantity for one provider, keyed by provider ID.
class TeamProviderSelection {
  const TeamProviderSelection({
    required this.post,
    required this.provider,
    this.quantity = 100,
  });

  final PostItem post;
  final PostSeller provider;
  final int quantity;

  TeamProviderSelection withQuantity(int value) =>
      TeamProviderSelection(post: post, provider: provider, quantity: value);
}
