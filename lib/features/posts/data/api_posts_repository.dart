import 'dart:io';
import 'dart:convert';
import 'dart:async';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:nini/core/network/api_client.dart';
import 'package:nini/core/security/secure_token_store.dart';
import 'package:nini/features/create_post/domain/models/gallery_attachment.dart';
import 'package:nini/features/create_post/domain/models/post_draft.dart';
import 'package:nini/features/posts/domain/models/profile_category.dart';
import 'package:nini/features/posts/domain/models/post_media_changes.dart';
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
  final Set<String> _editingPosts = {};
  final Set<String> _uncertainEdits = {};
  final Set<String> _mutatingPosts = {};
  final Set<String> _uncertainMutations = {};
  final Set<String> _deletedPosts = {};
  final _deletedController = StreamController<String>.broadcast(sync: true);
  final _commentCounts =
      StreamController<({String postId, int count})>.broadcast(sync: true);
  final _commentCountVersions = <String, int>{};
  final _latestCommentCounts = <String, int>{};
  int? commentCountFor(String id) => _latestCommentCounts[id];
  Stream<({String postId, int count})> get commentCounts =>
      _commentCounts.stream;
  void publishCommentCount(String id, int count) {
    _commentCountVersions[id] = (_commentCountVersions[id] ?? 0) + 1;
    if (isCurrentAccount() && count >= 0 && !_commentCounts.isClosed) {
      _latestCommentCounts[id] = count;
      _commentCounts.add((postId: id, count: count));
    }
  }

  Future<void> refreshCommentCount(String id) async {
    final version = _commentCountVersions[id] =
        (_commentCountVersions[id] ?? 0) + 1;
    final post = await loadDetail(id);
    final count = post.metadata['commentsCount'];
    if (isCurrentAccount() &&
        !_commentCounts.isClosed &&
        _commentCountVersions[id] == version &&
        count is int) {
      _latestCommentCounts[id] = count;
      _commentCounts.add((postId: id, count: count));
    }
  }

  Stream<String> get deletedPosts => _deletedController.stream;
  bool isDeleted(String id) => _deletedPosts.contains(id);
  void dispose() {
    _deletedController.close();
    _commentCounts.close();
  }

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

  Future<MyServerPost> loadEditablePost(String id) async {
    final post = await loadOwnedPost(id);
    final data = post.data;
    if (data['description'] is! String ||
        data['price'] is! int ||
        data['postType'] is! String ||
        data['owner'] is! Map) {
      throw const FormatException('Post is unavailable for editing.');
    }
    if (!const {
      'published',
      'pending_review',
      'changes_requested',
    }.contains(post.status)) {
      throw const PostApiException('This post cannot be edited.');
    }
    return post;
  }

  Future<MyServerPost> loadOwnedPost(String id) async {
    if (!ProfileCategory.isBackendId(id)) {
      throw const FormatException('Invalid post ID.');
    }
    final token = await _token();
    final response = await _request(
      () => client.getPublic('posts/${Uri.encodeComponent(id)}', token: token),
    );
    final data = response['data'];
    if (response['success'] != true ||
        data is! Map<String, dynamic> ||
        data['id'] != id ||
        data['isMine'] != true) {
      throw const FormatException('Post is unavailable.');
    }
    final post = MyServerPost.fromJson(data);
    return post;
  }

  Future<void> deleteOwnedPost(MyServerPost post) async {
    _checkAccount();
    if (!ProfileCategory.isBackendId(post.id) || isDeleted(post.id)) {
      throw const PostApiException('This post is unavailable.');
    }
    if (_uncertainMutations.contains(post.id)) {
      throw const PostApiException(
        'The previous request could not be confirmed. Check My Posts before trying again.',
      );
    }
    if (_editingPosts.contains(post.id) || !_mutatingPosts.add(post.id))
      throw const PostApiException('An action is already in progress.');
    try {
      await loadOwnedPost(post.id);
      final token = await _token();
      Map<String, dynamic> response;
      try {
        response = await _request(
          () => client.delete(
            'posts/${Uri.encodeComponent(post.id)}',
            token: token,
          ),
        );
      } on DioException catch (error) {
        if (error.response == null ||
            (error.response!.statusCode ?? 500) >= 500) {
          _uncertainMutations.add(post.id);
          try {
            await loadOwnedPost(post.id);
          } catch (_) {
            /* 404 is not proof of deletion. */
          }
          throw const PostApiException(
            'Deletion could not be confirmed. Check My Posts before trying again.',
          );
        }
        rethrow;
      } on FormatException {
        _uncertainMutations.add(post.id);
        throw const PostApiException(
          'Deletion could not be confirmed. Check My Posts before trying again.',
        );
      }
      final data = response['data'];
      if (response['success'] != true ||
          data is! Map ||
          data['id'] != post.id ||
          data['deleted'] != true) {
        _uncertainMutations.add(post.id);
        throw const PostApiException(
          'Deletion could not be confirmed. Check My Posts before trying again.',
        );
      }
      _deletedPosts.add(post.id);
      _feedGeneration++;
      _feedCache.clear();
      _deletedController.add(post.id);
    } finally {
      _mutatingPosts.remove(post.id);
    }
  }

  Future<MyServerPost> resubmitOwnedPost(MyServerPost post) async {
    _checkAccount();
    if (!ProfileCategory.isBackendId(post.id) ||
        post.status != 'changes_requested' ||
        isDeleted(post.id)) {
      throw const PostApiException(
        'Only posts returned for changes can be resubmitted.',
      );
    }
    if (_uncertainMutations.contains(post.id)) {
      throw const PostApiException(
        'The previous request could not be confirmed. Check My Posts before trying again.',
      );
    }
    if (_editingPosts.contains(post.id) || !_mutatingPosts.add(post.id))
      throw const PostApiException('An action is already in progress.');
    try {
      final current = await loadOwnedPost(post.id);
      if (current.status != 'changes_requested')
        throw const PostApiException(
          'Only posts returned for changes can be resubmitted.',
        );
      final token = await _token();
      Map<String, dynamic> response;
      try {
        response = await _request(
          () => client.post(
            'posts/${Uri.encodeComponent(post.id)}/resubmit',
            token: token,
          ),
        );
      } on DioException catch (error) {
        if (error.response != null && (error.response!.statusCode ?? 500) < 500)
          rethrow;
        _uncertainMutations.add(post.id);
        final confirmed = await _reconcileResubmit(post.id);
        if (confirmed != null) return confirmed;
        throw const PostApiException(
          'Resubmission could not be confirmed. Check My Posts before trying again.',
        );
      } on FormatException {
        _uncertainMutations.add(post.id);
        final confirmed = await _reconcileResubmit(post.id);
        if (confirmed != null) return confirmed;
        throw const PostApiException(
          'Resubmission could not be confirmed. Check My Posts before trying again.',
        );
      }
      final data = response['data'];
      if (response['success'] != true ||
          data is! Map<String, dynamic> ||
          data['id'] != post.id ||
          data['isMine'] != true) {
        _uncertainMutations.add(post.id);
        final confirmed = await _reconcileResubmit(post.id);
        if (confirmed != null) return confirmed;
        throw const PostApiException(
          'Resubmission could not be confirmed. Check My Posts before trying again.',
        );
      }
      try {
        return MyServerPost.fromJson(data);
      } catch (_) {
        _uncertainMutations.add(post.id);
        final confirmed = await _reconcileResubmit(post.id);
        if (confirmed != null) return confirmed;
        throw const PostApiException(
          'Resubmission could not be confirmed. Check My Posts before trying again.',
        );
      }
    } finally {
      _mutatingPosts.remove(post.id);
    }
  }

  Future<MyServerPost?> _reconcileResubmit(String id) async {
    try {
      final post = await loadOwnedPost(id);
      final review = post.data['review'];
      if (post.status == 'pending_review' &&
          review is Map &&
          review['submission'] == 'resubmitted') {
        _uncertainMutations.remove(id);
        return post;
      }
    } catch (_) {
      // An unavailable read cannot establish the outcome.
    }
    return null;
  }

  /// Compare supported fields to canonical backend values; omit everything else.
  static Map<String, dynamic> editChangesFor(
    MyServerPost original,
    PostDraft draft, {
    PostDraft? initialDraft,
    Set<String> touched = const {},
  }) {
    final data = original.data;
    final description = data['description'];
    final price = data['price'];
    if (description is! String || price is! int) {
      throw const FormatException('Incomplete post data.');
    }
    final changes = <String, dynamic>{};
    if (draft.title.trim() != original.title.trim()) {
      final title = draft.title.trim();
      if (title.length < 3 || title.length > 120) {
        throw const PostApiException(
          'Enter a title between 3 and 120 characters.',
        );
      }
      changes['title'] = title;
    }
    if (draft.caption != description) {
      final caption = draft.caption.trim();
      if (caption.length < 10 ||
          caption.length > 5000 ||
          draft.captionDelta.any((op) => op['insert'] is! String)) {
        throw const PostApiException(
          'Enter a plain text description between 10 and 5000 characters.',
        );
      }
      changes['description'] = caption;
    }
    final priceChanged =
        initialDraft == null || draft.price.trim() != initialDraft.price.trim();
    final newPrice = priceChanged ? _rial(draft.price) : price;
    if (newPrice != price) {
      final discount = data['discountPrice'];
      if (!data.containsKey('discountPrice') ||
          (discount != null && discount is! int)) {
        throw const PostApiException(
          'The current discount could not be verified.',
        );
      }
      changes['price'] = newPrice;
    }
    if (initialDraft != null) {
      _addEditableFields(changes, data, draft, initialDraft, newPrice, touched);
    }
    final discount = changes['discountPrice'] ?? data['discountPrice'];
    if (newPrice != price && discount is int && newPrice <= discount) {
      throw const PostApiException(
        'The price must remain above the discount price.',
      );
    }
    return changes;
  }

  static void _addEditableFields(
    Map<String, dynamic> changes,
    Map<String, dynamic> data,
    PostDraft draft,
    PostDraft initial,
    int price,
    Set<String> touched,
  ) {
    if (draft.postType != initial.postType) {
      throw const PostApiException('Post type cannot be changed.');
    }
    if (draft.categoryKey != initial.categoryKey) {
      if (!data.containsKey('category') || draft.categoryKey == null) {
        throw const PostApiException(
          'The global category cannot be safely cleared.',
        );
      }
      if (draft.categoryKey!.trim() != draft.categoryKey ||
          draft.categoryKey!.isEmpty ||
          ProfileCategory.isBackendId(draft.categoryKey!)) {
        throw const PostApiException(
          'The selected global category is invalid.',
        );
      }
      changes['category'] = draft.categoryKey;
    }
    if (draft.profileCategoryId != initial.profileCategoryId) {
      if (!data.containsKey('profileCategory') ||
          (draft.profileCategoryId != null &&
              !ProfileCategory.isBackendId(draft.profileCategoryId!))) {
        throw const PostApiException(
          'The profile category cannot be safely updated.',
        );
      }
      changes['profileCategoryId'] = draft.profileCategoryId;
    }
    if (draft.warehouseStock.trim() != initial.warehouseStock.trim()) {
      if (draft.postType != CreatePostType.product ||
          !data.containsKey('stock')) {
        throw const PostApiException('Stock cannot be safely updated.');
      }
      final value = _digits(draft.warehouseStock).trim();
      final stock = value.isEmpty ? null : int.tryParse(value);
      if (value.isNotEmpty && (stock == null || stock < 0)) {
        throw const PostApiException('Enter a valid stock amount.');
      }
      changes['stock'] = stock;
    }
    if (draft.inventoryStatus != initial.inventoryStatus ||
        (touched.contains('inventoryStatus') &&
            !const {
              'available',
              'out_of_stock',
            }.contains(data['inventoryStatus']))) {
      if (draft.postType != CreatePostType.product ||
          !data.containsKey('inventoryStatus') ||
          (data['inventoryStatus'] != null &&
              !const {
                'available',
                'out_of_stock',
              }.contains(data['inventoryStatus'])) ||
          draft.inventoryStatus == InventoryStatus.preOrder) {
        throw const PostApiException('This inventory status is not supported.');
      }
      changes['inventoryStatus'] =
          draft.inventoryStatus == InventoryStatus.inStock
          ? 'available'
          : 'out_of_stock';
    }
    if (draft.unit != initial.unit ||
        (touched.contains('unit') &&
            (data['unit'] is! String ||
                PostUnit.fromName(data['unit'] as String) == null))) {
      if (!data.containsKey('unit') ||
          (data['unit'] != null &&
              (data['unit'] is! String ||
                  PostUnit.fromName(data['unit'] as String) == null))) {
        throw const PostApiException(
          'The current unit cannot be safely edited.',
        );
      }
      changes['unit'] = draft.unit.name;
    }
    if (draft.preparationTime != initial.preparationTime ||
        (touched.contains('preparationTime') &&
            data['preparationTime'] != null &&
            !PreparationTime.values.any(
              (v) => v.label == data['preparationTime'],
            ))) {
      final old = data['preparationTime'];
      if (!data.containsKey('preparationTime') ||
          (old != null && !PreparationTime.values.any((v) => v.label == old))) {
        throw const PostApiException(
          'The current preparation time cannot be safely edited.',
        );
      }
      if (draft.preparationTime == PreparationTime.none) {
        throw const PostApiException(
          'Clearing preparation time is not yet supported.',
        );
      }
      changes['preparationTime'] = draft.preparationTime.label;
    }
    if (jsonEncode(draft.tags) != jsonEncode(initial.tags)) {
      if (!data.containsKey('tags') ||
          draft.tags.isEmpty ||
          draft.tags.length > 10 ||
          draft.tags.any((tag) => tag.length > 30)) {
        throw const PostApiException('These tags cannot be safely updated.');
      }
      changes['tags'] = draft.tags;
    }
    if (jsonEncode(draft.features.map((f) => f.toJson()).toList()) !=
        jsonEncode(initial.features.map((f) => f.toJson()).toList())) {
      final existing = data['features'];
      if (existing is! List ||
          existing.length != initial.features.length ||
          existing.any(
            (item) =>
                item is! Map ||
                item['feature'] is! String ||
                (item['value'] is! String &&
                    item['value'] is! num &&
                    item['value'] is! bool) ||
                !item.containsKey('unit') ||
                (item['unit'] != null && item['unit'] is! String),
          ) ||
          draft.features.isEmpty ||
          draft.features.length > 50) {
        throw const PostApiException(
          'These features cannot be safely updated.',
        );
      }
      changes['features'] = [
        for (final f in draft.features)
          if (initial.features.indexWhere((old) => identical(old, f))
              case final int index when index >= 0)
            {
              'feature': (existing[index] as Map)['feature'],
              'value': (existing[index] as Map)['value'],
              if ((existing[index] as Map).containsKey('unit'))
                'unit': (existing[index] as Map)['unit'],
            }
          else
            _editFeatureRequest(f),
      ];
    }
    _addScheduleChanges(changes, data, draft, initial);
    _addLocationChanges(changes, data, draft, initial);
    _addDiscountChanges(changes, data, draft, initial, price);
  }

  static Map<String, dynamic> _editFeatureRequest(PostFeature f) {
    final name = f.name.trim();
    final value = f.apiValue ?? f.value.trim();
    if (name.isEmpty ||
        name.length > 60 ||
        (value is String && (value.isEmpty || value.length > 200)) ||
        (value is! String && value is! num && value is! bool) ||
        (value is num && !value.isFinite) ||
        (f.unit?.length ?? 0) > 30) {
      throw const PostApiException('Enter a valid feature.');
    }
    return {'feature': name, 'value': value, 'unit': f.unit};
  }

  static void _addScheduleChanges(
    Map<String, dynamic> changes,
    Map<String, dynamic> data,
    PostDraft draft,
    PostDraft initial,
  ) {
    final a = initial.schedule, b = draft.schedule;
    if (a?.startsAt == b?.startsAt && a?.endsAt == b?.endsAt) return;
    if (!data.containsKey('scheduleStart') ||
        !data.containsKey('scheduleEnd') ||
        ((data['scheduleStart'] == null) != (data['scheduleEnd'] == null))) {
      throw const PostApiException(
        'The current schedule cannot be safely edited.',
      );
    }
    if (b == null) {
      throw const PostApiException(
        'Clearing the schedule is not yet supported.',
      );
    }
    if (!b.endsAt.isAfter(b.startsAt)) {
      throw const PostApiException('Enter a valid schedule.');
    }
    if (a?.startsAt != b.startsAt) {
      changes['scheduleStart'] = b.startsAt.toUtc().toIso8601String();
    }
    if (a?.endsAt != b.endsAt) {
      changes['scheduleEnd'] = b.endsAt.toUtc().toIso8601String();
    }
  }

  static void _addLocationChanges(
    Map<String, dynamic> changes,
    Map<String, dynamic> data,
    PostDraft draft,
    PostDraft initial,
  ) {
    final a = initial.address, b = draft.address;
    if (a?.address == b?.address &&
        a?.latitude == b?.latitude &&
        a?.longitude == b?.longitude) {
      return;
    }
    if (!data.containsKey('location') ||
        !data.containsKey('coordinates') ||
        (data['location'] == null && data['coordinates'] != null) ||
        b == null) {
      throw const PostApiException('This location cannot be safely edited.');
    }
    if (b.address.isEmpty ||
        b.address.length > 120 ||
        (b.latitude != null &&
            (!b.latitude!.isFinite || b.latitude! < -90 || b.latitude! > 90)) ||
        (b.longitude != null &&
            (!b.longitude!.isFinite ||
                b.longitude! < -180 ||
                b.longitude! > 180)) ||
        (a?.latitude != null && b.latitude == null) ||
        (a?.longitude != null && b.longitude == null)) {
      throw const PostApiException(
        'Clearing location or coordinates is not yet supported.',
      );
    }
    if (a?.address != b.address) changes['location'] = b.address;
    if (a?.latitude != b.latitude && b.latitude != null) {
      changes['latitude'] = b.latitude;
    }
    if (a?.longitude != b.longitude && b.longitude != null) {
      changes['longitude'] = b.longitude;
    }
  }

  static void _addDiscountChanges(
    Map<String, dynamic> changes,
    Map<String, dynamic> data,
    PostDraft draft,
    PostDraft initial,
    int price,
  ) {
    if (draft.discount.trim() == initial.discount.trim()) return;
    if (!data.containsKey('discountPrice')) {
      throw const PostApiException('The current discount cannot be verified.');
    }
    final input = _digits(draft.discount).trim();
    if (!RegExp(r'^\d{1,3}(?:\.\d{1,2})?$').hasMatch(input)) {
      throw const PostApiException('Enter a valid discount percentage.');
    }
    final parts = input.split('.');
    final basis =
        int.parse(parts.first) * 100 +
        (parts.length == 2 ? int.parse(parts[1].padRight(2, '0')) : 0);
    if (basis <= 0 || basis > 10000 || price <= 0) {
      throw const PostApiException('Clearing a discount is not yet supported.');
    }
    final amount = BigInt.from(price) * BigInt.from(10000 - basis);
    if (amount % BigInt.from(10000) != BigInt.zero) {
      throw const PostApiException(
        'This discount produces a fractional rial amount.',
      );
    }
    changes['discountPrice'] = (amount ~/ BigInt.from(10000)).toInt();
  }

  Future<MyServerPost> updateEditablePost(
    MyServerPost original,
    PostDraft draft, {
    PostDraft? initialDraft,
    PostMediaChanges? mediaChanges,
    List<String>? initialMediaPaths,
    Set<String> touched = const {},
  }) async {
    _checkAccount();
    final changes = editChangesFor(
      original,
      draft,
      initialDraft: initialDraft,
      touched: touched,
    );
    if (!const {
          'published',
          'pending_review',
          'changes_requested',
        }.contains(original.status) ||
        original.data['isMine'] != true) {
      throw const PostApiException('This post cannot be edited.');
    }
    final imagesChanged =
        mediaChanges != null &&
        _mediaEdited(original, draft, mediaChanges, initialMediaPaths);
    if (changes.isEmpty && !imagesChanged) return original;
    if (_uncertainEdits.contains(original.id)) {
      throw const PostApiException(
        'The previous save could not be confirmed. Check the post before trying again.',
      );
    }
    if (_mutatingPosts.contains(original.id) ||
        !_editingPosts.add(original.id)) {
      throw const PostApiException('A save is already in progress.');
    }
    try {
      final token = await _token();
      if (imagesChanged) {
        changes['images'] = await _editImages(
          original,
          draft,
          mediaChanges,
          token,
        );
      }
      Map<String, dynamic> response;
      try {
        response = await _request(
          () => client.patch(
            'posts/${Uri.encodeComponent(original.id)}',
            token: token,
            data: changes,
          ),
        );
      } on DioException catch (error) {
        if (error.response != null &&
            (error.response!.statusCode ?? 500) < 500) {
          rethrow;
        }
        _uncertainEdits.add(original.id);
        final fresh = await _reconcileEdit(original.id, changes);
        if (fresh != null) return fresh;
        throw const PostApiException(
          'The save could not be confirmed. Check the post before trying again.',
        );
      }
      final data = response['data'];
      if (response['success'] != true ||
          data is! Map<String, dynamic> ||
          data['id'] != original.id ||
          data['isMine'] != true) {
        _uncertainEdits.add(original.id);
        final fresh = await _reconcileEdit(original.id, changes);
        if (fresh != null) return fresh;
        throw const PostApiException(
          'The save could not be confirmed. Check the post before trying again.',
        );
      }
      late final MyServerPost result;
      try {
        result = MyServerPost.fromJson(data);
      } catch (_) {
        _uncertainEdits.add(original.id);
        final fresh = await _reconcileEdit(original.id, changes);
        if (fresh != null) return fresh;
        throw const PostApiException(
          'The save could not be confirmed. Check the post before trying again.',
        );
      }
      _feedGeneration++;
      _feedCache.clear();
      return result;
    } finally {
      _editingPosts.remove(original.id);
    }
  }

  Future<MyServerPost?> _reconcileEdit(
    String id,
    Map<String, dynamic> changes,
  ) async {
    try {
      final fresh = await loadEditablePost(id);
      if (_matchesEdit(fresh.data, changes)) {
        _uncertainEdits.remove(id);
        _feedGeneration++;
        _feedCache.clear();
        return fresh;
      }
    } catch (_) {
      // An unavailable read cannot establish the outcome.
    }
    return null;
  }

  bool _matchesEdit(Map<String, dynamic> data, Map<String, dynamic> changes) {
    for (final entry in changes.entries) {
      Object? value = data[entry.key];
      if (entry.key == 'category') value = value is Map ? value['key'] : null;
      if (entry.key == 'profileCategoryId') {
        if (!data.containsKey('profileCategory')) return false;
        final category = data['profileCategory'];
        value = category is Map ? category['id'] : null;
      }
      if (entry.key == 'images' || entry.key == 'features') {
        if (value is! List ||
            entry.value is! List ||
            value.length != (entry.value as List).length) {
          return false;
        }
        for (var index = 0; index < value.length; index++) {
          final actual = value[index], expected = (entry.value as List)[index];
          if (actual is! Map ||
              expected is! Map ||
              expected.entries.any((e) => actual[e.key] != e.value)) {
            return false;
          }
        }
      } else if (!data.containsKey(entry.key) &&
          entry.key != 'profileCategoryId') {
        return false;
      } else if (entry.key != 'images' &&
          entry.key != 'features' &&
          value != entry.value) {
        return false;
      }
    }
    return true;
  }

  bool _mediaEdited(
    MyServerPost original,
    PostDraft draft,
    PostMediaChanges media,
    List<String>? initialMediaPaths,
  ) {
    final items = original.data['images'];
    if (media.additions.isNotEmpty) return true;
    if (initialMediaPaths != null &&
        jsonEncode(initialMediaPaths) != jsonEncode(media.retainedPaths))
      return true;
    if (items is! List)
      return initialMediaPaths == null
          ? media.retainedPaths.isNotEmpty
          : draft.altTexts.isNotEmpty;
    final paths = [
      for (final item in items)
        if (item is Map && item['url'] is String) item['url'] as String,
    ];
    if (initialMediaPaths == null &&
        jsonEncode(paths) != jsonEncode(media.retainedPaths))
      return true;
    for (final item in items) {
      if (item is! Map || item['url'] is! String) continue;
      final key = 'media:${item['url']}';
      if (draft.altTexts.containsKey(key) &&
          draft.altTexts[key] != item['altText']) {
        return true;
      }
    }
    return false;
  }

  Future<List<Map<String, dynamic>>> _editImages(
    MyServerPost original,
    PostDraft draft,
    PostMediaChanges media,
    String token,
  ) async {
    final raw = original.data['images'];
    if (raw is! List ||
        raw.isEmpty ||
        raw.length > 8 ||
        media.retainedPaths.length + media.additions.length < 1 ||
        media.retainedPaths.length + media.additions.length > 8) {
      throw const PostApiException(
        'The original images could not be safely updated.',
      );
    }
    final source = <String, Map<String, dynamic>>{};
    for (final item in raw) {
      if (item is! Map || item['url'] is! String) {
        throw const PostApiException(
          'The original images could not be safely updated.',
        );
      }
      final url = item['url'] as String;
      final uri = Uri.tryParse(url);
      if (uri == null ||
          !const {'http', 'https'}.contains(uri.scheme) ||
          uri.host.isEmpty ||
          source.containsKey(url)) {
        throw const PostApiException(
          'The original images could not be safely updated.',
        );
      }
      final alt = item['altText'];
      final width = item['width'], height = item['height'];
      if ((alt != null && alt is! String) ||
          (width != null && width is! int) ||
          (height != null && height is! int)) {
        throw const PostApiException('The original image metadata is invalid.');
      }
      source[url] = {
        'url': url,
        if (alt is String) 'altText': alt,
        if (width is int) 'width': width,
        if (height is int) 'height': height,
      };
    }
    final result = <Map<String, dynamic>>[];
    final used = <String>{};
    for (final path in media.retainedPaths) {
      if (!used.add(path) || !source.containsKey(path)) {
        throw const PostApiException(
          'The original images could not be safely updated.',
        );
      }
      final image = Map<String, dynamic>.from(source[path]!);
      final alt = draft.altTexts['media:$path'];
      if (alt != null) {
        if (alt.length > 200) {
          throw const PostApiException('Image alt text is too long.');
        }
        image['altText'] = alt;
      }
      result.add(image);
    }
    final prepared = [
      for (final attachment in media.additions)
        await _validateImage(attachment),
    ];
    for (final (index, image) in prepared.indexed) {
      _checkAccount();
      var info = _uploads[image.key];
      if (info == null) {
        final file = await MultipartFile.fromFile(
          image.file.path,
          filename: p.basename(image.name),
          contentType: DioMediaType('image', image.format),
        );
        final response = await _request(
          () => client.postMultipart(
            'uploads?purpose=post',
            token: token,
            data: FormData.fromMap({'file': file}),
          ),
        );
        final data = response['data'];
        final uri = data is Map && data['url'] is String
            ? Uri.tryParse(data['url'] as String)
            : null;
        if (response['success'] != true ||
            uri == null ||
            !const {'http', 'https'}.contains(uri.scheme) ||
            uri.host.isEmpty ||
            (data is Map &&
                data['purpose'] != null &&
                data['purpose'] != 'post') ||
            (await sha256.bind(image.file.openRead()).first).toString() !=
                image.digest) {
          throw const PostApiException(
            'The image upload could not be confirmed.',
          );
        }
        info = {
          'url': uri.toString(),
          if (data['width'] is int) 'width': data['width'],
          if (data['height'] is int) 'height': data['height'],
        };
        _uploads[image.key] = info;
      }
      final alt = draft.altTexts[media.additions[index].id];
      if (alt != null && alt.length > 200) {
        throw const PostApiException('Image alt text is too long.');
      }
      result.add({...info, if (alt != null) 'altText': alt});
    }
    for (final image in prepared) {
      if ((await sha256.bind(image.file.openRead()).first).toString() !=
          image.digest) {
        throw const PostApiException('An image changed before submission.');
      }
    }
    return result;
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
          if (item is! Map ||
              !isDeleted(item['id'] is String ? item['id'] as String : ''))
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

  /// Explore uses the same public post envelope as the feed; prices are rial.
  Future<BackendPostsPage> explore({
    String? category,
    String? postType,
    int? minPrice,
    int? maxPrice,
    bool? inStock,
    num? minRating,
    String? tag,
    String? sort,
    int page = 1,
    int limit = 20,
  }) {
    if (category != null &&
        !const {
          'electronics',
          'fashion_clothing',
          'books',
          'home_kitchen',
          'sports',
          'services',
          'other',
        }.contains(category)) {
      throw const FormatException('Invalid explore category.');
    }
    if (postType != null && !const {'product', 'service'}.contains(postType)) {
      throw const FormatException('Invalid explore post type.');
    }
    if (sort != null &&
        !const {
          'newest',
          'popular',
          'price_asc',
          'price_desc',
          'rating',
        }.contains(sort)) {
      throw const FormatException('Invalid explore sort.');
    }
    if (page < 1 ||
        limit < 1 ||
        limit > 50 ||
        (minRating != null &&
            (!minRating.isFinite || minRating < 0 || minRating > 5))) {
      throw const FormatException('Invalid explore pagination or rating.');
    }
    return _publicPage('explore', {
      if (category != null) 'category': category,
      if (postType != null) 'postType': postType,
      if (minPrice != null) 'minPrice': '$minPrice',
      if (maxPrice != null) 'maxPrice': '$maxPrice',
      if (inStock != null) 'inStock': '$inStock',
      if (minRating != null) 'minRating': '$minRating',
      if (tag != null) 'tag': tag,
      if (sort != null) 'sort': sort,
      'page': '$page',
      'limit': '$limit',
    });
  }

  Future<List<String>> searchSuggestions(String query) => _searchTerms(
    'search/suggestions?${Uri(queryParameters: {'q': query}).query}',
    'text',
  );

  Future<List<String>> popularSearches() =>
      _searchTerms('search/popular', 'query');

  Future<List<String>> trendingSearches() =>
      _searchTerms('search/trending', 'query');

  Future<List<String>> _searchTerms(String endpoint, String field) async {
    final token = await _token();
    final response = await _request(
      () => client.getPublic(endpoint, token: token),
    );
    final data = response['data'];
    if (response['success'] != true || data is! Map || data['items'] is! List) {
      throw const FormatException('Invalid search terms response.');
    }
    final items = data['items'] as List;
    return List.unmodifiable(
      items
          .whereType<Map>()
          .map((item) => item[field])
          .whereType<String>()
          .where((value) => value.trim().isNotEmpty)
          .take(10),
    );
  }

  Future<void> logSearchClick({
    required String searchId,
    required String postId,
    required int position,
  }) async {
    if (!ProfileCategory.isBackendId(searchId) ||
        !ProfileCategory.isBackendId(postId) ||
        position < 1) {
      return;
    }
    final token = await _token();
    await _request(
      () => client.post(
        'search/log',
        token: token,
        data: {
          'searchId': searchId,
          'event': 'click',
          'postId': postId,
          'position': position,
        },
      ),
    );
  }

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
          if (post.status == 'published' && !isDeleted(post.id))
            backendPostFromJson(post.data),
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
              !isDeleted(item['id'] is String ? item['id'] as String : '') &&
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
      searchPositions: search ? _searchPositions(data) : const {},
    );
  }

  Map<String, int> _searchPositions(Map data) {
    final positions = <String, int>{};
    final items = data['items'] as List;
    final offset = ((data['page'] as int) - 1) * (data['limit'] as int);
    for (var index = 0; index < items.length; index++) {
      final item = items[index];
      if (item is Map &&
          item['id'] is String &&
          (item['status'] == null || item['status'] == 'published')) {
        positions.putIfAbsent(item['id'] as String, () => offset + index + 1);
      }
    }
    return positions;
  }

  Future<PostItem> loadDetail(String id) async {
    if (!ProfileCategory.isBackendId(id) || isDeleted(id)) {
      throw const FormatException('Invalid post ID.');
    }
    final token = await _token();
    final response = await _request(
      () => client.getPublic('posts/${Uri.encodeComponent(id)}', token: token),
    );
    final data = response['data'];
    if (isDeleted(id) ||
        response['success'] != true ||
        data is! Map<String, dynamic> ||
        data['id'] != id ||
        (data['status'] != null && data['status'] != 'published')) {
      throw const FormatException('Post is unavailable.');
    }
    return backendPostFromJson(data);
  }

  Future<({bool liked, int count})> setLike(
    String id, {
    required bool liked,
  }) async {
    if (!ProfileCategory.isBackendId(id) || isDeleted(id)) {
      throw const PostApiException('This post is unavailable.');
    }
    final token = await _token();
    final path = 'posts/${Uri.encodeComponent(id)}/like';
    final response = await _request(
      () => liked
          ? client.post(path, token: token)
          : client.delete(path, token: token),
    );
    final data = response['data'];
    if (response['success'] != true ||
        data is! Map ||
        data['postId'] != id ||
        data['isLiked'] != liked ||
        data['likes'] is! int ||
        (data['likes'] as int) < 0) {
      throw const FormatException('Like status was not confirmed.');
    }
    return (liked: liked, count: data['likes'] as int);
  }

  Future<void> setSaved(String id, {required bool saved}) async {
    if (!ProfileCategory.isBackendId(id) || isDeleted(id)) {
      throw const PostApiException('This post is unavailable.');
    }
    final token = await _token();
    final path = 'posts/${Uri.encodeComponent(id)}/save';
    final response = await _request(
      () => saved
          ? client.post(path, token: token)
          : client.delete(path, token: token),
    );
    final data = response['data'];
    if (response['success'] != true ||
        data is! Map ||
        data['postId'] != id ||
        data['isSaved'] != saved) {
      throw const FormatException('Save status was not confirmed.');
    }
  }

  Future<({List<PostComment> items, int total, int page, int limit})>
  loadComments(
    String postId, {
    String? parentId,
    int page = 1,
    int limit = 20,
  }) async {
    if (!ProfileCategory.isBackendId(postId) ||
        (parentId != null && !ProfileCategory.isBackendId(parentId)) ||
        page < 1 ||
        limit < 1 ||
        limit > 50) {
      throw const FormatException('Invalid comments request.');
    }
    final token = (await tokens.getToken())?.trim();
    final query = Uri(
      queryParameters: {
        'parentId': ?parentId,
        'page': '$page',
        'limit': '$limit',
      },
    ).query;
    final endpoint = 'posts/${Uri.encodeComponent(postId)}/comments?$query';
    final response = token == null || token.isEmpty
        ? await client.getPublic(endpoint)
        : await _request(() => client.getPublic(endpoint, token: token));
    final data = response['data'];
    if (response['success'] != true ||
        data is! Map ||
        data['items'] is! List ||
        data['total'] is! int ||
        (data['total'] as int) < 0 ||
        data['page'] != page ||
        data['limit'] != limit) {
      throw const FormatException('Invalid comments response.');
    }
    final items = <PostComment>[];
    for (final item in data['items'] as List) {
      if (item is! Map<String, dynamic>) {
        throw const FormatException('Invalid comment.');
      }
      final comment = PostComment.fromJson(item, postId: postId);
      if (comment.parentId != parentId) {
        throw const FormatException('Invalid comment parent.');
      }
      items.add(comment);
    }
    return (
      items: List<PostComment>.unmodifiable(items),
      total: data['total'] as int,
      page: page,
      limit: limit,
    );
  }

  Future<PostComment> createComment(
    String postId,
    String text, {
    String? parentId,
  }) async {
    final clean = text.trim();
    if (!ProfileCategory.isBackendId(postId) ||
        (parentId != null && !ProfileCategory.isBackendId(parentId)) ||
        clean.isEmpty ||
        clean.runes.length > 1000) {
      throw const PostApiException('Invalid comment.');
    }
    final token = await _token();
    final response = await _request(
      () => client.post(
        'posts/${Uri.encodeComponent(postId)}/comments',
        token: token,
        data: {'text': clean, 'parentId': ?parentId},
      ),
    );
    final data = response['data'];
    if (response['success'] != true || data is! Map<String, dynamic>) {
      throw const FormatException('Comment was not confirmed.');
    }
    final comment = PostComment.fromJson(data, postId: postId);
    if (comment.parentId != parentId || comment.text != clean) {
      throw const FormatException('Comment was not confirmed.');
    }
    return comment;
  }

  Future<int?> deleteComment(PostComment comment) async {
    if (!comment.canDelete || !ProfileCategory.isBackendId(comment.id)) {
      throw const PostApiException('Cannot delete this comment.');
    }
    final token = await _token();
    final response = await _request(
      () => client.delete(
        'comments/${Uri.encodeComponent(comment.id)}',
        token: token,
      ),
    );
    final data = response['data'];
    if (response['success'] != true ||
        data is! Map ||
        data['id'] != comment.id ||
        data['deleted'] != true ||
        (data['commentsCount'] != null &&
            (data['commentsCount'] is! int ||
                (data['commentsCount'] as int) < 0))) {
      throw const FormatException('Comment deletion was not confirmed.');
    }
    return data['commentsCount'] as int?;
  }

  Future<
    ({
      List<({PostItem post, DateTime? savedAt})> items,
      int total,
      int page,
      int limit,
    })
  >
  loadSaved({int page = 1, int limit = 20}) async {
    if (page < 1 || limit < 1 || limit > 50) {
      throw const FormatException('Invalid saved posts pagination.');
    }
    final token = await _token();
    final query = Uri(queryParameters: {'page': '$page', 'limit': '$limit'})
        .query;
    final response = await _request(
      () => client.get('users/me/saved?$query', token: token),
    );
    final data = response['data'];
    if (response['success'] != true ||
        data is! Map ||
        data['items'] is! List ||
        data['total'] is! int ||
        (data['total'] as int) < 0 ||
        data['page'] != page ||
        data['limit'] != limit) {
      throw const FormatException('Invalid saved posts response.');
    }
    final items = <({PostItem post, DateTime? savedAt})>[];
    for (final item in data['items'] as List) {
      if (item is! Map<String, dynamic>) {
        throw const FormatException('Invalid saved post.');
      }
      if (item['status'] != null && item['status'] != 'published') continue;
      if (isDeleted(item['id'] is String ? item['id'] as String : '')) continue;
      final date = item['savedAt'];
      if (date != null &&
          (date is! String || DateTime.tryParse(date) == null)) {
        throw const FormatException('Invalid saved date.');
      }
      items.add((
        post: backendPostFromJson(item),
        savedAt: date is String ? DateTime.parse(date) : null,
      ));
    }
    return (
      items: List<({PostItem post, DateTime? savedAt})>.unmodifiable(items),
      total: data['total'] as int,
      page: page,
      limit: limit,
    );
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
      if (url != null) {
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
    }
  } else {
    final url = imageUrl(json['image']) ?? imageUrl(json['thumbnailUrl']);
    if (url != null) {
      images.add(
        PostMedia(
          path: url,
          name: '',
          type: PostMediaType.image,
          thumbnailPath: imageUrl(json['thumbnailUrl']),
        ),
      );
    }
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
    if (json['isLiked'] is bool) 'isLiked': json['isLiked'],
    if (json['isSaved'] is bool) 'isSaved': json['isSaved'],
    if (json['commentsCount'] is int && (json['commentsCount'] as int) >= 0)
      'commentsCount': json['commentsCount'],
    if (json['likes'] is int && (json['likes'] as int) >= 0)
      'likes': json['likes'],
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

class PostComment {
  const PostComment({
    required this.id,
    required this.postId,
    required this.parentId,
    required this.text,
    required this.authorName,
    required this.authorAvatar,
    required this.createdAt,
    required this.canDelete,
    required this.repliesCount,
  });
  final String id, postId, text, authorName, authorAvatar;
  final String? parentId;
  final DateTime createdAt;
  final bool canDelete;
  final int repliesCount;

  factory PostComment.fromJson(
    Map<String, dynamic> json, {
    required String postId,
  }) {
    final id = json['id'],
        parent = json['parentId'],
        author = json['author'],
        created = json['createdAt'];
    if (id is! String ||
        !ProfileCategory.isBackendId(id) ||
        json['postId'] != postId ||
        (parent != null &&
            (parent is! String || !ProfileCategory.isBackendId(parent))) ||
        json['text'] is! String ||
        author is! Map ||
        author['id'] is! String ||
        created is! String ||
        DateTime.tryParse(created) == null ||
        (json['canDelete'] != null && json['canDelete'] is! bool) ||
        (json['repliesCount'] != null &&
            (json['repliesCount'] is! int ||
                (json['repliesCount'] as int) < 0))) {
      throw const FormatException('Invalid comment.');
    }
    final avatar = author['avatarUrl'];
    final uri = avatar is String ? Uri.tryParse(avatar) : null;
    return PostComment(
      id: id,
      postId: postId,
      parentId: parent as String?,
      text: json['text'] as String,
      authorName:
          author['name'] is String && (author['name'] as String).isNotEmpty
          ? author['name'] as String
          : author['username'] is String
          ? author['username'] as String
          : '',
      authorAvatar:
          uri != null &&
              ['http', 'https'].contains(uri.scheme) &&
              uri.host.isNotEmpty
          ? avatar as String
          : '',
      createdAt: DateTime.parse(created),
      canDelete: json['canDelete'] == true,
      repliesCount: json['repliesCount'] is int
          ? json['repliesCount'] as int
          : 0,
    );
  }
}

class BackendPostsPage {
  const BackendPostsPage({
    required this.items,
    required this.total,
    required this.page,
    required this.limit,
    this.searchId,
    this.understood,
    this.searchPositions = const {},
  });
  final List<PostItem> items;
  final int total, page, limit;
  final String? searchId;
  final SearchUnderstood? understood;
  final Map<String, int> searchPositions;
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
    final review = json['review'];
    return MyServerPost(
      id: json['id'] as String,
      title: json['title'] as String,
      status: json['status'] as String,
      image: json['thumbnailUrl'] is String
          ? json['thumbnailUrl'] as String
          : json['image'] is String
          ? json['image'] as String
          : null,
      reviewNote: review is Map && review['note'] is String
          ? review['note'] as String
          : json['reviewNote'] as String?,
      rejectionReason: review is Map && review['rejectionReason'] is String
          ? review['rejectionReason'] as String
          : json['rejectionReason'] as String?,
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
