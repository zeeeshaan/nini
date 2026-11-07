import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nini/core/icons/app_icons.dart';
import 'package:nini/core/localization/app_strings.dart';
import 'package:nini/core/localization/provider_order_strings.dart';
import 'package:nini/core/localization/receipt_strings.dart';
import 'package:nini/core/theme/app_text_styles.dart';
import 'package:nini/features/cart/domain/policies/order_access.dart';
import 'package:nini/features/cart/presentation/cubit/cart_cubit.dart';
import 'package:nini/features/chat/presentation/helpers/open_order_conversation.dart';
import 'package:nini/features/order_cancellation/presentation/pages/order_cancellation_screen.dart';
import 'package:nini/features/payment/presentation/widgets/invoice_screen_widgets/order_invoice_content.dart';
import 'package:nini/features/payment/presentation/helpers/receipt_navigation.dart';
import 'package:nini/shared/widgets/app_icons/app_icon.dart';
import 'package:nini/shared/widgets/app_toast/app_toast.dart';

import '../widgets/provider_invoice_actions/provider_invoice_actions.dart';

class ProviderInvoiceScreen extends StatefulWidget {
  const ProviderInvoiceScreen({super.key, required this.orderId});
  final String orderId;
  @override
  State<ProviderInvoiceScreen> createState() => _ProviderInvoiceScreenState();
}

class _ProviderInvoiceScreenState extends State<ProviderInvoiceScreen> {
  bool _saving = false;
  Future<void> _update(Future<bool> Function() action, String message) async {
    if (_saving) return;
    setState(() => _saving = true);
    final saved = await action();
    if (!mounted) return;
    setState(() => _saving = false);
    if (saved) {
      AppToast.success(context, message);
    } else {
      AppToast.warning(context, ReceiptStrings.saveFailed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartCubit>();
    final order = cart.findOrder(widget.orderId);
    final allowed =
        order != null && OrderAccess.isProvider(order, cart.localUser.id);
    final contact = allowed
        ? orderChatContact(
            order,
            currentUserId: cart.localUser.id,
            asProvider: true,
          )
        : null;
    return PopScope(
      canPop: !_saving,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            tooltip: AppStrings.back,
            onPressed: _saving ? null : () => Navigator.of(context).maybePop(),
            icon: const AppIcon(AppIcons.back, size: 20),
          ),
          title: const Text(
            ReceiptStrings.invoice,
            style: AppTextStyles.pageTitle,
          ),
          centerTitle: false,
          actions: [
            if (allowed && OrderAccess.isBuyer(order, cart.localUser.id))
              TextButton(
                onPressed: _saving
                    ? null
                    : () => openSavedInvoice(context, order.id),
                child: const Text(ProviderOrderStrings.buyerInvoice),
              ),
            if (contact != null)
              IconButton(
                tooltip: ProviderOrderStrings.messageBuyer,
                icon: const AppIcon(AppIcons.send, size: 24),
                onPressed: _saving
                    ? null
                    : () => openOrderConversation(context, contact),
              ),
          ],
        ),
        body: allowed
            ? OrderInvoiceContent(order: order)
            : const Center(child: Text(ProviderOrderStrings.unavailable)),
        bottomNavigationBar: !allowed
            ? null
            : ProviderInvoiceActions(
                order: order,
                userId: cart.localUser.id,
                saving: _saving,
                onAccept: () => _update(
                  () => cart.acceptProviderOrder(order.id),
                  ProviderOrderStrings.accepted,
                ),
                onAdvance: () => _update(
                  () => cart.advanceProviderOrder(order.id),
                  ProviderOrderStrings.updated,
                ),
                onCancel: () => Navigator.of(context).push<void>(
                  MaterialPageRoute(
                    builder: (_) => OrderCancellationScreen(orderId: order.id),
                  ),
                ),
              ),
      ),
    );
  }
}
