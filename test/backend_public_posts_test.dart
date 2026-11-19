import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nini/core/network/api_client.dart';
import 'package:nini/core/config/app_config/app_config.dart';
import 'package:nini/core/security/secure_token_store.dart';
import 'package:nini/features/posts/data/api_posts_repository.dart';
import 'package:nini/features/posts/presentation/cubit/backend_posts_cubit.dart';
import 'package:nini/features/search/presentation/pages/search_screen.dart';
import 'package:nini/features/search/presentation/widgets/results/search_result_card.dart';
import 'package:nini/features/search/presentation/widgets/common/search_city_list.dart';
import 'package:nini/features/search/presentation/widgets/results/search_results_grid.dart';
import 'package:nini/core/localization/strings/search_strings.dart';
import 'package:nini/shared/widgets/skeleton/app_shimmer.dart';
import 'package:nini/shared/widgets/skeleton/product_card_skeleton.dart';
import 'package:nini/shared/widgets/skeleton/post_card_skeleton.dart';
import 'package:nini/shared/widgets/skeleton/detail_skeleton.dart';
import 'package:nini/features/post_detail/presentation/cubit/post_detail_cubit.dart';
import 'package:nini/features/home/presentation/pages/home_screen.dart';

const postId = '00000000-0000-4000-8000-000000000001';
const secondId = '00000000-0000-4000-8000-000000000002';
const categoryId = '00000000-0000-4000-8000-000000000003';

Map<String, dynamic> card({
  String id = postId,
  String type = 'product',
  String? status,
}) => {
  'id': id,
  'title': 'A real post',
  'postType': type,
  'category': {'key': 'electronics', 'label': 'Electronics'},
  'profileCategory': {'id': categoryId, 'name': 'Electrical'},
  'owner': {
    'id': 'owner-id',
    'name': 'Owner',
    'username': 'owner',
    'avatarUrl': 'https://example.test/avatar.jpg',
  },
  'price': 12345,
  'finalPrice': 10000,
  'image': 'https://example.test/image.jpg',
  'publishedAt': '2026-11-19T00:00:00Z',
  if (status != null) 'status': status,
};

class Tokens extends SecureTokenStore {
  @override
  Future<String?> getToken() async => 'test-token';
}

class _RealHttp extends HttpOverrides {}

class Api extends ApiClient {
  final calls = <Uri>[];
  Map<String, dynamic> result = {};
  Completer<void>? publicGate;
  Object? publicError;
  @override
  Future<Map<String, dynamic>> getPublic(
    String endpoint, {
    String? token,
  }) async {
    expect(token, 'test-token');
    calls.add(Uri.parse(endpoint));
    await publicGate?.future;
    if (publicError != null) throw publicError!;
    return result;
  }

  @override
  Future<Map<String, dynamic>> get(
    String endpoint, {
    required String token,
  }) async {
    expect(token, 'test-token');
    calls.add(Uri.parse(endpoint));
    return result;
  }
}

class SearchApi extends ApiClient {
  final calls = <Uri>[];
  bool fail = false;

  @override
  Future<Map<String, dynamic>> getPublic(
    String endpoint, {
    String? token,
  }) async {
    final uri = Uri.parse(endpoint);
    calls.add(uri);
    if (fail) throw Exception('network error');
    final page = int.parse(uri.queryParameters['page']!);
    final items = [
      {...card(), 'image': null, 'location': null},
      {
        ...card(id: secondId, type: 'service'),
        'image': null,
        'location': 'Elsewhere',
      },
      {...card(id: categoryId, status: 'rejected'), 'image': null},
    ];
    final data = {'items': items, 'total': 3, 'page': page, 'limit': 20};
    return {
      'success': true,
      'data': uri.path == 'search'
          ? {
              'posts': data,
              'users': {
                'items': [
                  {'name': 'Person'},
                ],
                'total': 1,
              },
            }
          : data,
    };
  }
}

void main() {
  final configured = Uri.tryParse(AppConfig.apiBaseUrl);
  late Api api;
  late ApiPostsRepository repo;
  setUp(() {
    api = Api();
    repo = ApiPostsRepository(
      api,
      Tokens(),
      isCurrentAccount: () => true,
      onUnauthorized: () async {},
    );
  });
  Map<String, dynamic> page(
    List<Map<String, dynamic>> items, {
    int total = 1,
  }) => {'items': items, 'total': total, 'page': 1, 'limit': 20};

  test('loopback HTTP shares feed and forces manual refresh', () async {
    final server = await HttpServer.bind(
      InternetAddress.loopbackIPv4,
      configured!.port,
    );
    addTearDown(() => server.close(force: true));
    var requests = 0;
    server.listen((request) async {
      requests++;
      request.response.headers.contentType = ContentType.json;
      request.response.write(
        jsonEncode({
          'success': true,
          'data': page([card()]),
        }),
      );
      await request.response.close();
    });
    await HttpOverrides.runWithHttpOverrides(() async {
      final repository = ApiPostsRepository(
        ApiClient(),
        Tokens(),
        isCurrentAccount: () => true,
        onUnauthorized: () async {},
      );
      final home = FeedCubit(repository);
      final search = BackendPostsCubit(
        (page) => repository.loadFeed(page: page),
      );
      await home.refresh();
      await search.refresh();
      await home.refresh();
      expect(requests, 1);
      await home.refreshFromServer();
      expect(requests, 2);
      await home.close();
      await search.close();
    }, _RealHttp());
  }, skip: configured?.host != '127.0.0.1');

  test(
    'shared feed reduces Home Search Home and concurrent request counts',
    () async {
      api.result = {
        'success': true,
        'data': page([card()]),
      };
      final home = FeedCubit(repo);
      final search = BackendPostsCubit((page) => repo.loadFeed(page: page));
      await home.refresh();
      await search.refresh();
      await home.refresh();
      expect(api.calls.length, 1);
      api.publicGate = Completer<void>();
      final first = repo.loadFeed(force: true);
      final second = repo.loadFeed();
      await Future<void>.delayed(Duration.zero);
      expect(api.calls.length, 2);
      api.publicGate!.complete();
      await Future.wait([first, second]);
      await home.refreshFromServer();
      expect(api.calls.length, 3);
      api.result = {
        'success': true,
        'data': {
          'posts': page([card()]),
        },
      };
      await repo.search(query: 'first');
      await repo.search(query: 'second');
      expect(api.calls.length, 5);
      api.result = {
        'success': true,
        'data': {
          ...page([card()]),
          'page': 2,
        },
      };
      await repo.loadFeed(page: 2);
      expect(api.calls.length, 6);
      await home.close();
      await search.close();
    },
  );

  test('feed maps real products and services and filters explicit private statuses', () async {
    api.result = {
      'success': true,
      'data': page([
        card(),
        card(id: secondId, type: 'service'),
        card(status: 'pending_review'),
        card(status: 'rejected'),
      ], total: 4),
    };
    final result = await repo.loadFeed();
    expect(api.calls.single.path, 'feed');
    expect(api.calls.single.queryParameters, {
      'scope': 'all',
      'page': '1',
      'limit': '20',
    });
    expect(result.items.length, 2);
    final post = result.items.first;
    expect(post.id, postId);
    expect(post.price, '1000');
    expect(post.originalPrice, '1234.5');
    expect(post.media.single.path, 'https://example.test/image.jpg');
    expect(post.profileCategoryId, categoryId);
    expect(post.metadata['seller']['id'], 'owner-id');
    expect(result.items.last.isService, isTrue);
  });
  test('search encodes query and requests public posts', () async {
    api.result = {
      'success': true,
      'data': {
        'posts': page([card()]),
      },
    };
    final result = await repo.search(query: 'wire & برق');
    expect(api.calls.single.path, 'search');
    expect(api.calls.single.queryParameters['q'], 'wire & برق');
    expect(api.calls.single.queryParameters['type'], 'posts');
    expect(result.items.single.id, postId);
    expect((result.total, result.page, result.limit), (1, 1, 20));
    expect(result.searchId, isNull);
    expect(result.understood, isNull);
  });

  test('search retains documented metadata and backend order', () async {
    api.result = {
      'success': true,
      'data': {
        'searchId': 'server-returned-id',
        'understood': {
          'keywords': ['mobile', 'phone'],
          'intent': 'buy',
          'location': 'Tehran',
          'measures': [
            {'value': 120, 'unit': 'm2'},
            {'value': 1.5, 'unit': 'kg'},
          ],
          'didYouMean': [
            {'from': 'samsong', 'to': 'samsung'},
          ],
        },
        'posts': page([card(id: secondId), card(id: postId)], total: 2),
      },
    };
    final response = await repo.search(query: 'phone');
    expect(response.items.map((post) => post.id), [secondId, postId]);
    expect(response.searchId, 'server-returned-id');
    expect(response.understood?.keywords, ['mobile', 'phone']);
    expect(response.understood?.intent, 'buy');
    expect(response.understood?.location, 'Tehran');
    expect(response.understood?.measures?.first, (value: 120, unit: 'm2'));
    expect(response.understood?.didYouMean?.single, (
      from: 'samsong',
      to: 'samsung',
    ));
  });

  test(
    'search metadata safely handles null and omitted optional fields',
    () async {
      api.result = {
        'success': true,
        'data': {
          'searchId': null,
          'understood': {'intent': null, 'location': null, 'didYouMean': null},
          'posts': page([card()]),
        },
      };
      final result = await repo.search(query: 'phone');
      expect(result.searchId, isNull);
      expect(result.understood?.keywords, isNull);
      expect(result.understood?.measures, isNull);
      expect(result.understood?.didYouMean, isNull);
    },
  );

  test(
    'pagination keeps first-page search metadata and backend ordering',
    () async {
      const understood = SearchUnderstood(keywords: ['first']);
      final cubit = BackendPostsCubit(
        (page) async => BackendPostsPage(
          items: page == 1
              ? [backendPostFromJson(card(id: secondId))]
              : [backendPostFromJson(card(id: postId))],
          total: 2,
          page: page,
          limit: 1,
          searchId: page == 1 ? 'page-one' : 'unexpected-page-two',
          understood: page == 1
              ? understood
              : const SearchUnderstood(keywords: ['other']),
        ),
      );
      await cubit.refresh();
      await cubit.loadMore();
      expect(cubit.state.posts.map((post) => post.id), [secondId, postId]);
      expect(cubit.state.searchId, 'page-one');
      expect(cubit.state.understood, same(understood));
      await cubit.close();
    },
  );

  test('uncategorized backend posts remain readable', () {
    final post = backendPostFromJson({...card(), 'category': null});
    expect(post.category, isEmpty);
    expect(post.id, postId);
  });

  test(
    'feed cache expires after 25 seconds and keeps page and limit separate',
    () async {
      var now = DateTime.utc(2026, 1, 1);
      final repository = ApiPostsRepository(
        api,
        Tokens(),
        isCurrentAccount: () => true,
        onUnauthorized: () async {},
        clock: () => now,
      );
      api.result = {
        'success': true,
        'data': page([card()]),
      };
      await repository.loadFeed();
      now = now.add(const Duration(seconds: 24));
      await repository.loadFeed();
      expect(api.calls.length, 1);
      now = now.add(const Duration(seconds: 1));
      await repository.loadFeed();
      expect(api.calls.length, 2);
      api.result = {
        'success': true,
        'data': {
          ...page([card()]),
          'limit': 10,
        },
      };
      await repository.loadFeed(limit: 10);
      expect(api.calls.length, 3);
      api.result = {
        'success': true,
        'data': {
          ...page([card()]),
          'page': 2,
        },
      };
      await repository.loadFeed(page: 2);
      expect(api.calls.length, 4);
      await repository.loadFeed(page: 2);
      expect(api.calls.length, 4);
      expect(api.calls.last.queryParameters, {
        'scope': 'all',
        'page': '2',
        'limit': '20',
      });
    },
  );

  test(
    'forced refresh returns new approved posts and failure is never cached',
    () async {
      api.result = {
        'success': true,
        'data': page([
          card(status: 'published'),
          card(id: secondId, status: 'pending_review'),
        ], total: 2),
      };
      final initial = await repo.loadFeed();
      expect(initial.items.map((post) => post.id), [postId]);
      api.publicError = Exception('offline');
      await expectLater(repo.loadFeed(force: true), throwsException);
      api.publicError = null;
      api.result = {
        'success': true,
        'data': page([
          card(id: secondId, status: 'published'),
          card(status: 'rejected'),
        ], total: 2),
      };
      final updated = await repo.loadFeed();
      expect(updated.items.map((post) => post.id), [secondId]);
      expect(api.calls.length, 3);
      await repo.loadFeed();
      expect(api.calls.length, 3);
    },
  );

  test(
    'feed cache and pending results cannot cross accounts or logout',
    () async {
      var current = true;
      final firstAccount = ApiPostsRepository(
        api,
        Tokens(),
        isCurrentAccount: () => current,
        onUnauthorized: () async {},
      );
      api.result = {
        'success': true,
        'data': page([card()]),
      };
      await firstAccount.loadFeed();
      final cachedHit = firstAccount.loadFeed();
      current = false;
      await expectLater(cachedHit, throwsA(isA<PostApiException>()));
      await expectLater(
        firstAccount.loadFeed(),
        throwsA(isA<PostApiException>()),
      );
      final nextAccount = ApiPostsRepository(
        api,
        Tokens(),
        isCurrentAccount: () => true,
        onUnauthorized: () async {},
      );
      api.result = {
        'success': true,
        'data': page([card(id: secondId)]),
      };
      expect((await nextAccount.loadFeed()).items.single.id, secondId);
      expect(api.calls.length, 2);
      current = true;
      api.publicGate = Completer<void>();
      final pending = firstAccount.loadFeed(force: true);
      await Future<void>.delayed(Duration.zero);
      current = false;
      api.publicGate!.complete();
      await expectLater(pending, throwsA(isA<PostApiException>()));
    },
  );

  test(
    'manual refresh retains existing posts when the request fails',
    () async {
      api.result = {
        'success': true,
        'data': page([card()]),
      };
      final home = FeedCubit(repo);
      await home.refresh();
      api.publicError = Exception('offline');
      await home.refreshFromServer();
      expect(home.state.error, isTrue);
      expect(home.state.failedRefresh, isTrue);
      expect(home.state.posts.single.id, postId);
      api.publicError = null;
      await home.refreshFromServer();
      expect(home.state.error, isFalse);
      expect(api.calls.length, 3);
      await home.close();
    },
  );
  test('refreshing page one invalidates cached later pages', () async {
    api.result = {
      'success': true,
      'data': page([card()]),
    };
    await repo.loadFeed();
    api.result = {
      'success': true,
      'data': {
        ...page([card(id: secondId)]),
        'page': 2,
      },
    };
    await repo.loadFeed(page: 2);
    await repo.loadFeed(page: 2);
    expect(api.calls.length, 2);
    api.result = {
      'success': true,
      'data': page([card()]),
    };
    await repo.loadFeed(force: true);
    api.result = {
      'success': true,
      'data': {
        ...page([card(id: secondId)]),
        'page': 2,
      },
    };
    await repo.loadFeed(page: 2);
    expect(api.calls.length, 4);
  });

  test(
    'an old in-flight later page cannot refill the refreshed feed cache',
    () async {
      final gate = Completer<void>();
      api.publicGate = gate;
      final oldPage = repo.loadFeed(page: 2);
      await Future<void>.delayed(Duration.zero);
      api.publicGate = null;
      api.result = {
        'success': true,
        'data': page([card()]),
      };
      await repo.loadFeed(force: true);
      api.result = {
        'success': true,
        'data': {
          ...page([card(id: secondId)]),
          'page': 2,
        },
      };
      gate.complete();
      await oldPage;
      await repo.loadFeed(page: 2);
      expect(api.calls.length, 3);
    },
  );

  test(
    'manual refresh starts fresh when an automatic request is already running',
    () async {
      final gate = Completer<void>();
      api.publicGate = gate;
      final earlier = repo.loadFeed();
      await Future<void>.delayed(Duration.zero);
      api.publicGate = null;
      api.result = {
        'success': true,
        'data': page([card(id: secondId)]),
      };
      expect((await repo.loadFeed(force: true)).items.single.id, secondId);
      api.result = {
        'success': true,
        'data': page([card()]),
      };
      gate.complete();
      await earlier;
      expect((await repo.loadFeed()).items.single.id, secondId);
      expect(api.calls.length, 2);
    },
  );

  test('simultaneous manual refreshes share the same fresh request', () async {
    api.result = {
      'success': true,
      'data': page([card()]),
    };
    api.publicGate = Completer<void>();
    final first = repo.loadFeed(force: true);
    final second = repo.loadFeed(force: true);
    await Future<void>.delayed(Duration.zero);
    expect(api.calls.length, 1);
    api.publicGate!.complete();
    expect((await first).items.single.id, postId);
    expect((await second).items.single.id, postId);
  });

  testWidgets(
    'Home and empty Search share the feed and pull refresh forces a request',
    (tester) async {
      final client = SearchApi();
      final repository = ApiPostsRepository(
        client,
        Tokens(),
        isCurrentAccount: () => true,
        onUnauthorized: () async {},
      );
      final feed = FeedCubit(repository);
      final tab = ValueNotifier<int>(0);
      await tester.pumpWidget(
        RepositoryProvider<ApiPostsRepository>.value(
          value: repository,
          child: BlocProvider<FeedCubit>.value(
            value: feed,
            child: MaterialApp(
              home: Scaffold(
                body: ValueListenableBuilder<int>(
                  valueListenable: tab,
                  builder: (_, index, _) => IndexedStack(
                    index: index,
                    children: [
                      HomeScreen(active: index == 0),
                      SearchScreen(active: index == 1),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(client.calls.where((uri) => uri.path == 'feed').length, 1);
      tab.value = 1;
      await tester.pumpAndSettle();
      expect(find.byType(SearchResultCard), findsNWidgets(2));
      tab.value = 0;
      await tester.pumpAndSettle();
      expect(client.calls.where((uri) => uri.path == 'feed').length, 1);
      final indicator = tester.widget<RefreshIndicator>(
        find.byType(RefreshIndicator).first,
      );
      await indicator.onRefresh();
      await tester.pumpAndSettle();
      expect(client.calls.where((uri) => uri.path == 'feed').length, 2);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 1));
      await feed.close();
      tab.dispose();
    },
  );

  test('own published posts reuse mine with personal category UUID', () async {
    api.result = {
      'success': true,
      'data': page([
        card(status: 'published'),
        card(id: secondId, status: 'rejected'),
      ], total: 2),
    };
    final result = await repo.loadPublishedMine(categoryId: categoryId);
    expect(api.calls.single.path, 'posts/mine');
    expect(api.calls.single.queryParameters['status'], 'published');
    expect(api.calls.single.queryParameters['categoryId'], categoryId);
    expect(result.items.map((p) => p.id), [postId]);
  });
  test('detail fetches the actual ID and maps full real images', () async {
    api.result = {
      'success': true,
      'data': {
        ...card(),
        'description': 'Real description',
        'images': [
          {'url': 'https://example.test/full.png', 'altText': 'view'},
        ],
      },
    };
    final post = await repo.loadDetail(postId);
    expect(api.calls.single.path, 'posts/$postId');
    expect(post.caption, 'Real description');
    expect(post.media.single.path, 'https://example.test/full.png');
    api.result = {'success': true, 'data': card(status: 'rejected')};
    await expectLater(repo.loadDetail(postId), throwsFormatException);
  });
  test(
    'pagination deduplicates IDs and retains results after failure',
    () async {
      final item = backendPostFromJson(card());
      final other = backendPostFromJson(card(id: secondId));
      var fail = false;
      final cubit = BackendPostsCubit((page) async {
        if (fail) throw Exception('offline');
        return BackendPostsPage(
          items: page == 1 ? [item] : [item, other],
          total: 3,
          page: page,
          limit: 1,
        );
      });
      await cubit.refresh();
      await cubit.loadMore();
      expect(cubit.state.posts.map((p) => p.id), [postId, secondId]);
      fail = true;
      await cubit.loadMore();
      expect(cubit.state.error, isTrue);
      expect(cubit.state.posts.length, 2);
      await cubit.close();
    },
  );
  test('stale search response cannot replace the newer response', () async {
    final first = Completer<BackendPostsPage>();
    final cubit = BackendPostsCubit((_) => first.future);
    final old = cubit.refresh();
    final newPost = backendPostFromJson(card(id: secondId));
    await cubit.refresh(
      load: (_) async => BackendPostsPage(
        items: [newPost],
        total: 1,
        page: 1,
        limit: 20,
        searchId: 'new-query',
        understood: const SearchUnderstood(keywords: ['new']),
      ),
    );
    first.complete(
      BackendPostsPage(
        items: [backendPostFromJson(card())],
        total: 1,
        page: 1,
        limit: 20,
        searchId: 'old-query',
        understood: const SearchUnderstood(keywords: ['old']),
      ),
    );
    await old;
    expect(cubit.state.posts.single.id, secondId);
    expect(cubit.state.searchId, 'new-query');
    expect(cubit.state.understood?.keywords, ['new']);
    await cubit.close();
  });

  test('refresh retains existing posts and replaces them on success', () async {
    final first = backendPostFromJson(card());
    final second = backendPostFromJson(card(id: secondId));
    final next = Completer<BackendPostsPage>();
    var calls = 0;
    final cubit = BackendPostsCubit((_) {
      if (calls++ == 0) {
        return Future.value(
          BackendPostsPage(items: [first], total: 1, page: 1, limit: 20),
        );
      }
      return next.future;
    });
    await cubit.refresh();
    final refreshing = cubit.refresh();
    expect(cubit.state.loading, isTrue);
    expect(cubit.state.posts.single.id, postId);
    next.complete(
      BackendPostsPage(items: [second], total: 1, page: 1, limit: 20),
    );
    await refreshing;
    expect(cubit.state.posts.single.id, secondId);
    await cubit.close();
  });

  test('refresh failure keeps existing posts for retry', () async {
    var calls = 0;
    final cubit = BackendPostsCubit((_) async {
      if (calls++ > 0) throw Exception('offline');
      return BackendPostsPage(
        items: [backendPostFromJson(card())],
        total: 1,
        page: 1,
        limit: 20,
      );
    });
    await cubit.refresh();
    await cubit.refresh();
    expect(cubit.state.error, isTrue);
    expect(cubit.state.posts.single.id, postId);
    await cubit.close();
  });

  testWidgets('Home media skeleton is square and Detail retains known title', (
    tester,
  ) async {
    final post = backendPostFromJson({...card(), 'image': null});
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: SingleChildScrollView(child: PostCardSkeleton())),
      ),
    );
    final image = find
        .descendant(
          of: find.byType(PostCardSkeleton),
          matching: find.byType(AspectRatio),
        )
        .first;
    expect(
      tester.getSize(image).width,
      closeTo(tester.getSize(image).height, .01),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider(
          create: (_) => PostDetailCubit(),
          child: Scaffold(body: DetailsSkeleton(post: post)),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('A real post'), findsOneWidget);
    expect(find.byType(PostCardSkeleton), findsNothing);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });

  for (final width in [320.0, 390.0, 720.0]) {
    for (final dark in [false, true]) {
      testWidgets(
        'search skeleton matches card geometry at $width in ${dark ? 'dark' : 'light'} mode',
        (tester) async {
          final post = backendPostFromJson({...card(), 'image': null});
          Widget screen(bool loading) => MaterialApp(
            theme: dark ? ThemeData.dark() : ThemeData.light(),
            home: MediaQuery(
              data: const MediaQueryData(disableAnimations: true),
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: Scaffold(
                  body: Center(
                    child: SizedBox(
                      width: width,
                      height: 550,
                      child: RepaintBoundary(
                        key: const ValueKey('loading-grid-preview'),
                        child: SearchResultsGrid(
                          posts: [post],
                          isLoading: loading,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpWidget(screen(true));
          await tester.pump();
          expect(find.byType(AppShimmer), findsOneWidget);
          expect(find.byType(ShaderMask), findsNothing);
          final skeleton = find.byType(ProductCardSkeleton).first;
          final skeletonSize = tester.getSize(skeleton);
          final image = find
              .descendant(of: skeleton, matching: find.byType(AppSkeletonBox))
              .first;
          final imageSize = tester.getSize(image);
          expect(imageSize.width, closeTo(imageSize.height, .01));
          expect(imageSize.width, closeTo(skeletonSize.width, .01));
          if (width == 390 && const bool.fromEnvironment('CAPTURE_SKELETONS')) {
            await expectLater(
              find.byKey(const ValueKey('loading-grid-preview')),
              matchesGoldenFile(
                '/tmp/hywork-loading-grid-${dark ? 'dark' : 'light'}.png',
              ),
            );
          }
          await tester.pumpWidget(screen(false));
          await tester.pump();
          expect(tester.getSize(find.byType(SearchResultCard)), skeletonSize);
          await tester.pumpWidget(const SizedBox());
          await tester.pump(const Duration(seconds: 1));
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  testWidgets(
    'feed and exact title search render public results without filtering missing locations',
    (tester) async {
      final client = SearchApi();
      String? openedId;
      final repository = ApiPostsRepository(
        client,
        Tokens(),
        isCurrentAccount: () => true,
        onUnauthorized: () async {},
      );
      await tester.pumpWidget(
        RepositoryProvider<ApiPostsRepository>.value(
          value: repository,
          child: MaterialApp(
            home: Scaffold(
              body: SearchScreen(
                onPostSelected: (post, seller) => openedId = post.id,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(client.calls.single.path, 'feed');
      expect(find.byType(SearchResultCard), findsNWidgets(2));
      await tester.enterText(find.byType(TextField), 'A real post');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();
      expect(client.calls.last.path, 'search');
      expect(client.calls.last.queryParameters['q'], 'A real post');
      expect(client.calls.where((uri) => uri.path == 'search').length, 1);
      final cards = tester
          .widgetList<SearchResultCard>(find.byType(SearchResultCard))
          .toList();
      expect(cards.map((card) => card.post.id), [postId, secondId]);
      expect(cards.last.post.isService, isTrue);
      await tester.tap(find.byType(SearchResultCard).first);
      expect(openedId, postId);
      await tester.enterText(find.byType(TextField), '');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();
      expect(client.calls.where((uri) => uri.path == 'feed').length, 1);
      expect(find.byType(SearchResultCard), findsNWidgets(2));
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 1));
    },
  );

  testWidgets(
    'explicit city is sent in the backend query and selection refreshes results',
    (tester) async {
      final client = SearchApi();
      final repository = ApiPostsRepository(
        client,
        Tokens(),
        isCurrentAccount: () => true,
        onUnauthorized: () async {},
      );
      await tester.pumpWidget(
        RepositoryProvider<ApiPostsRepository>.value(
          value: repository,
          child: const MaterialApp(home: Scaffold(body: SearchScreen())),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip(SearchStrings.chooseCity));
      await tester.pumpAndSettle();
      expect(find.byType(SearchCityList), findsOneWidget);
      await tester.tap(find.text('Mashhad').last);
      await tester.pumpAndSettle();
      expect(client.calls.last.path, 'search');
      expect(client.calls.last.queryParameters['q'], 'مشهد');
      expect(find.byType(SearchResultCard), findsNWidgets(2));
      await tester.enterText(find.byType(TextField), 'A real post');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();
      expect(client.calls.last.queryParameters['q'], 'A real post مشهد');
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 1));
    },
  );

  testWidgets(
    'backend failures show retry instead of an empty successful grid',
    (tester) async {
      final client = SearchApi()..fail = true;
      final repository = ApiPostsRepository(
        client,
        Tokens(),
        isCurrentAccount: () => true,
        onUnauthorized: () async {},
      );
      await tester.pumpWidget(
        RepositoryProvider<ApiPostsRepository>.value(
          value: repository,
          child: const MaterialApp(home: Scaffold(body: SearchScreen())),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Could not load search results. Retry'), findsOneWidget);
    },
  );
}
