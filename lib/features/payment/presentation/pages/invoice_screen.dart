import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nini/core/icons/app_icons.dart';
import 'package:nini/core/localization/app_string/app_string.dart';
import 'package:nini/core/localization/strings/provider_order_strings.dart';
import 'package:nini/core/localization/strings/receipt_strings.dart';
import 'package:nini/core/theme/app_text_styles.dart';
import 'package:nini/features/cart/domain/policies/order_access.dart';
import 'package:nini/features/cart/domain/models/cart_order_status.dart';
import 'package:nini/features/cart/presentation/cubit/cart_cubit.dart';
import 'package:nini/features/chat/presentation/helpers/open_order_conversation.dart';
import 'package:nini/features/payment/presentation/pages/dispute_screen.dart';
import 'package:nini/features/payment/presentation/widgets/invoice/order_invoice_content.dart';
import 'package:nini/features/provider_invoice/presentation/helpers/open_provider_invoice.dart';
import 'package:nini/shared/widgets/app_button/app_button.dart';
import 'package:nini/shared/widgets/app_icons/app_icon.dart';
import 'package:nini/shared/widgets/app_toast/app_toast.dart';

class InvoiceScreen extends StatefulWidget {
  const InvoiceScreen({super.key, required this.orderId});
  final String orderId;
  @override
  State<InvoiceScreen> createState() => _InvoiceScreenState();
}

class _InvoiceScreenState extends State<InvoiceScreen> {
  bool _saving = false;
  Future<void> _confirm() async {
    if (_saving) return;
    final agreed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          ReceiptStrings.confirmCompletion,
          textAlign: TextAlign.right,
          textDirection: TextDirection.ltr,
        ),
        content: const Text(
          ReceiptStrings.confirmCompletionHelp,
          textAlign: TextAlign.right,
          textDirection: TextDirection.ltr,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              AppStrings.cancel,
              textDirection: TextDirection.ltr,
              textAlign: TextAlign.right,
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              ReceiptStrings.confirm,
              textDirection: TextDirection.ltr,
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
    if (!mounted || agreed != true) return;
    setState(() => _saving = true);
    final saved = await context.read<CartCubit>().confirmPaidOrder(
      widget.orderId,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (saved) {
      AppToast.success(context, ReceiptStrings.completed);
      Navigator.of(context).pop();
    } else {
      AppToast.warning(context, ReceiptStrings.saveFailed);
    }
  }

  void _problem() => Navigator.of(context).push<void>(
    MaterialPageRoute(builder: (_) => DisputeScreen(orderId: widget.orderId)),
  );

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartCubit>();
    final order = cart.findOrder(widget.orderId);
    final allowed =
        order != null &&
        order.isPaidReceipt &&
        OrderAccess.isBuyer(order, cart.localUser.id);
    final canConfirm =
        allowed && OrderAccess.canComplete(order, cart.localUser.id);
    final canManageSale =
        allowed && OrderAccess.isProvider(order, cart.localUser.id);
    final canDispute =
        allowed &&
        (order.dispute != null ||
            OrderAccess.canDispute(order, cart.localUser.id));
    final contact = allowed
        ? orderChatContact(
            order,
            currentUserId: cart.localUser.id,
            asProvider: false,
          )
        : null;
    return PopScope(
      canPop: !_saving,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Align(
            alignment: Alignment.centerRight,
            child: const Text(
              ReceiptStrings.invoice,
              style: AppTextStyles.screenTitle,
              textAlign: TextAlign.right,
              textDirection: TextDirection.ltr,
            ),
          ),
          centerTitle: false,
          actions: [
            if (canManageSale)
              TextButton(
                onPressed: _saving
                    ? null
                    : () => openProviderInvoice(context, order.id),
                child: const Text(
                  ProviderOrderStrings.manageSale,
                  textDirection: TextDirection.ltr,
                  textAlign: TextAlign.right,
                ),
              ),
            if (contact != null)
              IconButton(
                tooltip: ProviderOrderStrings.messageProvider,
                icon: const AppIcon(AppIcons.send, size: 24),
                onPressed: _saving
                    ? null
                    : () => openOrderConversation(context, contact),
              ),
            if (canDispute)
              IconButton(
                tooltip: ReceiptStrings.problem,
                icon: const AppIcon(AppIcons.more, size: 20),
                onPressed: _saving ? null : _problem,
              ),

            IconButton(
              tooltip: AppStrings.back,
              onPressed: _saving
                  ? null
                  : () => Navigator.of(context).maybePop(),
              icon: const AppIcon(AppIcons.backRight, size: 20),
            ),
          ],
        ),
        body: allowed
            ? OrderInvoiceContent(
                order: order,
                statusHint:
                    order.status == CartOrderStatus.paid &&
                        order.provider != null
                    ? ProviderOrderStrings.awaitingProvider
                    : !canConfirm &&
                          OrderAccess.canDispute(order, cart.localUser.id)
                    ? ProviderOrderStrings.awaitingFulfillment
                    : null,
              )
            : const Center(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    ReceiptStrings.unavailable,
                    textAlign: TextAlign.right,
                    textDirection: TextDirection.ltr,
                  ),
                ),
              ),
        bottomNavigationBar: !allowed
            ? null
            : SafeArea(
                top: false,
                child: Center(
                  heightFactor: 1,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: AppButton(
                              label: order.dispute == null
                                  ? ReceiptStrings.problem
                                  : ReceiptStrings.viewDispute,
                              variant: AppButtonVariant.outlined,
                              onPressed: !_saving && canDispute
                                  ? _problem
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: AppButton(
                              label: canConfirm
                                  ? ReceiptStrings.confirm
                                  : order.status?.label ??
                                        ReceiptStrings.confirm,
                              isLoading: _saving,
                              onPressed: canConfirm && !_saving
                                  ? _confirm
                                  : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
