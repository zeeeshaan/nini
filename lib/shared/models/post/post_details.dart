import 'package:nini/shared/models/post/post_attributes.dart';
import 'package:nini/shared/models/post/post_unit.dart';

export 'package:nini/shared/models/post/post_attributes.dart';
export 'package:nini/shared/models/post/post_unit.dart';

/// Typed details for presentation. Legacy metadata remains lossless at the JSON
/// boundary, including fields not yet consumed by the app.
class PostDetails {
  const PostDetails({
    this.caption = '',
    this.captionDelta = const [],
    this.tags = const [],
    this.address,
    this.schedule,
    this.features = const [],
    this.warehouseStock = '',
    this.discount = '',
    this.unit,
    this.altTexts = const {},
  }) : _serialized = null;

  const PostDetails._({
    required this.caption,
    required this.captionDelta,
    required this.tags,
    required this.address,
    required this.schedule,
    required this.features,
    required this.warehouseStock,
    required this.discount,
    required this.unit,
    required this.altTexts,
    required Map<String, dynamic> this._serialized,
  });

  final String caption, warehouseStock, discount;
  final PostUnit? unit;
  final List<Map<String, dynamic>> captionDelta;
  final List<String> tags;
  final PostAddress? address;
  final PostSchedule? schedule;
  final List<PostFeature> features;
  final Map<String, String> altTexts;
  final Map<String, dynamic>? _serialized;

  factory PostDetails.fromJson(Map<String, dynamic> json) => PostDetails._(
    caption: json['caption'] as String? ?? '',
    captionDelta: List.unmodifiable(
      (json['captionDelta'] as List? ?? []).map(
        (entry) => Map<String, dynamic>.unmodifiable(
          Map<String, dynamic>.from(entry as Map),
        ),
      ),
    ),
    tags: List<String>.unmodifiable(
      (json['tags'] as List? ?? []).cast<String>(),
    ),
    address: json['address'] == null
        ? null
        : PostAddress.fromJson(
            Map<String, dynamic>.from(json['address'] as Map),
          ),
    schedule: json['schedule'] == null
        ? null
        : PostSchedule.fromJson(
            Map<String, dynamic>.from(json['schedule'] as Map),
          ),
    features: List.unmodifiable(
      (json['features'] as List? ?? []).map(
        (entry) =>
            PostFeature.fromJson(Map<String, dynamic>.from(entry as Map)),
      ),
    ),
    warehouseStock: json['warehouseStock'] as String? ?? '',
    discount: json['discount']?.toString() ?? '',
    unit: PostUnit.fromName(json['unit'] as String?),
    altTexts: Map<String, String>.unmodifiable(
      Map<String, String>.from(json['altTexts'] as Map? ?? {}),
    ),
    serialized: Map.unmodifiable(json),
  );

  Map<String, dynamic> toJson() =>
      _serialized ??
      {
        'caption': caption,
        'captionDelta': captionDelta,
        'tags': tags,
        'address': address?.toJson(),
        'schedule': schedule?.toJson(),
        'features': features.map((feature) => feature.toJson()).toList(),
        'warehouseStock': warehouseStock,
        'discount': discount,
        if (unit != null) 'unit': unit!.name,
        'altTexts': altTexts,
      };
}
