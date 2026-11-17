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
import 'package:nini/features/home/presentation/helpers/home_post_navigation.dart';
import 'package:nini/features/home/presentation/widgets/common/home_seller_header.dart';
import 'package:nini/features/login/data/auth_repo.dart';
import 'package:nini/features/login/presentation/cubit/session_cubit.dart';
import 'package:nini/features/profile/data/api_public_profile_repository.dart';
import 'package:nini/features/profile/presentation/cubit/seller_profile_cubit.dart';
import 'package:nini/features/profile/presentation/pages/seller_profile_screen.dart';
import 'package:nini/features/profile/presentation/widgets/account/profile_stats.dart';
import 'package:nini/features/profile/presentation/widgets/posts/profile_post_card.dart';
import 'package:nini/features/profile/presentation/widgets/seller/seller_profile_header.dart';
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
  Object? failure;
  int writes = 0;
  @override
  Future<Map<String, dynamic>> getPublic(
    String endpoint, {
    String? token,
  }) async {
    paths.add(endpoint);
    credentials.add(token);
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
    throw StateError('Unexpected write in public-profile flow');
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
}) {
  Widget app = MaterialApp(home: screen);
  if (own != null) app = BlocProvider.value(value: own, child: app);
  if (session != null) app = BlocProvider.value(value: session, child: app);
  return RepositoryProvider.value(value: _repository(api), child: app);
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
    'real profile fields and backend counts replace passed identities and follow remains read-only',
    (tester) async {
      final api = _Api()
        ..replies['seller.one'] = _response({
          ..._data('seller.one'),
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
      expect(
        find.text(ProfilePostStrings.publicPostsUnavailable),
        findsOneWidget,
      );
      await tester.tap(find.widgetWithText(AppButton, AppStrings.following));
      await tester.pumpAndSettle();
      expect(
        find.widgetWithText(AppButton, AppStrings.following),
        findsOneWidget,
      );
      expect(find.text(ProfilePostStrings.followUnavailable), findsOneWidget);
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
}
