import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nini/core/localization/cart_strings.dart';
import 'package:nini/core/localization/order_information_strings.dart';
import 'package:nini/features/cart/domain/models/cart_item.dart';
import 'package:nini/features/cart/presentation/cubit/cart_cubit.dart';
import 'package:nini/features/cart/presentation/cubit/cart_state.dart';
import 'package:nini/features/cart/presentation/helpers/cart_format.dart';
import 'package:nini/features/cart/presentation/widgets/dialogs/cart_amount_dialog.dart';
import 'package:nini/features/create_post/domain/models/post_options.dart';
import 'package:nini/features/create_post/presentation/widgets/dialogs/address_dialog.dart';
import 'package:nini/features/create_post/presentation/widgets/dialogs/post_dialog.dart';
import 'package:nini/features/payment/domain/models/order_customer_details.dart';
import 'package:nini/features/payment/domain/models/payment_details.dart';
import 'package:nini/features/payment/presentation/pages/payment_gateway_screen.dart';
import 'package:nini/features/payment/presentation/pages/payment_screen.dart';
import 'package:nini/features/payment/presentation/widgets/order_information/order_information_actions.dart';
import 'package:nini/features/payment/presentation/widgets/order_information/order_information_fields.dart';
import 'package:nini/features/payment/presentation/widgets/order_information/order_information_header.dart';
import 'package:nini/features/payment/presentation/widgets/order_information/order_information_item.dart';
import 'package:nini/shared/widgets/app_toast/app_toast.dart';

/// Shared customer information step for selected product and service Cart items.
class OrderInformationScreen extends StatefulWidget {
  const OrderInformationScreen({super.key, this.successReturnLabel});
  final String? successReturnLabel;

  @override
  State<OrderInformationScreen> createState() => _OrderInformationScreenState();
}

class _OrderInformationScreenState extends State<OrderInformationScreen> {
  final _form = GlobalKey<FormState>();
  final _checkoutId = 'CHK-${DateTime.now().microsecondsSinceEpoch}';
  final _controllers = {
    for (final field in OrderCustomerField.values)
      field: TextEditingController(),
  };
  PostAddress? _mapAddress;
  bool _openingPayment = false;
  bool _gatewayOpen = false;

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _chooseAddress() async {
    final selected = await showPostDialog<AddressSelection>(
      context,
      AddressDialog(initial: _mapAddress),
    );
    if (!mounted || selected == null) return;
    _mapAddress = selected.selected;
    _controllers[OrderCustomerField.address]!.text = selected.selected.address;
  }

  Future<void> _editQuantity(CartItem item) async {
    final cart = context.read<CartCubit>();
    final amount = await showCartAmountDialog(
      context,
      value: item.quantity,
      wholeUnits: item.wholeUnits,
      maximum: item.maxQuantity,
    );
    if (amount != null && mounted) cart.updateQuantity(item.id, amount);
  }

  Future<void> _editCharges() async {
    final cart = context.read<CartCubit>();
    final amount = await showCartAmountDialog(
      context,
      value: cart.state.charges,
      allowZero: true,
      title: CartStrings.charges,
    );
    if (amount != null && mounted) cart.setCharges(amount);
  }

  bool _unchanged(CartState expected) {
    final current = context.read<CartCubit>().state;
    final selected = current.checkoutItems;
    return current.stage == CartStage.checkout &&
        !current.loading &&
        current.charges == expected.charges &&
        current.total == expected.total &&
        selected.length == expected.checkoutItems.length &&
        expected.checkoutItems.every(
          (item) => selected.any((entry) => identical(entry, item)),
        );
  }

  Future<String?> _openGateway(
    CartState expected,
    PaymentDetails details,
  ) async {
    if (!mounted || _gatewayOpen) return null;
    if (!_unchanged(expected)) {
      AppToast.warning(context, OrderInformationStrings.cartChanged);
      return null;
    }
    _gatewayOpen = true;
    try {
      return await Navigator.of(context).push<String>(
        MaterialPageRoute(
          builder: (_) => PaymentGatewayScreen(
            details: details,
            method: context.read<CartCubit>().state.method,
            successReturnLabel: widget.successReturnLabel,
          ),
        ),
      );
    } finally {
      _gatewayOpen = false;
    }
  }

  Future<void> _checkout() async {
    if (_openingPayment || !_form.currentState!.validate()) return;
    final cart = context.read<CartCubit>();
    final selected = cart.state;
    if (selected.loading || selected.checkoutItems.isEmpty) {
      AppToast.warning(context, OrderInformationStrings.emptyCheckout);
      return;
    }
    final customer = OrderCustomerDetails.fromValues({
      for (final entry in _controllers.entries) entry.key: entry.value.text,
    });
    final details = PaymentDetails(
      total: selected.total,
      summary: List.unmodifiable([
        (CartStrings.subtotal, cartMoney(selected.subtotal)),
        (CartStrings.discount, cartMoney(selected.discount)),
        (CartStrings.charges, cartMoney(selected.charges)),
      ]),
      address: customer.address,
      phone: customer.mobile,
      customer: customer,
      checkoutId: _checkoutId,
      items: List.unmodifiable(selected.checkoutItems),
    );
    FocusScope.of(context).unfocus();
    setState(() => _openingPayment = true);
    try {
      final orderId = await Navigator.of(context).push<String>(
        MaterialPageRoute(
          builder: (_) => PaymentScreen(
            details: details,
            initialMethod: selected.method,
            onMethodChanged: cart.setMethod,
            onConfirm: () => _openGateway(selected, details),
          ),
        ),
      );
      if (mounted && orderId != null) Navigator.of(context).pop(orderId);
    } finally {
      if (mounted) setState(() => _openingPayment = false);
    }
  }

  @override
  Widget build(BuildContext context) => BlocBuilder<CartCubit, CartState>(
    builder: (context, state) => Localizations.override(
      context: context,
      locale: const Locale('en'),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Scaffold(
          appBar: OrderInformationHeader(
            amount: cartMoney(state.total),
            onBack: () => Navigator.of(context).pop(),
            onCharges: _editCharges,
          ),
          body: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                child: Form(
                  key: _form,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final item in state.checkoutItems)
                        OrderInformationItem(
                          item: item,
                          onQuantity: () => _editQuantity(item),
                        ),
                      const Divider(height: 1),
                      OrderInformationFields(
                        controllers: _controllers,
                        onMap: _chooseAddress,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          bottomNavigationBar: OrderInformationActions(
            onCancel: () => Navigator.of(context).pop(),
            onCheckout: !_openingPayment && state.checkoutItems.isNotEmpty
                ? _checkout
                : null,
          ),
        ),
      ),
    ),
  );
}
