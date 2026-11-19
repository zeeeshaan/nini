import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_test/flutter_test.dart';
import 'package:nini/core/config/app_config/app_config.dart';
import 'package:nini/core/localization/strings/create_post_strings.dart';
import 'package:nini/core/network/api_client.dart';
import 'package:nini/core/security/secure_token_store.dart';
import 'package:nini/core/theme/app_theme.dart';
import 'package:nini/features/create_post/data/api_categories_repository.dart';
import 'package:nini/features/create_post/domain/models/post_draft.dart';
import 'package:nini/features/create_post/domain/models/gallery_attachment.dart';
import 'package:nini/features/create_post/presentation/cubit/create_post_cubit.dart';
import 'package:nini/features/create_post/presentation/cubit/post_categories_cubit.dart';
import 'package:nini/features/create_post/presentation/pages/create_post_details_screen.dart';
import 'package:nini/features/create_post/presentation/widgets/form/caption_editor.dart';
import 'package:nini/features/create_post/presentation/widgets/form/post_form_option_tile.dart';
import 'package:nini/shared/widgets/app_textfield/app_text_field.dart';
import 'package:nini/features/posts/presentation/helpers/post_draft_mapper.dart';
import 'package:nini/features/posts/domain/models/profile_category.dart';
import 'package:nini/features/posts/domain/profile_categories_repository.dart';
import 'package:nini/features/posts/data/api_posts_repository.dart';
import 'package:nini/features/posts/presentation/cubit/profile_categories_cubit.dart';
import 'package:nini/features/posts/presentation/widgets/categories/post_category_selector.dart';
import 'package:nini/shared/models/post/post_item.dart';
import 'package:nini/shared/widgets/app_toast/app_toast.dart';

const _catalog = [
  {'key': 'tools', 'label': 'Tools', 'labelFa': 'ابزار'},
  {'key': 'home_repairs', 'label': 'Home repairs'},
];

class _Api extends ApiClient {
  Map<String, dynamic> response = {'success': true, 'data': _catalog};
  final paths = <String>[];
  final tokens = <String?>[];
  Object? failure;
  Completer<void>? gate;

  @override
  Future<Map<String, dynamic>> getPublic(
    String endpoint, {
    String? token,
  }) async {
    paths.add(endpoint);
    tokens.add(token);
    await gate?.future;
    if (failure != null) throw failure!;
    return response;
  }
}

class _RealHttp extends HttpOverrides {}

class _PersonalCategories extends Fake implements ProfileCategoriesRepository {
  Completer<ProfileCategoryList>? gate;
  Object? failure;
  @override
  Future<ProfileCategoryList> load() async {
    if (failure != null) throw failure!;
    return gate == null
        ? const ProfileCategoryList(
            items: [
              ProfileCategory(
                id: '00000000-0000-4000-8000-000000000001',
                name: 'My category',
              ),
              ProfileCategory(
                id: '00000000-0000-4000-8000-000000000002',
                name: 'Other category',
              ),
            ],
          )
        : gate!.future;
  }
}

class _DraftCapture extends ApiPostsRepository {
  _DraftCapture()
    : super(
        ApiClient(),
        SecureTokenStore(),
        isCurrentAccount: _yes,
        onUnauthorized: _noop,
      );
  static bool _yes() => true;
  static Future<void> _noop() async {}
  PostDraft? draft;
  Completer<MyServerPost>? result;
  @override
  Future<MyServerPost> submit(
    PostDraft draft,
    List<GalleryAttachment> attachments,
  ) async {
    this.draft = draft;
    if (result != null) return result!.future;
    throw const PostApiException('Synthetic stop after draft validation');
  }
}

final class _SelectedFile extends PlatformFile {
  @override
  String get name => 'selected.pdf';
  @override
  Uri get uri => Uri.file('/synthetic/selected.pdf');
  @override
  Never noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

DioException _failure(DioExceptionType type, {int? status}) {
  final request = RequestOptions(path: 'categories');
  return DioException(
    requestOptions: request,
    type: type,
    response: status == null
        ? null
        : Response<Object>(
            requestOptions: request,
            statusCode: status,
            data: {'message': 'Private details must not appear in the UI'},
          ),
  );
}

Widget _host(
  PostCategoriesCubit categories,
  CreatePostCubit draft, {
  Brightness brightness = Brightness.light,
  bool navigation = false,
}) => MultiBlocProvider(
  providers: [
    BlocProvider.value(value: categories),
    BlocProvider.value(value: draft),
    BlocProvider(
      create: (_) => ProfileCategoriesCubit(_PersonalCategories())..load(),
    ),
  ],
  child: MaterialApp(
    theme: brightness == Brightness.dark ? AppTheme.dark : AppTheme.light,
    home: navigation
        ? Builder(
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
                child: const Text('Open details'),
              ),
            ),
          )
        : const Scaffold(
            body: PostCategorySelector(english: true, backendCategories: true),
          ),
  ),
);

void main() {
  test('public repository retains exact keys, labels, optional translation and server order', () async {
    final api = _Api();
    final result = await ApiCategoriesRepository(api).load();
    expect(api.paths, ['categories']);
    expect(api.tokens, [null]);
    expect(result.map((item) => item.key), ['tools', 'home_repairs']);
    expect(result.map((item) => item.label), ['Tools', 'Home repairs']);
    expect(result.first.labelFa, 'ابزار');
    expect(result.last.labelFa, isNull);
    expect(() => result.clear(), throwsUnsupportedError);
  });

  test(
    'empty response is empty, never replaced with demo categories',
    () async {
      final api = _Api()..response = {'success': true, 'data': <Object>[]};
      expect(await ApiCategoriesRepository(api).load(), isEmpty);
    },
  );

  for (final response in <Map<String, dynamic>>[
    {'success': false, 'data': _catalog},
    {
      'success': true,
      'data': {'items': _catalog},
    },
    {'data': _catalog},
    {
      'success': true,
      'data': [null],
    },
    {
      'success': true,
      'data': [
        {'key': 10, 'label': 'Invalid'},
      ],
    },
    {
      'success': true,
      'data': [
        {'key': '', 'label': 'Invalid'},
      ],
    },
    {
      'success': true,
      'data': [
        {'key': 'valid', 'label': ''},
      ],
    },
    {
      'success': true,
      'data': [
        {'key': 'valid', 'label': 'Valid', 'labelFa': 10},
      ],
    },
    {
      'success': true,
      'data': [_catalog.first, _catalog.first],
    },
  ]) {
    test('rejects malformed catalog ${jsonEncode(response)}', () async {
      final api = _Api()..response = response;
      await expectLater(
        ApiCategoriesRepository(api).load(),
        throwsFormatException,
      );
    });
  }

  test('overlapping loads share one request; returning to the flow does not reload', () async {
    final api = _Api()..gate = Completer<void>();
    final cubit = PostCategoriesCubit(ApiCategoriesRepository(api));
    addTearDown(cubit.close);
    final first = cubit.load();
    final second = cubit.load();
    expect(identical(first, second), isTrue);
    expect(cubit.state.loading, isTrue);
    expect(api.paths.length, 1);
    api.gate!.complete();
    await first;
    await cubit.load();
    expect(api.paths.length, 1);
    expect(cubit.state.find('home_repairs')?.label, 'Home repairs');
    expect(cubit.state.error, isNull);
  });

  test('closing the flow discards a pending result', () async {
    final api = _Api()..gate = Completer<void>();
    final cubit = PostCategoriesCubit(ApiCategoriesRepository(api));
    final request = cubit.load();
    await cubit.close();
    api.gate!.complete();
    await request;
    expect(cubit.state.categories, isEmpty);
    await cubit.load();
    expect(api.paths.length, 1);
  });

  for (final failure in <Object>[
    TimeoutException('timeout'),
    _failure(DioExceptionType.connectionTimeout),
    _failure(DioExceptionType.receiveTimeout),
    _failure(DioExceptionType.connectionError),
    _failure(DioExceptionType.badResponse, status: 500),
    _failure(DioExceptionType.badResponse, status: 401),
    const FormatException('Private raw response'),
  ]) {
    test(
      'failed ${failure.runtimeType} has a safe error, no fallback, and can retry',
      () async {
        final api = _Api()..failure = failure;
        final cubit = PostCategoriesCubit(ApiCategoriesRepository(api));
        addTearDown(cubit.close);
        await cubit.load();
        expect(cubit.state.error, isNotEmpty);
        expect(cubit.state.error, isNot(contains('Private')));
        expect(cubit.state.categories, isEmpty);
        expect(cubit.state.loading, isFalse);
        api.failure = null;
        await cubit.load();
        expect(api.paths.length, 2);
        expect(cubit.state.error, isNull);
        expect(cubit.state.categories.length, 2);
      },
    );
  }

  test('backend key survives unrelated form updates, post types, serialization and edit rehydration', () async {
    final draft = CreatePostCubit();
    addTearDown(draft.close);
    draft.selectProfileCategory('existing-local-tab');
    draft.selectCategory('home_repairs');
    draft.updateTitle('My service');
    draft.selectPostType(CreatePostType.services);
    draft.updateCaption('Existing form content');
    draft.selectPostType(CreatePostType.product);
    expect(draft.state.categoryKey, 'home_repairs');
    expect(draft.state.profileCategoryId, 'existing-local-tab');
    expect(draft.state.toJson()['category'], 'home_repairs');
    final post = PostItem(
      id: 'local-post',
      imageAsset: '',
      title: draft.state.title,
      category: 'Product',
      stockCount: 0,
      price: '',
      originalPrice: '',
      details: PostDetails.fromJson(draft.state.toJson()),
    );
    expect(
      postDraftFromPost(PostItem.fromJson(post.toJson())).categoryKey,
      'home_repairs',
    );
    draft.selectCategory(null);
    expect(draft.state.categoryKey, isNull);
    expect(draft.state.title, 'My service');
    expect(draft.state.caption, 'Existing form content');
  });

  for (final brightness in Brightness.values) {
    for (final width in [320.0, 720.0]) {
      testWidgets(
        'backend selection uses existing RTL dropdown, $brightness at $width',
        (tester) async {
          tester.view.physicalSize = Size(width, 850);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final api = _Api();
          final categories = PostCategoriesCubit(ApiCategoriesRepository(api));
          final draft = CreatePostCubit();
          addTearDown(categories.close);
          addTearDown(draft.close);
          await categories.load();
          await tester.pumpWidget(
            _host(categories, draft, brightness: brightness),
          );
          await tester.pumpAndSettle();
          final dropdown = find.byType(DropdownButtonFormField<String>);
          expect(
            Directionality.of(tester.element(dropdown)),
            TextDirection.rtl,
          );
          final before = tester.getRect(dropdown);
          expect(find.text('Manage categories'), findsNothing);
          expect(find.text('Web Development'), findsNothing);
          await tester.tap(dropdown);
          await tester.pumpAndSettle();
          expect(find.text('Tools'), findsOneWidget);
          await tester.tap(find.text('Home repairs').last);
          await tester.pumpAndSettle();
          expect(draft.state.categoryKey, 'home_repairs');
          expect(draft.state.profileCategoryId, isNull);
          expect(tester.getRect(dropdown), before);
          draft.selectPostType(CreatePostType.services);
          await tester.pumpAndSettle();
          expect(draft.state.categoryKey, 'home_repairs');
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  testWidgets(
    'personal category selection retains the previously selected global category',
    (tester) async {
      final categories = PostCategoriesCubit(ApiCategoriesRepository(_Api()));
      final draft = CreatePostCubit();
      addTearDown(categories.close);
      addTearDown(draft.close);
      await categories.load();
      await tester.pumpWidget(_host(categories, draft));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('My category').last);
      await tester.pumpAndSettle();
      expect(draft.state.categoryKey, isNull);
      expect(
        draft.state.profileCategoryId,
        '00000000-0000-4000-8000-000000000001',
      );
      expect(
        find.text(CreatePostStrings.choosePredefinedCategory),
        findsNothing,
      );
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tools').last);
      await tester.pumpAndSettle();
      expect(draft.state.categoryKey, 'tools');
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Home repairs').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Other category').last);
      await tester.pumpAndSettle();
      expect(draft.state.categoryKey, 'home_repairs');
      expect(
        draft.state.profileCategoryId,
        '00000000-0000-4000-8000-000000000002',
      );
      expect(find.text('Home repairs · Other category'), findsOneWidget);
      expect(
        find.text(CreatePostStrings.choosePredefinedCategory),
        findsNothing,
      );
    },
  );

  testWidgets('personal-first selection works in a narrow dark layout', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final categories = PostCategoriesCubit(ApiCategoriesRepository(_Api()));
    final draft = CreatePostCubit();
    addTearDown(categories.close);
    addTearDown(draft.close);
    await categories.load();
    await tester.pumpWidget(
      _host(categories, draft, brightness: Brightness.dark),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('My category').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tools').last);
    await tester.pumpAndSettle();
    expect(find.text('Tools · My category'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'personal choice remains visible for a later optional global choice',
    (tester) async {
      final categories = PostCategoriesCubit(ApiCategoriesRepository(_Api()));
      final draft = CreatePostCubit();
      addTearDown(categories.close);
      addTearDown(draft.close);
      await categories.load();
      await tester.pumpWidget(_host(categories, draft));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('My category').last);
      await tester.pumpAndSettle();
      expect(
        find.text(CreatePostStrings.choosePredefinedCategory),
        findsNothing,
      );
      expect(draft.state.categoryKey, isNull);
      expect(
        draft.state.profileCategoryId,
        '00000000-0000-4000-8000-000000000001',
      );
      expect(find.text('My category'), findsOneWidget);
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tools').last);
      await tester.pumpAndSettle();
      expect(draft.state.categoryKey, 'tools');
      expect(
        draft.state.profileCategoryId,
        '00000000-0000-4000-8000-000000000001',
      );
      expect(find.text('Tools · My category'), findsOneWidget);
    },
  );

  testWidgets(
    'missing required fields are marked and clear as the user fills them',
    (tester) async {
      final global = PostCategoriesCubit(ApiCategoriesRepository(_Api()));
      await global.load();
      final personal = ProfileCategoriesCubit(_PersonalCategories());
      await personal.load();
      final draft = CreatePostCubit();
      addTearDown(global.close);
      addTearDown(personal.close);
      addTearDown(draft.close);
      addTearDown(AppToast.dismiss);
      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider.value(value: global),
            BlocProvider.value(value: personal),
            BlocProvider.value(value: draft),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            localizationsDelegates: const [
              ...GlobalMaterialLocalizations.delegates,
              quill.FlutterQuillLocalizations.delegate,
            ],
            home: CreatePostDetailsScreen(
              attachments: [GalleryAttachment.fromFile(_SelectedFile())],
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text(CreatePostStrings.publish));
      await tester.pump(const Duration(milliseconds: 400));
      expect(
        tester
            .widget<PostCategorySelector>(find.byType(PostCategorySelector))
            .hasError,
        isFalse,
      );
      expect(
        tester.widget<CaptionEditor>(find.byType(CaptionEditor)).hasError,
        isTrue,
      );
      expect(
        tester
            .widget<PostFormOptionTile>(find.byType(PostFormOptionTile).first)
            .hasError,
        isTrue,
      );
      final fields = tester
          .widgetList<AppTextField>(find.byType(AppTextField))
          .toList();
      expect(
        fields
            .firstWhere(
              (field) => field.label == CreatePostStrings.productServiceTitle,
            )
            .hasError,
        isTrue,
      );
      expect(
        fields
            .firstWhere((field) => field.label == CreatePostStrings.price)
            .hasError,
        isTrue,
      );
      final titleField = tester
          .widgetList<InputDecorator>(find.byType(InputDecorator))
          .firstWhere(
            (field) =>
                field.decoration.labelText ==
                CreatePostStrings.productServiceTitle,
          );
      expect(
        (titleField.decoration.enabledBorder! as OutlineInputBorder)
            .borderSide
            .color,
        AppTheme.light.colorScheme.error,
      );
      final dropdown = tester.widget<DropdownButtonFormField<String>>(
        find.byType(DropdownButtonFormField<String>),
      );
      expect(dropdown.decoration.enabledBorder, isNull);
      draft.selectCategory('tools');
      draft.selectPostType(CreatePostType.product);
      draft.updateTitle('A valid title');
      draft.updateCaption('A valid description');
      draft.updatePrice('100');
      await tester.pump();
      expect(
        tester
            .widget<PostCategorySelector>(find.byType(PostCategorySelector))
            .hasError,
        isFalse,
      );
      expect(
        tester.widget<CaptionEditor>(find.byType(CaptionEditor)).hasError,
        isFalse,
      );
      expect(
        tester
            .widgetList<AppTextField>(find.byType(AppTextField))
            .firstWhere((field) => field.label == CreatePostStrings.price)
            .hasError,
        isFalse,
      );
      expect(tester.takeException(), isNull);
      AppToast.dismiss();
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'failure and empty catalog reuse retry UI; valid draft survives retry and invalid selection is cleared',
    (tester) async {
      final api = _Api()..failure = _failure(DioExceptionType.connectionError);
      final categories = PostCategoriesCubit(ApiCategoriesRepository(api));
      final draft = CreatePostCubit(
        initial: const PostDraft(categoryKey: 'tools', title: 'Keep title'),
      );
      addTearDown(categories.close);
      addTearDown(draft.close);
      await tester.pumpWidget(_host(categories, draft));
      await categories.load();
      await tester.pumpAndSettle();
      expect(
        find.text(CreatePostStrings.categoriesConnectionFailed),
        findsOneWidget,
      );
      expect(find.text('Tools'), findsNothing);
      expect(draft.state.categoryKey, 'tools');
      api.failure = null;
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      expect(draft.state.categoryKey, 'tools');
      api.response = {'success': true, 'data': <Object>[]};
      await categories.load(refresh: true);
      await tester.pumpAndSettle();
      expect(find.text(CreatePostStrings.categoriesEmpty), findsOneWidget);
      expect(draft.state.categoryKey, isNull);
      expect(draft.state.title, 'Keep title');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'back and forward retain the selected backend key without another request',
    (tester) async {
      final api = _Api();
      final categories = PostCategoriesCubit(ApiCategoriesRepository(api));
      final draft = CreatePostCubit();
      addTearDown(categories.close);
      addTearDown(draft.close);
      await categories.load();
      await tester.pumpWidget(_host(categories, draft, navigation: true));
      await tester.tap(find.text('Open details'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tools').last);
      await tester.pumpAndSettle();
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Open details'));
      await tester.pumpAndSettle();
      expect(draft.state.categoryKey, 'tools');
      expect(find.text('Tools'), findsOneWidget);
      expect(api.paths.length, 1);
      expect(tester.takeException(), isNull);
    },
  );

  for (final state in ['missing', 'empty', 'failure', 'loading']) {
    testWidgets(
      'Create Post permits no global category when catalog is $state',
      (tester) async {
        final api = _Api();
        if (state == 'empty') {
          api.response = {'success': true, 'data': <Object>[]};
        }
        if (state == 'failure') {
          api.failure = _failure(DioExceptionType.connectionError);
        }
        if (state == 'loading') api.gate = Completer<void>();
        final categories = PostCategoriesCubit(ApiCategoriesRepository(api));
        final request = categories.load();
        if (state != 'loading') await request;
        final draft = CreatePostCubit(
          initial: PostDraft(
            postType: CreatePostType.product,
            title: 'Keep my title',
            caption: 'Keep my description',
            price: '100',
            profileCategoryId: state == 'missing'
                ? '00000000-0000-4000-8000-000000000001'
                : null,
          ),
        );
        final capture = _DraftCapture();
        addTearDown(() async {
          AppToast.dismiss();
          await categories.close();
          await draft.close();
          if (api.gate != null && !api.gate!.isCompleted) {
            api.gate!.complete();
          }
        });
        await tester.pumpWidget(
          MultiBlocProvider(
            providers: [
              BlocProvider.value(value: categories),
              BlocProvider.value(value: draft),
              BlocProvider(
                create: (_) =>
                    ProfileCategoriesCubit(_PersonalCategories())..load(),
              ),
            ],
            child: RepositoryProvider<ApiPostsRepository>.value(
              value: capture,
              child: MaterialApp(
                theme: AppTheme.light,
                localizationsDelegates: const [
                  ...GlobalMaterialLocalizations.delegates,
                  quill.FlutterQuillLocalizations.delegate,
                ],
                home: CreatePostDetailsScreen(
                  attachments: [GalleryAttachment.fromFile(_SelectedFile())],
                ),
              ),
            ),
          ),
        );
        // A loading indicator intentionally animates until the request finishes.
        await tester.pump(const Duration(milliseconds: 300));
        await tester.tap(find.text(CreatePostStrings.publish));
        await tester.pump(const Duration(milliseconds: 300));
        expect(capture.draft, isNotNull);
        expect(capture.draft!.categoryKey, isNull);
        expect(draft.state.title, 'Keep my title');
        expect(draft.state.caption, 'Keep my description');
        if (state == 'missing') {
          expect(draft.state.categoryKey, isNull);
          expect(
            draft.state.profileCategoryId,
            '00000000-0000-4000-8000-000000000001',
          );
          expect(
            tester
                .widget<PostCategorySelector>(find.byType(PostCategorySelector))
                .hasError,
            isFalse,
          );
        }
        expect(tester.takeException(), isNull);
        if (api.gate != null) {
          api.gate!.complete();
          await tester.pump();
          await request;
        }
        AppToast.dismiss();
        await tester.pumpWidget(const SizedBox());
      },
    );
  }

  for (final scenario in [
    'valid',
    'unassigned',
    'stale',
    'legacy',
    'loading',
    'failure',
  ]) {
    testWidgets(
      'personal assignment $scenario is validated before existing publishing',
      (tester) async {
        const valid = '00000000-0000-4000-8000-000000000001';
        const stale = '00000000-0000-4000-8000-000000000099';
        final api = _Api();
        final global = PostCategoriesCubit(ApiCategoriesRepository(api));
        await global.load();
        final repository = _PersonalCategories();
        if (scenario == 'loading') {
          repository.gate = Completer<ProfileCategoryList>();
        }
        if (scenario == 'failure' || scenario == 'unassigned') {
          repository.failure = StateError('Synthetic network failure');
        }
        final personal = ProfileCategoriesCubit(repository);
        final loading = personal.load();
        if (scenario != 'loading') await loading;
        final draft = CreatePostCubit(
          initial: PostDraft(
            postType: CreatePostType.product,
            categoryKey: 'tools',
            profileCategoryId: scenario == 'unassigned'
                ? null
                : scenario == 'legacy'
                ? 'category_old_local'
                : scenario == 'stale'
                ? stale
                : valid,
            title: 'Keep title',
            caption: 'Keep caption',
            price: '100',
            captionDelta: const [
              {'insert': 'Keep caption'},
              {
                'insert': '\n',
                'attributes': {'align': 'right'},
              },
            ],
          ),
        );
        final saved = draft.state.toJson();
        final capture = _DraftCapture();
        addTearDown(global.close);
        addTearDown(personal.close);
        addTearDown(draft.close);
        addTearDown(AppToast.dismiss);
        await tester.pumpWidget(
          MultiBlocProvider(
            providers: [
              BlocProvider.value(value: global),
              BlocProvider.value(value: personal),
              BlocProvider.value(value: draft),
            ],
            child: RepositoryProvider<ApiPostsRepository>.value(
              value: capture,
              child: MaterialApp(
                theme: AppTheme.light,
                localizationsDelegates: const [
                  ...GlobalMaterialLocalizations.delegates,
                  quill.FlutterQuillLocalizations.delegate,
                ],
                home: CreatePostDetailsScreen(
                  attachments: [GalleryAttachment.fromFile(_SelectedFile())],
                ),
              ),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 300));
        await tester.tap(find.text(CreatePostStrings.publish));
        await tester.pump(const Duration(milliseconds: 300));
        if (scenario == 'valid' || scenario == 'unassigned') {
          expect(capture.draft, isNotNull);
          expect(
            capture.draft?.profileCategoryId,
            scenario == 'unassigned' ? null : valid,
          );
          expect(capture.draft?.categoryKey, 'tools');
        } else {
          expect(capture.draft, isNull);
          expect(
            find.text(
              scenario == 'loading'
                  ? CreatePostStrings.profileCategoriesLoading
                  : scenario == 'failure'
                  ? personal.state.error!
                  : CreatePostStrings.profileCategoryUnavailable,
            ),
            findsWidgets,
          );
        }
        expect(draft.state.toJson(), saved);
        expect(tester.takeException(), isNull);
        if (repository.gate != null) {
          repository.gate!.complete(const ProfileCategoryList());
          await tester.pump();
          await loading;
        }
        AppToast.dismiss();
        await tester.pumpWidget(const SizedBox());
      },
    );
  }

  testWidgets(
    'publishing with a personal category does not require a global category',
    (tester) async {
      const personalId = '00000000-0000-4000-8000-000000000001';
      final global = PostCategoriesCubit(ApiCategoriesRepository(_Api()));
      await global.load();
      final personal = ProfileCategoriesCubit(_PersonalCategories());
      await personal.load();
      final draft = CreatePostCubit(
        initial: const PostDraft(
          postType: CreatePostType.product,
          profileCategoryId: personalId,
          title: 'Valid title',
          caption: 'Valid description',
          price: '100',
        ),
      );
      final capture = _DraftCapture()..result = Completer<MyServerPost>();
      addTearDown(global.close);
      addTearDown(personal.close);
      addTearDown(draft.close);
      addTearDown(AppToast.dismiss);
      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider.value(value: global),
            BlocProvider.value(value: personal),
            BlocProvider.value(value: draft),
          ],
          child: RepositoryProvider<ApiPostsRepository>.value(
            value: capture,
            child: MaterialApp(
              theme: AppTheme.light,
              localizationsDelegates: const [
                ...GlobalMaterialLocalizations.delegates,
                quill.FlutterQuillLocalizations.delegate,
              ],
              home: CreatePostDetailsScreen(
                attachments: [GalleryAttachment.fromFile(_SelectedFile())],
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text(CreatePostStrings.publish));
      await tester.pump(const Duration(milliseconds: 300));
      expect(
        find.text(CreatePostStrings.choosePredefinedCategory),
        findsNothing,
      );
      expect(draft.state.profileCategoryId, personalId);
      expect(capture.draft, isNotNull);
      expect(capture.draft?.categoryKey, isNull);
      expect(capture.draft?.profileCategoryId, personalId);
      expect(find.text('Post Submitted for Review'), findsNothing);
      capture.result!.complete(
        const MyServerPost(
          id: '00000000-0000-4000-8000-000000000003',
          title: 'Valid title',
          status: 'pending_review',
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Post Submitted for Review'), findsOneWidget);
      expect(find.text('My category'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'review confirmation appears only after backend confirmation and closes the route',
    (tester) async {
      final api = _Api();
      final global = PostCategoriesCubit(ApiCategoriesRepository(api));
      await global.load();
      final personal = ProfileCategoriesCubit(_PersonalCategories());
      await personal.load();
      final draft = CreatePostCubit(
        initial: const PostDraft(
          postType: CreatePostType.product,
          categoryKey: 'tools',
          title: 'Keep title',
          caption: 'Keep description',
          price: '100',
          captionDelta: [
            {
              'insert': 'Keep description',
              'attributes': {'bold': true},
            },
            {
              'insert': '\n',
              'attributes': {'align': 'right'},
            },
          ],
        ),
      );
      final capture = _DraftCapture()..result = Completer<MyServerPost>();
      addTearDown(global.close);
      addTearDown(personal.close);
      addTearDown(draft.close);
      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider.value(value: global),
            BlocProvider.value(value: personal),
            BlocProvider.value(value: draft),
          ],
          child: RepositoryProvider<ApiPostsRepository>.value(
            value: capture,
            child: MaterialApp(
              theme: AppTheme.light,
              localizationsDelegates: const [
                ...GlobalMaterialLocalizations.delegates,
                quill.FlutterQuillLocalizations.delegate,
              ],
              home: Builder(
                builder: (context) => Scaffold(
                  body: TextButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<bool>(
                        builder: (_) => CreatePostDetailsScreen(
                          attachments: [
                            GalleryAttachment.fromFile(_SelectedFile()),
                          ],
                        ),
                      ),
                    ),
                    child: const Text('Open form'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open form'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(CreatePostStrings.publish));
      await tester.pump();
      expect(find.text('Post Submitted for Review'), findsNothing);
      expect(
        find.text(
          'The server saves the caption as plain text; formatting will not be saved.',
        ),
        findsOneWidget,
      );
      capture.result!.complete(
        const MyServerPost(
          id: '00000000-0000-4000-8000-000000000001',
          title: 'Keep title',
          status: 'pending_review',
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Post Submitted for Review'), findsOneWidget);
      expect(
        find.textContaining(
          'The caption was saved as plain text; formatting was not saved.',
        ),
        findsOneWidget,
      );
      await tester.tap(find.text('Got it'));
      await tester.pumpAndSettle();
      expect(find.text('Open form'), findsOneWidget);
      expect(find.text('Post Submitted for Review'), findsNothing);
      expect(tester.takeException(), isNull);
      AppToast.dismiss();
    },
  );

  final local = Uri.tryParse(AppConfig.apiBaseUrl);
  test('real Dio uses configured GET /api/categories with mobile header and no authorization', () async {
    final server = await HttpServer.bind(
      InternetAddress.loopbackIPv4,
      local!.port,
    );
    addTearDown(() => server.close(force: true));
    final errors = <Object>[];
    var requests = 0;
    server.listen((request) async {
      try {
        requests++;
        expect(request.method, 'GET');
        expect(request.uri.toString(), '/api/categories');
        expect(request.headers.value('X-Client'), 'mobile');
        expect(request.headers.value('Authorization'), isNull);
        request.response.headers.contentType = ContentType.json;
        request.response.write(jsonEncode({'success': true, 'data': _catalog}));
      } catch (error) {
        errors.add(error);
        request.response.statusCode = 500;
      } finally {
        await request.response.close();
      }
    });
    await HttpOverrides.runWithHttpOverrides(() async {
      final result = await ApiCategoriesRepository(ApiClient()).load();
      expect(result.first.key, 'tools');
    }, _RealHttp());
    expect(requests, 1);
    expect(errors, isEmpty);
  }, skip: local?.host != '127.0.0.1');
}
