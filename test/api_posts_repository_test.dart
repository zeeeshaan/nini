import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nini/core/network/api_client.dart';
import 'package:nini/core/media/media_compressor.dart';
import 'package:nini/features/create_post/data/gallery_media_preparer.dart';
import 'package:nini/core/config/app_config/app_config.dart';
import 'package:nini/core/security/secure_token_store.dart';
import 'package:nini/features/create_post/data/prepared_gallery_file.dart';
import 'package:nini/features/create_post/domain/models/gallery_attachment.dart';
import 'package:nini/features/create_post/domain/models/post_draft.dart';
import 'package:nini/features/posts/data/api_posts_repository.dart';
import 'package:nini/features/profile_settings/presentation/pages/posts_screen.dart';
import 'package:nini/shared/widgets/skeleton/product_card_skeleton.dart';
import 'package:nini/shared/widgets/skeleton/app_shimmer.dart';
import 'package:nini/features/create_post/presentation/cubit/post_features_cubit.dart';

class _Tokens extends SecureTokenStore {
  @override
  Future<String?> getToken() async => 'test-token';
}

class _RealHttp extends HttpOverrides {}

class _ConvertedImageCompressor extends MediaCompressor {
  bool? forced;
  @override
  Future<File> compressOwnedFile(
    File source, {
    MediaCompressionKind? kind,
    bool allowLargerImageResult = false,
  }) async {
    forced = allowLargerImageResult;
    final result = File('${source.parent.path}/converted.jpg');
    await result.writeAsBytes([255, 216, 255, 1, 2, 3]);
    return result;
  }
}

class _Api extends ApiClient {
  final calls = <String>[];
  final bodies = <Map<String, dynamic>>[];
  int uploads = 0;
  int? failUpload;
  bool losePostResponse = false;
  Completer<void>? gate;
  Completer<void>? uploadGate;
  Completer<void>? getGate;
  Map<String, dynamic>? uploadResponse;
  Map<String, dynamic>? getResponse;

  @override
  Future<Map<String, dynamic>> postMultipart(
    String endpoint, {
    required FormData data,
    required String token,
  }) async {
    expect(endpoint, 'uploads?purpose=post');
    expect(token, 'test-token');
    expect(data.files.map((f) => f.key), ['file']);
    calls.add('upload');
    uploads++;
    await uploadGate?.future;
    if (uploads == failUpload) {
      throw DioException(
        requestOptions: RequestOptions(path: endpoint),
        type: DioExceptionType.connectionError,
      );
    }
    return uploadResponse ??
        {
          'success': true,
          'data': {
            'url': 'https://example.test/$uploads.webp',
            'purpose': 'post',
          },
        };
  }

  @override
  Future<Map<String, dynamic>> post(
    String endpoint, {
    Map<String, dynamic>? data,
    String? token,
  }) async {
    expect(token, 'test-token');
    calls.add(endpoint);
    bodies.add(data!);
    await gate?.future;
    if (losePostResponse) {
      throw DioException(
        requestOptions: RequestOptions(path: endpoint),
        type: DioExceptionType.receiveTimeout,
      );
    }
    return {
      'success': true,
      'data': {
        'id': '00000000-0000-4000-8000-000000000001',
        'title': 'Test title',
        'status': 'pending_review',
      },
    };
  }

  @override
  Future<Map<String, dynamic>> get(
    String endpoint, {
    required String token,
  }) async {
    expect(token, 'test-token');
    calls.add(endpoint);
    await getGate?.future;
    return getResponse ??
        {
          'success': true,
          'data': {
            'items': [
              {
                'id': '00000000-0000-4000-8000-000000000001',
                'title': 'Test title',
                'status': 'pending_review',
              },
            ],
            'total': 1,
            'page': 1,
            'limit': 20,
          },
        };
  }
}

const draft = PostDraft(
  postType: CreatePostType.product,
  categoryKey: 'electronics',
  title: 'Test title',
  caption: 'A real description',
  price: '1,000',
  discount: '10',
  warehouseStock: '3',
);

void main() {
  late Directory directory;
  late _Api api;
  late ApiPostsRepository repository;
  bool current = true;
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('posts-test-');
    api = _Api();
    current = true;
    repository = ApiPostsRepository(
      api,
      _Tokens(),
      isCurrentAccount: () => current,
      onUnauthorized: () async {},
    );
  });
  tearDown(() async => directory.delete(recursive: true));

  Future<GalleryAttachment> image(String name, List<int> bytes) async {
    final file = File('${directory.path}/$name');
    await file.writeAsBytes(bytes);
    final prepared = PreparedGalleryFile(
      file,
      name: name,
      sizeBytes: bytes.length,
    );
    return GalleryAttachment.fromFile(prepared).withPreparedFile(prepared);
  }

  test('maps toman and percent using integers and services omit stock', () {
    final payload = ApiPostsRepository.requestFor(draft);
    expect(payload['price'], 10000);
    expect(payload['discountPrice'], 9000);
    expect(payload['stock'], 3);
    final service = ApiPostsRepository.requestFor(
      draft.copyWith(postType: CreatePostType.services, warehouseStock: ''),
    );
    expect(service['type'], 'service');
    expect(service.containsKey('stock'), isFalse);
    expect(service.containsKey('inventoryStatus'), isFalse);
    expect(
      () => ApiPostsRepository.requestFor(draft.copyWith(price: '1,2,3')),
      throwsA(isA<PostApiException>()),
    );
    expect(
      () => ApiPostsRepository.requestFor(draft.copyWith(price: '0')),
      throwsA(isA<PostApiException>()),
    );
  });

  test('confirmed submissions send the global key and optional personal UUID separately', () async {
    const personalId = '00000000-0000-4000-8000-000000000001';
    final attachment = await image('photo.jpg', [255, 216, 255, 1]);
    final globalOnly = await repository.submit(draft, [attachment]);
    final personal = await repository.submit(
      draft.copyWith(profileCategoryId: personalId),
      [attachment],
    );
    expect(globalOnly.status, 'pending_review');
    expect(personal.status, 'pending_review');
    expect(api.bodies.first['category'], 'electronics');
    expect(api.bodies.first.containsKey('profileCategoryId'), isFalse);
    expect(api.bodies.last['category'], 'electronics');
    expect(api.bodies.last['profileCategoryId'], personalId);
  });

  test(
    'category is optional and structured feature types and units are preserved',
    () {
      const personal = '00000000-0000-4000-8000-000000000001';
      final input = draft.copyWith(
        clearCategory: true,
        profileCategoryId: personal,
        features: const [
          PostFeature(name: 'Area', value: '120', unit: 'm2'),
          PostFeature(name: 'Height', value: '1.5'),
          PostFeature(name: 'Colour', value: 'Blue'),
          PostFeature(name: 'Serial', value: '0012'),
          PostFeature(name: 'Warranty', value: 'true', apiValue: true),
          PostFeature(name: 'Text', value: '120', apiValue: '120'),
        ],
      );
      final payload = ApiPostsRepository.requestFor(input);
      expect(payload.containsKey('category'), isFalse);
      expect(payload['profileCategoryId'], personal);
      expect(payload['features'], [
        {'feature': 'Area', 'value': 120, 'unit': 'm2'},
        {'feature': 'Height', 'value': 1.5},
        {'feature': 'Colour', 'value': 'Blue'},
        {'feature': 'Serial', 'value': '0012'},
        {'feature': 'Warranty', 'value': true},
        {'feature': 'Text', 'value': '120'},
      ]);
      expect(PostFeature.fromJson(input.features.first.toJson()).unit, 'm2');
      expect(PostFeature.fromJson(input.features[4].toJson()).apiValue, true);
      expect(
        () => ApiPostsRepository.requestFor(
          draft.copyWith(categoryKey: personal),
        ),
        throwsA(isA<PostApiException>()),
      );
      expect(
        () => ApiPostsRepository.requestFor(draft.copyWith(categoryKey: '')),
        throwsA(isA<PostApiException>()),
      );
      expect(
        () => ApiPostsRepository.requestFor(draft.copyWith(title: '')),
        throwsA(isA<PostApiException>()),
      );
    },
  );

  test('category-free submission keeps the pending review response', () async {
    final attachment = await image('photo.jpg', [255, 216, 255, 1]);
    final result = await repository.submit(
      draft.copyWith(clearCategory: true),
      [attachment],
    );
    expect(result.status, 'pending_review');
    expect(api.bodies.single.containsKey('category'), isFalse);
  });

  test(
    'editing a stored structured feature preserves its typed value and unit',
    () async {
      final cubit = PostFeaturesCubit(const [
        PostFeature(name: 'Area', value: '120', apiValue: 120, unit: 'm2'),
      ]);
      cubit.edit(0);
      expect(cubit.save('Total area', '120'), isTrue);
      expect(cubit.state.features.single.apiValue, 120);
      expect(cubit.state.features.single.unit, 'm2');
      cubit.edit(0);
      expect(cubit.save('Total area', '121'), isTrue);
      expect(cubit.state.features.single.apiValue, isNull);
      expect(cubit.state.features.single.unit, 'm2');
      await cubit.close();
    },
  );

  test(
    'preparation names a converted HEIC image for its actual JPEG bytes',
    () async {
      final source = File('${directory.path}/photo.heic');
      final bytes = [
        0,
        0,
        0,
        16,
        102,
        116,
        121,
        112,
        104,
        101,
        105,
        99,
        0,
        0,
        0,
        0,
      ];
      await source.writeAsBytes(bytes);
      final input = PreparedGalleryFile(
        source,
        name: 'photo.heic',
        sizeBytes: bytes.length,
      );
      final compressor = _ConvertedImageCompressor();
      final selected = await GalleryMediaPreparer(compressor: compressor)
          .prepare([GalleryAttachment.fromFile(input)], forPost: true);
      final prepared = selected.single.preparedFile!;
      addTearDown(
        () async =>
            Directory(File(prepared.xFile.path).parent.path)
                .delete(recursive: true),
      );
      expect(compressor.forced, isTrue);
      expect(prepared.name, 'photo.jpg');
      expect((await prepared.readAsBytes()).take(3), [255, 216, 255]);
    },
  );

  test('automatic Quill alignment does not block a plain description', () {
    final body = ApiPostsRepository.requestFor(
      draft.copyWith(
        captionDelta: [
          {'insert': 'A real description'},
          {
            'insert': '\n',
            'attributes': {'align': 'right', 'direction': 'rtl'},
          },
        ],
      ),
    );
    expect(body['description'], 'A real description');
    expect(body.containsKey('captionDelta'), isFalse);
  });

  test('uploads sequentially and creates with ordered URLs and real pending identity', () async {
    final a = await image('a.jpg', [255, 216, 255, 1]);
    final b = await image('b.png', [137, 80, 78, 71, 13, 10, 26, 10]);
    final post = await repository.submit(draft, [a, b]);
    expect(api.calls, ['upload', 'upload', 'posts']);
    expect(api.bodies.single['images'], [
      {'url': 'https://example.test/1.webp'},
      {'url': 'https://example.test/2.webp'},
    ]);
    expect(post.id, '00000000-0000-4000-8000-000000000001');
    expect(post.status, 'pending_review');
  });

  test(
    'failed upload preserves confirmed image and retries only missing files',
    () async {
      final a = await image('a.jpg', [255, 216, 255, 1]);
      final b = await image('b.webp', [
        82,
        73,
        70,
        70,
        0,
        0,
        0,
        0,
        87,
        69,
        66,
        80,
      ]);
      api.failUpload = 2;
      await expectLater(
        repository.submit(draft, [a, b]),
        throwsA(isA<DioException>()),
      );
      expect(api.calls, ['upload', 'upload']);
      await repository.submit(draft, [a, b]);
      expect(api.uploads, 3);
      expect(api.bodies.single['images'], [
        {'url': 'https://example.test/1.webp'},
        {'url': 'https://example.test/3.webp'},
      ]);
    },
  );

  test(
    'a changed file is uploaded again and a parallel submission is rejected',
    () async {
      final a = await image('a.jpg', [255, 216, 255, 1]);
      final b = await image('b.jpg', [255, 216, 255, 2]);
      api.failUpload = 2;
      await expectLater(
        repository.submit(draft, [a, b]),
        throwsA(isA<DioException>()),
      );
      await File('${directory.path}/a.jpg').writeAsBytes([255, 216, 255, 3]);
      api.gate = Completer<void>();
      final first = repository.submit(draft, [a, b]);
      while (api.bodies.isEmpty) {
        await Future<void>.delayed(Duration.zero);
      }
      await expectLater(
        repository.submit(draft, [a, b]),
        throwsA(isA<PostApiException>()),
      );
      api.gate!.complete();
      await first;
      expect(api.uploads, 4);
      expect(api.bodies, hasLength(1));
    },
  );

  test('rejects invalid media before any network request', () async {
    final video = await image('video.mp4', [0, 1, 2]);
    await expectLater(
      repository.submit(draft, [video]),
      throwsA(isA<PostApiException>()),
    );
    final oversized = await image('large.jpg', [
      255,
      216,
      255,
      ...List.filled(5 * 1024 * 1024, 0),
    ]);
    await expectLater(
      repository.submit(draft, [oversized]),
      throwsA(isA<PostApiException>()),
    );
    await expectLater(
      repository.submit(draft, List.filled(9, video)),
      throwsA(isA<PostApiException>()),
    );
    expect(api.calls, isEmpty);
  });

  test(
    'unconverted HEIC reports the actual unsupported format before upload',
    () async {
      final a = await image('a.heic', [
        0,
        0,
        0,
        16,
        102,
        116,
        121,
        112,
        104,
        101,
        105,
        99,
        0,
        0,
        0,
        0,
      ]);
      await expectLater(
        repository.submit(draft, [a]),
        throwsA(
          isA<PostApiException>().having(
            (error) => error.message,
            'message',
            contains('HEIC/HEIF'),
          ),
        ),
      );
      expect(api.calls, isEmpty);
    },
  );

  test('invalid upload response never triggers post creation', () async {
    final a = await image('a.jpg', [255, 216, 255, 1]);
    api.uploadResponse = {
      'success': true,
      'data': {'url': 'not-a-url'},
    };
    await expectLater(
      repository.submit(draft, [a]),
      throwsA(isA<PostApiException>()),
    );
    expect(api.calls, ['upload']);
  });

  test('account change during upload stops the post request', () async {
    final a = await image('a.jpg', [255, 216, 255, 1]);
    api.uploadGate = Completer<void>();
    final pending = repository.submit(draft, [a]);
    while (api.uploads == 0) {
      await Future<void>.delayed(Duration.zero);
    }
    current = false;
    api.uploadGate!.complete();
    await expectLater(pending, throwsA(isA<PostApiException>()));
    expect(api.calls, ['upload']);
  });

  test(
    'rich captions are sent as plain text; unsupported inventory is rejected',
    () {
      final rich = draft.copyWith(
        captionDelta: [
          {
            'insert': 'A real description',
            'attributes': {'bold': true},
          },
          {
            'insert': '\n',
            'attributes': {'align': 'right', 'direction': 'rtl'},
          },
        ],
      );
      final body = ApiPostsRepository.requestFor(rich);
      expect(body['description'], 'A real description');
      expect(body.containsKey('captionDelta'), isFalse);
      expect(rich.captionDelta.first['attributes'], {'bold': true});
      expect(
        () => ApiPostsRepository.requestFor(
          draft.copyWith(inventoryStatus: InventoryStatus.preOrder),
        ),
        throwsA(isA<PostApiException>()),
      );
      expect(
        () => ApiPostsRepository.requestFor(
          draft.copyWith(postType: CreatePostType.services),
        ),
        throwsA(isA<PostApiException>()),
      );
    },
  );

  test(
    'ambiguous create reconciles by read and blocks duplicate create',
    () async {
      final a = await image('a.jpg', [255, 216, 255, 1]);
      api.losePostResponse = true;
      await expectLater(
        repository.submit(draft, [a]),
        throwsA(isA<DioException>()),
      );
      expect(api.calls, ['upload', 'posts', 'posts/mine?page=1&limit=20']);
      await expectLater(
        repository.submit(draft, [a]),
        throwsA(isA<PostApiException>()),
      );
      expect(api.bodies, hasLength(1));
    },
  );

  test(
    'My Posts parses status and pagination and blocks changed accounts',
    () async {
      final page = await repository.loadMine();
      expect(page.items.single.status, 'pending_review');
      expect(page.total, 1);
      current = false;
      await expectLater(
        repository.loadMine(),
        throwsA(isA<PostApiException>()),
      );
      expect(api.calls, hasLength(1));
    },
  );

  testWidgets('My Posts displays the backend review status', (tester) async {
    await tester.pumpWidget(
      RepositoryProvider<ApiPostsRepository>.value(
        value: repository,
        child: const MaterialApp(home: PostsScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Test title'), findsOneWidget);
    expect(find.text('pending review'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'My Posts falls back from thumbnail to original and keeps status',
    (tester) async {
      api.getResponse = {
        'success': true,
        'data': {
          'items': [
            {
              'id': '00000000-0000-4000-8000-000000000001',
              'title': 'Test title',
              'status': 'pending_review',
              'image': 'https://example.test/original.jpg',
              'thumbnailUrl': 'https://example.test/thumb.jpg',
            },
          ],
          'total': 1,
          'page': 1,
          'limit': 20,
        },
      };
      await tester.pumpWidget(
        RepositoryProvider<ApiPostsRepository>.value(
          value: repository,
          child: const MaterialApp(home: PostsScreen()),
        ),
      );
      await tester.pump();
      await tester.pump();
      final image = tester.widget<Image>(
        find.byWidgetPredicate(
          (widget) =>
              widget is Image &&
              widget.image is NetworkImage &&
              (widget.image as NetworkImage).url ==
                  'https://example.test/thumb.jpg',
        ),
      );
      expect(
        (image.image as NetworkImage).url,
        'https://example.test/thumb.jpg',
      );
      final fallback = image.errorBuilder!(
        tester.element(find.byType(PostsScreen)),
        Exception('thumbnail failed'),
        null,
      ) as Image;
      expect(
        (fallback.image as NetworkImage).url,
        'https://example.test/original.jpg',
      );
      expect(
        fallback.errorBuilder!(
          tester.element(find.byType(PostsScreen)),
          Exception('failed'),
          null,
        ),
        isA<Icon>(),
      );
      expect(find.text('pending review'), findsOneWidget);
    },
  );

  test('malformed My Posts thumbnail data does not prevent parsing', () {
    final post = MyServerPost.fromJson({
      'id': '00000000-0000-4000-8000-000000000001',
      'title': 'Test title',
      'status': 'published',
      'thumbnailUrl': 42,
      'image': 'https://example.test/original.jpg',
    });
    expect(post.image, 'https://example.test/original.jpg');
  });

  testWidgets(
    'My Posts uses matching grid placeholders while the first page loads',
    (tester) async {
      api.getGate = Completer<void>();
      await tester.pumpWidget(
        RepositoryProvider<ApiPostsRepository>.value(
          value: repository,
          child: const MaterialApp(home: PostsScreen()),
        ),
      );
      await tester.pump();
      expect(find.byType(ProductCardSkeleton), findsWidgets);
      expect(find.byType(AppShimmer), findsOneWidget);
      api.getGate!.complete();
      await tester.pumpAndSettle();
      expect(find.byType(ProductCardSkeleton), findsNothing);
      expect(find.text('pending review'), findsWidgets);
    },
  );

  test(
    'identical simultaneous My Posts requests share one backend request',
    () async {
      api.getGate = Completer<void>();
      final first = repository.loadMine();
      final second = repository.loadMine();
      await Future<void>.delayed(Duration.zero);
      expect(api.calls, ['posts/mine?page=1&limit=20']);
      api.getGate!.complete();
      expect((await first).items.single.id, (await second).items.single.id);
    },
  );

  final configured = Uri.tryParse(AppConfig.apiBaseUrl);
  test('Dio sends the documented upload, creation and list requests', () async {
    final server = await HttpServer.bind(
      InternetAddress.loopbackIPv4,
      configured!.port,
    );
    addTearDown(() => server.close(force: true));
    final calls = <String>[];
    final errors = <Object>[];
    server.listen((request) async {
      try {
        calls.add('${request.method} ${request.uri}');
        expect(request.headers.value('Authorization'), 'Bearer test-token');
        expect(request.headers.value('X-Client'), 'mobile');
        request.response.headers.contentType = ContentType.json;
        if (request.uri.path.endsWith('/uploads')) {
          expect(request.uri.queryParameters, {'purpose': 'post'});
          expect(request.headers.contentType?.mimeType, 'multipart/form-data');
          final body = latin1.decode(
            await request.expand((bytes) => bytes).toList(),
          );
          expect(body, contains('name="file"'));
          expect(body, contains('filename="a.jpg"'));
          expect(body.toLowerCase(), contains('content-type: image/jpeg'));
          request.response.write(
            jsonEncode({
              'success': true,
              'data': {'url': 'https://example.test/a.webp', 'purpose': 'post'},
            }),
          );
        } else if (request.method == 'POST') {
          final body =
              jsonDecode(await utf8.decoder.bind(request).join()) as Map;
          expect(body['price'], 10000);
          expect(body['category'], 'electronics');
          expect(
            body['profileCategoryId'],
            '00000000-0000-4000-8000-000000000001',
          );
          expect(body['images'], [
            {'url': 'https://example.test/a.webp'},
          ]);
          request.response.write(
            jsonEncode({
              'success': true,
              'data': {
                'id': '00000000-0000-4000-8000-000000000001',
                'title': 'Test title',
                'status': 'pending_review',
              },
            }),
          );
        } else {
          expect(request.uri.queryParameters, {'page': '1', 'limit': '20'});
          request.response.write(
            jsonEncode({
              'success': true,
              'data': {'items': [], 'total': 0, 'page': 1, 'limit': 20},
            }),
          );
        }
      } catch (error) {
        errors.add(error);
        request.response.statusCode = 500;
      } finally {
        await request.response.close();
      }
    });
    final a = await image('a.png', [255, 216, 255, 1]);
    await HttpOverrides.runWithHttpOverrides(() async {
      final real = ApiPostsRepository(
        ApiClient(),
        _Tokens(),
        isCurrentAccount: () => true,
        onUnauthorized: () async {},
      );
      final result = await real.submit(
        draft.copyWith(
          profileCategoryId: '00000000-0000-4000-8000-000000000001',
        ),
        [a],
      );
      expect(result.status, 'pending_review');
      expect((await real.loadMine()).items, isEmpty);
    }, _RealHttp());
    expect(errors, isEmpty);
    expect(calls, [
      'POST /api/uploads?purpose=post',
      'POST /api/posts',
      'GET /api/posts/mine?page=1&limit=20',
    ]);
  }, skip: configured?.host != '127.0.0.1');
}
