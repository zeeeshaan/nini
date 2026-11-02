// dart format width=100
import 'package:flutter/material.dart';
import 'package:nini/core/localization/cart_strings.dart';

import '../../cubit/cart_state.dart';

class CartTabs extends StatelessWidget {
  const CartTabs({super.key, required this.selected, required this.onSelected});
  final CartTab selected;
  final ValueChanged<CartTab> onSelected;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    const labels = [CartStrings.cart, CartStrings.history, CartStrings.sales];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
      child: Column(
        children: [
          Row(
            textDirection: TextDirection.ltr,
            children: [
              for (final tab in CartTab.values)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Semantics(
                      selected: selected == tab,
                      button: true,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(28),
                        onTap: () => onSelected(tab),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(28),
                            color: selected == tab ? colors.onSurface : colors.surface,
                          ),
                          child: Text(
                            labels[tab.index],
                            textAlign: TextAlign.right,
                            textDirection: TextDirection.rtl,
                            style: TextStyle(
                              fontSize: 12,
                              color: selected == tab ? colors.surface : colors.onSurface,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 40,
              height: 3,
              decoration: BoxDecoration(
                color: Theme.of(context).dividerColor,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Center(
                child: Container(
                  width: 16,
                  height: 3,
                  decoration: BoxDecoration(
                    color: colors.onSurface,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
