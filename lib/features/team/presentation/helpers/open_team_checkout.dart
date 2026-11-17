import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nini/core/localization/strings/receipt_strings.dart';
import 'package:nini/features/cart/domain/models/cart_snapshot.dart';
import 'package:nini/features/cart/domain/repositories/cart_repository.dart';
import 'package:nini/features/cart/presentation/cubit/cart_cubit.dart';
import 'package:nini/features/payment/presentation/pages/order_information_screen.dart';
import 'package:nini/features/post_detail/presentation/helpers/post_cart_item.dart';
import 'package:nini/features/team/domain/team_request.dart';

/// Reuses the existing payment flow with a memory-only cart for this UI preview.
Future<String?> openTeamCheckout(
  BuildContext context,
  TeamRequest request,
) async {
  if (request.status != TeamRequestStatus.accepted) return null;
  final items = request.providers.map((selection) {
    final item = postCartItem(selection.post, seller: selection.provider);
    return item?.withQuantity(selection.quantity);
  }).toList();
  if (items.isEmpty ||
      items.any((item) => item == null || !item.accepts(item.quantity))) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'A selected service has no valid price or quantity.',
          textAlign: TextAlign.right,
          textDirection: TextDirection.ltr,
        ),
      ),
    );
    return null;
  }
  final cart = CartCubit(
    MemoryCartRepository(CartSnapshot(items: items.nonNulls.toList())),
  );
  try {
    await cart.load();
    cart.checkout();
    if (!context.mounted) return null;
    final navigatorKey = GlobalKey<NavigatorState>();
    return await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (checkoutContext) => BlocProvider.value(
          value: cart,
          child: NavigatorPopHandler<String>(
            onPopWithResult: (result) => navigatorKey.currentState!.pop(result),
            child: Navigator(
              key: navigatorKey,
              onGenerateRoute: (_) {
                final route = _TeamCheckoutEntryRoute(
                  onClose: (result) =>
                      Navigator.of(checkoutContext).pop(result),
                );
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (route.isActive) route.attachExit();
                });
                return route;
              },
            ),
          ),
        ),
      ),
    );
  } finally {
    await cart.close();
  }
}

/// A local-history entry intercepts the existing form's pop calls while keeping
/// the first nested route alive until its preview host closes.
class _TeamCheckoutEntryRoute extends MaterialPageRoute<String> {
  _TeamCheckoutEntryRoute({required this.onClose})
    : super(
        builder: (_) => const OrderInformationScreen(
          successReturnLabel: ReceiptStrings.backToMyTeam,
        ),
      );

  final ValueChanged<String?> onClose;
  String? _result;

  void attachExit() => addLocalHistoryEntry(
    LocalHistoryEntry(
      impliesAppBarDismissal: false,
      onRemove: () => onClose(_result),
    ),
  );

  @override
  bool didPop(String? result) {
    _result = result;
    return super.didPop(result);
  }
}
