import 'dispute_attachment.dart';

class OrderDispute {
  OrderDispute({
    required this.id,
    required this.description,
    required this.createdAt,
    List<DisputeAttachment> attachments = const [],
  }) : attachments = List.unmodifiable(attachments);
  final String id, description;
  final DateTime createdAt;
  final List<DisputeAttachment> attachments;
  Map<String, dynamic> toJson() => {
    'id': id,
    'description': description,
    'createdAt': createdAt.toUtc().toIso8601String(),
    'attachments': attachments.map((item) => item.toJson()).toList(),
  };
  factory OrderDispute.fromJson(Map<String, dynamic> json) => OrderDispute(
    id: json['id'] as String,
    description: json['description'] as String,
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
