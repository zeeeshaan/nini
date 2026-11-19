import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:nini/core/network/api_client.dart';
import 'package:nini/core/security/secure_token_store.dart';
import 'package:nini/features/create_post/domain/models/gallery_attachment.dart';
import 'package:nini/features/create_post/domain/models/post_draft.dart';
import 'package:nini/features/posts/domain/models/profile_category.dart';
import 'package:nini/shared/models/post/post_item.dart';
import 'package:path/path.dart' as p;

/// Account-owned server posts are deliberately separate from local posts.
class ApiPostsRepository {
  ApiPostsRepository(
    this.client,
    this.tokens, {
    required this.isCurrentAccount,
    required this.onUnauthorized,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;
  final ApiClient client;
  final SecureTokenStore tokens;
  final bool Function() isCurrentAccount;
  final Future<void> Function() onUnauthorized;
  final DateTime Function() _clock;
  final Map<String, Map<String, dynamic>> _uploads = {};
  final Map<String, Future<MyPostsPage>> _pendingPages = {};
  final _feedCache = <(int, int), (BackendPostsPage, DateTime)>{};
  final _pendingFeed = <(int, int), (Future<BackendPostsPage>, int, bool)>{};
  static const _feedFreshness = Duration(seconds: 25);
  int _feedGeneration = 0;
  bool _submitting = false;
  bool _outcomeUnknown = false;
  String? uncertainMessage;

  void _checkAccount() {
    if (!isCurrentAccount()) {
      throw const PostApiException('Your account changed. Sign in again.');
    }
  }

  Future<String> _token() async {
    _checkAccount();
    final value = (await tokens.getToken())?.trim();
    _checkAccount();
    if (value == null || value.isEmpty || value.contains(RegExp(r'[\r\n]'))) {
      await onUnauthorized();
      throw const PostApiException('Your session has expired.');
    }
    return value;
  }

  Future<T> _request<T>(Future<T> Function() action) async {
    _checkAccount();
    try {
      final result = await action();
      _checkAccount();
      return result;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401 && isCurrentAccount()) {
        await onUnauthorized();
      }
      rethrow;
    }
  }

  /// Inputs displayed elsewhere in the app use toman; the API accepts rial.
  static int _rial(String value) {
    final input = _digits(value).trim();
    if (!RegExp(r'^(?:\d+|\d{1,3}(?:,\d{3})+)(?:\.\d)?$').hasMatch(input)) {
      throw const PostApiException(
        'Enter a valid price in toman (at most one decimal place).',
      );
    }
    final normalized = input.replaceAll(',', '');
    final parts = normalized.split('.');
    final result =
        BigInt.parse(parts.first) * BigInt.from(10) +
        BigInt.from(parts.length == 2 ? int.parse(parts[1]) : 0);
    if (result > BigInt.parse('9223372036854775807')) {
      throw const PostApiException('Price is too large.');
    }
    return result.toInt();
  }

  static String _digits(String text) {
    const fa = '۰۱۲۳۴۵۶۷۸۹', ar = '٠١٢٣٤٥٦٧٨٩';
    return text.replaceAllMapped(RegExp(r'[۰-۹٠-٩]'), (m) {
      final c = m.group(0)!;
      return (fa.contains(c) ? fa.indexOf(c) : ar.indexOf(c)).toString();
    });
  }

  static Map<String, dynamic> requestFor(PostDraft draft) {
    final title = draft.title.trim(), description = draft.caption.trim();
    if (draft.postType == null ||
        title.length < 3 ||
        title.length > 120 ||
        description.length < 10 ||
        description.length > 5000) {
      throw const PostApiException(
        'Enter a valid post type, title (3–120 characters) and description (10–5000 characters).',
      );
    }
    final category = draft.categoryKey;
    if (category != null &&
        (category.isEmpty ||
            category.trim() != category ||
            ProfileCategory.isBackendId(category))) {
      throw const PostApiException('The selected global category is invalid.');
    }
    if (draft.profileCategoryId != null &&
        !ProfileCategory.isBackendId(draft.profileCategoryId!)) {
      throw const PostApiException('The selected profile category is invalid.');
    }
    for (final op in draft.captionDelta) {
      if (op['insert'] is! String) {
        throw const PostApiException(
          'The server supports text descriptions only. Remove embedded content before submitting.',
        );
      }
    }
    if (draft.postType == CreatePostType.product &&
        draft.inventoryStatus == InventoryStatus.preOrder) {
      throw const PostApiException(
        'Pre-order status is not supported by the server.',
      );
    }
    if (draft.postType == CreatePostType.services &&
        (draft.warehouseStock.trim().isNotEmpty ||
            draft.inventoryStatus != InventoryStatus.inStock)) {
      throw const PostApiException(
        'The server does not save stock or inventory status for services.',
      );
    }
    final price = _rial(draft.price);
    final discountText = _digits(draft.discount).trim();
    int? discountPrice;
    if (discountText.isNotEmpty) {
      if (!RegExp(r'^\d{1,3}(?:\.\d{1,2})?$').hasMatch(discountText)) {
        throw const PostApiException('Enter a valid discount percentage.');
      }
      final pieces = discountText.split('.');
      final basisPoints =
          int.parse(pieces[0]) * 100 +
          (pieces.length == 2 ? int.parse(pieces[1].padRight(2, '0')) : 0);
      if (basisPoints > 10000) {
        throw const PostApiException(
          'Discount must be between 0 and 100 percent.',
        );
      }
      if (basisPoints > 0) {
        if (price == 0) {
          throw const PostApiException(
            'A discounted price must be lower than the original price.',
          );
        }
        final numerator = BigInt.from(price) * BigInt.from(10000 - basisPoints);
        if (numerator % BigInt.from(10000) != BigInt.zero) {
          throw const PostApiException(
            'This discount produces a fractional rial amount.',
          );
        }
        discountPrice = (numerator ~/ BigInt.from(10000)).toInt();
      }
    }
    int? stock;
    if (draft.postType == CreatePostType.product &&
        draft.warehouseStock.trim().isNotEmpty) {
      final value = _digits(draft.warehouseStock).trim();
      if (!RegExp(r'^\d+$').hasMatch(value) ||
          (stock = int.tryParse(value)) == null) {
        throw const PostApiException('Enter a valid whole-number stock.');
      }
    }
    if (draft.tags.length > 10 ||
        draft.tags.any((e) => e.length > 30) ||
        draft.features.length > 50) {
      throw const PostApiException(
        'The server allows up to 10 tags and 50 features.',
      );
    }
    final address = draft.address;
    if (address != null &&
        (address.city.isNotEmpty ||
            address.province.isNotEmpty ||
            address.postalCode.isNotEmpty ||
            address.buildingNumber.isNotEmpty ||
            address.unitNumber.isNotEmpty)) {
      throw const PostApiException(
        'The server does not support the separate city, province, postal code, building or unit address fields.',
      );
    }
    if (address != null && address.address.length > 120) {
      throw const PostApiException('Address must be at most 120 characters.');
    }
    return {
      'type': draft.postType == CreatePostType.product ? 'product' : 'service',
      if (draft.categoryKey != null) 'category': draft.categoryKey,
      if (draft.profileCategoryId != null)
        'profileCategoryId': draft.profileCategoryId,
      'title': title,
      'description': description,
      'price': price,
      'discountPrice': ?discountPrice,
      if (draft.postType == CreatePostType.product) ...{
        'stock': ?stock,
        'inventoryStatus': draft.inventoryStatus == InventoryStatus.outOfStock
            ? 'out_of_stock'
            : 'available',
      },
      'unit': draft.unit.name,
      if (draft.preparationTime != PreparationTime.none)
        'preparationTime': draft.preparationTime.label,
      if (draft.schedule != null) ...{
        'scheduleStart': draft.schedule!.startsAt.toUtc().toIso8601String(),
        'scheduleEnd': draft.schedule!.endsAt.toUtc().toIso8601String(),
      },
      'tags': draft.tags,
      if (draft.features.isNotEmpty)
        'features': [for (final f in draft.features) _featureRequest(f)],
      if (address != null) ...{
        'location': address.address,
        if (address.latitude != null) 'latitude': address.latitude,
        if (address.longitude != null) 'longitude': address.longitude,
      },
    };
  }

  static Map<String, dynamic> _featureRequest(PostFeature feature) {
    final name = feature.name.trim();
    final text = feature.value.trim();
    final unit = feature.unit;
    if (name.isEmpty ||
        name.length > 60 ||
        text.isEmpty ||
        (unit != null && unit.length > 30)) {
      throw const PostApiException('Enter a valid feature and value.');
    }
    Object value = feature.apiValue ?? text;
    if (feature.apiValue == null) {
      final normalized = _digits(text);
      if (RegExp(r'^-?(?:0|[1-9]\d*)(?:\.\d+)?$').hasMatch(normalized)) {
        value = normalized.contains('.')
            ? (double.tryParse(normalized) ?? text)
            : (int.tryParse(normalized) ?? text);
      }
    }
    if ((value is! String && value is! num && value is! bool) ||
        (value is String && value.length > 200) ||
        (value is num && !value.isFinite)) {
      throw const PostApiException('Enter a valid feature value.');
    }
    return {'feature': name, 'value': value, 'unit': ?unit};
  }

  Future<({File file, String key, String format, String name, String digest})>
  _validateImage(GalleryAttachment attachment) async {
    final prepared = attachment.preparedFile;
    if (prepared == null) {
      throw const PostApiException('A selected image is unavailable.');
    }
    final file = File(prepared.xFile.path);
    final stat = await file.stat();
    if (stat.type != FileSystemEntityType.file ||
        stat.size == 0 ||
        stat.size > 5 * 1024 * 1024) {
      throw const PostApiException(
        'Each image must be available and at most 5 MB.',
      );
    }
    final handle = await file.open();
    late final List<int> bytes;
    try {
      bytes = await handle.read(12);
    } finally {
      await handle.close();
    }
    final format =
        bytes.length >= 3 &&
            bytes[0] == 255 &&
            bytes[1] == 216 &&
            bytes[2] == 255
        ? 'jpeg'
        : bytes.length >= 8 &&
              bytes.sublist(0, 8).join(',') == '137,80,78,71,13,10,26,10'
        ? 'png'
        : bytes.length >= 12 &&
              String.fromCharCodes(bytes.take(4)) == 'RIFF' &&
              String.fromCharCodes(bytes.sublist(8, 12)) == 'WEBP'
        ? 'webp'
        : '';
    if (format.isEmpty) {
      final heif =
          bytes.length >= 12 &&
          String.fromCharCodes(bytes.sublist(4, 8)) == 'ftyp' &&
          const [
            'heic',
            'heix',
            'hevc',
            'hevx',
            'mif1',
            'msf1',
          ].contains(String.fromCharCodes(bytes.sublist(8, 12)));
      throw PostApiException(
        heif
            ? 'This HEIC/HEIF image could not be converted. Use a JPG, PNG or WebP image.'
            : 'Only JPG, PNG and WebP images can be submitted. Videos and other files are not supported.',
      );
    }
    final ext = p.extension(prepared.name).toLowerCase();
    final matches = format == 'jpeg'
        ? ['.jpg', '.jpeg'].contains(ext)
        : ext == '.$format';
    final name = matches
        ? prepared.name
        : p.setExtension(prepared.name, format == 'jpeg' ? '.jpg' : '.$format');
    final digest = (await sha256.bind(file.openRead()).first).toString();
    return (
      file: file,
      key: '${attachment.id}|${file.path}|$digest',
      format: format,
      name: name,
      digest: digest,
    );
  }

  Future<MyServerPost> submit(
    PostDraft draft,
    List<GalleryAttachment> attachments,
  ) async {
    if (_submitting) {
      throw const PostApiException('A submission is already in progress.');
    }
    if (_outcomeUnknown) {
      throw const PostApiException(
        'The previous submission may have succeeded. Check My Posts before trying again.',
      );
    }
    _submitting = true;
    try {
      final payload = requestFor(draft);
      if (attachments.isEmpty || attachments.length > 8) {
        throw const PostApiException('Select between one and eight images.');
      }
      final images =
          <
            ({File file, String key, String format, String name, String digest})
          >[];
      for (final attachment in attachments) {
        images.add(await _validateImage(attachment));
      }
      for (final value in draft.altTexts.values) {
        if (value.length > 200) {
          throw const PostApiException(
            'Image alt text must be at most 200 characters.',
          );
        }
      }
      final token = await _token();
      final uploaded = <Map<String, dynamic>>[];
      for (final (index, image) in images.indexed) {
        _checkAccount();
        var info = _uploads[image.key];
        if (info == null) {
          final file = await MultipartFile.fromFile(
            image.file.path,
            filename: p.basename(image.name),
            contentType: DioMediaType('image', image.format),
          );
          _checkAccount();
          final response = await _request(
            () => client.postMultipart(
              'uploads?purpose=post',
              token: token,
              data: FormData.fromMap({'file': file}),
            ),
          );
          final data = response['data'];
          if ((await sha256.bind(image.file.openRead()).first).toString() !=
              image.digest) {
            throw const PostApiException(
              'An image changed during upload. Please try again.',
            );
          }
          final uri = data is Map && data['url'] is String
              ? Uri.tryParse(data['url'] as String)
              : null;
          if (response['success'] != true ||
              uri == null ||
              !['http', 'https'].contains(uri.scheme) ||
              uri.host.isEmpty ||
              (data is Map &&
                  data['purpose'] != null &&
                  data['purpose'] != 'post')) {
            throw const PostApiException(
              'The server did not confirm the image upload.',
            );
          }
          info = {
            'url': uri.toString(),
            if (data['width'] is int) 'width': data['width'],
            if (data['height'] is int) 'height': data['height'],
          };
          _uploads[image.key] = info;
        }
        final alt = draft.altTexts[attachments[index].id];
        uploaded.add({
          ...info,
          if (alt != null && alt.isNotEmpty) 'altText': alt,
        });
      }
      for (final image in images) {
        if ((await sha256.bind(image.file.openRead()).first).toString() !=
            image.digest) {
          throw const PostApiException(
            'An image changed before submission. Please try again.',
          );
        }
      }
      _checkAccount();
      payload['images'] = uploaded;
      Map<String, dynamic> response;
      try {
        response = await _request(
          () => client.post('posts', token: token, data: payload),
        );
      } on DioException catch (e) {
        if (e.response == null || (e.response!.statusCode ?? 500) >= 500) {
          _outcomeUnknown = true;
          try {
            final page = await loadMine();
            final possible = page.items.where((post) {
              final category = post.data['category'];
              return post.title == payload['title'] &&
                  post.data['postType'] == payload['type'] &&
                  post.data['price'] == payload['price'] &&
                  category is Map &&
                  category['key'] == payload['category'];
            }).length;
            uncertainMessage = possible == 0
                ? 'Submission could not be confirmed. No possible match appeared on the first My Posts page; check all pages before retrying.'
                : 'Submission could not be confirmed. My Posts contains $possible possible match(es); check them before retrying.';
          } catch (_) {
            uncertainMessage = 'Submission could not be confirmed and My Posts could not be checked. Check My Posts before retrying.';
          }
        }
        rethrow;
      } catch (_) {
        _outcomeUnknown = true;
        rethrow;
      }
      final data = response['data'];
      if (response['success'] != true || data is! Map<String, dynamic>) {
        _outcomeUnknown = true;
        throw const PostApiException(
          'Submission could not be confirmed. Check My Posts before trying again.',
        );
      }
      try {
        return MyServerPost.fromJson(data);
      } catch (_) {
        _outcomeUnknown = true;
        rethrow;
      }
    } finally {
      _submitting = false;
    }
  }

  Future<MyPostsPage> loadMine({
    int page = 1,
    int limit = 20,
    String? status,
    String? categoryId,
  }) {
    if (page < 1 ||
        limit < 1 ||
        limit > 50 ||
        (status != null &&
            !const [
              'pending_review',
              'changes_requested',
              'rejected',
              'published',
              'suspended',
            ].contains(status)) ||
        (categoryId != null && !ProfileCategory.isBackendId(categoryId))) {
      throw const PostApiException('Invalid My Posts filter.');
    }
    final query = Uri(
      queryParameters: {
        'page': '$page',
        'limit': '$limit',
        'status': ?status,
        'categoryId': ?categoryId,
      },
    ).query;
    return _pendingPages.putIfAbsent(
      query,
      () => _loadMine(query).whenComplete(() {
        _pendingPages.remove(query);
      }),
    );
  }

  Future<MyPostsPage> _loadMine(String query) async {
    final token = await _token();
    final response = await _request(
      () => client.get('posts/mine?$query', token: token),
    );
    final data = response['data'];
    if (response['success'] != true ||
        data is! Map<String, dynamic> ||
        data['items'] is! List ||
        data['total'] is! int ||
        data['page'] is! int ||
        data['limit'] is! int ||
        (data['total'] as int) < 0 ||
        (data['page'] as int) < 1 ||
        (data['limit'] as int) < 1 ||
        (data['limit'] as int) > 50 ||
        (data['statusCounts'] != null &&
            (data['statusCounts'] is! Map ||
                (data['statusCounts'] as Map).entries.any(
                  (e) =>
                      e.key is! String ||
                      e.value is! int ||
                      (e.value as int) < 0,
                )))) {
      throw const FormatException('Invalid My Posts response.');
    }
    return MyPostsPage(
      items: [
        for (final item in data['items'] as List)
          MyServerPost.fromJson(Map<String, dynamic>.from(item as Map)),
      ],
      total: data['total'] as int,
      page: data['page'] as int,
      limit: data['limit'] as int,
      statusCounts: data['statusCounts'] == null
          ? null
          : Map<String, int>.from(data['statusCounts'] as Map),
    );
  }

  Future<BackendPostsPage> loadFeed({
    int page = 1,
    int limit = 20,
    bool force = false,
  }) async {
    _checkAccount();
    final key = (page, limit);
    final pending = _pendingFeed[key];
    if (pending != null &&
        pending.$2 == _feedGeneration &&
        (!force || pending.$3)) {
      final result = await pending.$1;
      _checkAccount();
      return result;
    }
    final cached = _feedCache[key];
    if (!force && cached != null) {
      final age = _clock().difference(cached.$2);
      if (!age.isNegative && age < _feedFreshness) {
        final result = await Future<BackendPostsPage>.value(cached.$1);
        _checkAccount();
        return result;
      }
    }
    if (page == 1 || force) {
      _feedGeneration++;
      if (page == 1) {
        _feedCache.clear();
      } else {
        _feedCache.remove(key);
      }
    } else {
      _feedCache.remove(key);
    }
    final generation = _feedGeneration;
    late final Future<BackendPostsPage> request;
    request =
        _publicPage('feed', {
              'scope': 'all',
              'page': '$page',
              'limit': '$limit',
            })
            .then((result) {
              _checkAccount();
              final immutable = BackendPostsPage(
                items: List.unmodifiable(result.items),
                total: result.total,
                page: result.page,
                limit: result.limit,
              );
              if (generation == _feedGeneration) {
                final now = _clock();
                _feedCache.removeWhere((_, entry) {
                  final age = now.difference(entry.$2);
                  return age.isNegative || age >= _feedFreshness;
                });
                if (_feedCache.length >= 20) {
                  _feedCache.remove(_feedCache.keys.first);
                }
                _feedCache[key] = (immutable, now);
              }
              return immutable;
            })
            .whenComplete(() {
              if (identical(_pendingFeed[key]?.$1, request)) {
                _pendingFeed.remove(key);
              }
            });
    _pendingFeed[key] = (request, generation, force);
    final result = await request;
    _checkAccount();
    return result;
  }

  Future<BackendPostsPage> search({
    required String query,
    int page = 1,
    int limit = 20,
  }) => _publicPage('search', {
    'q': query,
    'type': 'posts',
    'page': '$page',
    'limit': '$limit',
  }, search: true);

  Future<BackendPostsPage> loadPublishedMine({
    int page = 1,
    int limit = 20,
    String? categoryId,
  }) async {
    final response = await loadMine(
      status: 'published',
      page: page,
      limit: limit,
      categoryId: categoryId,
    );
    return BackendPostsPage(
      items: [
        for (final post in response.items)
          if (post.status == 'published') backendPostFromJson(post.data),
      ],
      total: response.total,
      page: response.page,
      limit: response.limit,
    );
  }

  Future<BackendPostsPage> _publicPage(
    String path,
    Map<String, String> query, {
    bool search = false,
  }) async {
    final token = await _token();
    final response = await _request(
      () => client.getPublic(
        '$path?${Uri(queryParameters: query).query}',
        token: token,
      ),
    );
    final root = response['data'];
    final data = search && root is Map ? root['posts'] : root;
    if (response['success'] != true ||
        data is! Map ||
        data['items'] is! List ||
        data['total'] is! int ||
        data['page'] is! int ||
        data['limit'] is! int ||
        (data['page'] as int) < 1 ||
        (data['limit'] as int) < 1 ||
        (data['limit'] as int) > 50 ||
        (data['total'] as int) < 0) {
      throw const FormatException('Invalid posts response.');
    }
    return BackendPostsPage(
      items: [
        for (final item in data['items'] as List)
          if (item is Map &&
              (item['status'] == null || item['status'] == 'published'))
            backendPostFromJson(Map<String, dynamic>.from(item)),
      ],
      total: data['total'] as int,
      page: data['page'] as int,
      limit: data['limit'] as int,
      searchId: search && root is Map && root['searchId'] is String
          ? root['searchId'] as String
          : null,
      understood: search && root is Map && root['understood'] is Map
          ? SearchUnderstood.fromJson(
              Map<String, dynamic>.from(root['understood'] as Map),
            )
          : null,
    );
  }

  Future<PostItem> loadDetail(String id) async {
    if (!ProfileCategory.isBackendId(id))
      throw const FormatException('Invalid post ID.');
    final token = await _token();
    final response = await _request(
      () => client.getPublic('posts/${Uri.encodeComponent(id)}', token: token),
    );
    final data = response['data'];
    if (response['success'] != true ||
        data is! Map<String, dynamic> ||
        data['id'] != id ||
        (data['status'] != null && data['status'] != 'published')) {
      throw const FormatException('Post is unavailable.');
    }
    return backendPostFromJson(data);
  }
}

/// Maps the documented PostCard/PublicPost fields without fabricating identity.
PostItem backendPostFromJson(Map<String, dynamic> json) {
  final id = json['id'], title = json['title'], type = json['postType'];
  final owner = json['owner'], category = json['category'];
  if (id is! String ||
      !ProfileCategory.isBackendId(id) ||
      title is! String ||
      !const ['product', 'service'].contains(type) ||
      owner is! Map ||
      owner['id'] is! String ||
      (owner['id'] as String).isEmpty ||
      (category != null && (category is! Map || category['key'] is! String))) {
    throw const FormatException('Invalid post data.');
  }
  String money(Object? value) {
    if (value is! int || value < 0) return '';
    return value % 10 == 0 ? '${value ~/ 10}' : '${value ~/ 10}.${value % 10}';
  }

  String? imageUrl(Object? value) {
    if (value is! String) return null;
    final uri = Uri.tryParse(value);
    return uri != null &&
            const ['http', 'https'].contains(uri.scheme) &&
            uri.host.isNotEmpty
        ? value
        : null;
  }

  final images = <PostMedia>[];
  if (json['images'] is List) {
    for (final image in json['images'] as List) {
      if (image is! Map) continue;
      final url = imageUrl(image['url']);
      if (url != null)
        images.add(
          PostMedia(
            path: url,
            name: '',
            type: PostMediaType.image,
            thumbnailPath: imageUrl(image['thumbnailUrl']),
            altText: image['altText'] is String
                ? image['altText'] as String
                : '',
          ),
        );
    }
  } else {
    final url = imageUrl(json['image']) ?? imageUrl(json['thumbnailUrl']);
    if (url != null)
      images.add(
        PostMedia(
          path: url,
          name: '',
          type: PostMediaType.image,
          thumbnailPath: imageUrl(json['thumbnailUrl']),
        ),
      );
  }
  final seller = {
    'id': owner['id'],
    'name': owner['name'] is String ? owner['name'] : '',
    'username': owner['username'] is String ? owner['username'] : '',
    'avatarAsset': imageUrl(owner['avatarUrl']) ?? '',
    'location': json['location'] is String ? json['location'] : '',
    'bio': '',
  };
  final personal = json['profileCategory'];
  final coordinates = json['coordinates'];
  final rawPrice = json['price'], finalPrice = json['finalPrice'] ?? rawPrice;
  final features = json['features'] is List
      ? [
          for (final f in json['features'] as List)
            if (f is Map &&
                f['feature'] is String &&
                (f['value'] is String ||
                    f['value'] is num ||
                    f['value'] is bool))
              {
                'name': f['feature'],
                'value': f['value'].toString(),
                if (f['value'] is num || f['value'] is bool)
                  'apiValue': f['value'],
                if (f['unit'] is String) 'unit': f['unit'],
              },
        ]
      : <Map<String, dynamic>>[];
  final metadata = <String, dynamic>{
    'backend': true,
    'backendStatus': json['status'],
    'inStock': json['inStock'],
    if (json['rating'] is num) 'rating': json['rating'],
    'postType': type == 'service' ? 'services' : 'product',
    if (category is Map) 'category': category['key'],
    'seller': seller,
    'caption': json['description'] is String ? json['description'] : '',
    'tags': json['tags'] is List
        ? (json['tags'] as List).whereType<String>().toList()
        : <String>[],
    'features': features,
    if (json['unit'] is String) 'unit': json['unit'],
    if (json['stock'] is int) 'warehouseStock': '${json['stock']}',
    if (json['location'] is String)
      'address': {
        'address': json['location'],
        if (coordinates is Map && coordinates['lat'] is num)
          'latitude': coordinates['lat'],
        if (coordinates is Map && coordinates['lng'] is num)
          'longitude': coordinates['lng'],
      },
  };
  return PostItem(
    id: id,
    imageAsset: '',
    title: title,
    category: category is Map && category['label'] is String
        ? category['label'] as String
        : category is Map
        ? category['key'] as String
        : '',
    profileCategoryId:
        personal is Map &&
            personal['id'] is String &&
            ProfileCategory.isBackendId(personal['id'] as String)
        ? personal['id'] as String
        : null,
    stockCount: json['stock'] is int ? json['stock'] as int : 0,
    price: money(finalPrice),
    originalPrice: rawPrice is int && finalPrice is int && finalPrice < rawPrice
        ? money(rawPrice)
        : '',
    media: List.unmodifiable(images),
    details: PostDetails.fromJson(metadata),
    publishedAt: json['publishedAt'] is String
        ? DateTime.tryParse(json['publishedAt'] as String)
        : null,
  );
}

class BackendPostsPage {
  const BackendPostsPage({
    required this.items,
    required this.total,
    required this.page,
    required this.limit,
    this.searchId,
    this.understood,
  });
  final List<PostItem> items;
  final int total, page, limit;
  final String? searchId;
  final SearchUnderstood? understood;
}

/// Optional fields documented by the Smart Search response.
class SearchUnderstood {
  const SearchUnderstood({
    this.keywords,
    this.intent,
    this.location,
    this.measures,
    this.didYouMean,
  });
  final List<String>? keywords;
  final String? intent, location;
  final List<({num? value, String? unit})>? measures;
  final List<({String? from, String? to})>? didYouMean;

  factory SearchUnderstood.fromJson(Map<String, dynamic> json) {
    final keywords = json['keywords'],
        measures = json['measures'],
        corrections = json['didYouMean'];
    return SearchUnderstood(
      keywords: keywords is List
          ? List.unmodifiable(keywords.whereType<String>())
          : null,
      intent: json['intent'] is String ? json['intent'] as String : null,
      location: json['location'] is String ? json['location'] as String : null,
      measures: measures is List
          ? List.unmodifiable([
              for (final item in measures)
                if (item is Map)
                  (
                    value: item['value'] is num ? item['value'] as num : null,
                    unit: item['unit'] is String
                        ? item['unit'] as String
                        : null,
                  ),
            ])
          : null,
      didYouMean: corrections is List
          ? List.unmodifiable([
              for (final item in corrections)
                if (item is Map)
                  (
                    from: item['from'] is String
                        ? item['from'] as String
                        : null,
                    to: item['to'] is String ? item['to'] as String : null,
                  ),
            ])
          : null,
    );
  }
}

class MyServerPost {
  const MyServerPost({
    required this.id,
    required this.title,
    required this.status,
    this.image,
    this.reviewNote,
    this.rejectionReason,
    this.data = const {},
  });
  final String id, title, status;
  final String? image, reviewNote, rejectionReason;
  final Map<String, dynamic> data;
  factory MyServerPost.fromJson(Map<String, dynamic> json) {
    if (json['id'] is! String ||
        !ProfileCategory.isBackendId(json['id'] as String) ||
        json['title'] is! String ||
        json['status'] is! String ||
        !const [
          'pending_review',
          'changes_requested',
          'rejected',
          'published',
          'suspended',
        ].contains(json['status'])) {
      throw const FormatException('Invalid server post.');
    }
    return MyServerPost(
      id: json['id'] as String,
      title: json['title'] as String,
      status: json['status'] as String,
      image: json['thumbnailUrl'] is String
          ? json['thumbnailUrl'] as String
          : json['image'] is String
          ? json['image'] as String
          : null,
      reviewNote: json['reviewNote'] as String?,
      rejectionReason: json['rejectionReason'] as String?,
      data: Map.unmodifiable(json),
    );
  }
}

class MyPostsPage {
  const MyPostsPage({
    required this.items,
    required this.total,
    required this.page,
    required this.limit,
    this.statusCounts,
  });
  final List<MyServerPost> items;
  final int total, page, limit;
  final Map<String, int>? statusCounts;
}

class PostApiException implements Exception {
  const PostApiException(this.message);
  final String message;
}
