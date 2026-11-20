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
import 'package:nini/features/posts/presentation/cubit/post_likes_cubit.dart';
import 'package:nini/features/saved_posts/presentation/cubit/saved_posts_cubit.dart';
import 'package:nini/features/saved_posts/domain/saved_posts_repository.dart';
import 'package:nini/features/saved_posts/domain/saved_post.dart';
import 'package:dio/dio.dart';
import 'package:nini/features/search/presentation/pages/search_screen.dart';
import 'package:nini/features/search/presentation/cubit/search_cubit.dart';
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
import 'package:nini/features/posts/presentation/widgets/interactions/comments_sheet.dart';
import 'package:nini/shared/models/post/post_item.dart';

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

const commentId = '40000000-0000-4000-8000-000000000001';
const replyId = '40000000-0000-4000-8000-000000000002';
Map<String, dynamic> commentData({
  String id = commentId,
  String? parentId,
  String text = 'Real comment',
  bool canDelete = true,
}) => {
  'id': id,
  'postId': postId,
  'parentId': parentId,
  'text': text,
  'author': {
    'id': secondId,
    'name': 'Real author',
    'username': 'author',
    'avatarUrl': null,
  },
  'createdAt': '2026-11-19T00:00:00Z',
  'canDelete': canDelete,
  'repliesCount': 0,
};

class CommentsApi extends ApiClient {
  final calls = <String>[];
  final bodies = <Map<String, dynamic>>[];
  Completer<void>? gate;
  Completer<void>? getGate;
  Object? failure;
  List<Map<String, dynamic>> comments = [];
  int total = 0;
  @override
  Future<Map<String, dynamic>> getPublic(
    String endpoint, {
    String? token,
  }) async {
    calls.add('GET $endpoint');
    expect(token, 'test-token');
    if (endpoint.contains('/comments?')) {
      final uri = Uri.parse(endpoint);
      await getGate?.future;
      return {
        'success': true,
        'data': {
          'items': comments,
          'total': total,
          'page': int.parse(uri.queryParameters['page']!),
          'limit': 20,
        },
      };
    }
    return {
      'success': true,
      'data': {...card(), 'commentsCount': total},
    };
  }

  @override
  Future<Map<String, dynamic>> post(
    String endpoint, {
    Map<String, dynamic>? data,
    String? token,
  }) async {
    calls.add('POST $endpoint');
    expect(token, 'test-token');
    bodies.add(data!);
    await gate?.future;
    if (failure != null) throw failure!;
    return {
      'success': true,
      'data': commentData(
        id: data['parentId'] == null ? commentId : replyId,
        parentId: data['parentId'] as String?,
        text: data['text'] as String,
      ),
    };
  }

  @override
  Future<Map<String, dynamic>> delete(
    String endpoint, {
    required String token,
  }) async {
    calls.add('DELETE $endpoint');
    expect(token, 'test-token');
    if (failure != null) throw failure!;
    return {
      'success': true,
      'data': {
        'id': endpoint.split('/').last,
        'deleted': true,
        'removedCount': 1,
        'commentsCount': 0,
      },
    };
  }
}

class LocalSavedFake implements SavedPostsRepository {
  List<SavedPost> items = [];
  @override
  Future<List<SavedPost>> load() async => List.of(items);
  @override
  Future<void> save(List<SavedPost> posts) async {
    items = List.of(posts);
  }
}

class SaveApi extends ApiClient {
  final calls = <String>[];
  final pages = <int, List<Map<String, dynamic>>>{};
  bool saved = false;
  Object? failure;
  Object? readFailure;
  Object? listFailure;
  Completer<void>? gate;
  @override
  Future<Map<String, dynamic>> get(
    String endpoint, {
    required String token,
  }) async {
    expect(token, 'test-token');
    calls.add('GET $endpoint');
    if (listFailure != null) throw listFailure!;
    final page = int.parse(Uri.parse(endpoint).queryParameters['page']!);
    return {
      'success': true,
      'data': {
        'items':
            pages[page] ??
            (saved && page == 1
                ? [
                    {...card(), 'isSaved': true},
                  ]
                : []),
        'total': pages.isEmpty ? (saved ? 1 : 0) : 21,
        'page': page,
        'limit': 20,
      },
    };
  }

  @override
  Future<Map<String, dynamic>> getPublic(
    String endpoint, {
    String? token,
  }) async {
    calls.add('GET $endpoint');
    if (readFailure != null) throw readFailure!;
    return {
      'success': true,
      'data': {...card(), 'isSaved': saved},
    };
  }

  @override
  Future<Map<String, dynamic>> post(
    String endpoint, {
    Map<String, dynamic>? data,
    String? token,
  }) async {
    expect(token, 'test-token');
    expect(data, isNull);
    calls.add('POST $endpoint');
    await gate?.future;
    if (failure != null) throw failure!;
    saved = true;
    return {
      'success': true,
      'data': {'postId': postId, 'isSaved': true},
    };
  }

  @override
  Future<Map<String, dynamic>> delete(
    String endpoint, {
    required String token,
  }) async {
    expect(token, 'test-token');
    calls.add('DELETE $endpoint');
    await gate?.future;
    if (failure != null) throw failure!;
    saved = false;
    return {
      'success': true,
      'data': {'postId': postId, 'isSaved': false},
    };
  }
}

class LikeApi extends ApiClient {
  final calls = <String>[];
  Completer<void>? gate;
  Object? failure;
  Object? readFailure;
  bool liked = false;
  int count = 12;
  Map<String, dynamic>? response;
  @override
  Future<Map<String, dynamic>> post(
    String endpoint, {
    Map<String, dynamic>? data,
    String? token,
  }) async {
    calls.add('POST $endpoint');
    expect(token, 'test-token');
    expect(data, isNull);
    await gate?.future;
    if (failure != null) throw failure!;
    liked = true;
    return response ??
        {
          'success': true,
          'data': {'postId': postId, 'isLiked': true, 'likes': 13},
        };
  }

  @override
  Future<Map<String, dynamic>> delete(
    String endpoint, {
    required String token,
  }) async {
    calls.add('DELETE $endpoint');
    expect(token, 'test-token');
    await gate?.future;
    if (failure != null) throw failure!;
    liked = false;
    return response ??
        {
          'success': true,
          'data': {'postId': postId, 'isLiked': false, 'likes': 12},
        };
  }

  @override
  Future<Map<String, dynamic>> getPublic(
    String endpoint, {
    String? token,
  }) async {
    calls.add('GET $endpoint');
    if (readFailure != null) throw readFailure!;
    return {
      'success': true,
      'data': {...card(), 'isLiked': liked, 'likes': count},
    };
  }
}

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

class SmartSearchApi extends ApiClient {
  final calls = <Uri>[];
  final logs = <Map<String, dynamic>>[];
  final suggestionRequests = <String, Completer<Map<String, dynamic>>>{};
  bool failPopular = false;
  bool failLogs = false;

  @override
  Future<Map<String, dynamic>> getPublic(
    String endpoint, {
    String? token,
  }) async {
    final uri = Uri.parse(endpoint);
    calls.add(uri);
    if (uri.path == 'search/suggestions') {
      return (suggestionRequests[uri.queryParameters['q']!] ??= Completer())
          .future;
    }
    if (uri.path == 'search/popular') {
      if (failPopular) throw Exception('offline');
      return {
        'success': true,
        'data': {
          'items': [
            {'query': 'Popular one'},
            {'query': 'Popular two'},
          ],
        },
      };
    }
    if (uri.path == 'search/trending') {
      return {
        'success': true,
        'data': {
          'items': [
            {'query': 'Trending one'},
          ],
        },
      };
    }
    final page = int.parse(uri.queryParameters['page']!);
    final items = page == 1
        ? [card(status: 'rejected'), card(id: secondId)]
        : [card(id: categoryId)];
    final data = {'items': items, 'total': 3, 'page': page, 'limit': 2};
    return {
      'success': true,
      'data': uri.path == 'search'
          ? {'searchId': page == 1 ? postId : null, 'posts': data}
          : data,
    };
  }

  @override
  Future<Map<String, dynamic>> post(
    String endpoint, {
    Map<String, dynamic>? data,
    String? token,
  }) async {
    expect(endpoint, 'search/log');
    logs.add(data!);
    if (failLogs) throw Exception('offline');
    return {
      'success': true,
      'data': {'recorded': true},
    };
  }
}

class ThreePageSearchApi extends ApiClient {
  final logs = <Map<String, dynamic>>[];
  bool missingFirstId = false;
  @override
  Future<Map<String, dynamic>> getPublic(
    String endpoint, {
    String? token,
  }) async {
    final uri = Uri.parse(endpoint);
    final page = int.parse(uri.queryParameters['page']!);
    final query = uri.queryParameters['q']!;
    final id = [postId, secondId, categoryId][page - 1];
    return {
      'success': true,
      'data': {
        if (!(page == 1 && missingFirstId))
          'searchId': page == 1
              ? (query == 'first' ? postId : secondId)
              : categoryId,
        'posts': {
          'items': [card(id: id)],
          'total': 3,
          'page': page,
          'limit': 1,
        },
      },
    };
  }

  @override
  Future<Map<String, dynamic>> post(
    String endpoint, {
    Map<String, dynamic>? data,
    String? token,
  }) async {
    expect(endpoint, 'search/log');
    expect(token, 'test-token');
    logs.add(Map.of(data!));
    return {
      'success': true,
      'data': {'recorded': true},
    };
  }
}

void main() {
  testWidgets(
    'Search without a backend provider does not show sample suggestions',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: SearchScreen())),
      );
      await tester.enterText(find.byType(TextField), 'plumbing');
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump();
      expect(find.text('Emergency plumbing'), findsNothing);
      expect(find.text('Drain cleaning'), findsNothing);
      expect(find.text(SearchStrings.noResults), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    },
  );

  for (final fail in [false, true]) {
    testWidgets(
      'backend ${fail ? 'failure' : 'empty suggestions'} never produces sample suggestions',
      (tester) async {
        final client = SmartSearchApi();
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
        await tester.enterText(find.byType(TextField), 'plumbing');
        await tester.pump(const Duration(milliseconds: 301));
        await tester.pump();
        final request = client.suggestionRequests['plumbing']!;
        if (fail) {
          request.completeError(Exception('offline'));
        } else {
          request.complete({
            'success': true,
            'data': {'items': []},
          });
        }
        await tester.pumpAndSettle();
        expect(find.text('Emergency plumbing'), findsNothing);
        expect(find.text('Drain cleaning'), findsNothing);
        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(seconds: 1));
        repository.dispose();
      },
    );
  }
  test('logging out and back into the same account does not reactivate the old feed cache', () async {
    var authenticated = true;
    var accountRevision = 7;
    final initialRevision = accountRevision;
    final api = Api()
      ..result = {
        'success': true,
        'data': {
          'items': [card()],
          'total': 1,
          'page': 1,
          'limit': 20,
        },
      };
    final old = ApiPostsRepository(
      api,
      Tokens(),
      isCurrentAccount: () =>
          authenticated && accountRevision == initialRevision,
      onUnauthorized: () async {},
    );
    await old.loadFeed();
    authenticated = false;
    accountRevision++;
    await expectLater(old.loadFeed(), throwsA(isA<PostApiException>()));
    authenticated = true;
    await expectLater(old.loadFeed(), throwsA(isA<PostApiException>()));
    api.result = {
      'success': true,
      'data': {
        'items': [card(id: secondId)],
        'total': 1,
        'page': 1,
        'limit': 20,
      },
    };
    final loginRevision = accountRevision;
    final fresh = ApiPostsRepository(
      api,
      Tokens(),
      isCurrentAccount: () => authenticated && accountRevision == loginRevision,
      onUnauthorized: () async {},
    );
    expect((await fresh.loadFeed()).items.single.id, secondId);
    expect(api.calls, hasLength(2));
    old.dispose();
    fresh.dispose();
  });
  test('search click logs retain page-one ID and backend positions across three pages', () async {
    final api = ThreePageSearchApi();
    final repository = ApiPostsRepository(
      api,
      Tokens(),
      isCurrentAccount: () => true,
      onUnauthorized: () async {},
    );
    final cubit = BackendPostsCubit(
      (page) => repository.search(query: 'first', page: page, limit: 1),
    );
    await cubit.refresh();
    for (var page = 1; page <= 3; page++) {
      if (page > 1) await cubit.loadMore();
      final post = cubit.state.posts[page - 1];
      await repository.logSearchClick(
        searchId: cubit.state.searchId!,
        postId: post.id,
        position: cubit.state.searchPositions[post.id]!,
      );
      expect(api.logs.last, {
        'searchId': postId,
        'event': 'click',
        'postId': post.id,
        'position': page,
      });
    }
    await cubit.refresh(
      load: (page) => repository.search(query: 'second', page: page, limit: 1),
    );
    expect(cubit.state.searchId, secondId);
    expect(cubit.state.searchPositions.keys, [postId]);
    await cubit.loadMore();
    await repository.logSearchClick(
      searchId: cubit.state.searchId!,
      postId: secondId,
      position: cubit.state.searchPositions[secondId]!,
    );
    expect(api.logs.last['searchId'], secondId);
    expect(api.logs.last['position'], 2);
    await cubit.close();
    repository.dispose();
  });

  test('missing first search ID is not replaced by later pages or invalid analytics', () async {
    final api = ThreePageSearchApi()..missingFirstId = true;
    final repository = ApiPostsRepository(
      api,
      Tokens(),
      isCurrentAccount: () => true,
      onUnauthorized: () async {},
    );
    final cubit = BackendPostsCubit(
      (page) => repository.search(query: 'first', page: page, limit: 1),
    );
    await cubit.refresh();
    await cubit.loadMore();
    await cubit.loadMore();
    expect(cubit.state.searchId, isNull);
    await repository.logSearchClick(searchId: '', postId: postId, position: 1);
    await repository.logSearchClick(
      searchId: postId,
      postId: 'not-a-uuid',
      position: 1,
    );
    await repository.logSearchClick(
      searchId: postId,
      postId: secondId,
      position: 0,
    );
    expect(api.logs, isEmpty);
    await cubit.close();
    repository.dispose();
  });

  test(
    'starting a new query clears previous search metadata before it completes',
    () async {
      final pending = Completer<BackendPostsPage>();
      final cubit = BackendPostsCubit(
        (_) async => BackendPostsPage(
          items: [backendPostFromJson(card())],
          total: 1,
          page: 1,
          limit: 1,
          searchId: postId,
          searchPositions: {postId: 1},
        ),
      );
      await cubit.refresh();
      final next = cubit.refresh(load: (_) => pending.future);
      expect(cubit.state.searchId, isNull);
      expect(cubit.state.searchPositions, isEmpty);
      pending.complete(
        BackendPostsPage(
          items: [backendPostFromJson(card(id: secondId))],
          total: 1,
          page: 1,
          limit: 1,
          searchId: secondId,
          searchPositions: {secondId: 1},
        ),
      );
      await next;
      expect(cubit.state.searchId, secondId);
      expect(cubit.state.searchPositions, {secondId: 1});
      await cubit.close();
    },
  );

  test('personalized feed flags remain account-scoped and forced refresh updates values', () async {
    Map<String, dynamic> accountPage(List<Map<String, dynamic>> items) => {
      'items': items,
      'total': items.length,
      'page': 1,
      'limit': 20,
    };
    var currentA = true;
    final api = Api()
      ..result = {
        'success': true,
        'data': accountPage([
          {...card(), 'isLiked': true, 'isSaved': false},
        ]),
      };
    final first = ApiPostsRepository(
      api,
      Tokens(),
      isCurrentAccount: () => currentA,
      onUnauthorized: () async {},
    );
    final a = await first.loadFeed();
    expect(a.items.single.metadata['isLiked'], isTrue);
    expect(a.items.single.metadata['isSaved'], isFalse);
    await first.loadFeed();
    expect(api.calls.length, 1);
    currentA = false;
    await expectLater(first.loadFeed(), throwsA(isA<PostApiException>()));
    api.result = {
      'success': true,
      'data': accountPage([
        {...card(), 'isLiked': false, 'isSaved': true},
      ]),
    };
    final second = ApiPostsRepository(
      api,
      Tokens(),
      isCurrentAccount: () => true,
      onUnauthorized: () async {},
    );
    final b = await second.loadFeed();
    expect(b.items.single.metadata['isLiked'], isFalse);
    expect(b.items.single.metadata['isSaved'], isTrue);
    expect(api.calls.length, 2);
    api.result = {
      'success': true,
      'data': accountPage([
        {...card(), 'isLiked': true, 'isSaved': true},
      ]),
    };
    expect(
      (await second.loadFeed(force: true)).items.single.metadata['isLiked'],
      isTrue,
    );
    expect(api.calls.length, 3);
    expect(
      api.calls.every((uri) => uri.queryParameters['scope'] == 'all'),
      isTrue,
    );
    first.dispose();
    second.dispose();
  });
  test(
    'confirmed comment deletion updates shared count and failures retain data',
    () async {
      final api = CommentsApi()
        ..comments = [commentData()]
        ..total = 1;
      final repo = ApiPostsRepository(
        api,
        Tokens(),
        isCurrentAccount: () => true,
        onUnauthorized: () async {},
      );
      final post = backendPostFromJson({...card(), 'commentsCount': 1});
      final home = PostDetailCubit(
        postId: postId,
        post: post,
        repository: repo,
      );
      final detail = PostDetailCubit(
        postId: postId,
        post: post,
        repository: repo,
      );
      await detail.loadComments();
      api.failure = DioException(
        requestOptions: RequestOptions(path: 'comments/$commentId'),
        response: Response(
          requestOptions: RequestOptions(path: 'comments/$commentId'),
          statusCode: 403,
        ),
        type: DioExceptionType.badResponse,
      );
      expect(await detail.deleteComment(detail.state.comments.single), isFalse);
      expect(detail.state.comments, hasLength(1));
      api.failure = null;
      expect(await detail.deleteComment(detail.state.comments.single), isTrue);
      expect(detail.state.comments, isEmpty);
      expect(home.state.commentCount, 0);
      await home.close();
      await detail.close();
      repo.dispose();
    },
  );

  test('account change discards a late comments response', () async {
    final api = CommentsApi()
      ..comments = [commentData()]
      ..total = 1
      ..getGate = Completer<void>();
    var current = true;
    final repo = ApiPostsRepository(
      api,
      Tokens(),
      isCurrentAccount: () => current,
      onUnauthorized: () async {},
    );
    final cubit = PostDetailCubit(
      postId: postId,
      post: backendPostFromJson(card()),
      repository: repo,
    );
    final pending = cubit.loadComments();
    await Future<void>.delayed(Duration.zero);
    current = false;
    api.getGate!.complete();
    await pending;
    expect(cubit.state.comments, isEmpty);
    await cubit.close();
    repo.dispose();
  });
  testWidgets(
    'existing comments sheet renders backend results and confirms composer',
    (tester) async {
      final api = CommentsApi()
        ..comments = [commentData()]
        ..total = 1;
      final repo = ApiPostsRepository(
        api,
        Tokens(),
        isCurrentAccount: () => true,
        onUnauthorized: () async {},
      );
      final cubit = PostDetailCubit(
        postId: postId,
        post: backendPostFromJson(card()),
        repository: repo,
      );
      await tester.runAsync(() => cubit.loadComments());
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CommentsSheet(postId: postId, backend: true, cubit: cubit),
          ),
        ),
      );
      expect(find.text('Real comment'), findsOneWidget);
      expect(find.text('Amazing work! 🔥😍'), findsNothing);
      await tester.enterText(find.byType(TextField), 'New backend comment');
      await tester.tap(find.byTooltip('Add comment'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('New backend comment'), findsOneWidget);
      expect(api.bodies.single, {'text': 'New backend comment'});
      await tester.pumpWidget(const SizedBox());
      await tester.runAsync(() => cubit.close());
      repo.dispose();
    },
  );
  test(
    'comment endpoints use documented IDs, reply fields and permissions',
    () async {
      final api = CommentsApi()
        ..comments = [commentData()]
        ..total = 1;
      final repo = ApiPostsRepository(
        api,
        Tokens(),
        isCurrentAccount: () => true,
        onUnauthorized: () async {},
      );
      final page = await repo.loadComments(postId);
      expect(api.calls.first, 'GET posts/$postId/comments?page=1&limit=20');
      expect(page.items.single.authorName, 'Real author');
      expect(page.items.single.id, commentId);
      api.comments = [commentData(id: replyId)];
      final second = await repo.loadComments(postId, page: 2);
      expect(second.page, 2);
      expect(second.items.single.id, replyId);
      expect(api.calls.last, 'GET posts/$postId/comments?page=2&limit=20');
      api.comments = [commentData(id: replyId, parentId: commentId)];
      final replies = await repo.loadComments(postId, parentId: commentId);
      expect(replies.items.single.parentId, commentId);
      expect(api.calls.last, contains('parentId=$commentId'));
      final created = await repo.createComment(
        postId,
        ' Reply ',
        parentId: commentId,
      );
      expect(created.id, replyId);
      expect(api.bodies.single, {'text': 'Reply', 'parentId': commentId});
      expect(await repo.deleteComment(created), 0);
      expect(api.calls.last, 'DELETE comments/$replyId');
      final forbidden = PostComment.fromJson(
        commentData(canDelete: false),
        postId: postId,
      );
      await expectLater(
        repo.deleteComment(forbidden),
        throwsA(isA<PostApiException>()),
      );
      repo.dispose();
    },
  );

  test('comment submission guards duplicate requests and shows only confirmed results', () async {
    final api = CommentsApi()..gate = Completer<void>();
    final repo = ApiPostsRepository(
      api,
      Tokens(),
      isCurrentAccount: () => true,
      onUnauthorized: () async {},
    );
    final post = backendPostFromJson({...card(), 'commentsCount': 0});
    final cubit = PostDetailCubit(postId: postId, post: post, repository: repo);
    await cubit.loadComments();
    final pending = cubit.submitComment('Real comment');
    await Future<void>.delayed(Duration.zero);
    expect(await cubit.submitComment('Real comment'), isFalse);
    expect(cubit.state.comments, isEmpty);
    api.gate!.complete();
    expect(await pending, isTrue);
    expect(cubit.state.comments.single.id, commentId);
    expect(api.calls.where((c) => c.startsWith('POST')), hasLength(1));
    await cubit.close();
    repo.dispose();
  });

  test('uncertain comment submission does not silently resend', () async {
    final api = CommentsApi()
      ..failure = DioException(
        requestOptions: RequestOptions(path: 'comments'),
        type: DioExceptionType.receiveTimeout,
      );
    final repo = ApiPostsRepository(
      api,
      Tokens(),
      isCurrentAccount: () => true,
      onUnauthorized: () async {},
    );
    final cubit = PostDetailCubit(
      postId: postId,
      post: backendPostFromJson(card()),
      repository: repo,
    );
    await cubit.loadComments();
    expect(await cubit.submitComment('Real comment'), isFalse);
    expect(await cubit.submitComment('Real comment'), isFalse);
    expect(api.calls.where((c) => c.startsWith('POST')), hasLength(1));
    expect(cubit.state.comments, isEmpty);
    await cubit.close();
    repo.dispose();
  });
  test(
    'backend save and unsave update shared state and refresh real saved list',
    () async {
      final api = SaveApi();
      final repo = ApiPostsRepository(
        api,
        Tokens(),
        isCurrentAccount: () => true,
        onUnauthorized: () async {},
      );
      final local = LocalSavedFake();
      final saved = SavedPostsCubit(local, backendPosts: repo);
      final post = backendPostFromJson({...card(), 'isSaved': false});
      await saved.load();
      saved.seed(post);
      expect(await saved.toggle(post), isTrue);
      expect(api.calls, contains('POST posts/$postId/save'));
      expect(saved.isSaved(postId), isTrue);
      expect(saved.state.posts.single.post.id, postId);
      expect(local.items, isEmpty);
      expect(await saved.remove(postId), isTrue);
      expect(api.calls, contains('DELETE posts/$postId/save'));
      expect(saved.isSaved(postId), isFalse);
      expect(saved.state.posts, isEmpty);
      await saved.close();
      repo.dispose();
    },
  );

  test(
    'saved API pagination preserves backend order and empty pages',
    () async {
      final api = SaveApi()
        ..pages[1] = [
          {...card(), 'savedAt': '2026-11-19T00:00:00Z'},
        ]
        ..pages[2] = [
          {...card(id: secondId), 'savedAt': '2026-11-18T00:00:00Z'},
        ];
      final repo = ApiPostsRepository(
        api,
        Tokens(),
        isCurrentAccount: () => true,
        onUnauthorized: () async {},
      );
      final saved = SavedPostsCubit(LocalSavedFake(), backendPosts: repo);
      await saved.load();
      await saved.loadMore();
      expect(saved.state.posts.map((e) => e.post.id), [postId, secondId]);
      expect(api.calls, contains('GET users/me/saved?page=2&limit=20'));
      expect(saved.state.posts.first.savedAt, DateTime.utc(2026, 11, 19));
      await saved.close();
      repo.dispose();
    },
  );

  test(
    'save timeout is not blindly retried when reconciliation fails',
    () async {
      final api = SaveApi()
        ..failure = DioException(
          requestOptions: RequestOptions(path: 'posts/$postId/save'),
          type: DioExceptionType.receiveTimeout,
        )
        ..readFailure = DioException(
          requestOptions: RequestOptions(path: 'posts/$postId'),
          type: DioExceptionType.connectionError,
        );
      final repo = ApiPostsRepository(
        api,
        Tokens(),
        isCurrentAccount: () => true,
        onUnauthorized: () async {},
      );
      final saved = SavedPostsCubit(LocalSavedFake(), backendPosts: repo);
      final post = backendPostFromJson({...card(), 'isSaved': false});
      await saved.load();
      saved.seed(post);
      expect(await saved.toggle(post), isFalse);
      expect(await saved.toggle(post), isFalse);
      expect(api.calls.where((v) => v.startsWith('POST')), hasLength(1));
      expect(saved.isSaved(postId), isFalse);
      await saved.close();
      repo.dispose();
    },
  );

  test(
    'concurrent save and account switch cannot update the new session',
    () async {
      final api = SaveApi()..gate = Completer<void>();
      var current = true;
      final repo = ApiPostsRepository(
        api,
        Tokens(),
        isCurrentAccount: () => current,
        onUnauthorized: () async {},
      );
      final saved = SavedPostsCubit(LocalSavedFake(), backendPosts: repo);
      final post = backendPostFromJson({...card(), 'isSaved': false});
      await saved.load();
      saved.seed(post);
      final pending = saved.toggle(post);
      await Future<void>.delayed(Duration.zero);
      expect(await saved.toggle(post), isFalse);
      current = false;
      api.gate!.complete();
      expect(await pending, isFalse);
      expect(saved.isSaved(postId), isFalse);
      expect(api.calls.where((v) => v.startsWith('POST')), hasLength(1));
      await saved.close();
      repo.dispose();
    },
  );

  test('local-only bookmarks remain usable when the saved API fails', () async {
    final api = SaveApi()
      ..listFailure = DioException(
        requestOptions: RequestOptions(path: 'users/me/saved'),
        type: DioExceptionType.connectionError,
      );
    final repo = ApiPostsRepository(
      api,
      Tokens(),
      isCurrentAccount: () => true,
      onUnauthorized: () async {},
    );
    final storage = LocalSavedFake();
    final saved = SavedPostsCubit(storage, backendPosts: repo);
    const local = PostItem(
      id: 'local-only',
      imageAsset: '',
      title: 'Local',
      category: '',
      stockCount: 0,
      price: '',
      originalPrice: '',
    );
    await saved.load();
    expect(saved.state.loadFailed, isTrue);
    expect(await saved.toggle(local), isTrue);
    expect(storage.items.single.post.id, 'local-only');
    expect(api.calls.where((call) => call.startsWith('POST')), isEmpty);
    await saved.close();
    repo.dispose();
  });
  test(
    'backend like and unlike use confirmed IDs, state and counts across views',
    () async {
      final api = LikeApi();
      final repo = ApiPostsRepository(
        api,
        Tokens(),
        isCurrentAccount: () => true,
        onUnauthorized: () async {},
      );
      final likes = PostLikesCubit(repo);
      final post = backendPostFromJson({
        ...card(),
        'isLiked': false,
        'likes': 12,
      });
      final home = PostDetailCubit(postId: postId, post: post, likes: likes);
      final detail = PostDetailCubit(postId: postId, post: post, likes: likes);
      expect(home.state.likeCount, 12);
      expect(await home.toggleLike(), isTrue);
      await Future<void>.delayed(Duration.zero);
      expect(api.calls.first, 'POST posts/$postId/like');
      expect(home.state.isLiked, isTrue);
      expect(detail.state.isLiked, isTrue);
      expect(detail.state.likeCount, 13);
      expect(await detail.toggleLike(), isTrue);
      await Future<void>.delayed(Duration.zero);
      expect(api.calls.last, 'DELETE posts/$postId/like');
      expect(home.state.isLiked, isFalse);
      expect(home.state.likeCount, 12);
      await home.close();
      await detail.close();
      await likes.close();
      repo.dispose();
    },
  );

  test(
    'backend likes prevent duplicate taps and reject mismatched response',
    () async {
      final api = LikeApi()..gate = Completer<void>();
      final repo = ApiPostsRepository(
        api,
        Tokens(),
        isCurrentAccount: () => true,
        onUnauthorized: () async {},
      );
      final likes = PostLikesCubit(repo);
      likes.seed(
        backendPostFromJson({...card(), 'isLiked': false, 'likes': 12}),
      );
      final first = likes.toggleBackend(postId);
      await Future<void>.delayed(Duration.zero);
      expect(await likes.toggleBackend(postId), isFalse);
      api.gate!.complete();
      expect(await first, isTrue);
      expect(api.calls.where((c) => c.startsWith('POST')), hasLength(1));
      api.response = {
        'success': true,
        'data': {'postId': secondId, 'isLiked': false, 'likes': 0},
      };
      expect(await likes.toggleBackend(postId), isFalse);
      expect(likes.backendState(postId)?.count, 12);
      await likes.close();
      repo.dispose();
    },
  );

  test(
    'account changes prevent late like result and backend rejects invalid IDs',
    () async {
      final api = LikeApi()..gate = Completer<void>();
      var current = true;
      final repo = ApiPostsRepository(
        api,
        Tokens(),
        isCurrentAccount: () => current,
        onUnauthorized: () async {},
      );
      final likes = PostLikesCubit(repo);
      likes.seed(
        backendPostFromJson({...card(), 'isLiked': false, 'likes': 12}),
      );
      final pending = likes.toggleBackend(postId);
      await Future<void>.delayed(Duration.zero);
      current = false;
      api.gate!.complete();
      expect(await pending, isFalse);
      expect(likes.backendState(postId)?.liked, isFalse);
      expect(api.calls, ['POST posts/$postId/like']);
      await likes.close();
      repo.dispose();
    },
  );

  test(
    'network timeout reconciles with backend and never assumes a like',
    () async {
      final api = LikeApi()
        ..failure = DioException(
          requestOptions: RequestOptions(path: 'posts/$postId/like'),
          type: DioExceptionType.receiveTimeout,
        )
        ..liked = false
        ..count = 12;
      final repo = ApiPostsRepository(
        api,
        Tokens(),
        isCurrentAccount: () => true,
        onUnauthorized: () async {},
      );
      final likes = PostLikesCubit(repo);
      likes.seed(
        backendPostFromJson({...card(), 'isLiked': false, 'likes': 12}),
      );
      expect(await likes.toggleBackend(postId), isFalse);
      expect(api.calls, ['POST posts/$postId/like', 'GET posts/$postId']);
      expect(likes.backendState(postId)?.liked, isFalse);
      expect(likes.backendState(postId)?.count, 12);
      await likes.close();
      repo.dispose();
    },
  );

  test('unknown backend like state is read before a mutation', () async {
    final api = LikeApi();
    final repo = ApiPostsRepository(
      api,
      Tokens(),
      isCurrentAccount: () => true,
      onUnauthorized: () async {},
    );
    final likes = PostLikesCubit(repo);
    likes.seed(backendPostFromJson(card()));
    expect(await likes.toggleBackend(postId), isTrue);
    expect(await likes.toggleBackend('local-id'), isFalse);
    expect(api.calls, ['GET posts/$postId', 'POST posts/$postId/like']);
    await likes.close();
    repo.dispose();
  });

  test('unconfirmed timeout with failed read blocks a blind retry', () async {
    final api = LikeApi()
      ..failure = DioException(
        requestOptions: RequestOptions(path: 'posts/$postId/like'),
        type: DioExceptionType.receiveTimeout,
      )
      ..readFailure = DioException(
        requestOptions: RequestOptions(path: 'posts/$postId'),
        type: DioExceptionType.connectionError,
      );
    final repo = ApiPostsRepository(
      api,
      Tokens(),
      isCurrentAccount: () => true,
      onUnauthorized: () async {},
    );
    final likes = PostLikesCubit(repo);
    likes.seed(backendPostFromJson({...card(), 'isLiked': false, 'likes': 12}));
    expect(await likes.toggleBackend(postId), isFalse);
    expect(await likes.toggleBackend(postId), isFalse);
    expect(api.calls, ['POST posts/$postId/like', 'GET posts/$postId']);
    expect(likes.backendState(postId)?.liked, false);
    await likes.close();
    repo.dispose();
  });
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

  test(
    'all-scope feed and search retain posts from different authors',
    () async {
      final first = {
        ...card(id: postId, status: 'published'),
        'owner': {'id': 'author-one', 'name': 'One'},
      };
      final second = {
        ...card(id: secondId, status: 'published'),
        'owner': {'id': 'author-two', 'name': 'Two'},
      };
      final private = {
        ...card(id: categoryId, status: 'changes_requested'),
        'owner': {'id': 'author-three', 'name': 'Three'},
      };
      api.result = {
        'success': true,
        'data': page([first, second, private], total: 3),
      };
      final feed = await repo.loadFeed();
      expect(api.calls.single.queryParameters, {
        'scope': 'all',
        'page': '1',
        'limit': '20',
      });
      expect(feed.items.map((post) => post.metadata['seller']['id']), [
        'author-one',
        'author-two',
      ]);
      api.result = {
        'success': true,
        'data': {
          'posts': page([second, first, private], total: 3),
        },
      };
      final search = await repo.search(query: 'example');
      expect(api.calls.last.queryParameters, {
        'q': 'example',
        'type': 'posts',
        'page': '1',
        'limit': '20',
      });
      expect(search.items.map((post) => post.metadata['seller']['id']), [
        'author-two',
        'author-one',
      ]);
    },
  );

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
      expect(client.calls.where((call) => call.path == 'feed').length, 1);
      expect(find.byType(SearchResultCard), findsNWidgets(2));
      await tester.enterText(find.byType(TextField), 'A real post');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();
      final searchCall = client.calls.where((uri) => uri.path == 'search').last;
      expect(searchCall.queryParameters['q'], 'A real post');
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

  test(
    'smart endpoints parse server terms and encode suggestion queries',
    () async {
      final client = SmartSearchApi();
      final repository = ApiPostsRepository(
        client,
        Tokens(),
        isCurrentAccount: () => true,
        onUnauthorized: () async {},
      );
      expect(await repository.popularSearches(), [
        'Popular one',
        'Popular two',
      ]);
      expect(await repository.trendingSearches(), ['Trending one']);
      final future = repository.searchSuggestions('چای & tea');
      await Future<void>.delayed(Duration.zero);
      expect(client.calls.last.path, 'search/suggestions');
      expect(client.calls.last.queryParameters['q'], 'چای & tea');
      client.suggestionRequests['چای & tea']!.complete({
        'success': true,
        'data': {
          'items': [
            for (var i = 0; i < 12; i++) {'text': 'term $i', 'source': 'title'},
          ],
        },
      });
      expect((await future).length, 10);
    },
  );

  test(
    'suggestions discard stale responses and empty input clears them',
    () async {
      final client = SmartSearchApi();
      final repository = ApiPostsRepository(
        client,
        Tokens(),
        isCurrentAccount: () => true,
        onUnauthorized: () async {},
      );
      final cubit = SearchCubit(repository);
      addTearDown(cubit.close);
      cubit.editQuery('old');
      final old = cubit.loadSuggestions('old');
      await Future<void>.delayed(Duration.zero);
      cubit.editQuery('new');
      final latest = cubit.loadSuggestions('new');
      await Future<void>.delayed(Duration.zero);
      client.suggestionRequests['new']!.complete({
        'success': true,
        'data': {
          'items': [
            {'text': 'new result'},
          ],
        },
      });
      await latest;
      client.suggestionRequests['old']!.complete({
        'success': true,
        'data': {
          'items': [
            {'text': 'old result'},
          ],
        },
      });
      await old;
      expect(cubit.state.suggestions, ['new result']);
      cubit.editQuery('');
      expect(cubit.state.suggestions, isEmpty);
    },
  );

  test('search click positions retain backend positions after filtering and pagination', () async {
    final client = SmartSearchApi();
    final repository = ApiPostsRepository(
      client,
      Tokens(),
      isCurrentAccount: () => true,
      onUnauthorized: () async {},
    );
    final cubit = BackendPostsCubit(
      (page) => repository.search(query: 'test', page: page, limit: 2),
    );
    addTearDown(cubit.close);
    await cubit.refresh();
    expect(cubit.state.posts.single.id, secondId);
    expect(cubit.state.searchPositions[secondId], 2);
    await cubit.loadMore();
    expect(cubit.state.searchPositions[categoryId], 3);
    expect(cubit.state.searchId, postId);
    await repository.logSearchClick(
      searchId: cubit.state.searchId!,
      postId: categoryId,
      position: cubit.state.searchPositions[categoryId]!,
    );
    expect(client.logs.single, {
      'searchId': postId,
      'event': 'click',
      'postId': categoryId,
      'position': 3,
    });
    await repository.logSearchClick(
      searchId: 'invalid',
      postId: secondId,
      position: 1,
    );
    expect(client.logs.length, 1);
    await repository.logSearchClick(
      searchId: postId,
      postId: secondId,
      position: 1,
    );
    expect(client.logs.last['position'], 1);
  });

  testWidgets('popular term starts normal search', (tester) async {
    final client = SmartSearchApi();
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
    expect(find.text('Popular one'), findsOneWidget);
    expect(find.text('Popular two'), findsOneWidget);
    expect(find.text('Trending one'), findsOneWidget);
    expect(client.calls.where((uri) => uri.path == 'search/popular').length, 1);
    expect(
      client.calls.where((uri) => uri.path == 'search/trending').length,
      1,
    );
    await tester.tap(find.text('Popular one'));
    await tester.pumpAndSettle();
    expect(
      client.calls
          .where((uri) => uri.path == 'search')
          .last
          .queryParameters['q'],
      'Popular one',
    );
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('trending term starts the existing backend search', (
    tester,
  ) async {
    final client = SmartSearchApi();
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
    await tester.tap(find.text('Trending one'));
    await tester.pumpAndSettle();
    expect(
      client.calls
          .where((uri) => uri.path == 'search')
          .last
          .queryParameters['q'],
      'Trending one',
    );
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
    repository.dispose();
  });

  testWidgets(
    'discovery and suggestions use backend terms without hiding feed',
    (tester) async {
      final client = SmartSearchApi()..failPopular = true;
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
      expect(find.text('Trending one'), findsOneWidget);
      expect(find.byType(SearchResultCard), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'abc');
      await tester.pump(const Duration(milliseconds: 299));
      expect(
        client.calls.where((uri) => uri.path == 'search/suggestions'),
        isEmpty,
      );
      await tester.pump(const Duration(milliseconds: 2));
      await tester.pump();
      expect(
        client.calls
            .where((uri) => uri.path == 'search/suggestions')
            .single
            .queryParameters['q'],
        'abc',
      );
      client.suggestionRequests['abc']!.complete({
        'success': true,
        'data': {
          'items': [
            {'text': 'Backend suggestion'},
          ],
        },
      });
      await tester.pumpAndSettle();
      expect(find.text('Backend suggestion'), findsOneWidget);
      await tester.tap(find.text('Backend suggestion'));
      await tester.pumpAndSettle();
      expect(
        client.calls
            .where((uri) => uri.path == 'search')
            .last
            .queryParameters['q'],
        'Backend suggestion',
      );
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'Backend suggestion',
      );
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 1));
    },
  );

  testWidgets(
    'search clicks navigate even if logging fails; feed clicks do not log',
    (tester) async {
      final client = SmartSearchApi()..failLogs = true;
      final repository = ApiPostsRepository(
        client,
        Tokens(),
        isCurrentAccount: () => true,
        onUnauthorized: () async {},
      );
      final opened = <String>[];
      await tester.pumpWidget(
        RepositoryProvider<ApiPostsRepository>.value(
          value: repository,
          child: MaterialApp(
            home: Scaffold(
              body: SearchScreen(
                onPostSelected: (post, _) => opened.add(post.id),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byType(SearchResultCard).first);
      expect(client.logs, isEmpty);
      await tester.enterText(find.byType(TextField), 'match');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();
      await tester.tap(find.byType(SearchResultCard).first);
      await tester.pump();
      expect(opened, [secondId, secondId]);
      expect(client.logs.single, {
        'searchId': postId,
        'event': 'click',
        'postId': secondId,
        'position': 2,
      });
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 1));
    },
  );

  test(
    'explore sends documented filters and preserves public result order',
    () async {
      api.result = {
        'success': true,
        'data': {
          'items': [
            card(id: secondId),
            card(status: 'rejected'),
            card(id: postId),
          ],
          'total': 3,
          'page': 2,
          'limit': 20,
        },
      };
      final result = await repo.explore(
        category: 'electronics',
        postType: 'service',
        minPrice: 10,
        maxPrice: 1000,
        inStock: true,
        minRating: 4.5,
        tag: 'tea & coffee',
        sort: 'price_asc',
        page: 2,
      );
      expect(api.calls.single.path, 'explore');
      expect(api.calls.single.queryParameters, {
        'category': 'electronics',
        'postType': 'service',
        'minPrice': '10',
        'maxPrice': '1000',
        'inStock': 'true',
        'minRating': '4.5',
        'tag': 'tea & coffee',
        'sort': 'price_asc',
        'page': '2',
        'limit': '20',
      });
      expect(result.items.map((p) => p.id), [secondId, postId]);
      expect(result.page, 2);
      expect(() => repo.explore(postType: 'invalid'), throwsFormatException);
      expect(() => repo.explore(minRating: 6), throwsFormatException);
    },
  );

  test('My Posts reads documented nested review note', () {
    final post = MyServerPost.fromJson({
      'id': postId,
      'title': 'Example',
      'status': 'changes_requested',
      'review': {'note': 'Please revise', 'rejectionReason': null},
    });
    expect(post.reviewNote, 'Please revise');
    expect(post.rejectionReason, isNull);
  });

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
