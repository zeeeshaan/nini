import 'package:flutter/material.dart';
import 'package:nini/core/constants/app_icons/app_icons.dart';
import 'package:nini/shared/widgets/app_icons/app_icon.dart';
import 'package:nini/features/team/domain/team_request.dart';
import 'package:nini/features/team/presentation/widgets/member_request/team_request_status_sheet.dart';
import 'package:nini/shared/widgets/app_button/app_button.dart';

class TeamRequestReviewActions extends StatelessWidget {
  const TeamRequestReviewActions({
    super.key,
    required this.request,
    required this.onStatus,
    required this.onCheckout,
    required this.onEdit,
  });

  final TeamRequest request;
  final VoidCallback onStatus, onCheckout, onEdit;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      TextButton.icon(
        onPressed: onStatus,
        icon: const AppIcon(AppIcons.chevronUp, size: 20),
        label: Text(
          TeamRequestStatusSheet.label(request.status),
          textAlign: TextAlign.right,
          textDirection: TextDirection.ltr,
        ),
      ),
      if (request.status == TeamRequestStatus.accepted)
        AppButton(label: 'Add payment / Checkout', onPressed: onCheckout)
      else if (request.status == TeamRequestStatus.declined ||
          request.status == TeamRequestStatus.cancelled)
        AppButton(label: 'Edit request', onPressed: onEdit),
    ],
  );
}
