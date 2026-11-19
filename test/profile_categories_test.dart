import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nini/app/app_providers.dart';
import 'package:nini/core/config/app_config/app_config.dart';
import 'package:nini/core/localization/strings/profile_post_strings.dart';
import 'package:nini/core/network/api_client.dart';
import 'package:nini/core/security/secure_token_store.dart';
import 'package:nini/core/theme/app_theme.dart';
import 'package:nini/features/create_post/data/api_categories_repository.dart';
import 'package:nini/features/create_post/domain/models/post_draft.dart';
import 'package:nini/features/create_post/presentation/cubit/create_post_cubit.dart';
import 'package:nini/features/create_post/presentation/cubit/post_categories_cubit.dart';
import 'package:nini/features/login/presentation/cubit/session_cubit.dart';
import 'package:nini/features/posts/data/api_profile_categories_repository.dart';
import 'package:nini/features/posts/data/local_profile_categories_repository.dart';
import 'package:nini/features/posts/domain/profile_categories_repository.dart';
import 'package:nini/features/posts/domain/models/profile_category.dart';
import 'package:nini/features/posts/presentation/cubit/profile_categories_cubit.dart';
import 'package:nini/features/posts/presentation/helpers/post_draft_mapper.dart';
import 'package:nini/features/posts/presentation/widgets/categories/post_category_selector.dart';
import 'package:nini/features/posts/presentation/widgets/categories/profile_category_row.dart';
import 'package:nini/features/posts/presentation/pages/profile_categories_screen.dart';
import 'package:nini/features/profile/presentation/widgets/categories/category_chips.dart';
import 'package:nini/features/profile/presentation/widgets/categories/profile_category_chip.dart';
import 'package:nini/shared/models/post/post_item.dart';
import 'package:nini/shared/widgets/app_toast/app_toast.dart';

const _first = '00000000-0000-4000-8000-000000000001';
const _second = '00000000-0000-4000-8000-000000000002';
const _created = '00000000-0000-4000-8000-000000000003';

Map<String, dynamic> _item(
  String id,
  String name, {
  int position = 0,
  int posts = 0,
}) => {
  'id': id,
  'name': name,
  'position': position,
  'postsCount': posts,
  'createdAt': '2026-11-19T08:00:00.000Z',
};
Map<String, dynamic> _response(Object? data) => {'success': true, 'data': data};
Map<String, dynamic> _catalog({String name = 'Backend category'}) => _response({
  'allCount': 7,
  'uncategorizedCount': 2,
  'items': [
    _item(_first, name, posts: 3),
    _item(_second, 'Another category', position: 1, posts: 2),
  ],
});

class _Tokens extends SecureTokenStore {
  String? token = 'synthetic-a';
  Completer<String?>? gate;
  @override
  Future<String?> getToken() async => gate == null ? token : gate!.future;
  @override
  Future<void> deleteToken() async => token = null;
}

class _Api extends ApiClient {
  Map<String, dynamic> reply = _catalog();
  Map<String, dynamic>? createdReply;
  Object? getFailure, postFailure;
  Completer<void>? getGate, postGate;
  final gets = <String>[];
  final posts = <({String path, String? token, Map<String, dynamic>? data})>[];
  final credentials = <String>[];
  final accountReplies = <String, Map<String, dynamic>>{};
  final publicGets = <String>[];
  final mutations =
      <
        ({String method, String path, Map<String, dynamic>? data, String token})
      >[];
  Object? mutationFailure;
  Completer<void>? mutationGate;
  Map<String, dynamic>? renameReply, deleteReply, orderReply;
  bool commitOrderBeforeFailure = false;

  List<Map<String, dynamic>> get _items =>
      List<Map<String, dynamic>>.from((reply['data'] as Map)['items'] as List);
  void _saveItems(List<Map<String, dynamic>> items) {
    reply = _response({
      ...reply['data'] as Map<String, dynamic>,
      'items': items,
    });
  }

  @override
  Future<Map<String, dynamic>> patch(
    String endpoint, {
    required Map<String, dynamic> data,
    required String token,
  }) async {
    mutations.add((method: 'PATCH', path: endpoint, data: data, token: token));
    await mutationGate?.future;
    if (mutationFailure != null) throw mutationFailure!;
    final id = endpoint.split('/').last;
    final result =
        renameReply ??
        _response({
          ..._items.firstWhere((item) => item['id'] == id),
          'name': data['name'],
        });
    final updated = result['data'];
    if (result['success'] == true &&
        updated is Map<String, dynamic> &&
        updated['id'] == id) {
      _saveItems([
        for (final item in _items)
          if (item['id'] == id) updated else item,
      ]);
    }
    return result;
  }

  @override
  Future<Map<String, dynamic>> delete(
    String endpoint, {
    required String token,
  }) async {
    mutations.add((method: 'DELETE', path: endpoint, data: null, token: token));
    await mutationGate?.future;
    if (mutationFailure != null) throw mutationFailure!;
    final id = endpoint.split('/').last;
    final result =
        deleteReply ??
        _response({
          'id': id,
          'deleted': true,
          'postsMoved': _items.firstWhere(
            (item) => item['id'] == id,
          )['postsCount'],
        });
    if (result['success'] == true &&
        result['data'] is Map &&
        result['data']['deleted'] == true) {
      final moved = result['data']['postsMoved'] as int? ?? 0;
      _saveItems(_items.where((item) => item['id'] != id).toList());
      reply = _response({
        ...reply['data'] as Map<String, dynamic>,
        'uncategorizedCount':
            (reply['data']['uncategorizedCount'] as int? ?? 0) + moved,
      });
    }
    return result;
  }

  @override
  Future<Map<String, dynamic>> put(
    String endpoint, {
    required Map<String, dynamic> data,
    required String token,
  }) async {
    mutations.add((method: 'PUT', path: endpoint, data: data, token: token));
    await mutationGate?.future;
    final ids = List<String>.from(data['ids'] as List);
    if (mutationFailure == null || commitOrderBeforeFailure) {
      final before = _items;
      _saveItems([
        for (final (index, id) in ids.indexed)
          {...before.firstWhere((item) => item['id'] == id), 'position': index},
      ]);
    }
    if (mutationFailure != null) throw mutationFailure!;
    return orderReply ?? reply;
  }

  @override
  Future<Map<String, dynamic>> getPublic(
    String endpoint, {
    String? token,
  }) async {
    publicGets.add(endpoint);
    return _response([
      {'key': 'electronics', 'label': 'Electronics'},
    ]);
  }

  @override
  Future<Map<String, dynamic>> get(
    String endpoint, {
    required String token,
  }) async {
    gets.add(endpoint);
    credentials.add(token);
    if (endpoint == 'auth/me') {
      return _response({
        'id': token == 'synthetic-a' ? 'account-a' : 'account-b',
      });
    }
    final response = accountReplies[token] ?? reply;
    await getGate?.future;
    if (getFailure != null) throw getFailure!;
    return response;
  }

  @override
  Future<Map<String, dynamic>> post(
    String endpoint, {
    Map<String, dynamic>? data,
    String? token,
  }) async {
    posts.add((path: endpoint, token: token, data: data));
    if (endpoint == 'auth/logout') return _response(null);
    await postGate?.future;
    if (postFailure != null) throw postFailure!;
    final result =
        createdReply ??
        _response(_item(_created, data!['name'] as String, position: 2));
    final created = result['data'];
    if (result['success'] == true &&
        created is Map<String, dynamic> &&
        created['name'] == data?['name']) {
      if (!_items.any((item) => item['id'] == created['id'])) {
        _saveItems([..._items, created]);
      }
    }
    return result;
  }
}

ApiProfileCategoriesRepository _repo(_Api api, [_Tokens? tokens]) =>
    ApiProfileCategoriesRepository(
      api,
      tokens ?? _Tokens(),
      isCurrentAccount: () => true,
      onUnauthorized: () async {},
    );

DioException _error({
  int? status,
  DioExceptionType type = DioExceptionType.badResponse,
  String message = 'Private server details',
}) {
  final options = RequestOptions(path: 'users/me/categories');
  return DioException(
    requestOptions: options,
    type: type,
    response: status == null
        ? null
        : Response<Object>(
            requestOptions: options,
            statusCode: status,
            data: {'success': false, 'message': message},
          ),
  );
}

class _RealHttp extends HttpOverrides {}

Widget _chips(ProfileCategoriesCubit cubit, Brightness brightness) =>
    BlocProvider.value(
      value: cubit,
      child: MaterialApp(
        theme: brightness == Brightness.dark ? AppTheme.dark : AppTheme.light,
        home: const Scaffold(body: ProfileCategoryChips()),
      ),
    );

class _AccountProbe extends StatelessWidget {
  const _AccountProbe();
  @override
  Widget build(BuildContext context) => BlocBuilder<SessionCubit, SessionState>(
    builder: (context, state) => state.status != SessionStatus.authenticated
        ? const Text('Signed out')
        : BlocBuilder<ProfileCategoriesCubit, ProfileCategoriesState>(
            builder: (context, categories) => Column(
              children: [
                const Text('Signed in'),
                for (final category in categories.categories)
                  Text(category.name),
              ],
            ),
          ),
  );
}

Widget _assignmentHost(
  ProfileCategoriesCubit personal,
  PostCategoriesCubit global,
  CreatePostCubit draft, {
  Brightness brightness = Brightness.light,
}) => MultiBlocProvider(
  providers: [
    BlocProvider.value(value: personal),
    BlocProvider.value(value: global),
    BlocProvider.value(value: draft),
  ],
  child: MaterialApp(
    theme: brightness == Brightness.dark ? AppTheme.dark : AppTheme.light,
    home: Builder(
      builder: (context) => Scaffold(
        body: TextButton(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => Scaffold(
                appBar: AppBar(),
                body: const PostCategorySelector(
                  english: true,
                  backendCategories: true,
                ),
              ),
            ),
          ),
          child: const Text('Open Create Post'),
        ),
      ),
    ),
  ),
);

void main() {
  test('personal assignment accepts only available UUIDs and preserves every other draft field', () async {
    final draft = CreatePostCubit(
      initial: const PostDraft(
        categoryKey: 'electronics',
        profileCategoryId: _first,
        title: 'Keep title',
        caption: 'Keep caption',
        price: '100',
        tags: ['keep'],
      ),
    );
    addTearDown(draft.close);
    final available = [
      ProfileCategory.fromApiJson(_item(_second, 'Real category')),
    ];
    final before = draft.state.toJson();
    for (final id in ['', 'All', 'category_old_local', _created]) {
      expect(draft.assignProfileCategory(id, available), isFalse);
      expect(draft.state.toJson(), before);
    }
    expect(draft.assignProfileCategory(_second, available), isTrue);
    expect(draft.state.toJson(), {...before, 'profileCategoryId': _second});
    await draft.close();
    expect(draft.assignProfileCategory(_second, available), isFalse);
  });

  test('legacy post category IDs survive rehydration without conversion or stored-data mutation', () {
    final post = PostItem(
      id: 'legacy-record',
      imageAsset: '',
      title: 'Real local post',
      category: 'Product',
      stockCount: 0,
      price: '100',
      originalPrice: '',
      profileCategoryId: 'category_local_real',
      details: PostDetails.fromJson({
        'category': 'electronics',
        'caption': 'Keep caption',
      }),
    );
    final before = jsonEncode(post.toJson());
    final draft = postDraftFromPost(post);
    expect(draft.profileCategoryId, 'category_local_real');
    expect(draft.categoryKey, 'electronics');
    expect(jsonEncode(post.toJson()), before);
  });

  for (final brightness in Brightness.values) {
    testWidgets(
      'one dropdown shows backend global and personal categories ($brightness)',
      (tester) async {
        final api = _Api();
        final personal = ProfileCategoriesCubit(_repo(api));
        final global = PostCategoriesCubit(ApiCategoriesRepository(api));
        final draft = CreatePostCubit(
          initial: const PostDraft(
            categoryKey: 'electronics',
            title: 'Keep title',
            caption: 'Keep caption',
          ),
        );
        addTearDown(personal.close);
        addTearDown(global.close);
        addTearDown(draft.close);
        await personal.load();
        personal.select(_second);
        expect(await personal.create('Mobile Development'), isTrue);
        await global.load();
        await tester.pumpWidget(
          _assignmentHost(personal, global, draft, brightness: brightness),
        );
        await tester.tap(find.text('Open Create Post'));
        await tester.pumpAndSettle();
        final dropdown = find.byType(DropdownButtonFormField<String>);
        final bounds = tester.getRect(dropdown);
        expect(find.text('Manage categories'), findsNothing);
        expect(find.byIcon(Icons.tune), findsNothing);
        await tester.tap(dropdown);
        await tester.pumpAndSettle();
        expect(find.text('Electronics'), findsWidgets);
        expect(find.text('Mobile Development'), findsOneWidget);
        expect(find.text(ProfilePostStrings.all), findsNothing);
        await tester.tap(find.text('Mobile Development').last);
        await tester.pumpAndSettle();
        expect(draft.state.profileCategoryId, _created);
        expect(draft.state.categoryKey, 'electronics');
        expect(personal.state.selectedId, _second);
        expect(find.text('Electronics · Mobile Development'), findsOneWidget);
        expect(tester.getRect(dropdown), bounds);
        await tester.pageBack();
        await tester.pumpAndSettle();
        await tester.tap(find.text('Open Create Post'));
        await tester.pumpAndSettle();
        expect(find.text('Electronics · Mobile Development'), findsOneWidget);
        await tester.tap(dropdown);
        await tester.pumpAndSettle();
        await tester.tap(find.text('No profile category').last);
        await tester.pumpAndSettle();
        expect(draft.state.profileCategoryId, isNull);
        expect(draft.state.categoryKey, 'electronics');
        expect(draft.state.title, 'Keep title');
        expect(draft.state.caption, 'Keep caption');
        expect(api.gets, ['users/me/categories']);
        expect(api.publicGets, ['categories']);
        expect(api.posts.length, 1);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'new backend category appears in an already-open dropdown; choosing personal first never invents a global key',
    (tester) async {
      final api = _Api();
      final personal = ProfileCategoriesCubit(_repo(api));
      final global = PostCategoriesCubit(ApiCategoriesRepository(api));
      final draft = CreatePostCubit();
      addTearDown(personal.close);
      addTearDown(global.close);
      addTearDown(draft.close);
      await personal.load();
      await global.load();
      await tester.pumpWidget(_assignmentHost(personal, global, draft));
      await tester.tap(find.text('Open Create Post'));
      await tester.pumpAndSettle();
      expect(await personal.create('Mobile Development'), isTrue);
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mobile Development').last);
      await tester.pumpAndSettle();
      expect(draft.state.profileCategoryId, _created);
      expect(draft.state.categoryKey, isNull);
      expect(find.text('Select predefined category'), findsNothing);
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Electronics').last);
      await tester.pumpAndSettle();
      expect(draft.state.categoryKey, 'electronics');
      expect(draft.state.profileCategoryId, _created);
      expect(draft.state.toJson()['category'], 'electronics');
      expect(draft.state.toJson()['profileCategoryId'], _created);
      expect(find.text('Electronics · Mobile Development'), findsOneWidget);
      expect(api.gets.length, 1);
      expect(api.posts.single.path, 'users/me/categories');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'fresh backend reload makes saved personal categories available in the combined dropdown',
    (tester) async {
      final api = _Api()
        ..reply = _response({
          'allCount': 0,
          'items': [_item(_created, 'Mobile Development')],
        });
      final first = ProfileCategoriesCubit(_repo(api));
      await first.load();
      await first.close();
      final restarted = ProfileCategoriesCubit(_repo(api));
      final global = PostCategoriesCubit(ApiCategoriesRepository(api));
      final draft = CreatePostCubit(
        initial: const PostDraft(categoryKey: 'electronics'),
      );
      addTearDown(restarted.close);
      addTearDown(global.close);
      addTearDown(draft.close);
      await restarted.load();
      await global.load();
      await tester.pumpWidget(_assignmentHost(restarted, global, draft));
      await tester.tap(find.text('Open Create Post'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mobile Development').last);
      await tester.pumpAndSettle();
      expect(draft.state.profileCategoryId, _created);
      expect(api.gets.length, 2);
      expect(api.posts, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'combined dropdown keeps global choices usable during personal loading, failure and empty responses',
    (tester) async {
      final api = _Api()..getGate = Completer<void>();
      final personal = ProfileCategoriesCubit(_repo(api));
      final global = PostCategoriesCubit(ApiCategoriesRepository(api));
      final draft = CreatePostCubit(
        initial: const PostDraft(categoryKey: 'electronics'),
      );
      addTearDown(personal.close);
      addTearDown(global.close);
      addTearDown(draft.close);
      final request = personal.load();
      await global.load();
      await tester.pumpWidget(_assignmentHost(personal, global, draft));
      await tester.tap(find.text('Open Create Post'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      api.getFailure = _error(type: DioExceptionType.connectionError);
      api.getGate!.complete();
      await tester.pumpAndSettle();
      await request;
      expect(
        find.text(ProfilePostStrings.categoryConnectionFailed),
        findsOneWidget,
      );
      expect(find.text('Web Development'), findsNothing);
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Electronics').last);
      await tester.pumpAndSettle();
      api.getFailure = null;
      api.reply = _response({'items': <Object>[]});
      await tester.tap(find.text(ProfilePostStrings.retry));
      await tester.pumpAndSettle();
      expect(personal.state.categories, isEmpty);
      expect(draft.state.profileCategoryId, isNull);
      expect(draft.state.categoryKey, 'electronics');
      expect(api.posts, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  test(
    'GET maps real IDs, names, response ordering, positions and all counts',
    () async {
      final api = _Api();
      final result = await _repo(api).load();
      expect(api.gets, ['users/me/categories']);
      expect(api.credentials, ['synthetic-a']);
      expect(result.allCount, 7);
      expect(result.uncategorizedCount, 2);
      expect(result.items.map((item) => item.id), [_first, _second]);
      expect(result.items.map((item) => item.position), [0, 1]);
      expect(result.items.map((item) => item.postsCount), [3, 2]);
      expect(result.items.first.createdAt, DateTime.utc(2026, 11, 19, 8));
      expect(() => result.items.clear(), throwsUnsupportedError);
      expect(api.posts, isEmpty);
    },
  );

  test(
    'empty and optional count fields do not fabricate categories or numbers',
    () async {
      final api = _Api()..reply = _response({'items': <Object>[]});
      final list = await _repo(api).load();
      expect(list.items, isEmpty);
      expect(list.allCount, isNull);
      expect(list.uncategorizedCount, isNull);
      api.reply = _response({
        'allCount': 0,
        'uncategorizedCount': 0,
        'items': <Object>[],
      });
      expect((await _repo(api).load()).allCount, 0);
      api.reply = _response({
        'items': [
          {'id': _first, 'name': 'Real name'},
        ],
      });
      expect((await _repo(api).load()).items.first.postsCount, isNull);
    },
  );

  for (final data in <Object?>[
    null,
    [],
    {'items': {}},
    {
      'items': [null],
    },
    {
      'items': [
        {'id': 'local-category', 'name': 'Bad identity'},
      ],
    },
    {
      'items': [
        {'id': _first, 'name': 123},
      ],
    },
    {
      'items': [
        {..._item(_first, 'Invalid'), 'postsCount': -1},
      ],
    },
    {
      'items': [
        {..._item(_first, 'Invalid'), 'position': '0'},
      ],
    },
    {
      'items': [
        {..._item(_first, 'Invalid'), 'createdAt': 'not-a-date'},
      ],
    },
    {
      'items': [_item(_first, 'Repeated'), _item(_first, 'Repeated')],
    },
    {'items': [], 'allCount': -1},
    {'items': [], 'uncategorizedCount': '2'},
  ]) {
    test(
      'invalid GET response fails without fallback: ${jsonEncode(data)}',
      () async {
        final api = _Api()..reply = _response(data);
        await expectLater(_repo(api).load(), throwsFormatException);
      },
    );
  }

  test('POST sends only a trimmed name and accepts only a confirmed backend category', () async {
    final api = _Api();
    final category = await _repo(api).create('  Mobile Development  ');
    expect(api.posts.single.path, 'users/me/categories');
    expect(api.posts.single.token, 'synthetic-a');
    expect(api.posts.single.data, {'name': 'Mobile Development'});
    expect(category.id, _created);
    expect(category.position, 2);
    expect(category.postsCount, 0);
    expect(api.gets, isEmpty);
    api.createdReply = _response(_item(_created, 'A different name'));
    await expectLater(
      _repo(api).create('Requested name'),
      throwsFormatException,
    );
    api.createdReply = {
      'success': false,
      'data': _item(_created, 'Requested name'),
    };
    await expectLater(
      _repo(api).create('Requested name'),
      throwsFormatException,
    );
  });

  for (final name in ['', ' ', 'X', 'All', 'a' * 41]) {
    test(
      'invalid creation name is rejected before POST: ${name.length} characters',
      () async {
        final api = _Api();
        await expectLater(
          _repo(api).create(name),
          throwsA(isA<ProfileCategoryException>()),
        );
        expect(api.posts, isEmpty);
      },
    );
  }

  test('missing or unsafe tokens never send invalid Bearer headers', () async {
    for (final token in <String?>[null, '', ' ', 'unsafe\ncredential']) {
      final api = _Api();
      final tokens = _Tokens()..token = token;
      var expired = 0;
      final repo = ApiProfileCategoriesRepository(
        api,
        tokens,
        isCurrentAccount: () => true,
        onUnauthorized: () async {
          expired++;
        },
      );
      await expectLater(repo.load(), throwsA(isA<ProfileCategoryException>()));
      expect(api.gets, isEmpty);
      expect(expired, 1);
    }
  });

  test('401 uses existing session callback, clears stale data and does not report success', () async {
    final api = _Api();
    var expired = 0;
    final repo = ApiProfileCategoriesRepository(
      api,
      _Tokens(),
      isCurrentAccount: () => true,
      onUnauthorized: () async {
        expired++;
      },
    );
    final cubit = ProfileCategoriesCubit(repo);
    addTearDown(cubit.close);
    await cubit.load();
    cubit.select(_first);
    api.postFailure = _error(status: 401);
    expect(await cubit.create('New category'), isFalse);
    expect(expired, 1);
    expect(cubit.state.categories, isEmpty);
    expect(cubit.state.selectedId, isNull);
    expect(cubit.state.allCount, isNull);
    expect(cubit.state.loadFailed, isTrue);
  });

  test(
    'reload is deduplicated and preserves valid selection and counts',
    () async {
      final api = _Api()..getGate = Completer<void>();
      final cubit = ProfileCategoriesCubit(_repo(api));
      addTearDown(cubit.close);
      final first = cubit.load();
      final second = cubit.load();
      expect(identical(first, second), isTrue);
      api.getGate!.complete();
      await first;
      await cubit.load();
      expect(api.gets.length, 1);
      cubit.select(_first);
      await cubit.load(refresh: true);
      expect(cubit.state.selectedId, _first);
      expect(cubit.state.allCount, 7);
      api.reply = _response({
        'allCount': 7,
        'uncategorizedCount': 7,
        'items': <Object>[],
      });
      await cubit.load(refresh: true);
      expect(cubit.state.selectedId, isNull);
      expect(cubit.state.categories, isEmpty);
      expect(cubit.state.allCount, 7);
    },
  );

  test('creation waits for backend, appends once and preserves selection and counts', () async {
    final api = _Api()..postGate = Completer<void>();
    final cubit = ProfileCategoriesCubit(_repo(api));
    addTearDown(cubit.close);
    await cubit.load();
    cubit.select(_second);
    final creating = cubit.create('Mobile Development');
    expect(cubit.state.saving, isTrue);
    expect(cubit.state.categories.length, 2);
    expect(await cubit.create('Mobile Development'), isFalse);
    // Let the first request reach the API before checking request count.
    await Future<void>.delayed(Duration.zero);
    expect(api.posts.length, 1);
    api.postGate!.complete();
    expect(await creating, isTrue);
    expect(cubit.state.categories.map((item) => item.id), [
      _first,
      _second,
      _created,
    ]);
    expect(cubit.state.selectedId, _second);
    expect(cubit.state.allCount, 7);
    expect(cubit.state.uncategorizedCount, 2);
    expect(cubit.state.categories.last.postsCount, 0);
    expect(await cubit.create('MOBILE DEVELOPMENT'), isFalse);
    expect(api.posts.length, 1);
    expect(cubit.state.error, ProfilePostStrings.duplicateName);
  });

  test('20-category limit and case-insensitive duplicates are validated without POST', () async {
    final api = _Api()
      ..reply = _response({
        'allCount': 7,
        'items': [
          for (var i = 0; i < 20; i++)
            _item(
              '00000000-0000-4000-8000-${(i + 1).toString().padLeft(12, '0')}',
              'Category $i',
              position: i,
            ),
        ],
      });
    final cubit = ProfileCategoriesCubit(_repo(api));
    addTearDown(cubit.close);
    await cubit.load();
    expect(await cubit.create('New category'), isFalse);
    expect(cubit.state.error, ProfilePostStrings.categoryLimit);
    expect(await cubit.create('CATEGORY 0'), isFalse);
    expect(cubit.state.error, ProfilePostStrings.duplicateName);
    expect(api.posts, isEmpty);
    expect(cubit.state.categories.length, 20);
  });

  for (final failure in <Object>[
    _error(status: 400),
    _error(status: 409, message: 'You already have a category with this name'),
    _error(status: 409, message: 'Maximum category limit'),
    _error(status: 500),
    _error(type: DioExceptionType.connectionError),
    _error(type: DioExceptionType.receiveTimeout),
    TimeoutException('timeout'),
    const FormatException('Unconfirmed private response'),
  ]) {
    test(
      'creation ${failure.runtimeType} failure preserves confirmed categories and allows retry',
      () async {
        final api = _Api()..postFailure = failure;
        final cubit = ProfileCategoriesCubit(_repo(api));
        addTearDown(cubit.close);
        await cubit.load();
        cubit.select(_first);
        expect(await cubit.create('New category'), isFalse);
        expect(cubit.state.error, isNotEmpty);
        expect(cubit.state.error, isNot(contains('Private')));
        expect(cubit.state.categories.length, 2);
        expect(cubit.state.selectedId, _first);
        expect(cubit.state.allCount, 7);
        expect(cubit.state.saving, isFalse);
        api.postFailure = null;
        expect(await cubit.create('New category'), isTrue);
        expect(cubit.state.categories.length, 3);
      },
    );
  }

  test(
    'GET failure has no sample fallback and retry loads real data',
    () async {
      final api = _Api()
        ..getFailure = _error(type: DioExceptionType.connectionError);
      final cubit = ProfileCategoriesCubit(_repo(api));
      addTearDown(cubit.close);
      await cubit.load();
      expect(cubit.state.categories, isEmpty);
      expect(cubit.state.allCount, isNull);
      expect(cubit.state.loadFailed, isTrue);
      expect(cubit.state.error, ProfilePostStrings.categoryConnectionFailed);
      api.getFailure = null;
      await cubit.load();
      expect(cubit.state.categories.length, 2);
      expect(cubit.state.loadFailed, isFalse);
      expect(cubit.state.error, isNull);
    },
  );

  test(
    'confirmed rename and deletion use real APIs and retain All post counts',
    () async {
      final api = _Api();
      final cubit = ProfileCategoriesCubit(_repo(api));
      addTearDown(cubit.close);
      await cubit.load();
      cubit.select(_first);
      expect(await cubit.rename(_first, 'Renamed category'), isTrue);
      expect(cubit.state.find(_first)?.name, 'Renamed category');
      expect(cubit.state.find(_first)?.postsCount, 3);
      expect(cubit.state.selectedId, _first);
      expect(await cubit.delete(_first), isTrue);
      expect(cubit.state.find(_first), isNull);
      expect(cubit.state.selectedId, isNull);
      expect(cubit.state.allCount, 7);
      expect(cubit.state.uncategorizedCount, 5);
      expect(api.mutations.map((item) => item.method), ['PATCH', 'DELETE']);
      expect(api.posts, isEmpty);
    },
  );

  test('an account change during token lookup prevents a request using the next account token', () async {
    final api = _Api();
    final tokens = _Tokens()..gate = Completer<String?>();
    var current = true;
    var expired = 0;
    final repo = ApiProfileCategoriesRepository(
      api,
      tokens,
      isCurrentAccount: () => current,
      onUnauthorized: () async {
        expired++;
      },
    );
    final result = expectLater(
      repo.create('New category'),
      throwsA(isA<ProfileCategoryException>()),
    );
    current = false;
    tokens.gate!.complete('synthetic-b');
    await result;
    expect(api.posts, isEmpty);
    expect(expired, 0);
  });

  for (final creating in [false, true]) {
    test(
      'closed account Cubit ignores pending ${creating ? 'POST' : 'GET'} results',
      () async {
        final api = _Api();
        var current = true;
        final repo = ApiProfileCategoriesRepository(
          api,
          _Tokens(),
          isCurrentAccount: () => current,
          onUnauthorized: () async {},
        );
        final cubit = ProfileCategoriesCubit(repo);
        if (creating) await cubit.load();
        final gate = Completer<void>();
        if (creating) {
          api.postGate = gate;
        } else {
          api.getGate = gate;
        }
        final Future<Object?> pending = creating
            ? cubit.create('New category')
            : cubit.load();
        await Future<void>.delayed(Duration.zero);
        current = false;
        await cubit.close();
        gate.complete();
        await pending;
        expect(
          cubit.state.categories.any((item) => item.id == _created),
          isFalse,
        );
        expect(cubit.isClosed, isTrue);
      },
    );
  }

  test('legacy local JSON and genuine IDs are retained without upload or deletion', () async {
    final dir = await Directory.systemTemp.createTemp(
      'hywork-legacy-categories-',
    );
    addTearDown(() => dir.delete(recursive: true));
    final folder = await Directory('${dir.path}/nini_profile_categories')
        .create();
    final file = File('${folder.path}/categories.json');
    const raw =
        '{"version":1,"categories":[{"id":"category_local_real","name":"My unsynchronized category"}]}';
    await file.writeAsString(raw);
    final legacy = LocalProfileCategoriesRepository(
      directoryProvider: () async => dir,
    );
    expect((await legacy.load()).items.single.id, 'category_local_real');
    final api = _Api();
    await _repo(api).load();
    expect(await file.readAsString(), raw);
    expect(api.posts, isEmpty);
  });

  for (final brightness in Brightness.values) {
    for (final width in [320.0, 720.0]) {
      testWidgets(
        'existing chips and creation dialog retain RTL layout, $brightness at $width',
        (tester) async {
          tester.view.physicalSize = Size(width, 900);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final api = _Api();
          final cubit = ProfileCategoriesCubit(_repo(api));
          await cubit.load();
          addTearDown(cubit.close);
          await tester.pumpWidget(_chips(cubit, brightness));
          await tester.pumpAndSettle();
          final all = tester
              .widgetList<ProfileCategoryChip>(find.byType(ProfileCategoryChip))
              .first;
          expect(all.label, ProfilePostStrings.all);
          expect(all.count, 7);
          expect(all.isSelected, isTrue);
          final button = find.byIcon(Icons.add);
          expect(tester.getCenter(button).dx, greaterThan(width / 2));
          await tester.tap(button);
          await tester.pumpAndSettle();
          await tester.tap(find.byIcon(Icons.add_circle_outline));
          await tester.pumpAndSettle();
          expect(
            tester
                .widget<TextFormField>(find.byType(TextFormField))
                .initialValue,
            isEmpty,
          );
          final input = tester.widget<TextField>(find.byType(TextField));
          expect(input.textAlign, TextAlign.right);
          expect(input.maxLength, 40);
          await tester.enterText(
            find.byType(TextFormField),
            'Mobile Development',
          );
          await tester.tap(find.text(ProfilePostStrings.done).last);
          await tester.pumpAndSettle();
          expect(find.byType(TextFormField), findsNothing);
          expect(cubit.state.categories.last.id, _created);
          expect(cubit.state.categories.last.name, 'Mobile Development');
          expect(api.posts.length, 1);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  testWidgets(
    'failed creation retains the existing dialog and entered name; duplicate taps send one request',
    (tester) async {
      final api = _Api()..postGate = Completer<void>();
      final cubit = ProfileCategoriesCubit(_repo(api));
      await cubit.load();
      addTearDown(cubit.close);
      await tester.pumpWidget(_chips(cubit, Brightness.light));
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.add_circle_outline));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField), 'Keep my draft');
      await tester.tap(find.text(ProfilePostStrings.done).last);
      await tester.pump();
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
      expect(api.posts.length, 1);
      api.postFailure = _error(status: 500);
      api.postGate!.complete();
      await tester.pumpAndSettle();
      expect(find.byType(TextFormField), findsOneWidget);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'Keep my draft',
      );
      expect(cubit.state.categories.length, 2);
      expect(find.text(ProfilePostStrings.saveFailed), findsOneWidget);
      api.postFailure = null;
      await tester.tap(find.text(ProfilePostStrings.done).last);
      await tester.pumpAndSettle();
      expect(find.byType(TextFormField), findsNothing);
      expect(cubit.state.categories.length, 3);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'AppProviders recreates categories at logout and isolates the next account',
    (tester) async {
      final api = _Api();
      api.accountReplies['synthetic-a'] = _catalog(
        name: 'Account A private category',
      );
      api.accountReplies['synthetic-b'] = _catalog(
        name: 'Account B private category',
      );
      final tokens = _Tokens();
      await tester.pumpWidget(
        AppProviders(
          apiClient: api,
          tokenStore: tokens,
          child: const MaterialApp(home: Scaffold(body: _AccountProbe())),
        ),
      );
      final firstContext = tester.element(find.text('Signed out'));
      final session = firstContext.read<SessionCubit>();
      await session.restore();
      await tester.pumpAndSettle();
      expect(find.text('Account A private category'), findsOneWidget);
      final old = tester
          .element(find.text('Signed in'))
          .read<ProfileCategoriesCubit>();
      api.getGate = Completer<void>();
      final pending = old.load(refresh: true);
      await tester.pump();
      await session.logout();
      await tester.pumpAndSettle();
      expect(old.isClosed, isTrue);
      expect(find.text('Account A private category'), findsNothing);
      final gate = api.getGate!;
      api.getGate = null;
      tokens.token = 'synthetic-b';
      await session.restore();
      await tester.pumpAndSettle();
      gate.complete();
      await tester.pump();
      await pending;
      await tester.pumpAndSettle();
      expect(find.text('Account B private category'), findsOneWidget);
      expect(find.text('Account A private category'), findsNothing);
      expect(
        tester.element(find.text('Signed in')).read<ProfileCategoriesCubit>(),
        isNot(same(old)),
      );
      expect(tester.takeException(), isNull);
    },
  );

  for (final brightness in Brightness.values) {
    testWidgets(
      'category manager long-press reorder saves and reloads UUID order in $brightness',
      (tester) async {
        final api = _Api()..mutationGate = Completer<void>();
        final cubit = ProfileCategoriesCubit(_repo(api));
        addTearDown(cubit.close);
        await cubit.load();
        cubit.select(_first);
        await tester.pumpWidget(_chips(cubit, brightness));
        await tester.tap(find.byIcon(Icons.add));
        await tester.pumpAndSettle();
        expect(find.byType(ProfileCategoryRow), findsNWidgets(2));
        expect(find.text(ProfilePostStrings.all), findsNothing);
        final drag = await tester.startGesture(
          tester.getCenter(find.text('Backend category')),
        );
        await tester.pump(const Duration(milliseconds: 600));
        await tester.pumpAndSettle();
        await drag.moveBy(const Offset(0, 10));
        await tester.pump();
        await drag.moveBy(const Offset(0, 160));
        await tester.pumpAndSettle();
        await drag.up();
        await tester.pumpAndSettle();
        expect(api.mutations.single.data, {
          'ids': [_second, _first],
        });
        expect(cubit.state.saving, isTrue);
        expect(cubit.state.categories.map((item) => item.id), [
          _first,
          _second,
        ]);
        expect(
          tester
              .widgetList<ReorderableDelayedDragStartListener>(
                find.byType(ReorderableDelayedDragStartListener),
              )
              .every((item) => !item.enabled),
          isTrue,
        );
        expect(
          tester
              .widgetList<ProfileCategoryRow>(find.byType(ProfileCategoryRow))
              .every((item) => !item.enabled),
          isTrue,
        );
        tester
            .widget<ReorderableListView>(find.byType(ReorderableListView))
            .onReorderItem!(0, 1);
        await tester.pump();
        expect(api.mutations, hasLength(1));
        api.mutationGate!.complete();
        await tester.pumpAndSettle();
        expect(
          tester
              .widgetList<ProfileCategoryRow>(find.byType(ProfileCategoryRow))
              .map((row) => row.category.id),
          [_second, _first],
        );
        expect(cubit.state.selectedId, _first);
        await cubit.load(refresh: true);
        await tester.pumpAndSettle();
        expect(cubit.state.categories.map((item) => item.id), [
          _second,
          _first,
        ]);
        await tester.pageBack();
        await tester.pumpAndSettle();
        await tester.tap(find.byIcon(Icons.add));
        await tester.pumpAndSettle();
        expect(
          tester
              .widgetList<ProfileCategoryRow>(find.byType(ProfileCategoryRow))
              .map((row) => row.category.id),
          [_second, _first],
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'failed manager reorder restores authoritative rows and reports the error',
    (tester) async {
      final api = _Api()..mutationFailure = _error(status: 500);
      final cubit = ProfileCategoriesCubit(_repo(api));
      addTearDown(cubit.close);
      addTearDown(AppToast.dismiss);
      await cubit.load();
      await tester.pumpWidget(_chips(cubit, Brightness.light));
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      tester
          .widget<ReorderableListView>(find.byType(ReorderableListView))
          .onReorderItem!(0, 1);
      await tester.pumpAndSettle();
      expect(api.mutations, hasLength(1));
      expect(api.gets, hasLength(2));
      expect(
        tester
            .widgetList<ProfileCategoryRow>(find.byType(ProfileCategoryRow))
            .map((row) => row.category.id),
        [_first, _second],
      );
      expect(find.text(ProfilePostStrings.saveFailed), findsOneWidget);
      expect(cubit.state.saving, isFalse);
      expect(
        tester
            .widgetList<ProfileCategoryRow>(find.byType(ProfileCategoryRow))
            .every((row) => row.enabled),
        isTrue,
      );
      await tester.pump(const Duration(seconds: 4));
      expect(tester.takeException(), isNull);
    },
  );

  test('reorder sends every UUID once, retains selection and uses confirmed response order', () async {
    final api = _Api();
    final cubit = ProfileCategoriesCubit(_repo(api));
    addTearDown(cubit.close);
    await cubit.load();
    cubit.select(_first);
    expect(await cubit.reorder([_second, _first]), isTrue);
    expect(cubit.state.categories.map((item) => item.id), [_second, _first]);
    expect(cubit.state.categories.map((item) => item.position), [0, 1]);
    expect(cubit.state.selectedId, _first);
    expect(api.mutations.single.method, 'PUT');
    expect(api.mutations.single.path, 'users/me/categories/order');
    expect(api.mutations.single.data, {
      'ids': [_second, _first],
    });
    expect(await cubit.reorder([_second, _first]), isTrue);
    expect(api.mutations.length, 1);
    for (final ids in <List<String>>[
      [_first],
      [_first, _first],
      ['All', _second],
    ]) {
      expect(await cubit.reorder(ids), isFalse);
      expect(cubit.state.error, ProfilePostStrings.categoryOrderInvalid);
    }
    expect(api.mutations.length, 1);
  });

  testWidgets(
    'authenticated startup preloads the one shared personal category source before category UI opens',
    (tester) async {
      final api = _Api();
      final tokens = _Tokens();
      await tester.pumpWidget(
        AppProviders(
          apiClient: api,
          tokenStore: tokens,
          child: const MaterialApp(home: Scaffold(body: Text('Startup probe'))),
        ),
      );
      final context = tester.element(find.text('Startup probe'));
      expect(api.gets, isEmpty);
      await context.read<SessionCubit>().restore();
      await tester.pumpAndSettle();
      expect(api.gets, ['auth/me', 'users/me/categories']);
      final shared = context.read<ProfileCategoriesCubit>();
      expect(shared.state.find(_first)?.name, 'Backend category');
      await shared.load();
      expect(api.gets.length, 2);
      expect(tester.takeException(), isNull);
    },
  );

  test('uncertain reorder reloads authoritative backend order and never claims success', () async {
    final api = _Api()
      ..mutationFailure = _error(type: DioExceptionType.receiveTimeout)
      ..commitOrderBeforeFailure = true;
    final cubit = ProfileCategoriesCubit(_repo(api));
    addTearDown(cubit.close);
    await cubit.load();
    expect(await cubit.reorder([_second, _first]), isFalse);
    expect(cubit.state.categories.map((item) => item.id), [_second, _first]);
    expect(cubit.state.error, ProfilePostStrings.categoryTimeout);
    expect(api.gets.length, 2);
    expect(cubit.state.allCount, 7);
  });

  for (final operation in ['rename', 'delete', 'reorder']) {
    test(
      '$operation rejects repeated submissions and only commits a confirmed response',
      () async {
        final api = _Api()..mutationGate = Completer<void>();
        final cubit = ProfileCategoriesCubit(_repo(api));
        addTearDown(cubit.close);
        await cubit.load();
        Future<bool> submit() => switch (operation) {
          'rename' => cubit.rename(_first, 'Updated name'),
          'delete' => cubit.delete(_first),
          _ => cubit.reorder([_second, _first]),
        };
        final request = submit();
        await Future<void>.delayed(Duration.zero);
        expect(cubit.state.saving, isTrue);
        expect(cubit.state.categories.first.name, 'Backend category');
        expect(await submit(), isFalse);
        expect(api.mutations.length, 1);
        api.mutationGate!.complete();
        expect(await request, isTrue);
        expect(cubit.state.saving, isFalse);
        if (operation == 'delete') expect(cubit.state.allCount, 7);
      },
    );

    test(
      '$operation network failure keeps confirmed state and exposes an error',
      () async {
        final api = _Api()
          ..mutationFailure = _error(type: DioExceptionType.connectionError);
        final cubit = ProfileCategoriesCubit(_repo(api));
        addTearDown(cubit.close);
        await cubit.load();
        cubit.select(_first);
        final result = switch (operation) {
          'rename' => await cubit.rename(_first, 'Updated name'),
          'delete' => await cubit.delete(_first),
          _ => await cubit.reorder([_second, _first]),
        };
        expect(result, isFalse);
        expect(cubit.state.categories.map((item) => item.id), [
          _first,
          _second,
        ]);
        expect(cubit.state.selectedId, _first);
        expect(cubit.state.allCount, 7);
        expect(cubit.state.error, ProfilePostStrings.categoryConnectionFailed);
        expect(cubit.state.saving, isFalse);
      },
    );
  }

  test('rename validates uniqueness and returned identity; deletion validates confirmation and moved count', () async {
    final api = _Api();
    final cubit = ProfileCategoriesCubit(_repo(api));
    addTearDown(cubit.close);
    await cubit.load();
    expect(await cubit.rename(_first, 'ANOTHER CATEGORY'), isFalse);
    expect(await cubit.rename(_first, 'X'), isFalse);
    expect(await cubit.delete('All'), isFalse);
    expect(await cubit.delete('category_old_local'), isFalse);
    expect(api.mutations, isEmpty);
    api.renameReply = _response(_item(_second, 'Updated name'));
    expect(await cubit.rename(_first, 'Updated name'), isFalse);
    expect(cubit.state.find(_first)?.name, 'Backend category');
    api.deleteReply = _response({
      'id': _first,
      'deleted': false,
      'postsMoved': 3,
    });
    expect(await cubit.delete(_first), isFalse);
    expect(cubit.state.find(_first), isNotNull);
    api.deleteReply = _response({
      'id': _first,
      'deleted': true,
      'postsMoved': -1,
    });
    expect(await cubit.delete(_first), isFalse);
    expect(cubit.state.allCount, 7);
  });

  test(
    'omitted delete counts remain unknown instead of being fabricated',
    () async {
      final api = _Api()
        ..deleteReply = _response({'id': _first, 'deleted': true});
      final cubit = ProfileCategoriesCubit(_repo(api));
      addTearDown(cubit.close);
      await cubit.load();
      expect(await cubit.delete(_first), isTrue);
      expect(cubit.state.uncategorizedCount, isNull);
      expect(cubit.state.allCount, 7);
    },
  );

  testWidgets(
    'selected name is visible; rename propagates and delete clears only the draft assignment',
    (tester) async {
      final api = _Api();
      final personal = ProfileCategoriesCubit(_repo(api));
      final global = PostCategoriesCubit(ApiCategoriesRepository(api));
      final draft = CreatePostCubit(
        initial: const PostDraft(
          categoryKey: 'electronics',
          title: 'Keep title',
          caption: 'Keep caption',
          price: '100',
        ),
      );
      addTearDown(personal.close);
      addTearDown(global.close);
      addTearDown(draft.close);
      await personal.load();
      await global.load();
      await tester.pumpWidget(_assignmentHost(personal, global, draft));
      await tester.tap(find.text('Open Create Post'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Backend category').last);
      await tester.pumpAndSettle();
      expect(find.text('Electronics · Backend category'), findsOneWidget);
      Navigator.of(tester.element(find.byType(DropdownButtonFormField<String>)))
          .push(
            MaterialPageRoute<void>(
              builder: (_) => const ProfileCategoriesScreen(english: true),
            ),
          );
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.edit_outlined).first);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextFormField),
        'Visible renamed category',
      );
      await tester.tap(find.text(ProfilePostStrings.done).last);
      await tester.pumpAndSettle();
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(
        find.text('Electronics · Visible renamed category'),
        findsOneWidget,
      );
      expect(draft.state.profileCategoryId, _first);
      Navigator.of(tester.element(find.byType(DropdownButtonFormField<String>)))
          .push(
            MaterialPageRoute<void>(
              builder: (_) => const ProfileCategoriesScreen(english: true),
            ),
          );
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.delete_outline).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text(ProfilePostStrings.delete).last);
      await tester.pumpAndSettle();
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('Manage categories'), findsNothing);
      expect(draft.state.profileCategoryId, isNull);
      expect(draft.state.categoryKey, 'electronics');
      expect(draft.state.title, 'Keep title');
      expect(draft.state.caption, 'Keep caption');
      expect(draft.state.price, '100');
      expect(personal.state.allCount, 7);
      expect(personal.state.uncategorizedCount, 5);
      expect(api.mutations.map((item) => item.method), ['PATCH', 'DELETE']);
      // There is no PostsCubit/media store in this harness: deletion never touches them.
      expect(tester.takeException(), isNull);
    },
  );

  final local = Uri.tryParse(AppConfig.apiBaseUrl);
  test('real Dio uses configured authenticated GET and POST with mobile header and exact name body', () async {
    final server = await HttpServer.bind(
      InternetAddress.loopbackIPv4,
      local!.port,
    );
    addTearDown(() => server.close(force: true));
    final methods = <String>[];
    final errors = <Object>[];
    server.listen((request) async {
      try {
        methods.add(request.method);
        expect(request.uri.path, startsWith('/api/users/me/categories'));
        expect(request.headers.value('X-Client'), 'mobile');
        expect(request.headers.value('Authorization'), 'Bearer synthetic-a');
        request.response.headers.contentType = ContentType.json;
        if (request.method == 'POST') {
          expect(request.headers.contentType?.mimeType, 'application/json');
          final data = jsonDecode(await utf8.decoder.bind(request).join());
          expect(data, {'name': 'Mobile Development'});
          request.response.statusCode = 201;
          request.response.write(
            jsonEncode(
              _response(_item(_created, 'Mobile Development', position: 2)),
            ),
          );
        } else if (request.method == 'PATCH') {
          expect(request.uri.path, '/api/users/me/categories/$_first');
          expect(jsonDecode(await utf8.decoder.bind(request).join()), {
            'name': 'Updated name',
          });
          request.response.write(
            jsonEncode(_response(_item(_first, 'Updated name', posts: 3))),
          );
        } else if (request.method == 'PUT') {
          expect(request.uri.path, '/api/users/me/categories/order');
          expect(jsonDecode(await utf8.decoder.bind(request).join()), {
            'ids': [_second, _first],
          });
          request.response.write(
            jsonEncode(
              _response({
                'allCount': 7,
                'uncategorizedCount': 2,
                'items': [
                  _item(_second, 'Another category'),
                  _item(_first, 'Updated name', position: 1, posts: 3),
                ],
              }),
            ),
          );
        } else if (request.method == 'DELETE') {
          expect(request.uri.path, '/api/users/me/categories/$_first');
          expect(await utf8.decoder.bind(request).join(), isEmpty);
          request.response.write(
            jsonEncode(
              _response({'id': _first, 'deleted': true, 'postsMoved': 3}),
            ),
          );
        } else {
          expect(request.method, 'GET');
          request.response.write(jsonEncode(_catalog()));
        }
      } catch (error) {
        errors.add(error);
        request.response.statusCode = 500;
      } finally {
        await request.response.close();
      }
    });
    await HttpOverrides.runWithHttpOverrides(() async {
      final repo = ApiProfileCategoriesRepository(
        ApiClient(),
        _Tokens(),
        isCurrentAccount: () => true,
        onUnauthorized: () async {},
      );
      expect((await repo.load()).allCount, 7);
      expect((await repo.create('Mobile Development')).id, _created);
      expect((await repo.rename(_first, 'Updated name')).id, _first);
      expect((await repo.reorder([_second, _first])).items.first.id, _second);
      expect(await repo.delete(_first), 3);
    }, _RealHttp());
    expect(methods, ['GET', 'POST', 'PATCH', 'PUT', 'DELETE']);
    expect(errors, isEmpty);
  }, skip: local?.host != '127.0.0.1');
}
