import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nini/core/config/app_config/app_config.dart';
import 'package:nini/core/localization/app_string/app_string.dart';
import 'package:nini/core/localization/strings/profile_post_strings.dart';
import 'package:nini/core/network/api_client.dart';
import 'package:nini/core/security/secure_token_store.dart';
import 'package:nini/core/theme/app_theme.dart';
import 'package:nini/features/home/presentation/helpers/home_post_navigation.dart';
import 'package:nini/features/home/presentation/widgets/common/home_seller_header.dart';
import 'package:nini/features/login/data/auth_repo.dart';
import 'package:nini/features/login/presentation/cubit/session_cubit.dart';
import 'package:nini/features/profile/data/api_public_profile_repository.dart';
import 'package:nini/features/posts/domain/models/profile_category.dart';
import 'package:nini/features/posts/domain/profile_categories_repository.dart';
import 'package:nini/features/posts/presentation/cubit/profile_categories_cubit.dart';
import 'package:nini/features/profile/presentation/widgets/categories/profile_category_chip.dart';
import 'package:nini/features/profile/presentation/widgets/categories/category_chips.dart';
import 'package:nini/features/profile/presentation/cubit/seller_profile_cubit.dart';
import 'package:nini/features/profile/presentation/pages/seller_profile_screen.dart';
import 'package:nini/features/profile/presentation/widgets/account/profile_stats.dart';
import 'package:nini/features/profile/presentation/widgets/posts/profile_post_card.dart';
import 'package:nini/features/profile/presentation/widgets/seller/seller_profile_header.dart';
import 'package:nini/features/profile/presentation/widgets/seller/seller_profile_content.dart';
import 'package:nini/features/profile_settings/domain/user_profile.dart';
import 'package:nini/features/profile_settings/domain/user_profile_repository.dart';
import 'package:nini/features/profile_settings/presentation/cubit/user_profile_cubit.dart';
import 'package:nini/features/post_detail/presentation/pages/post_detail_screen.dart';
import 'package:nini/features/post_detail/presentation/widgets/common/post_author_header.dart';
import 'package:nini/features/posts/presentation/widgets/common/seller_avatar.dart';
import 'package:nini/features/search/data/search_catalog.dart';
import 'package:nini/features/search/presentation/widgets/results/search_results_grid.dart';
import 'package:nini/shared/models/post/post_item.dart';
import 'package:nini/shared/models/post/post_seller.dart';
import 'package:nini/shared/widgets/app_button/app_button.dart';
import 'package:nini/shared/widgets/skeleton/profile_skeleton.dart';

const _publicOne = '10000000-0000-4000-8000-000000000001';
const _publicTwo = '10000000-0000-4000-8000-000000000002';
const _categoryOne = '20000000-0000-4000-8000-000000000001';
const _categoryTwo = '20000000-0000-4000-8000-000000000002';
const _postOne = '30000000-0000-4000-8000-000000000001';
const _postTwo = '30000000-0000-4000-8000-000000000002';
Map<String, dynamic> _serverPost(
  String id, {
  String owner = _publicOne,
  String status = 'published',
}) => {
  'id': id,
  'title': 'Real post $id',
  'postType': 'product',
  'status': status,
  'price': 10000,
  'finalPrice': 10000,
  'owner': {'id': owner, 'name': 'Seller', 'username': 'seller.one'},
  'image': 'https://example.test/image.jpg',
  'thumbnailUrl': 'https://example.test/thumb.jpg',
};
Map<String, dynamic> _categoryList(String name, {int count = 5}) => _response({
  'allCount': count,
  'uncategorizedCount': 1,
  'items': [
    {'id': _categoryOne, 'name': name, 'position': 0, 'postsCount': 3},
    {
      'id': _categoryTwo,
      'name': 'Second public category',
      'position': 1,
      'postsCount': 1,
    },
  ],
});

class _OwnCategories extends Fake implements ProfileCategoriesRepository {}

Map<String, dynamic> _data(String username, {String? id}) => {
  'id': id ?? 'id-$username',
  'username': username,
  'name': 'Backend $username',
  'avatarUrl': null,
  'bio': 'Confirmed biography',
  'city': 'Confirmed city',
  'followersCount': 12,
  'followingCount': 7,
  'postsCount': 27,
  'isMe': false,
  'isFollowing': false,
};
Map<String, dynamic> _response(Map<String, dynamic> data) => {
  'success': true,
  'data': data,
};

class _Tokens extends SecureTokenStore {
  String? value;
  int deletions = 0;
  @override
  Future<String?> getToken() async => value;
  @override
  Future<void> deleteToken() async {
    deletions++;
    value = null;
  }
}

class _Api extends ApiClient {
  final paths = <String>[];
  final credentials = <String?>[];
  final replies = <String, Map<String, dynamic>>{};
  final gates = <String, Completer<void>>{};
  final peopleReplies = <String, Map<String, dynamic>>{};
  final postReplies = <String, Map<String, dynamic>>{};
  Object? postsFailure;
  Object? peopleFailure;
  Object? failure;
  int writes = 0;
  String? followPath;
  String? followToken;
  Map<String, dynamic>? followReply;
  Object? followFailure;
  Completer<void>? followGate;
  String? deletePath;
  String? deleteToken;
  Map<String, dynamic>? deleteReply;
  Object? deleteFailure;
  Completer<void>? deleteGate;
  int deletes = 0;
  final categoryReplies = <String, Map<String, dynamic>>{};
  Object? categoryFailure;
  @override
  Future<Map<String, dynamic>> getPublic(
    String endpoint, {
    String? token,
  }) async {
    paths.add(endpoint);
    credentials.add(token);
    if (endpoint.contains('/posts?')) {
      await gates[endpoint]?.future;
      if (postsFailure != null) throw postsFailure!;
      return postReplies[endpoint] ??
          _response({'items': [], 'total': 0, 'page': 1, 'limit': 20});
    }
    if (endpoint.contains('/followers?') || endpoint.contains('/following?')) {
      final reply = peopleReplies[endpoint];
      await gates[endpoint]?.future;
      if (peopleFailure != null) throw peopleFailure!;
      if (reply == null) throw StateError('Missing people fixture');
      return reply;
    }
    if (endpoint.startsWith('users/') && endpoint.endsWith('/categories')) {
      final id = endpoint.split('/')[1];
      final reply =
          categoryReplies[id] ??
          _response({'allCount': 27, 'items': <Object>[]});
      await gates['categories:$id']?.future;
      if (categoryFailure != null) throw categoryFailure!;
      return reply;
    }
    final username = Uri.decodeComponent(
      endpoint.substring('users/profile/'.length),
    );
    final reply = replies[username] ?? _response(_data(username));
    await gates[username]?.future;
    if (failure != null) throw failure!;
    return reply;
  }

  @override
  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? data,
    String? token,
  }) async {
    writes++;
    followPath = path;
    followToken = token;
    expect(data, isNull);
    await followGate?.future;
    if (followFailure != null) throw followFailure!;
    if (followReply != null) return followReply!;
    throw StateError('Unexpected write in public-profile flow');
  }

  @override
  Future<Map<String, dynamic>> delete(
    String path, {
    required String token,
  }) async {
    deletes++;
    deletePath = path;
    deleteToken = token;
    await deleteGate?.future;
    if (deleteFailure != null) throw deleteFailure!;
    return deleteReply ??
        _response({'userId': _publicOne, 'isFollowing': false});
  }
}

class _OwnProfiles extends Fake implements UserProfileRepository {
  @override
  Future<UserProfile> load() async => const UserProfile(
    id: 'own-account',
    username: 'my.account',
    firstName: 'Own account',
  );
}

class _Auth extends AuthRepository {
  _Auth() : super(_Api());
  String? actor = 'own-account';
  @override
  Future<String?> restoreSession() async => actor;
  @override
  Future<void> logout() async {}
}

class _RealHttp extends HttpOverrides {}

DioException _error({
  int? status,
  DioExceptionType type = DioExceptionType.badResponse,
}) {
  final options = RequestOptions(path: 'users/profile/seller.one');
  return DioException(
    requestOptions: options,
    type: type,
    response: status == null
        ? null
        : Response<dynamic>(
            requestOptions: options,
            statusCode: status,
            data: {'message': 'Private server details must not be displayed'},
          ),
  );
}

ApiPublicProfileRepository _repository(_Api api, [_Tokens? tokens]) =>
    ApiPublicProfileRepository(api, tokens ?? _Tokens());
Widget _host(
  _Api api,
  Widget screen, {
  UserProfileCubit? own,
  SessionCubit? session,
  _Tokens? tokens,
}) {
  Widget app = MaterialApp(home: screen);
  if (own != null) app = BlocProvider.value(value: own, child: app);
  if (session != null) app = BlocProvider.value(value: session, child: app);
  return RepositoryProvider.value(value: _repository(api, tokens), child: app);
}

PostItem _post({bool service = false, PostSeller? seller}) => PostItem(
  id: service ? 'remote-service' : 'remote-product',
  imageAsset: 'assets/img1.png',
  title: service ? 'Remote service' : 'Remote product',
  category: service ? 'Plumbing' : 'Products',
  stockCount: service ? 0 : 2,
  price: '12000',
  originalPrice: '',
  metadata: {
    'postType': service ? 'services' : 'product',
    if (seller != null) 'seller': seller.toJson(),
  },
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'public posts use target UUID, category and shared public mapper',
    () async {
      const endpoint =
          'users/$_publicOne/posts?categoryId=$_categoryOne&page=1&limit=20';
      final api = _Api()
        ..postReplies[endpoint] = _response({
          'items': [
            _serverPost(_postOne),
            _serverPost(_postTwo, status: 'pending_review'),
          ],
          'total': 2,
          'page': 1,
          'limit': 20,
        });
      final result = await _repository(api)
          .loadPosts(_publicOne, categoryId: _categoryOne);
      expect(api.paths, [endpoint]);
      expect(result.items.map((p) => p.id), [_postOne]);
      expect(result.items.single.price, '1000');
      expect(
        result.items.single.media.single.thumbnailPath,
        'https://example.test/thumb.jpg',
      );
      await expectLater(
        _repository(api).loadPosts('invalid'),
        throwsFormatException,
      );
    },
  );

  test(
    'public post pagination, category switching and stale responses',
    () async {
      const first = 'users/$_publicOne/posts?page=1&limit=20';
      const second = 'users/$_publicOne/posts?page=2&limit=20';
      const category =
          'users/$_publicOne/posts?categoryId=$_categoryOne&page=1&limit=20';
      final api = _Api()
        ..replies['seller.one'] = _response(_data('seller.one', id: _publicOne))
        ..postReplies[first] = _response({
          'items': [_serverPost(_postOne)],
          'total': 21,
          'page': 1,
          'limit': 20,
        })
        ..postReplies[second] = _response({
          'items': [_serverPost(_postTwo)],
          'total': 21,
          'page': 2,
          'limit': 20,
        })
        ..postReplies[category] = _response({
          'items': [],
          'total': 0,
          'page': 1,
          'limit': 20,
        });
      final cubit = SellerProfileCubit(_repository(api));
      await cubit.load('seller.one');
      await Future<void>.delayed(Duration.zero);
      await cubit.loadPosts(next: true);
      expect(cubit.state.posts.posts.map((p) => p.id), [_postOne, _postTwo]);
      cubit.selectCategory(_categoryOne);
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.posts.posts, isEmpty);
      expect(api.paths, contains(category));
      await cubit.close();
    },
  );

  testWidgets(
    'public profile shows backend posts in existing grid and category selection',
    (tester) async {
      const first = 'users/$_publicOne/posts?page=1&limit=20';
      const category =
          'users/$_publicOne/posts?categoryId=$_categoryOne&page=1&limit=20';
      final api = _Api()
        ..replies['seller.one'] = _response(_data('seller.one', id: _publicOne))
        ..categoryReplies[_publicOne] = _categoryList('Real category')
        ..postReplies[first] = _response({
          'items': [_serverPost(_postOne)],
          'total': 1,
          'page': 1,
          'limit': 20,
        })
        ..postReplies[category] = _response({
          'items': [],
          'total': 0,
          'page': 1,
          'limit': 20,
        });
      await tester.pumpWidget(
        _host(api, const SellerProfileScreen(username: 'seller.one')),
      );
      await tester.pumpAndSettle();
      expect(find.byType(ProfilePostCard), findsOneWidget);
      await tester.tap(find.text('Real category'));
      await tester.pumpAndSettle();
      expect(api.paths, contains(category));
      expect(find.byType(ProfilePostCard), findsNothing);
    },
  );

  test(
    'late profile posts cannot replace a different profile or category',
    () async {
      const first = 'users/$_publicOne/posts?page=1&limit=20';
      const category =
          'users/$_publicOne/posts?categoryId=$_categoryOne&page=1&limit=20';
      final api = _Api()
        ..replies['seller.one'] = _response(_data('seller.one', id: _publicOne))
        ..replies['seller.two'] = _response(_data('seller.two', id: _publicTwo))
        ..gates[first] = Completer<void>()
        ..postReplies[first] = _response({
          'items': [_serverPost(_postOne)],
          'total': 1,
          'page': 1,
          'limit': 20,
        })
        ..postReplies[category] = _response({
          'items': [],
          'total': 0,
          'page': 1,
          'limit': 20,
        });
      final cubit = SellerProfileCubit(_repository(api));
      await cubit.load('seller.one');
      cubit.selectCategory(_categoryOne);
      await Future<void>.delayed(Duration.zero);
      api.gates[first]!.complete();
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.posts.posts, isEmpty);
      await cubit.load('seller.two');
      expect(cubit.state.profile?.seller.id, _publicTwo);
      expect(cubit.state.posts.posts, isEmpty);
      await cubit.close();
    },
  );
  test(
    'followers and following requests preserve backend ordering and metadata',
    () async {
      const followers = 'users/$_publicOne/followers?page=1&limit=20';
      const following = 'users/$_publicOne/following?page=1&limit=20';
      final api = _Api()
        ..peopleReplies[followers] = _response({
          'items': [
            {
              ..._data('seller.two', id: _publicTwo),
              'verified': true,
              'followedAt': '2026-11-15T08:30:00Z',
            },
            {..._data('seller.one', id: _publicOne), 'username': null},
          ],
          'total': 2,
          'page': 1,
          'limit': 20,
        })
        ..peopleReplies[following] = _response({
          'items': [],
          'total': 0,
          'page': 1,
          'limit': 20,
        });
      final repo = _repository(api, _Tokens()..value = 'token');
      final people = await repo.loadFollowers(_publicOne);
      expect(api.paths.first, followers);
      expect(api.credentials.first, 'token');
      expect(people.items.map((p) => p.profile.seller.id), [
        _publicTwo,
        _publicOne,
      ]);
      expect(people.items.first.verified, true);
      expect(people.items.first.followedAt, DateTime.utc(2026, 11, 15, 8, 30));
      expect(people.items.last.profile.seller.username, '');
      expect((await repo.loadFollowing(_publicOne)).items, isEmpty);
      expect(api.paths.last, following);
      await expectLater(repo.loadFollowers('invalid'), throwsFormatException);
    },
  );

  test(
    'people pagination retains separate lists and preserves profile on failure',
    () async {
      const first = 'users/$_publicOne/followers?page=1&limit=20';
      const second = 'users/$_publicOne/followers?page=2&limit=20';
      const following = 'users/$_publicOne/following?page=1&limit=20';
      final api = _Api()
        ..replies['seller.one'] = _response(_data('seller.one', id: _publicOne))
        ..peopleReplies[first] = _response({
          'items': [_data('seller.one', id: _publicOne)],
          'total': 21,
          'page': 1,
          'limit': 20,
        })
        ..peopleReplies[second] = _response({
          'items': [_data('seller.two', id: _publicTwo)],
          'total': 21,
          'page': 2,
          'limit': 20,
        })
        ..peopleReplies[following] = _response({
          'items': [],
          'total': 0,
          'page': 1,
          'limit': 20,
        });
      final cubit = SellerProfileCubit(_repository(api));
      await cubit.load('seller.one');
      await cubit.loadFollowers();
      await cubit.loadFollowers(next: true);
      await cubit.loadFollowing();
      expect(cubit.state.followers.items.map((p) => p.profile.seller.id), [
        _publicOne,
        _publicTwo,
      ]);
      expect(cubit.state.followedUsers.items, isEmpty);
      expect(cubit.state.followedUsers.loaded, isTrue);
      api.peopleFailure = _error(type: DioExceptionType.connectionError);
      await cubit.loadFollowers();
      expect(cubit.state.followers.error, isTrue);
      expect(cubit.state.followers.items, hasLength(2));
      expect(cubit.state.profile?.seller.id, _publicOne);
      await cubit.close();
    },
  );

  test(
    'late people response cannot cross profile or session invalidation',
    () async {
      const endpoint = 'users/$_publicOne/followers?page=1&limit=20';
      for (final invalidate in [false, true]) {
        final api = _Api()
          ..replies['seller.one'] = _response(
            _data('seller.one', id: _publicOne),
          )
          ..replies['seller.two'] = _response(
            _data('seller.two', id: _publicTwo),
          )
          ..peopleReplies[endpoint] = _response({
            'items': [_data('seller.one', id: _publicOne)],
            'total': 1,
            'page': 1,
            'limit': 20,
          })
          ..gates[endpoint] = Completer<void>();
        final cubit = SellerProfileCubit(_repository(api));
        await cubit.load('seller.one');
        final pending = cubit.loadFollowers();
        await Future<void>.delayed(Duration.zero);
        if (invalidate) {
          cubit.invalidate();
        } else {
          await cubit.load('seller.two');
        }
        api.gates[endpoint]!.complete();
        await pending;
        expect(cubit.state.followers.items, isEmpty);
        expect(cubit.state.profile?.seller.id, invalidate ? null : _publicTwo);
        await cubit.close();
      }
    },
  );

  test('loaded followers refresh after a confirmed follow without fabricating entries', () async {
    const endpoint = 'users/$_publicOne/followers?page=1&limit=20';
    final api = _Api()
      ..replies['seller.one'] = _response(_data('seller.one', id: _publicOne))
      ..peopleReplies[endpoint] = _response({
        'items': [],
        'total': 0,
        'page': 1,
        'limit': 20,
      })
      ..followReply = _response({
        ..._data('seller.one', id: _publicOne),
        'isFollowing': true,
      });
    final cubit = SellerProfileCubit(
      _repository(api, _Tokens()..value = 'token'),
    );
    await cubit.load('seller.one');
    await cubit.loadFollowers();
    api.peopleReplies[endpoint] = _response({
      'items': [_data('seller.two', id: _publicTwo)],
      'total': 1,
      'page': 1,
      'limit': 20,
    });
    await cubit.follow(accountId: _publicTwo, isCurrentAccount: () => true);
    await Future<void>.delayed(Duration.zero);
    expect(api.paths.where((path) => path == endpoint), hasLength(2));
    expect(cubit.state.followers.items.single.profile.seller.id, _publicTwo);
    await cubit.close();
  });
  test(
    'unfollow sends authenticated DELETE and refreshes authoritative count',
    () async {
      final api = _Api()
        ..replies['seller.one'] = _response({
          ..._data('seller.one', id: _publicOne),
          'isFollowing': true,
        });
      final cubit = SellerProfileCubit(
        _repository(api, _Tokens()..value = 'token'),
      );
      await cubit.load('seller.one');
      final categories = cubit.state.categories;
      api.replies['seller.one'] = _response({
        ..._data('seller.one', id: _publicOne),
        'followersCount': 11,
      });
      await cubit.unfollow(accountId: _publicTwo, isCurrentAccount: () => true);
      expect(api.deletePath, 'users/$_publicOne/follow');
      expect(api.deleteToken, 'token');
      expect(cubit.state.profile?.isFollowing, isFalse);
      expect(cubit.state.profile?.followersCount, 11);
      expect(cubit.state.categories, same(categories));
      await cubit.unfollow(accountId: _publicTwo, isCurrentAccount: () => true);
      expect(api.deletes, 1);
      await cubit.close();
    },
  );

  test(
    'unfollow failure and uncertain outcome do not invent success or retry',
    () async {
      final api = _Api()
        ..replies['seller.one'] = _response({
          ..._data('seller.one', id: _publicOne),
          'isFollowing': true,
        })
        ..deleteFailure = _error(type: DioExceptionType.receiveTimeout);
      final cubit = SellerProfileCubit(
        _repository(api, _Tokens()..value = 'token'),
      );
      await cubit.load('seller.one');
      await cubit.unfollow(accountId: _publicTwo, isCurrentAccount: () => true);
      expect(cubit.state.profile?.isFollowing, isTrue);
      expect(cubit.state.profile?.followersCount, 12);
      await cubit.unfollow(accountId: _publicTwo, isCurrentAccount: () => true);
      expect(api.deletes, 1);
      await cubit.close();
    },
  );

  test(
    'confirmed unfollow does not invent a count when refresh fails',
    () async {
      final api = _Api()
        ..replies['seller.one'] = _response({
          ..._data('seller.one', id: _publicOne),
          'isFollowing': true,
        });
      final cubit = SellerProfileCubit(
        _repository(api, _Tokens()..value = 'token'),
      );
      await cubit.load('seller.one');
      api.failure = _error(type: DioExceptionType.connectionError);
      await cubit.unfollow(accountId: _publicTwo, isCurrentAccount: () => true);
      expect(cubit.state.profile?.isFollowing, isFalse);
      expect(cubit.state.profile?.followersCount, isNull);
      await cubit.close();
    },
  );

  test('late unfollow result is discarded after switching profile', () async {
    final api = _Api()
      ..replies['seller.one'] = _response({
        ..._data('seller.one', id: _publicOne),
        'isFollowing': true,
      })
      ..replies['seller.two'] = _response(_data('seller.two', id: _publicTwo))
      ..deleteGate = Completer<void>();
    final cubit = SellerProfileCubit(
      _repository(api, _Tokens()..value = 'token'),
    );
    await cubit.load('seller.one');
    final pending = cubit.unfollow(
      accountId: 'other-account',
      isCurrentAccount: () => true,
    );
    await Future<void>.delayed(Duration.zero);
    await cubit.load('seller.two');
    api.deleteGate!.complete();
    await pending;
    expect(cubit.state.profile?.seller.id, _publicTwo);
    expect(cubit.state.profile?.followersCount, 12);
    await cubit.close();
  });

  test('unfollow response for another user cannot confirm success', () async {
    final api = _Api()
      ..replies['seller.one'] = _response({
        ..._data('seller.one', id: _publicOne),
        'isFollowing': true,
      })
      ..deleteReply = _response({'userId': _publicTwo, 'isFollowing': false});
    final cubit = SellerProfileCubit(
      _repository(api, _Tokens()..value = 'token'),
    );
    await cubit.load('seller.one');
    await cubit.unfollow(accountId: _publicTwo, isCurrentAccount: () => true);
    expect(cubit.state.profile?.isFollowing, isTrue);
    expect(cubit.state.followError, contains('could not be confirmed'));
    await cubit.close();
  });

  test(
    'unfollow prevents self, unauthenticated and concurrent mutations',
    () async {
      final api = _Api()
        ..replies['seller.one'] = _response({
          ..._data('seller.one', id: _publicOne),
          'isFollowing': true,
        })
        ..deleteGate = Completer<void>();
      final cubit = SellerProfileCubit(
        _repository(api, _Tokens()..value = 'token'),
      );
      await cubit.load('seller.one');
      await cubit.unfollow(accountId: null, isCurrentAccount: () => false);
      await cubit.unfollow(accountId: _publicOne, isCurrentAccount: () => true);
      expect(api.deletes, 0);
      final pending = cubit.unfollow(
        accountId: _publicTwo,
        isCurrentAccount: () => true,
      );
      await Future<void>.delayed(Duration.zero);
      await cubit.unfollow(accountId: _publicTwo, isCurrentAccount: () => true);
      await cubit.follow(accountId: _publicTwo, isCurrentAccount: () => true);
      expect(api.deletes, 1);
      expect(api.writes, 0);
      api.deleteGate!.complete();
      await pending;
      await cubit.close();
    },
  );

  testWidgets('existing Following button invokes unfollow and updates count', (
    tester,
  ) async {
    final api = _Api()
      ..replies['seller.one'] = _response({
        ..._data('seller.one', id: _publicOne),
        'isFollowing': true,
      });
    final session = SessionCubit(_Auth());
    await session.restore();
    addTearDown(session.close);
    await tester.pumpWidget(
      _host(
        api,
        const SellerProfileScreen(username: 'seller.one'),
        session: session,
        tokens: _Tokens()..value = 'token',
      ),
    );
    await tester.pumpAndSettle();
    api.replies['seller.one'] = _response({
      ..._data('seller.one', id: _publicOne),
      'followersCount': 11,
    });
    await tester.tap(find.widgetWithText(AppButton, AppStrings.following));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppButton, AppStrings.follow), findsOneWidget);
    expect(
      tester.widget<ProfileStats>(find.byType(ProfileStats)).salesCount,
      '11',
    );
    expect(api.deletes, 1);
    await tester.pumpWidget(const SizedBox());
  });
  test(
    'follow posts the real user UUID and uses confirmed status and count',
    () async {
      final api = _Api()
        ..replies['seller.one'] = _response(_data('seller.one', id: _publicOne))
        ..followReply = _response({
          ..._data('seller.one', id: _publicOne),
          'isFollowing': true,
          'followersCount': 13,
        });
      final tokens = _Tokens()..value = 'synthetic-credential';
      final cubit = SellerProfileCubit(_repository(api, tokens));
      await cubit.load('seller.one');
      final categories = cubit.state.categories;
      await cubit.follow(accountId: _publicTwo, isCurrentAccount: () => true);
      expect(api.followPath, 'users/$_publicOne/follow');
      expect(api.followToken, 'synthetic-credential');
      expect(cubit.state.profile?.isFollowing, isTrue);
      expect(cubit.state.profile?.followersCount, 13);
      expect(cubit.state.categories, same(categories));
      await cubit.follow(accountId: _publicTwo, isCurrentAccount: () => true);
      expect(api.writes, 1);
      await cubit.close();
    },
  );

  test(
    'follow blocks self, logged-out users and repeated concurrent taps',
    () async {
      final api = _Api()
        ..replies['seller.one'] = _response(_data('seller.one', id: _publicOne))
        ..followReply = _response({
          ..._data('seller.one', id: _publicOne),
          'isFollowing': true,
        })
        ..followGate = Completer<void>();
      final cubit = SellerProfileCubit(
        _repository(api, _Tokens()..value = 'token'),
      );
      await cubit.load('seller.one');
      await cubit.follow(accountId: null, isCurrentAccount: () => false);
      await cubit.follow(accountId: _publicOne, isCurrentAccount: () => true);
      expect(api.writes, 0);
      final first = cubit.follow(
        accountId: _publicTwo,
        isCurrentAccount: () => true,
      );
      await Future<void>.delayed(Duration.zero);
      await cubit.follow(accountId: _publicTwo, isCurrentAccount: () => true);
      expect(api.writes, 1);
      api.followGate!.complete();
      await first;
      await cubit.close();
    },
  );

  test('failed or stale follow never changes another profile', () async {
    final api = _Api()
      ..replies['seller.one'] = _response(_data('seller.one', id: _publicOne))
      ..replies['seller.two'] = _response(_data('seller.two', id: _publicTwo))
      ..followReply = _response({
        ..._data('seller.one', id: _publicOne),
        'isFollowing': true,
      })
      ..followGate = Completer<void>();
    final cubit = SellerProfileCubit(
      _repository(api, _Tokens()..value = 'token'),
    );
    await cubit.load('seller.one');
    final pending = cubit.follow(
      accountId: 'other-account',
      isCurrentAccount: () => true,
    );
    await Future<void>.delayed(Duration.zero);
    await cubit.load('seller.two');
    api.followGate!.complete();
    await pending;
    expect(cubit.state.profile?.seller.id, _publicTwo);
    expect(cubit.state.profile?.isFollowing, isFalse);
    api.followFailure = _error(status: 403);
    await cubit.follow(
      accountId: 'other-account',
      isCurrentAccount: () => true,
    );
    expect(cubit.state.profile?.isFollowing, isFalse);
    expect(cubit.state.followError, isNotNull);
    await cubit.close();
  });

  test(
    'an uncertain follow is reconciled or blocked from blind retry',
    () async {
      final api = _Api()
        ..replies['seller.one'] = _response(_data('seller.one', id: _publicOne))
        ..followFailure = _error(type: DioExceptionType.receiveTimeout);
      final cubit = SellerProfileCubit(
        _repository(api, _Tokens()..value = 'token'),
      );
      await cubit.load('seller.one');
      await cubit.follow(accountId: _publicTwo, isCurrentAccount: () => true);
      expect(cubit.state.profile?.isFollowing, isFalse);
      expect(cubit.state.followError, contains('could not be confirmed'));
      await cubit.follow(accountId: _publicTwo, isCurrentAccount: () => true);
      expect(api.writes, 1);
      await cubit.close();
    },
  );

  test('account switch during follow ignores the late response', () async {
    final api = _Api()
      ..replies['seller.one'] = _response(_data('seller.one', id: _publicOne))
      ..followReply = _response({
        ..._data('seller.one', id: _publicOne),
        'isFollowing': true,
      })
      ..followGate = Completer<void>();
    final cubit = SellerProfileCubit(
      _repository(api, _Tokens()..value = 'token'),
    );
    await cubit.load('seller.one');
    var current = true;
    final pending = cubit.follow(
      accountId: _publicTwo,
      isCurrentAccount: () => current,
    );
    await Future<void>.delayed(Duration.zero);
    current = false;
    cubit.invalidate();
    api.followGate!.complete();
    await pending;
    expect(cubit.state.profile, isNull);
    await cubit.close();
  });

  testWidgets('existing Follow button displays confirmed server result', (
    tester,
  ) async {
    final api = _Api()
      ..replies['seller.one'] = _response(_data('seller.one', id: _publicOne))
      ..followReply = _response({
        ..._data('seller.one', id: _publicOne),
        'isFollowing': true,
        'followersCount': 18,
      });
    final session = SessionCubit(_Auth());
    await session.restore();
    addTearDown(session.close);
    await tester.pumpWidget(
      _host(
        api,
        const SellerProfileScreen(username: 'seller.one'),
        session: session,
        tokens: _Tokens()..value = 'token',
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(AppButton, AppStrings.follow));
    await tester.pumpAndSettle();
    expect(
      find.widgetWithText(AppButton, AppStrings.following),
      findsOneWidget,
    );
    expect(
      tester.widget<ProfileStats>(find.byType(ProfileStats)).salesCount,
      '18',
    );
    expect(api.writes, 1);
    await tester.pumpWidget(const SizedBox());
  });
  for (final authenticated in [false, true]) {
    test(
      'valid public profile ${authenticated ? 'with' : 'without'} authentication maps actual server fields',
      () async {
        final api = _Api();
        final tokens = _Tokens()
          ..value = authenticated ? 'synthetic-credential' : null;
        api.replies['seller.one'] = _response({
          ..._data('seller.one'),
          'isMe': true,
          'isFollowing': true,
          'avatarUrl': 'https://example.com/avatar.webp',
        });
        final profile = await _repository(
          api,
          tokens,
        ).load(' @seller.one ', expectedUserId: 'id-seller.one');
        expect(api.paths, ['users/profile/seller.one']);
        expect(api.credentials, [tokens.value]);
        expect(profile.seller.id, 'id-seller.one');
        expect(profile.seller.username, 'seller.one');
        expect(profile.seller.name, 'Backend seller.one');
        expect(profile.seller.avatarAsset, 'https://example.com/avatar.webp');
        expect(profile.followersCount, 12);
        expect(profile.followingCount, 7);
        expect(profile.postsCount, 27);
        expect(profile.isMe, isTrue);
        expect(profile.isFollowing, isTrue);
        expect(tokens.deletions, 0);
      },
    );
  }
  for (final username in [
    '',
    'Display Name',
    'local-profile',
    '../seller',
    'a/b',
    'a?b',
    '@',
    'ab',
    'UPPERCASE',
  ]) {
    test(
      'invalid or missing username is not guessed or requested: $username',
      () async {
        final api = _Api();
        await expectLater(
          _repository(api).load(username),
          throwsFormatException,
        );
        expect(api.paths, isEmpty);
      },
    );
  }
  test(
    'missing optional fields remain empty or unknown instead of demo data',
    () async {
      final api = _Api()
        ..replies['seller.one'] = _response({
          'id': 'remote',
          'username': 'seller.one',
        });
      final profile = await _repository(api).load('seller.one');
      expect(profile.seller.name, isEmpty);
      expect(profile.seller.avatarAsset, isEmpty);
      expect(profile.seller.bio, isEmpty);
      expect(profile.seller.location, isEmpty);
      expect(profile.followersCount, isNull);
      expect(profile.followingCount, isNull);
      expect(profile.postsCount, isNull);
      expect(profile.isFollowing, isNull);
    },
  );
  for (final response in [
    {'success': false, 'data': _data('seller.one')},
    {'success': true, 'data': null},
    _response(_data('different.user')),
    _response({..._data('seller.one'), 'id': ''}),
    _response({..._data('seller.one'), 'followersCount': -1}),
    _response({..._data('seller.one'), 'isFollowing': 'true'}),
    _response({..._data('seller.one'), 'bio': 42}),
  ]) {
    test(
      'invalid response or mismatched identity never becomes a public profile: ${response['data']}',
      () async {
        final api = _Api()..replies['seller.one'] = response;
        await expectLater(
          _repository(api).load('seller.one'),
          throwsFormatException,
        );
      },
    );
  }
  test('a selected backend ID must match the returned user', () async {
    await expectLater(
      _repository(_Api()).load('seller.one', expectedUserId: 'another-id'),
      throwsFormatException,
    );
  });
  for (final url in [
    'assets/img1.png',
    '/device/photo.jpg',
    'javascript:alert(1)',
    'https:///missing-host',
  ]) {
    test('invalid public avatar uses the neutral fallback: $url', () async {
      final api = _Api()
        ..replies['seller.one'] = _response({
          ..._data('seller.one'),
          'avatarUrl': url,
        });
      final profile = await _repository(api).load('seller.one');
      expect(profile.seller.avatarAsset, isEmpty);
      expect(profile.seller.name, 'Backend seller.one');
    });
  }
  for (final scenario in [
    (
      status: 404,
      type: DioExceptionType.badResponse,
      message: ProfilePostStrings.publicUnavailable,
    ),
    (
      status: 401,
      type: DioExceptionType.badResponse,
      message: ProfilePostStrings.publicSessionFailed,
    ),
    (
      status: 500,
      type: DioExceptionType.badResponse,
      message: ProfilePostStrings.publicLoadFailed,
    ),
    (
      status: null,
      type: DioExceptionType.connectionError,
      message: ProfilePostStrings.publicConnectionFailed,
    ),
    (
      status: null,
      type: DioExceptionType.receiveTimeout,
      message: ProfilePostStrings.publicTimeout,
    ),
  ]) {
    test(
      'public ${scenario.status ?? scenario.type} has a safe error and retry does not change authentication',
      () async {
        final api = _Api()
          ..failure = _error(status: scenario.status, type: scenario.type);
        final tokens = _Tokens()..value = 'synthetic-credential';
        final cubit = SellerProfileCubit(_repository(api, tokens));
        addTearDown(cubit.close);
        await cubit.load('seller.one');
        expect(cubit.state.profile, isNull);
        expect(cubit.state.error, scenario.message);
        expect(cubit.state.canRetry, scenario.status != 404);
        expect(tokens.value, 'synthetic-credential');
        expect(tokens.deletions, 0);
        api.failure = null;
        await cubit.load('seller.one');
        expect(cubit.state.profile!.seller.username, 'seller.one');
        expect(api.paths, hasLength(2));
      },
    );
  }
  test('duplicate loads coalesce and a late previous-user response cannot replace the selected profile', () async {
    final api = _Api()
      ..gates['seller.one'] = Completer<void>()
      ..gates['seller.two'] = Completer<void>();
    final cubit = SellerProfileCubit(_repository(api));
    addTearDown(cubit.close);
    final first = cubit.load('seller.one');
    final duplicate = cubit.load('seller.one');
    await Future<void>.delayed(Duration.zero);
    expect(api.paths, hasLength(1));
    final second = cubit.load('seller.two');
    expect(cubit.state.profile, isNull);
    api.gates['seller.two']!.complete();
    await second;
    expect(cubit.state.profile!.seller.username, 'seller.two');
    api.gates['seller.one']!.complete();
    await Future.wait([first, duplicate]);
    expect(cubit.state.profile!.seller.username, 'seller.two');
    expect(api.paths, hasLength(2));
  });
  test('closed and invalidated Cubits discard pending profile and relationship data', () async {
    for (final close in [false, true]) {
      final api = _Api()..gates['seller.one'] = Completer<void>();
      final cubit = SellerProfileCubit(_repository(api));
      final loading = cubit.load('seller.one');
      if (close) {
        await cubit.close();
      } else {
        cubit.invalidate();
      }
      api.gates['seller.one']!.complete();
      await loading;
      expect(cubit.state.profile, isNull);
      if (!close) await cubit.close();
    }
  });
  testWidgets(
    'real profile fields and backend counts remain visible when logged out',
    (tester) async {
      final api = _Api()
        ..replies['seller.one'] = _response({
          ..._data('seller.one', id: _publicOne),
          'isFollowing': true,
        });
      final own = UserProfileCubit(_OwnProfiles());
      await own.load();
      addTearDown(own.close);
      final previous = own.state.profile;
      await tester.pumpWidget(
        _host(api, const SellerProfileScreen(username: 'seller.one'), own: own),
      );
      await tester.pumpAndSettle();
      expect(find.text('Backend seller.one'), findsOneWidget);
      expect(find.text('@seller.one'), findsOneWidget);
      expect(find.text('Confirmed biography'), findsOneWidget);
      expect(find.text('Confirmed city'), findsOneWidget);
      final stats = tester.widget<ProfileStats>(find.byType(ProfileStats));
      expect(stats.postCount, '27');
      expect(stats.salesCount, '12');
      expect(stats.customerCount, '7');
      expect(stats.salesLabel, AppStrings.followers);
      expect(stats.customerLabel, AppStrings.following);
      expect(find.byType(ProfilePostCard), findsNothing);
      expect(find.text(AppStrings.noSellerPosts), findsOneWidget);
      await tester.tap(find.widgetWithText(AppButton, AppStrings.following));
      await tester.pumpAndSettle();
      expect(
        find.widgetWithText(AppButton, AppStrings.following),
        findsOneWidget,
      );
      expect(find.text('Please sign in to follow this user.'), findsOneWidget);
      expect(api.writes, 0);
      expect(own.state.profile, same(previous));
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'loading and 404 states show no previous or fabricated seller data',
    (tester) async {
      final api = _Api()
        ..gates['seller.one'] = Completer<void>()
        ..failure = _error(status: 404);
      await tester.pumpWidget(
        _host(api, const SellerProfileScreen(username: 'seller.one')),
      );
      await tester.pump();
      expect(find.byType(ProfileSkeleton), findsOneWidget);
      expect(find.byType(SellerProfileHeader), findsNothing);
      api.gates['seller.one']!.complete();
      await tester.pumpAndSettle();
      expect(find.text(ProfilePostStrings.publicUnavailable), findsOneWidget);
      expect(find.byType(SellerProfileHeader), findsNothing);
      expect(find.widgetWithText(AppButton, AppStrings.retry), findsNothing);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'missing username shows an unavailable state without a repository or fabricated identity',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: SellerProfileScreen(username: 'Display Name')),
      );
      await tester.pumpAndSettle();
      expect(
        find.text(ProfilePostStrings.publicIdentityMissing),
        findsOneWidget,
      );
      expect(find.text('Display Name'), findsNothing);
      expect(find.byType(SellerProfileHeader), findsNothing);
    },
  );
  testWidgets('retry recovers from a connection failure without stale data', (
    tester,
  ) async {
    final api = _Api()
      ..failure = _error(type: DioExceptionType.connectionError);
    await tester.pumpWidget(
      _host(api, const SellerProfileScreen(username: 'seller.one')),
    );
    await tester.pumpAndSettle();
    expect(
      find.text(ProfilePostStrings.publicConnectionFailed),
      findsOneWidget,
    );
    expect(find.byType(SellerProfileHeader), findsNothing);
    api.failure = null;
    await tester.tap(find.widgetWithText(AppButton, AppStrings.retry));
    await tester.pumpAndSettle();
    expect(find.text('Backend seller.one'), findsOneWidget);
    expect(api.paths, hasLength(2));
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('changing the screen username clears the previous profile', (
    tester,
  ) async {
    final api = _Api()..gates['seller.two'] = Completer<void>();
    await tester.pumpWidget(
      _host(api, const SellerProfileScreen(username: 'seller.one')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Backend seller.one'), findsOneWidget);
    await tester.pumpWidget(
      _host(api, const SellerProfileScreen(username: 'seller.two')),
    );
    await tester.pump();
    expect(find.text('Backend seller.one'), findsNothing);
    expect(find.byType(ProfileSkeleton), findsOneWidget);
    api.gates['seller.two']!.complete();
    await tester.pumpAndSettle();
    expect(find.text('Backend seller.two'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets(
    'session identity recognizes own sellers before profile loading',
    (tester) async {
      final api = _Api();
      final session = SessionCubit(_Auth());
      await session.restore();
      addTearDown(session.close);
      var opened = false;
      const seller = PostSeller(
        id: 'own-account',
        username: 'my.account',
        name: 'My real name',
        avatarAsset: '',
      );
      await tester.pumpWidget(
        _host(
          api,
          Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => openHomeSeller(
                  context,
                  _post(seller: seller),
                  seller,
                  onOwnProfilePressed: () => opened = true,
                ),
                child: const Text('Own profile'),
              ),
            ),
          ),
          session: session,
        ),
      );
      await tester.tap(find.text('Own profile'));
      await tester.pumpAndSettle();
      expect(opened, isTrue);
      expect(api.paths, isEmpty);
      expect(find.byType(SellerProfileScreen), findsNothing);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'isMe opens the own-profile navigation callback without changing own data',
    (tester) async {
      final api = _Api()
        ..replies['seller.one'] = _response({
          ..._data('seller.one'),
          'isMe': true,
        });
      var opened = 0;
      final own = UserProfileCubit(_OwnProfiles());
      await own.load();
      addTearDown(own.close);
      final previous = own.state.profile;
      await tester.pumpWidget(
        _host(
          api,
          SellerProfileScreen(
            username: 'seller.one',
            onOwnProfilePressed: () => opened++,
          ),
          own: own,
        ),
      );
      await tester.pumpAndSettle();
      expect(opened, 1);
      expect(own.state.profile, same(previous));
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets('logout and account switching invalidate pending public data', (
    tester,
  ) async {
    final api = _Api()..gates['seller.one'] = Completer<void>();
    final auth = _Auth();
    final session = SessionCubit(auth);
    await session.restore();
    addTearDown(session.close);
    await tester.pumpWidget(
      _host(
        api,
        const SellerProfileScreen(username: 'seller.one'),
        session: session,
      ),
    );
    await tester.pump();
    await session.logout();
    await tester.pump();
    auth.actor = 'second-account';
    await session.restore();
    api.gates['seller.one']!.complete();
    await tester.pumpAndSettle();
    expect(find.byType(SellerProfileHeader), findsNothing);
    expect(find.text(ProfilePostStrings.publicSessionChanged), findsOneWidget);
    expect(api.paths, hasLength(1));
    await tester.pumpWidget(const SizedBox());
  });
  for (final source in [
    'Home',
    'product detail',
    'service detail',
    'Search service card',
  ]) {
    testWidgets(
      '$source hands off the real username, fetches a public profile and returns normally',
      (tester) async {
        final api = _Api();
        const seller = PostSeller(
          id: 'id-seller.one',
          username: 'seller.one',
          name: 'Feed identity',
          avatarAsset: '',
        );
        final post = _post(service: source.contains('service'), seller: seller);
        await tester.pumpWidget(
          _host(
            api,
            Scaffold(
              body: Builder(
                builder: (context) {
                  if (source == 'Home') {
                    return HomeSellerHeader(
                      seller: seller,
                      onPressed: () => openHomeSeller(context, post, seller),
                    );
                  }
                  if (source == 'Search service card') {
                    return SearchResultsGrid(
                      posts: [post],
                      onPostSelected: (selected) => openHomePost(
                        context,
                        selected,
                        SearchCatalog.sellerFor(selected)!,
                      ),
                    );
                  }
                  return TextButton(
                    onPressed: () => openHomePost(context, post, seller),
                    child: const Text('Open details'),
                  );
                },
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        if (source == 'Search service card') {
          await tester.tap(find.byType(ProfilePostCard));
          await tester.pumpAndSettle();
        } else if (source != 'Home') {
          await tester.tap(find.text('Open details'));
          await tester.pumpAndSettle();
        }
        final avatar = find.descendant(
          of: find.byType(
            source == 'Home' ? HomeSellerHeader : PostAuthorHeader,
          ),
          matching: find.byType(SellerAvatar),
        );
        await tester.ensureVisible(avatar);
        await tester.tap(avatar);
        await tester.pumpAndSettle();
        expect(find.byType(SellerProfileScreen), findsOneWidget);
        expect(api.paths, ['users/profile/seller.one']);
        expect(find.text('Backend seller.one'), findsOneWidget);
        expect(find.text('Feed identity'), findsNothing);
        expect(find.byType(ProfilePostCard), findsNothing);
        Navigator.of(tester.element(find.byType(SellerProfileScreen))).pop();
        await tester.pumpAndSettle();
        expect(find.byType(SellerProfileScreen), findsNothing);
        if (source != 'Home') {
          expect(find.byType(PostDetailScreen), findsOneWidget);
        }
        await tester.pumpWidget(const SizedBox());
      },
    );
  }
  test(
    'Search no longer presents bundled provider listings as server data',
    () {
      expect(SearchCatalog.resultsFor('تهران', ''), isEmpty);
      final local = PostItem.fromJson({
        ..._post(service: true).toJson(),
        'publishedAt': DateTime(2026).toIso8601String(),
      });
      expect(SearchCatalog.resultsFor('تهران', '', publishedPosts: [local]), [
        local,
      ]);
      expect(
        PostSeller.fromJson(
          const PostSeller(
            id: 'remote',
            username: 'seller.one',
            name: 'Backend',
            avatarAsset: '',
          ).toJson(),
        ).username,
        'seller.one',
      );
    },
  );

  test('public categories require a user UUID and use the public endpoint without credentials', () async {
    final api = _Api();
    api.categoryReplies[_publicOne] = _categoryList('Real public name');
    final tokens = _Tokens()..value = 'synthetic-credential';
    final repo = _repository(api, tokens);
    final categories = await repo.loadCategories(_publicOne);
    expect(api.paths, ['users/$_publicOne/categories']);
    expect(api.credentials, [null]);
    expect(categories.allCount, 5);
    expect(categories.items.map((item) => item.name), [
      'Real public name',
      'Second public category',
    ]);
    expect(categories.items.map((item) => item.position), [0, 1]);
    for (final id in ['seller.one', 'local-id', '../other']) {
      await expectLater(repo.loadCategories(id), throwsFormatException);
    }
    expect(api.paths.length, 1);
    expect(tokens.value, 'synthetic-credential');
    expect(tokens.deletions, 0);
  });

  test('profile fetch supplies the UUID; duplicate loads and old category responses cannot cross profiles', () async {
    final api = _Api();
    api.replies['seller.one'] = _response(_data('seller.one', id: _publicOne));
    api.replies['seller.two'] = _response(_data('seller.two', id: _publicTwo));
    api.categoryReplies[_publicOne] = _categoryList('First user categories');
    api.categoryReplies[_publicTwo] = _categoryList(
      'Second user categories',
      count: 8,
    );
    api.gates['categories:$_publicOne'] = Completer<void>();
    final cubit = SellerProfileCubit(_repository(api));
    addTearDown(cubit.close);
    final first = cubit.load('seller.one');
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state.profile?.seller.id, _publicOne);
    expect(cubit.state.categoriesLoading, isTrue);
    final duplicate = cubit.load('seller.one');
    expect(identical(first, duplicate), isTrue);
    expect(
      api.paths,
      unorderedEquals([
        'users/profile/seller.one',
        'users/$_publicOne/posts?page=1&limit=20',
        'users/$_publicOne/categories',
      ]),
    );
    final second = cubit.load('seller.two');
    expect(cubit.state.profile, isNull);
    expect(cubit.state.categories, isNull);
    await second;
    expect(cubit.state.categories?.items.first.name, 'Second user categories');
    expect(cubit.state.categories?.allCount, 8);
    api.gates['categories:$_publicOne']!.complete();
    await first;
    expect(cubit.state.profile?.seller.id, _publicTwo);
    expect(cubit.state.categories?.items.first.name, 'Second user categories');
    expect(api.writes, 0);
  });

  test('public category failure retains confirmed profile, supports retry and has no own-category fallback', () async {
    final api = _Api();
    api.replies['seller.one'] = _response(_data('seller.one', id: _publicOne));
    api.categoryFailure = _error(type: DioExceptionType.connectionError);
    final cubit = SellerProfileCubit(_repository(api));
    addTearDown(cubit.close);
    await cubit.load('seller.one');
    expect(cubit.state.profile?.seller.id, _publicOne);
    expect(cubit.state.categories, isNull);
    expect(
      cubit.state.categoriesError,
      ProfilePostStrings.publicCategoriesFailed,
    );
    api.categoryFailure = null;
    api.categoryReplies[_publicOne] = _response({
      'allCount': 0,
      'items': <Object>[],
    });
    await cubit.retryCategories();
    expect(cubit.state.categories?.items, isEmpty);
    expect(cubit.state.categories?.allCount, 0);
    expect(cubit.state.categoriesError, isNull);
    expect(
      api.paths.where((path) => path.startsWith('users/profile/')).length,
      1,
    );
    api.categoryReplies[_publicOne] = _response({
      'items': [
        {'id': 'invalid'},
      ],
    });
    await cubit.retryCategories();
    expect(cubit.state.categories, isNull);
    expect(cubit.state.categoriesError, isNotNull);
  });

  test(
    'pending category results are discarded on invalidation and closure',
    () async {
      for (final close in [false, true]) {
        final api = _Api();
        api.replies['seller.one'] = _response(
          _data('seller.one', id: _publicOne),
        );
        api.gates['categories:$_publicOne'] = Completer<void>();
        final cubit = SellerProfileCubit(_repository(api));
        final request = cubit.load('seller.one');
        await Future<void>.delayed(Duration.zero);
        if (close) {
          await cubit.close();
        } else {
          cubit.invalidate();
        }
        api.gates['categories:$_publicOne']!.complete();
        await request;
        expect(cubit.state.categories, isNull);
        if (!close) {
          expect(cubit.state.profile, isNull);
          await cubit.close();
        }
      }
    },
  );

  testWidgets(
    'public counts bind to the existing header while own category state stays isolated',
    (tester) async {
      final api = _Api();
      api.replies['seller.one'] = _response(
        _data('seller.one', id: _publicOne),
      );
      api.categoryReplies[_publicOne] = _categoryList(
        'Public backend category',
        count: 5,
      );
      final own = ProfileCategoriesCubit(_OwnCategories());
      own.emit(
        const ProfileCategoriesState(
          categories: [
            ProfileCategory(id: _categoryTwo, name: 'Own private category'),
          ],
          loading: false,
          allCount: 99,
        ),
      );
      addTearDown(own.close);
      final before = own.state;
      await tester.pumpWidget(
        BlocProvider.value(
          value: own,
          child: _host(api, const SellerProfileScreen(username: 'seller.one')),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester.widget<ProfileStats>(find.byType(ProfileStats)).postCount,
        '5',
      );
      final state = tester
          .element(find.byType(SellerProfileContent))
          .read<SellerProfileCubit>()
          .state;
      expect(state.categories?.items.first.name, 'Public backend category');
      expect(own.state, same(before));
      expect(find.text('Own private category'), findsNothing);
      final chips = tester
          .widgetList<ProfileCategoryChip>(find.byType(ProfileCategoryChip))
          .toList();
      expect(chips.map((chip) => chip.label), [
        ProfilePostStrings.all,
        'Public backend category',
        'Second public category',
      ]);
      expect(chips.map((chip) => chip.count), [5, 3, 1]);
      expect(chips.every((chip) => chip.onTap != null), isTrue);
      expect(find.byIcon(Icons.add), findsNothing);
      expect(find.byIcon(Icons.edit_outlined), findsNothing);
      expect(find.byIcon(Icons.delete_outline), findsNothing);
      await tester.ensureVisible(find.text('Public backend category'));
      await tester.tap(find.text('Public backend category'));
      await tester.pumpAndSettle();
      expect(own.state, same(before));
      expect(api.writes, 0);
      expect(find.byType(ProfilePostCard), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'public category UI clears during profile switching and ignores late responses',
    (tester) async {
      final api = _Api();
      api.replies['seller.one'] = _response(
        _data('seller.one', id: _publicOne),
      );
      api.replies['seller.two'] = _response(
        _data('seller.two', id: _publicTwo),
      );
      api.categoryReplies[_publicOne] = _categoryList(
        'First public categories',
      );
      api.categoryReplies[_publicTwo] = _categoryList('Second user categories');
      await tester.pumpWidget(
        _host(api, const SellerProfileScreen(username: 'seller.one')),
      );
      await tester.pumpAndSettle();
      expect(find.text('First public categories'), findsOneWidget);
      final oldCubit = tester
          .element(find.byType(SellerProfileContent))
          .read<SellerProfileCubit>();
      api.gates['categories:$_publicOne'] = Completer<void>();
      final oldRequest = oldCubit.retryCategories();
      await tester.pumpAndSettle();
      expect(find.byType(ProfileCategoryChip), findsNothing);
      expect(
        find.text(ProfilePostStrings.publicCategoriesLoading),
        findsOneWidget,
      );
      api.gates['categories:$_publicTwo'] = Completer<void>();
      await tester.pumpWidget(
        _host(api, const SellerProfileScreen(username: 'seller.two')),
      );
      await tester.pumpAndSettle();
      expect(find.text('First public categories'), findsNothing);
      expect(find.byType(ProfileCategoryChip), findsNothing);
      api.gates['categories:$_publicTwo']!.complete();
      await tester.pumpAndSettle();
      expect(find.text('Second user categories'), findsOneWidget);
      api.gates['categories:$_publicOne']!.complete();
      await oldRequest;
      await tester.pumpAndSettle();
      expect(find.text('First public categories'), findsNothing);
      expect(find.text('Second user categories'), findsOneWidget);
      expect(api.writes, 0);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'public category failure and empty results never show fabricated chips',
    (tester) async {
      final api = _Api();
      api.replies['seller.one'] = _response(
        _data('seller.one', id: _publicOne),
      );
      api.categoryFailure = _error(type: DioExceptionType.connectionError);
      await tester.pumpWidget(
        _host(api, const SellerProfileScreen(username: 'seller.one')),
      );
      await tester.pumpAndSettle();
      expect(
        find.text(ProfilePostStrings.publicCategoriesFailed),
        findsOneWidget,
      );
      expect(find.byType(ProfileCategoryChip), findsNothing);
      expect(find.text('Backend seller.one'), findsOneWidget);
      api.categoryFailure = null;
      api.categoryReplies[_publicOne] = _response({
        'allCount': 0,
        'items': <Object>[],
      });
      final cubit = tester
          .element(find.byType(SellerProfileContent))
          .read<SellerProfileCubit>();
      await cubit.retryCategories();
      await tester.pumpAndSettle();
      final chip = tester.widget<ProfileCategoryChip>(
        find.byType(ProfileCategoryChip),
      );
      expect(chip.label, ProfilePostStrings.all);
      expect(chip.count, 0);
      expect(chip.onTap, isNotNull);
      expect(find.byIcon(Icons.add), findsNothing);
      expect(find.byType(ProfilePostCard), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  for (final brightness in Brightness.values) {
    for (final width in [320.0, 720.0]) {
      testWidgets(
        'read-only public chips retain styling, RTL order and large-text layout in $brightness at $width',
        (tester) async {
          tester.view.physicalSize = Size(width, 900);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final categories = ProfileCategoryList.fromApiJson(
            _categoryList('Public backend category')['data']
                as Map<String, dynamic>,
          );
          await tester.pumpWidget(
            MaterialApp(
              theme: brightness == Brightness.dark
                  ? AppTheme.dark
                  : AppTheme.light,
              home: MediaQuery(
                data: MediaQueryData(
                  size: Size(width, 900),
                  textScaler: TextScaler.linear(1.6),
                ),
                child: Scaffold(
                  body: ProfileCategoryChips.readOnly(categories: categories),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          final chips = tester
              .widgetList<ProfileCategoryChip>(find.byType(ProfileCategoryChip))
              .toList();
          expect(chips.first.label, ProfilePostStrings.all);
          expect(chips.every((chip) => chip.onTap == null), isTrue);
          expect(
            tester.getCenter(find.text(ProfilePostStrings.all)).dx,
            greaterThan(width / 2),
          );
          expect(
            tester.getCenter(find.text(ProfilePostStrings.all)).dx,
            greaterThan(
              tester.getCenter(find.text('Public backend category')).dx,
            ),
          );
          final text = tester.widget<Text>(
            find.text('Public backend category'),
          );
          expect(text.textAlign, TextAlign.right);
          expect(text.textDirection, TextDirection.ltr);
          expect(find.byType(IconButton), findsNothing);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  final local = Uri.tryParse(AppConfig.apiBaseUrl);
  test('real Dio public GET sends optional Bearer and mobile headers with the configured URL', () async {
    final server = await HttpServer.bind(
      InternetAddress.loopbackIPv4,
      local!.port,
    );
    addTearDown(() => server.close(force: true));
    final headers = <String?>[];
    final errors = <Object>[];
    server.listen((request) async {
      try {
        expect(request.method, 'GET');
        expect(request.uri.path, '/api/users/profile/seller.one');
        expect(request.headers.value('X-Client'), 'mobile');
        headers.add(request.headers.value('Authorization'));
        request.response.headers.contentType = ContentType.json;
        request.response.write(jsonEncode(_response(_data('seller.one'))));
        await request.response.close();
      } catch (error) {
        errors.add(error);
        request.response.statusCode = 500;
        await request.response.close();
      }
    });
    final tokens = _Tokens();
    await HttpOverrides.runWithHttpOverrides(() async {
      final repository = ApiPublicProfileRepository(ApiClient(), tokens);
      await repository.load('@seller.one');
      tokens.value = 'synthetic-credential';
      await repository.load('seller.one');
    }, _RealHttp());
    expect(errors, isEmpty);
    expect(headers, [null, 'Bearer synthetic-credential']);
  }, skip: local?.host != '127.0.0.1');
  test('real Dio fetches public categories by backend UUID without Bearer authentication', () async {
    final server = await HttpServer.bind(
      InternetAddress.loopbackIPv4,
      local!.port,
    );
    addTearDown(() => server.close(force: true));
    final errors = <Object>[];
    final paths = <String>[];
    server.listen((request) async {
      try {
        expect(request.method, 'GET');
        expect(request.headers.value('X-Client'), 'mobile');
        expect(request.headers.value('Authorization'), isNull);
        paths.add(request.uri.path);
        request.response.headers.contentType = ContentType.json;
        request.response.write(
          jsonEncode(
            request.uri.path == '/api/users/profile/seller.one'
                ? _response(_data('seller.one', id: _publicOne))
                : _categoryList('Public category'),
          ),
        );
      } catch (error) {
        errors.add(error);
        request.response.statusCode = 500;
      } finally {
        await request.response.close();
      }
    });
    await HttpOverrides.runWithHttpOverrides(() async {
      final repo = ApiPublicProfileRepository(ApiClient(), _Tokens());
      final profile = await repo.load('seller.one');
      final categories = await repo.loadCategories(profile.seller.id);
      expect(categories.items.first.name, 'Public category');
    }, _RealHttp());
    expect(paths, [
      '/api/users/profile/seller.one',
      '/api/users/$_publicOne/categories',
    ]);
    expect(errors, isEmpty);
  }, skip: local?.host != '127.0.0.1');
}
