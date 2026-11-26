import 'package:hywork/features/create_post/domain/models/post_options.dart';

export 'package:hywork/features/create_post/domain/models/post_options.dart';

enum CreatePostType { product, services }

/// Session draft shared by the gallery and details route. Nullable values can
/// explicitly be cleared; dialog cancellation never writes to this state.
class PostDraft {
  const PostDraft({
    this.postType,
    this.profileCategoryId,
    this.categoryKey,
    this.title = '',
    this.caption = '',
    this.captionDelta = const [],
    this.price = '',
    this.discount = '',
    this.warehouseStock = '',
    this.preparationTime = PreparationTime.none,
    this.unit = PostUnit.piece,
    this.inventoryStatus = InventoryStatus.inStock,
    this.schedule,
    this.address,
    this.savedAddresses = const [],
    this.features = const [],
    this.tags = const [],
    this.altTexts = const {},
  });
  final CreatePostType? postType;
  final String? profileCategoryId;
  final String? categoryKey;
  final String title, caption, price, discount, warehouseStock;
  final List<Map<String, dynamic>> captionDelta;
  final PreparationTime preparationTime;
  final PostUnit unit;
  final InventoryStatus inventoryStatus;
  final PostSchedule? schedule;
  final PostAddress? address;
  final List<PostAddress> savedAddresses;
  final List<PostFeature> features;
  final List<String> tags;
  final Map<String, String> altTexts;

  PostDraft copyWith({
    CreatePostType? postType,
    String? profileCategoryId,
    bool clearProfileCategory = false,
    String? categoryKey,
    bool clearCategory = false,
    String? title,
    String? caption,
    List<Map<String, dynamic>>? captionDelta,
    String? price,
    String? discount,
    String? warehouseStock,
    PreparationTime? preparationTime,
    PostUnit? unit,
    InventoryStatus? inventoryStatus,
    PostSchedule? schedule,
    bool clearSchedule = false,
    PostAddress? address,
    bool clearAddress = false,
    List<PostAddress>? savedAddresses,
    List<PostFeature>? features,
    List<String>? tags,
    Map<String, String>? altTexts,
  }) => PostDraft(
    postType: postType ?? this.postType,
    profileCategoryId: clearProfileCategory
        ? null
        : profileCategoryId ?? this.profileCategoryId,
    categoryKey: clearCategory ? null : categoryKey ?? this.categoryKey,
    title: title ?? this.title,
    caption: caption ?? this.caption,
    captionDelta: captionDelta == null
        ? this.captionDelta
        : List.unmodifiable(
            captionDelta.map(
              (entry) => Map<String, dynamic>.unmodifiable(entry),
            ),
          ),
    price: price ?? this.price,
    discount: discount ?? this.discount,
    warehouseStock: warehouseStock ?? this.warehouseStock,
    preparationTime: preparationTime ?? this.preparationTime,
    unit: unit ?? this.unit,
    inventoryStatus: inventoryStatus ?? this.inventoryStatus,
    schedule: clearSchedule ? null : schedule ?? this.schedule,
    address: clearAddress ? null : address ?? this.address,
    savedAddresses: savedAddresses == null
        ? this.savedAddresses
        : List.unmodifiable(savedAddresses),
    features: features == null ? this.features : List.unmodifiable(features),
    tags: tags == null ? this.tags : List.unmodifiable(tags),
    altTexts: altTexts == null ? this.altTexts : Map.unmodifiable(altTexts),
  );

  /// Ready for a future publishing API. Dates are serialized in UTC; rich
  /// formatting is kept as Quill Delta alongside searchable plain text.
  Map<String, dynamic> toJson() => {
    'postType': postType?.name,
    'profileCategoryId': profileCategoryId,
    'category': categoryKey,
    'title': title,
    'caption': caption,
    'captionDelta': captionDelta,
    'price': price,
    'discount': discount,
    'warehouseStock': warehouseStock,
    'preparationDays': preparationTime.days,
    'unit': unit.name,
    'inventoryStatus': inventoryStatus.name,
    'schedule': schedule?.toJson(),
    'address': address?.toJson(),
    'features': features.map((f) => f.toJson()).toList(),
    'tags': tags,
    'altTexts': altTexts,
  };
}
