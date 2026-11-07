import 'package:nini/features/payment/domain/models/dispute_attachment.dart';

/// Provider explanation, independent of a buyer's dispute or a bank refund.
class OrderCancellation {
  OrderCancellation({
    required this.providerId,
    required this.reason,
    required this.createdAt,
    List<DisputeAttachment> attachments = const [],
  }) : attachments = List.unmodifiable(attachments);
  final String providerId, reason;
  final DateTime createdAt;
  final List<DisputeAttachment> attachments;
  Map<String, dynamic> toJson() => {
    'providerId': providerId,
    'reason': reason,
    'createdAt': createdAt.toUtc().toIso8601String(),
    'attachments': attachments.map((item) => item.toJson()).toList(),
  };
  factory OrderCancellation.fromJson(Map<String, dynamic> json) =>
      OrderCancellation(
        providerId: json['providerId'] as String,
        reason: json['reason'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String).toLocal(),
        attachments: (json['attachments'] as List? ?? [])
            .map(
              (entry) => DisputeAttachment.fromJson(
                Map<String, dynamic>.from(entry as Map),
              ),
            )
            .toList(),
      );
}
