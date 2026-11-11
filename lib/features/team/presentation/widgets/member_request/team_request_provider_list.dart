import 'package:flutter/material.dart';
import 'package:nini/core/theme/app_text_styles.dart';
import 'package:nini/features/cart/presentation/helpers/cart_format.dart';
import 'package:nini/features/team/domain/team_request.dart';
import 'package:nini/features/team/presentation/widgets/member_request/team_request_provider_card.dart';
import 'package:nini/features/team/presentation/widgets/member_request/team_request_quantity.dart';

class TeamRequestProviderList extends StatelessWidget {
  const TeamRequestProviderList({
    super.key,
    required this.request,
    this.onQuantityChanged,
  });

  final TeamRequest request;
  final void Function(String providerId, int quantity)? onQuantityChanged;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (var index = 0; index < request.providers.length; index++) ...[
        if (index > 0)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(height: 1),
          ),
        TeamRequestProviderCard(request: request.providers[index]),
        const SizedBox(height: 12),
        if (onQuantityChanged != null)
          TeamRequestQuantity(
            quantity: request.providers[index].quantity,
            unit: request.providers[index].post.details.unit?.label ?? 'عدد',
            onChanged: (value) =>
                onQuantityChanged!(request.providers[index].provider.id, value),
          )
        else
          Text(
            '${cartQuantity(request.providers[index].quantity)} ${request.providers[index].post.details.unit?.label ?? 'عدد'}',
            textAlign: TextAlign.right,
            style: AppTextStyles.bodyBold,
          ),
      ],
    ],
  );
}
