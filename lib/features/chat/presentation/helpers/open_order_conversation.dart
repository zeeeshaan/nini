import 'package:flutter/material.dart';
import 'package:nini/features/cart/domain/models/cart_order.dart';
import 'package:nini/shared/models/post/post_seller.dart';

import 'open_seller_conversation.dart';

/// Uses participant IDs, never a name or avatar comparison.
PostSeller? orderChatContact(
  CartOrder order, {
  required String currentUserId,
  required bool asProvider,
}) {
  PostSeller? contact;
  if (asProvider) {
    final buyerId = order.customerId;
    if (buyerId == null || buyerId.isEmpty || buyerId == 'local-customer') {
      return null;
    }
    final name = order.customer?.fullName.trim() ?? '';
    final buyer = order.buyer?.id == buyerId ? order.buyer : null;
    if (buyer == null && name.isEmpty) return null;
    contact = PostSeller(
      id: buyerId,
      name: buyer?.name.isNotEmpty == true ? buyer!.name : name,
      avatarAsset: buyer?.avatarAsset ?? '',
      location: buyer?.location.isNotEmpty == true
          ? buyer!.location
          : order.customer?.city ?? '',
      bio: buyer?.bio ?? '',
    );
  } else {
    contact = order.provider;
    if (contact == null) {
      final sellers = {
        for (final item in order.items)
          if (item.seller != null) item.seller!.id: item.seller!,
      };
      if (sellers.length == 1) contact = sellers.values.single;
    }
  }
  if (contact == null || contact.id.isEmpty || contact.id == currentUserId) {
    return null;
  }
  return contact;
}

void openOrderConversation(BuildContext context, PostSeller contact) =>
    openSellerConversation(context, contact);
