import 'package:flutter/material.dart';
import 'package:nini/core/localization/app_string/app_string.dart';
import 'package:nini/core/localization/strings/provider_order_strings.dart';
import 'package:nini/features/cart/domain/models/cart_order.dart';
import 'package:nini/features/cart/domain/models/cart_order_status.dart';
import 'package:nini/features/cart/domain/policies/order_access.dart';
import 'package:nini/shared/widgets/app_button/app_button.dart';

class ProviderInvoiceActions extends StatelessWidget {
  const ProviderInvoiceActions({
    super.key,
    required this.order,
    required this.userId,
    required this.saving,
    required this.onAccept,
    required this.onCancel,
    required this.onAdvance,
  });
  final CartOrder order;
  final String userId;
  final bool saving;
  final VoidCallback onAccept, onCancel, onAdvance;
  @override
  Widget build(BuildContext context) {
    final accept = OrderAccess.canAccept(order, userId);
    final next = OrderAccess.nextProviderStatus(order, userId);
    final label = accept
        ? ProviderOrderStrings.accept
        : switch (next) {
            CartOrderStatus.preparing => ProviderOrderStrings.startPreparing,
            CartOrderStatus.shipped => ProviderOrderStrings.markShipped,
            CartOrderStatus.scheduled => ProviderOrderStrings.schedule,
            CartOrderStatus.inProgress => ProviderOrderStrings.startService,
            _ => order.status?.label ?? '',
          };
    return SafeArea(
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
                    label: AppStrings.cancel,
                    variant: AppButtonVariant.outlined,
                    onPressed: !saving && OrderAccess.canCancel(order, userId)
                        ? onCancel
                        : null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: AppButton(
                    label: label,
                    isLoading: saving,
                    onPressed: saving
                        ? null
                        : accept
                        ? onAccept
                        : next != null
                        ? onAdvance
                        : null,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
