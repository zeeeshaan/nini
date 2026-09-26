/// Product "Information": attribute keys (features) with the values the
/// seller offers, plus the variants built from them.
library;

class ProductAttribute {
  const ProductAttribute(this.name, [this.values = const []]);

  final String name;
  final List<String> values;

  ProductAttribute withValues(List<String> values) =>
      ProductAttribute(name, values);
}

enum InventoryStatus {
  inStock('موجود'),
  outOfStock('ناموجود'),
  comingSoon('به‌زودی');

  const InventoryStatus(this.label);
  final String label;
}

/// One sellable combination: attribute name -> picked value (null for
/// "any"), plus its own price and inventory settings.
class ProductVariant {
  const ProductVariant({
    this.values = const {},
    this.price,
    this.discountPrice,
    this.discountEndsAt,
    this.preOrder = false,
    this.sku = '',
    this.status = InventoryStatus.inStock,
    this.stock = 1,
    this.threshold = 1,
    this.downloadLimit = 1,
    this.downloadExpiryDays = 1,
    this.downloadFiles = const [],
    this.unit,
  });

  final Map<String, String?> values;

  /// Toman.
  final int? price;
  final int? discountPrice;

  /// When set, [discountPrice] is a limited-time offer ending at this time.
  final DateTime? discountEndsAt;
  final bool preOrder;
  final String sku;
  final InventoryStatus status;
  final int stock;

  /// Low-stock warning level.
  final int threshold;
  final int downloadLimit;
  final int downloadExpiryDays;

  /// Ids of the post's own media ([PickedMedia.id]) a buyer can download
  /// after purchase.
  final List<String> downloadFiles;
  final String? unit;

  /// The price a buyer pays right now.
  int? get effectivePrice =>
      discountPrice != null &&
          (discountEndsAt == null || discountEndsAt!.isAfter(DateTime.now()))
      ? discountPrice
      : price;

  ProductVariant copyWith({
    Map<String, String?>? values,
    int? Function()? price,
    int? Function()? discountPrice,
    DateTime? Function()? discountEndsAt,
    bool? preOrder,
    String? sku,
    InventoryStatus? status,
    int? stock,
    int? threshold,
    int? downloadLimit,
    int? downloadExpiryDays,
    List<String>? downloadFiles,
    String? Function()? unit,
  }) => ProductVariant(
    values: values ?? this.values,
    price: price != null ? price() : this.price,
    discountPrice: discountPrice != null ? discountPrice() : this.discountPrice,
    discountEndsAt: discountEndsAt != null
        ? discountEndsAt()
        : this.discountEndsAt,
    preOrder: preOrder ?? this.preOrder,
    sku: sku ?? this.sku,
    status: status ?? this.status,
    stock: stock ?? this.stock,
    threshold: threshold ?? this.threshold,
    downloadLimit: downloadLimit ?? this.downloadLimit,
    downloadExpiryDays: downloadExpiryDays ?? this.downloadExpiryDays,
    downloadFiles: downloadFiles ?? this.downloadFiles,
    unit: unit != null ? unit() : this.unit,
  );
}

/// Units a price can be quoted per, grouped roughly as in the design:
/// count, length, weight, volume, area, time and digital.
const kUnits = [
  'عدد',
  'قطعه',
  'آیتم',
  'واحد',
  'ست',
  'بسته',
  'جفت',
  'دوجین',
  'جعبه',
  'کیسه',
  'باندل',
  'میلی‌متر',
  'سانتی‌متر',
  'متر',
  'کیلومتر',
  'اینچ',
  'فوت',
  'یارد',
  'مایل',
  'میلی‌گرم',
  'گرم',
  'کیلوگرم',
  'تن',
  'اونس',
  'پوند',
  'میلی‌لیتر',
  'لیتر',
  'متر مکعب',
  'گالن',
  'اونس مایع',
  'کوارت',
  'پاینت',
  'سانتی‌متر مربع',
  'متر مربع',
  'هکتار',
  'ایکر',
  'فوت مربع',
  'یارد مربع',
  'ثانیه',
  'دقیقه',
  'ساعت',
  'روز',
  'هفته',
  'ماه',
  'سال',
  'جلسه',
  'بازدید',
  'به ازای هر ساعت',
  'به ازای هر روز',
  'به ازای هر پروژه',
  'به ازای هر کار',
  'به ازای هر جلسه',
  'به ازای هر بازدید',
  'به ازای هر مشاوره',
  'به ازای هر صفحه',
  'به ازای هر کلمه',
  'به ازای هر کاراکتر',
  'مگابایت',
  'گیگابایت',
  'ترابایت',
  'دانلود',
  'لایسنس',
  'کاربر',
  'حساب',
  'برگ',
  'رول',
  'پنل',
  'بطری',
];

/// Attribute keys offered on the Feature page.
const kSuggestedFeatures = [
  'سال تولید',
  'رم',
  'حافظه داخلی',
  'رنگ',
  'سایز',
  'برند',
  'مدل',
  'جنس',
  'وزن',
  'گارانتی',
];

/// Ready-made values for well-known features; anything else starts empty
/// and the seller types its own.
List<String> suggestedValues(String feature) {
  final now = DateTime.now().year;
  return switch (feature) {
    'سال تولید' => [for (var y = now; y >= now - 25; y--) '$y'],
    'رم' => ['2GB', '4GB', '6GB', '8GB', '12GB', '16GB', '32GB', '64GB'],
    'حافظه داخلی' => ['64GB', '128GB', '256GB', '512GB', '768GB', '1TB', '2TB'],
    'رنگ' => [
      'مشکی',
      'سفید',
      'خاکستری',
      'نقره‌ای',
      'طلایی',
      'آبی',
      'قرمز',
      'سبز',
    ],
    'سایز' => ['XS', 'S', 'M', 'L', 'XL', 'XXL'],
    'گارانتی' => ['۶ ماه', '۱۲ ماه', '۱۸ ماه', '۲۴ ماه'],
    _ => const [],
  };
}
