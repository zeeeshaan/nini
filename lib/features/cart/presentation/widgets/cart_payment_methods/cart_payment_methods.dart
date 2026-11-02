// dart format width=100
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../domain/models/payment_method.dart';

class CartPaymentMethods extends StatelessWidget {
  const CartPaymentMethods({super.key, required this.selected, required this.onSelected});
  final PaymentMethod selected;
  final ValueChanged<PaymentMethod> onSelected;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (final method in PaymentMethod.values)
        Padding(
          padding: const EdgeInsets.only(bottom: 9),
          child: Semantics(
            button: true,
            selected: method == selected,
            label: method.label,
            child: InkWell(
              key: ValueKey('payment-${method.name}'),
              borderRadius: BorderRadius.circular(12),
              onTap: () => onSelected(method),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                constraints: const BoxConstraints(minHeight: 72),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Theme.of(context).colorScheme.onSurface,
                          width: 2,
                        ),
                      ),
                      child: method == selected
                          ? DecoratedBox(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            )
                          : null,
                    ),
                    const Spacer(),
                    SvgPicture.asset(
                      method.asset,
                      width: 48,
                      height: 48,
                      semanticsLabel: method.label,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
    ],
  );
}
