import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart'
    show CompressFormat, FlutterImageCompressPlatform;
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nini/app/app_providers.dart';
import 'package:nini/features/dashboard/presentation/pages/dashboard_screen.dart';
import 'package:nini/features/dashboard/presentation/cubit/dashboard_navigation_cubit.dart';
import 'package:nini/features/dashboard/presentation/widgets/bottom_navbar/dashboard_bottom_nav.dart';
import 'package:nini/features/dashboard/presentation/widgets/bottom_navbar/dashboard_nav_item.dart';

import 'package:nini/features/profile/presentation/pages/profile_screen.dart';
import 'package:nini/features/profile/presentation/pages/seller_profile_screen.dart';
import 'package:nini/features/home/presentation/helpers/home_post_navigation.dart';
import 'package:nini/features/home/presentation/widgets/common/home_seller_header.dart';
import 'package:nini/features/home/presentation/widgets/published/home_published_post_card.dart';
import 'package:nini/features/home/presentation/widgets/published/home_post_media_slider.dart';
import 'package:nini/features/post_detail/presentation/pages/post_detail_screen.dart';
import 'package:nini/features/post_detail/presentation/widgets/common/post_author_header.dart';
import 'package:nini/features/posts/presentation/widgets/common/seller_avatar.dart';
import 'package:nini/shared/models/post/post_seller.dart';
import 'package:nini/features/profile/presentation/widgets/account/profile_avatar.dart';
import 'package:nini/features/posts/domain/posts_repository.dart';
import 'package:nini/features/posts/domain/profile_categories_repository.dart';
import 'package:nini/features/posts/presentation/cubit/posts_cubit.dart';
import 'package:nini/features/posts/presentation/cubit/profile_categories_cubit.dart';
import 'package:nini/features/cart/domain/repositories/cart_repository.dart';
import 'package:nini/features/cart/presentation/cubit/cart_cubit.dart';
import 'package:nini/features/notifications/presentation/cubit/notifications_cubit.dart';
import 'package:nini/shared/models/post/post_item.dart';

import 'package:nini/core/config/app_config/app_config.dart';
import 'package:nini/core/localization/strings/profile_edit_strings.dart';
import 'package:nini/core/localization/app_string/app_string.dart';
import 'package:nini/features/profile_settings/presentation/widgets/form/profile_birth_field.dart';
import 'package:nini/core/network/api_client.dart';
import 'package:nini/core/media/media_compressor.dart';
import 'package:nini/core/security/secure_token_store.dart';
import 'package:nini/shared/widgets/app_images/profile_image_provider.dart';
import 'package:nini/features/login/presentation/cubit/session_cubit.dart';
import 'package:nini/features/profile_settings/data/api_user_profile_repository.dart';
import 'package:nini/features/profile_settings/domain/user_profile.dart';
import 'package:nini/features/profile_settings/presentation/cubit/profile_photo_cubit.dart';
import 'package:nini/features/profile_settings/presentation/cubit/user_profile_cubit.dart';
import 'package:nini/features/profile_settings/presentation/pages/profile_edit_screen.dart';
import 'package:nini/features/profile_settings/presentation/widgets/form/profile_edit_field.dart';

const _account = 'test-account-a';
Uint8List _photoBytes() => Uint8List.fromList([
  0x89,
  0x50,
  0x4e,
  0x47,
  0x0d,
  0x0a,
  0x1a,
  0x0a,
  1,
  2,
  3,
  4,
]);
Map<String, dynamic> _user({
  String id = _account,
  String? name = 'Test User',
}) => {
  'id': id,
  'name': name,
  'username': null,
  'email': 'test@example.com',
  'bio': null,
  'city': 'Test city',
  'gender': null,
  'birthDate': null,
  'avatarUrl': null,
};
Map<String, dynamic> _response(Map<String, dynamic> user) => {
  'success': true,
  'data': user,
};
UserProfile _edit(UserProfile profile, Map<String, dynamic> changes) =>
    UserProfile.fromJson({...profile.toJson(), ...changes});

class _Tokens extends SecureTokenStore {
  String? value = 'synthetic-test-credential';
  @override
  Future<String?> getToken() async => value;
  @override
  Future<void> deleteToken() async => value = null;
}

class _Api extends ApiClient {
  Map<String, dynamic> user = _user();
  Map<String, dynamic>? sent, reply;
  Map<String, dynamic> uploadReply = _response({
    'url': 'https://example.com/uploaded-avatar.png',
    'purpose': 'avatar',
  });
  FormData? uploadData;
  String? uploadEndpoint;
  final Set<String> patchOmissions = {}, getOmissions = {};
  final credentials = <String>[];
  String? endpoint, credential;
  int loads = 0, saves = 0, logouts = 0, uploads = 0;
  Object? saveError, loadError, uploadError;
  Completer<void>? loadGate, saveGate, uploadGate;

  @override
  Future<Map<String, dynamic>> get(
    String endpoint, {
    required String token,
  }) async {
    loads++;
    credentials.add(token);
    await loadGate?.future;
    if (loadError != null) throw loadError!;
    return _response(
      Map<String, dynamic>.of(user)
        ..removeWhere((key, _) => getOmissions.contains(key)),
    );
  }

  @override
  Future<Map<String, dynamic>> patch(
    String endpoint, {
    required Map<String, dynamic> data,
    required String token,
  }) async {
    saves++;
    credentials.add(token);
    this.endpoint = endpoint;
    credential = token;
    sent = data;
    await saveGate?.future;
    if (saveError != null) throw saveError!;
    if (reply != null) return reply!;
    user = {...user, ...data};
    return _response(
      Map<String, dynamic>.of(user)
        ..removeWhere((key, _) => patchOmissions.contains(key)),
    );
  }

  @override
  Future<Map<String, dynamic>> postMultipart(
    String endpoint, {
    required FormData data,
    required String token,
  }) async {
    uploads++;
    credentials.add(token);
    uploadEndpoint = endpoint;
    uploadData = data;
    credential = token;
    await uploadGate?.future;
    if (uploadError != null) throw uploadError!;
    return uploadReply;
  }

  @override
  Future<Map<String, dynamic>> post(
    String endpoint, {
    Map<String, dynamic>? data,
    String? token,
  }) async {
    logouts++;
    return {'success': true, 'data': null};
  }
}

ApiUserProfileRepository _repository(
  _Api api, {
  _Tokens? tokens,
  String userId = _account,
  Future<void> Function()? onUnauthorized,
}) => ApiUserProfileRepository(
  api,
  tokens ?? _Tokens(),
  userId: userId,
  onUnauthorized: onUnauthorized ?? () async {},
);
DioException _error({
  int? status,
  Object? body,
  DioExceptionType type = DioExceptionType.badResponse,
}) {
  final request = RequestOptions(path: 'users/me');
  return DioException(
    requestOptions: request,
    type: type,
    response: status == null
        ? null
        : Response<dynamic>(
            requestOptions: request,
            statusCode: status,
            data: body,
          ),
  );
}

Finder _field(String label) => find.descendant(
  of: find.byWidgetPredicate(
    (widget) => widget is ProfileEditField && widget.label == label,
  ),
  matching: find.byType(TextFormField),
);

Finder _birthField() => find.descendant(
  of: find.byType(ProfileBirthField),
  matching: find.byType(TextFormField),
);
Future<void> _chooseBirth(WidgetTester tester, DateTime date) async {
  await tester.ensureVisible(_birthField());
  await tester.tap(_birthField());
  await tester.pumpAndSettle();
  await tester.tap(find.text('Gregorian'));
  await tester.pumpAndSettle();
  tester
      .widget<CalendarDatePicker>(find.byType(CalendarDatePicker))
      .onDateChanged(date);
  await tester.pump();
  final labels = MaterialLocalizations.of(
    tester.element(find.byType(AlertDialog)),
  );
  await tester.tap(find.text(labels.okButtonLabel));
  await tester.pumpAndSettle();
}

Future<void> _clearBirth(WidgetTester tester) async {
  await tester.ensureVisible(_birthField());
  await tester.longPress(_birthField());
  await tester.pumpAndSettle();
  await tester.tap(find.text(ProfileEditStrings.clearBirthDate));
  await tester.pumpAndSettle();
}

class _RealHttp extends HttpOverrides {}

class _Compression extends Fake implements FlutterImageCompressPlatform {
  _Compression(this.output, {this.fail = false});
  final Uint8List output;
  final bool fail;
  final requests = <Map<String, Object>>[];

  @override
  Future<Uint8List> compressWithList(
    Uint8List image, {
    int minWidth = 1920,
    int minHeight = 1080,
    int quality = 95,
    int rotate = 0,
    int inSampleSize = 1,
    bool autoCorrectionAngle = true,
    CompressFormat format = CompressFormat.jpeg,
    bool keepExif = false,
  }) async {
    requests.add({
      'image': image,
      'minWidth': minWidth,
      'minHeight': minHeight,
      'quality': quality,
      'format': format,
      'keepExif': keepExif,
    });
    if (fail) throw PlatformException(code: 'compression_failed');
    return output;
  }
}

class _Posts extends Fake implements PostsRepository {
  _Posts([this.posts = const []]);
  final List<PostItem> posts;
  @override
  Future<List<PostItem>> load() async => posts;
}

class _Categories extends Fake implements ProfileCategoriesRepository {}

class _Cart extends Fake implements CartRepository {}

void main() {
  for (final fromDetails in [false, true]) {
    testWidgets(
      'own Home avatar selects the existing bottom-bar Profile tab${fromDetails ? ' after closing post details' : ''}',
      (tester) async {
        final profile = UserProfileCubit(_repository(_Api()));
        await profile.load();
        final post = PostItem(
          id: 'dashboard-post',
          imageAsset: 'assets/img1.png',
          title: 'Dashboard post',
          category: 'Products',
          stockCount: 2,
          price: '100',
          originalPrice: '',
          publishedAt: DateTime(2026, 11, 17),
        );
        final posts = PostsCubit(_Posts([post]));
        await posts.load();
        final categories = ProfileCategoriesCubit(_Categories());
        final cart = CartCubit(_Cart());
        final notifications = NotificationsCubit(cart);
        addTearDown(profile.close);
        addTearDown(posts.close);
        addTearDown(categories.close);
        addTearDown(cart.close);
        addTearDown(notifications.close);
        await tester.pumpWidget(
          MultiBlocProvider(
            providers: [
              BlocProvider.value(value: profile),
              BlocProvider.value(value: posts),
              BlocProvider.value(value: categories),
              BlocProvider.value(value: cart),
              BlocProvider.value(value: notifications),
            ],
            child: const MaterialApp(
              home: DashboardScreen(initialTab: DashboardTab.home),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final dashboard = tester.state(find.byType(DashboardScreen));
        expect(
          tester
              .widget<DashboardBottomNav>(find.byType(DashboardBottomNav))
              .selectedTab,
          DashboardTab.home,
        );
        if (fromDetails) {
          await tester.tap(find.byType(HomePostMediaSlider));
          await tester.pumpAndSettle();
          expect(find.byType(PostDetailScreen), findsOneWidget);
        }
        final avatar = find.descendant(
          of: find.byType(fromDetails ? PostAuthorHeader : HomeSellerHeader),
          matching: find.byType(SellerAvatar),
        );
        await tester.ensureVisible(avatar);
        await tester.pumpAndSettle();
        await tester.tap(avatar);
        await tester.pumpAndSettle();
        expect(find.byType(PostDetailScreen), findsNothing);
        expect(find.byType(SellerProfileScreen), findsNothing);
        expect(find.byType(ProfileScreen), findsOneWidget);
        expect(tester.state(find.byType(DashboardScreen)), same(dashboard));
        expect(
          tester
              .widget<DashboardBottomNav>(find.byType(DashboardBottomNav))
              .selectedTab,
          DashboardTab.profile,
        );
        final pager = tester.widget<PageView>(
          find.byKey(const PageStorageKey<String>('dashboard_tabs')),
        );
        expect(pager.controller!.page, DashboardTab.profile.index);
        expect(
          Navigator.of(tester.element(find.byType(ProfileScreen))).canPop(),
          isFalse,
        );
        await tester.tap(
          find.byWidgetPredicate(
            (widget) =>
                widget is DashboardNavItem && widget.tab == DashboardTab.home,
          ),
        );
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<DashboardBottomNav>(find.byType(DashboardBottomNav))
              .selectedTab,
          DashboardTab.home,
        );
        expect(pager.controller!.page, DashboardTab.home.index);
        expect(find.byType(HomePublishedPostCard), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }

  for (final own in [true, false]) {
    for (final fromDetails in [false, true]) {
      testWidgets(
        'Home author navigation opens ${own ? 'account Profile' : 'other-user profile view'}${fromDetails ? ' through post details' : ' from the avatar'} using backend identity',
        (tester) async {
          final profile = UserProfileCubit(_repository(_Api()));
          await profile.load();
          // The author ID must work even before the local post list is available.
          final posts = PostsCubit(_Posts());
          await posts.load();
          final categories = ProfileCategoriesCubit(_Categories());
          final cart = CartCubit(_Cart());
          final notifications = NotificationsCubit(cart);
          addTearDown(profile.close);
          addTearDown(posts.close);
          addTearDown(categories.close);
          addTearDown(cart.close);
          addTearDown(notifications.close);
          const post = PostItem(
            id: 'new-home-post',
            imageAsset: 'assets/img1.png',
            title: 'Published post',
            category: 'Products',
            stockCount: 2,
            price: '100',
            originalPrice: '',
          );
          final author = own
              ? profile.seller
              : const PostSeller(
                  id: 'another-backend-account',
                  name: 'Another seller',
                  avatarAsset: '',
                );
          await tester.pumpWidget(
            MultiBlocProvider(
              providers: [
                BlocProvider.value(value: profile),
                BlocProvider.value(value: posts),
                BlocProvider.value(value: categories),
                BlocProvider.value(value: cart),
                BlocProvider.value(value: notifications),
              ],
              child: MaterialApp(
                home: Scaffold(
                  body: Builder(
                    builder: (context) {
                      if (fromDetails) {
                        return TextButton(
                          onPressed: () => openHomePost(context, post, author),
                          child: const Text('Open post'),
                        );
                      }
                      return SingleChildScrollView(
                        child: own
                            ? const HomePublishedPostCard(post: post)
                            : HomeSellerHeader(
                                seller: author,
                                onPressed: () =>
                                    openHomeSeller(context, post, author),
                              ),
                      );
                    },
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          if (fromDetails) {
            await tester.tap(find.text('Open post'));
            await tester.pumpAndSettle();
            expect(find.byType(PostDetailScreen), findsOneWidget);
          }
          final avatar = find.descendant(
            of: find.byType(fromDetails ? PostAuthorHeader : HomeSellerHeader),
            matching: find.byType(SellerAvatar),
          );
          await tester.ensureVisible(avatar);
          await tester.tap(avatar);
          await tester.pumpAndSettle();
          expect(
            find.byType(ProfileScreen),
            own ? findsOneWidget : findsNothing,
          );
          expect(
            find.byType(SellerProfileScreen),
            own ? findsNothing : findsOneWidget,
          );
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox());
        },
      );
    }
  }

  test(
    'incomplete profile has no fabricated defaults and preserves backend ID',
    () async {
      final api = _Api()..user = _user(name: null);
      final profile = await _repository(api).load();
      expect(profile.firstName, isEmpty);
      expect(profile.bio, isEmpty);
      expect(profile.businessType, isEmpty);
      expect(profile.seller.id, _account);
      expect(profile.withAvatar('https://example.com/avatar.jpg').id, _account);
    },
  );

  test('only changed documented fields are sent in one PATCH', () async {
    final api = _Api();
    final repository = _repository(api);
    final profile = await repository.load();
    final saved = await repository.save(
      _edit(profile, {
        'firstName': 'Updated',
        'username': 'updated_user',
        'bio': 'Updated bio',
        'city': 'Updated city',
        'gender': 'other',
        'birthDate': '1990-04-21',
      }),
    );
    expect(api.saves, 1);
    expect(api.endpoint, 'users/me');
    expect(api.credential, 'synthetic-test-credential');
    expect(api.sent, {
      'name': 'Updated User',
      'username': 'updated_user',
      'bio': 'Updated bio',
      'city': 'Updated city',
      'gender': 'other',
      'birthDate': '1990-04-21',
    });
    expect(saved.displayName, 'Updated User');
    expect(saved.email, profile.email);
    expect((await _repository(api).load()).bio, 'Updated bio');
  });

  test('whitespace and unchanged fields do not create a PATCH', () async {
    final api = _Api()..user = {..._user(), 'email': ' test@example.com '};
    final repository = _repository(api);
    final profile = await repository.load();
    final saved = await repository.save(
      _edit(profile, {
        'email': 'test@example.com',
        'bio': ' ',
        'city': ' Test city ',
      }),
    );
    expect(saved, same(profile));
    expect(api.saves, 0);
  });

  for (final field in ['email', 'nationality', 'businessType']) {
    test(
      'changed $field reaches backend and updates state after confirmation',
      () async {
        final api = _Api();
        final cubit = UserProfileCubit(_repository(api));
        addTearDown(cubit.close);
        await cubit.load();
        final value = field == 'email' ? 'edited@example.com' : 'Edited value';
        expect(
          await cubit.save(
            _edit(cubit.state.profile, {field: value, 'bio': 'Also edited'}),
          ),
          isTrue,
        );
        expect(api.sent, {field: value, 'bio': 'Also edited'});
        expect(api.saves, 1);
        expect(api.loads, field == 'businessType' ? 2 : 1);
        expect(cubit.state.profile.toJson()[field], value);
      },
    );
    test(
      'ignored $field triggers one read-back and is not falsely saved',
      () async {
        final api = _Api();
        final cubit = UserProfileCubit(_repository(api));
        addTearDown(cubit.close);
        await cubit.load();
        final previous = cubit.state.profile;
        api.reply = _response(api.user);
        expect(
          await cubit.save(_edit(previous, {field: 'Edited value'})),
          isFalse,
        );
        expect(api.saves, 1);
        expect(api.loads, 2);
        expect(cubit.state.profile, same(previous));
        expect(
          cubit.state.errorMessage,
          contains(ProfileEditStrings.fieldLabel(field)),
        );
      },
    );
  }

  test(
    'unchanged additional fields are parsed and retained without being resent',
    () async {
      final api = _Api()
        ..user = {
          ..._user(),
          'nationality': 'Existing nationality',
          'businessType': 'Existing business',
        };
      final repository = _repository(api);
      final previous = await repository.load();
      expect(previous.nationality, 'Existing nationality');
      expect(previous.businessType, 'Existing business');
      final saved = await repository.save(
        _edit(previous, {'bio': 'New biography'}),
      );
      expect(api.sent, {'bio': 'New biography'});
      expect(saved.nationality, previous.nationality);
      expect(saved.businessType, previous.businessType);
    },
  );

  test(
    'photo selection is retained when an unconfirmed upload cannot be saved',
    () async {
      final bytes = _photoBytes();
      final photo = ProfilePhotoCubit(
        imagePicker: () async => XFile('/synthetic/photo.jpg'),
      );
      addTearDown(photo.close);
      expect(await photo.pick(cropPhoto: (_) async => bytes), isTrue);
      final api = _Api()..uploadError = _error(status: 404);
      final cubit = UserProfileCubit(_repository(api));
      addTearDown(cubit.close);
      await cubit.load();
      final previous = cubit.state.profile;
      expect(
        await cubit.save(
          _edit(previous, {'bio': 'Keep draft'}),
          photo: photo.state,
        ),
        isFalse,
      );
      expect(api.saves, 0);
      expect(cubit.state.profile, same(previous));
      expect(photo.state, same(bytes));
      expect(bytes, _photoBytes());
      expect(api.uploads, 1);
      expect(
        cubit.state.errorMessage,
        ProfileEditStrings.photoUploadUnavailable,
      );
    },
  );

  test(
    'confirmed avatar URLs and clearing use avatarUrl, never a device path',
    () async {
      final api = _Api();
      final repository = _repository(api);
      final previous = await repository.load();
      final saved = await repository.save(
        previous.withAvatar('https://example.com/avatar.jpg'),
      );
      expect(api.sent, {'avatarUrl': 'https://example.com/avatar.jpg'});
      expect(saved.avatarPath, 'https://example.com/avatar.jpg');
      final cleared = await repository.save(saved.withAvatar(''));
      expect(api.sent, {'avatarUrl': ''});
      expect(cleared.avatarPath, isEmpty);
      final calls = api.saves;
      await expectLater(
        repository.save(cleared.withAvatar('/device/photo.jpg')),
        throwsException,
      );
      expect(api.saves, calls);
    },
  );

  test(
    'cleared nullable values are confirmed when backend returns null',
    () async {
      final api = _Api()
        ..user = {
          ..._user(),
          'bio': 'Old',
          'gender': 'other',
          'birthDate': '1990-04-21',
        };
      final repository = _repository(api);
      final previous = await repository.load();
      api.reply = _response({
        ...api.user,
        'name': null,
        'bio': null,
        'gender': null,
        'birthDate': null,
      });
      api.user = Map<String, dynamic>.from(api.reply!['data'] as Map);
      final saved = await repository.save(
        _edit(previous, {
          'firstName': '',
          'lastName': '',
          'bio': '',
          'gender': '',
          'birthDate': null,
        }),
      );
      expect(saved.displayName, isEmpty);
      expect(saved.bio, isEmpty);
      expect(saved.birthDate, isNull);
    },
  );

  for (final field in [
    'firstName',
    'username',
    'bio',
    'city',
    'gender',
    'birthDate',
    'avatarPath',
  ]) {
    test(
      'ignored $field cannot report success or replace authoritative profile',
      () async {
        final api = _Api();
        final cubit = UserProfileCubit(_repository(api));
        addTearDown(cubit.close);
        await cubit.load();
        final previous = cubit.state.profile;
        api.reply = _response(api.user);
        final value = switch (field) {
          'username' => 'changed_user',
          'gender' => 'other',
          'birthDate' => '1990-04-21',
          'avatarPath' => 'https://example.com/avatar.jpg',
          _ => 'Changed',
        };
        expect(await cubit.save(_edit(previous, {field: value})), isFalse);
        expect(api.saves, 1);
        expect(cubit.state.profile, same(previous));
        expect(cubit.state.errorMessage, contains('server did not confirm'));
      },
    );
  }

  test(
    'partial profile response preserves omitted values without false failure',
    () async {
      final api = _Api();
      final cubit = UserProfileCubit(_repository(api));
      addTearDown(cubit.close);
      await cubit.load();
      final previous = cubit.state.profile;
      api.reply = _response({'id': _account, 'name': 'Updated User'});
      expect(
        await cubit.save(_edit(previous, {'firstName': 'Updated'})),
        isTrue,
      );
      expect(cubit.state.profile.displayName, 'Updated User');
      expect(cubit.state.profile.email, previous.email);
      expect(cubit.state.profile.city, previous.city);
      expect(api.loads, 1);
    },
  );

  test(
    'false success and another account ID cannot replace the profile',
    () async {
      final api = _Api();
      final cubit = UserProfileCubit(_repository(api));
      addTearDown(cubit.close);
      await cubit.load();
      final previous = cubit.state.profile;
      for (final reply in [
        {'success': false},
        _response(_user(id: 'another-account')),
      ]) {
        api.reply = reply;
        expect(
          await cubit.save(_edit(previous, {'firstName': 'Updated'})),
          isFalse,
        );
        expect(cubit.state.profile, same(previous));
      }
    },
  );

  test(
    '400 validation identifies fields without exposing response values',
    () async {
      final api = _Api();
      final cubit = UserProfileCubit(_repository(api));
      addTearDown(cubit.close);
      await cubit.load();
      api.saveError = _error(
        status: 400,
        body: {
          'message': 'Do not display private server details',
          'errors': [
            {'path': 'bio', 'message': 'private submitted content'},
            {
              'path': ['body', 'name'],
              'message': 'private value',
            },
          ],
        },
      );
      expect(
        await cubit.save(_edit(cubit.state.profile, {'bio': 'New biography'})),
        isFalse,
      );
      expect(cubit.state.errorMessage, contains('Bio'));
      expect(cubit.state.errorMessage, contains('Name'));
      expect(cubit.state.errorMessage, isNot(contains('private')));
    },
  );

  for (final scenario in [
    (
      status: 400,
      type: DioExceptionType.badResponse,
      message: ProfileEditStrings.invalidFields,
    ),
    (
      status: 401,
      type: DioExceptionType.badResponse,
      message: ProfileEditStrings.sessionExpired,
    ),
    (
      status: 409,
      type: DioExceptionType.badResponse,
      message: ProfileEditStrings.usernameTaken,
    ),
    (
      status: 500,
      type: DioExceptionType.badResponse,
      message: ProfileEditStrings.saveFailed,
    ),
    (
      status: null,
      type: DioExceptionType.connectionError,
      message: ProfileEditStrings.connectionFailed,
    ),
    (
      status: null,
      type: DioExceptionType.receiveTimeout,
      message: ProfileEditStrings.timeout,
    ),
  ]) {
    test(
      '${scenario.status ?? scenario.type} preserves profile and allows retry',
      () async {
        var unauthorized = 0;
        final api = _Api();
        final cubit = UserProfileCubit(
          _repository(
            api,
            onUnauthorized: () async {
              unauthorized++;
            },
          ),
        );
        addTearDown(cubit.close);
        await cubit.load();
        final previous = cubit.state.profile;
        api.saveError = _error(status: scenario.status, type: scenario.type);
        expect(
          await cubit.save(_edit(previous, {'bio': 'New biography'})),
          isFalse,
        );
        expect(cubit.state.profile, same(previous));
        expect(cubit.state.errorMessage, scenario.message);
        expect(unauthorized, scenario.status == 401 ? 1 : 0);
        api.saveError = null;
        expect(
          await cubit.save(_edit(previous, {'bio': 'New biography'})),
          isTrue,
        );
      },
    );
  }

  test(
    'concurrent loads and saves are coalesced; state waits for confirmation',
    () async {
      final api = _Api()..loadGate = Completer<void>();
      final cubit = UserProfileCubit(_repository(api));
      addTearDown(cubit.close);
      final first = cubit.load(), second = cubit.load();
      await Future<void>.delayed(Duration.zero);
      expect(api.loads, 1);
      api.loadGate!.complete();
      await Future.wait([first, second]);
      final previous = cubit.state.profile;
      api.saveGate = Completer<void>();
      final one = cubit.save(_edit(previous, {'bio': 'First'}));
      final two = cubit.save(_edit(previous, {'bio': 'Second'}));
      await Future<void>.delayed(Duration.zero);
      expect(api.saves, 1);
      expect(cubit.state.saving, isTrue);
      expect(cubit.state.profile, same(previous));
      api.saveGate!.complete();
      expect(await one, isTrue);
      expect(await two, isTrue);
      expect(cubit.state.profile.bio, 'First');
    },
  );

  for (final value in [null, '', 'invalid\r\ncredential']) {
    test(
      'missing or malformed credential never creates a profile request: ${value == null ? 'missing' : 'invalid'}',
      () async {
        final api = _Api();
        final tokens = _Tokens()..value = value;
        await expectLater(
          _repository(api, tokens: tokens).load(),
          throwsException,
        );
        expect(api.loads, 0);
      },
    );
  }

  for (final saving in [false, true]) {
    test(
      'closing during ${saving ? 'save' : 'load'} cannot publish late state',
      () async {
        final api = _Api();
        final cubit = UserProfileCubit(_repository(api), userId: _account);
        if (saving) await cubit.load();
        final previous = cubit.state.profile;
        if (saving) {
          api.saveGate = Completer<void>();
        } else {
          api.loadGate = Completer<void>();
        }
        final pending = saving
            ? cubit.save(_edit(previous, {'bio': 'Late value'}))
            : cubit.load();
        final closing = cubit.close();
        if (saving) {
          api.saveGate!.complete();
        } else {
          api.loadGate!.complete();
        }
        await pending;
        await closing;
        expect(cubit.isClosed, isTrue);
        expect(cubit.state.profile, same(previous));
      },
    );
  }

  testWidgets('backend validation preserves form edits and does not navigate', (
    tester,
  ) async {
    final api = _Api();
    final cubit = UserProfileCubit(_repository(api));
    addTearDown(cubit.close);
    await cubit.load();
    await tester.pumpWidget(
      BlocProvider.value(
        value: cubit,
        child: const MaterialApp(home: ProfileEditScreen()),
      ),
    );
    await tester.pumpAndSettle();
    api.saveError = _error(
      status: 400,
      body: {
        'errors': [
          {'path': 'email'},
        ],
      },
    );
    await tester.enterText(_field(ProfileEditStrings.name), 'Draft name');
    await tester.enterText(
      _field(ProfileEditStrings.email),
      'edited@example.com',
    );
    await tester.tap(find.byTooltip('Done'));
    await tester.pumpAndSettle();
    expect(api.saves, 1);
    expect(find.byType(ProfileEditScreen), findsOneWidget);
    expect(
      tester
          .widget<TextFormField>(_field(ProfileEditStrings.name))
          .controller!
          .text,
      'Draft name',
    );
    expect(
      tester
          .widget<TextFormField>(_field(ProfileEditStrings.email))
          .controller!
          .text,
      'edited@example.com',
    );
    expect(cubit.state.profile.displayName, 'Test User');
    expect(cubit.state.errorMessage, contains('Email'));
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'incomplete account can save a 200-character bio without inventing a name',
    (tester) async {
      final api = _Api()..user = _user(name: null);
      final cubit = UserProfileCubit(_repository(api));
      addTearDown(cubit.close);
      await cubit.load();
      await tester.pumpWidget(
        BlocProvider.value(
          value: cubit,
          child: const MaterialApp(home: ProfileEditScreen()),
        ),
      );
      await tester.pumpAndSettle();
      final biography = 'b' * 200;
      await tester.ensureVisible(_field(ProfileEditStrings.bio));
      await tester.enterText(_field(ProfileEditStrings.bio), biography);
      await tester.tap(find.byTooltip('Done'));
      await tester.pumpAndSettle();
      expect(api.sent, {'bio': biography});
      expect(cubit.state.profile.bio, biography);
      expect(cubit.state.profile.firstName, isEmpty);
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'logout recreates profile state for the next account and profile 401 uses existing session cleanup',
    (tester) async {
      final api = _Api();
      final tokens = _Tokens();
      late BuildContext scoped;
      await tester.pumpWidget(
        AppProviders(
          apiClient: api,
          tokenStore: tokens,
          child: MaterialApp(
            home: Builder(
              builder: (context) {
                scoped = context;
                return const Scaffold(body: Text('Account test'));
              },
            ),
          ),
        ),
      );
      final session = scoped.read<SessionCubit>();
      await session.restore();
      final first = scoped.read<UserProfileCubit>();
      await first.load();
      api.loadError = _error(status: 401);
      await first.load();
      await tester.pumpAndSettle();
      expect(session.state.status, SessionStatus.unauthenticated);
      expect(tokens.value, isNull);
      expect(first.isClosed, isTrue);
      api.loadError = null;
      api.user = _user(id: 'test-account-b', name: 'Second Account');
      tokens.value = 'synthetic-second-credential';
      await session.restore();
      final second = scoped.read<UserProfileCubit>();
      await second.load();
      expect(identical(first, second), isFalse);
      expect(second.state.profile.id, 'test-account-b');
      expect(second.state.profile.displayName, 'Second Account');
      await tester.pumpWidget(const SizedBox());
    },
  );

  test(
    'read-back confirms fields omitted by PATCH without a second write',
    () async {
      final api = _Api()
        ..patchOmissions.addAll(['nationality', 'businessType']);
      final cubit = UserProfileCubit(_repository(api));
      addTearDown(cubit.close);
      await cubit.load();
      expect(
        await cubit.save(
          _edit(cubit.state.profile, {
            'nationality': 'Test nationality',
            'businessType': 'Test business',
          }),
        ),
        isTrue,
      );
      expect(api.loads, 2);
      expect(api.saves, 1);
      expect(cubit.state.profile.nationality, 'Test nationality');
      expect(cubit.state.profile.businessType, 'Test business');
    },
  );

  test('partial confirmation updates only server values and explicitly names pending edits', () async {
    final api = _Api()
      ..patchOmissions.addAll(['nationality', 'businessType'])
      ..getOmissions.addAll(['nationality', 'businessType']);
    final cubit = UserProfileCubit(_repository(api));
    addTearDown(cubit.close);
    await cubit.load();
    expect(
      await cubit.save(
        _edit(cubit.state.profile, {
          'firstName': 'Updated',
          'city': 'Updated city',
          'nationality': 'Unconfirmed nationality',
          'businessType': 'Unconfirmed business',
        }),
      ),
      isFalse,
    );
    expect(api.saves, 1);
    expect(api.loads, 2);
    expect(cubit.state.profile.displayName, 'Updated User');
    expect(cubit.state.profile.city, 'Updated city');
    expect(cubit.state.profile.nationality, isEmpty);
    expect(cubit.state.profile.businessType, isEmpty);
    expect(
      cubit.state.errorMessage,
      contains('Confirmed by the server: Name, City'),
    );
    expect(
      cubit.state.errorMessage,
      contains('did not confirm saving: Nationality, Shop / business type'),
    );
    expect(cubit.state.saveFailed, isTrue);
    // A retry sends the pending fields, not the already confirmed name and city.
    expect(
      await cubit.save(
        _edit(cubit.state.profile, {
          'nationality': 'Unconfirmed nationality',
          'businessType': 'Unconfirmed business',
        }),
      ),
      isFalse,
    );
    expect(api.sent!.keys.toSet(), {'nationality', 'businessType'});
  });

  test(
    'partial GET loads preserve known values; explicit null clears them',
    () async {
      final api = _Api()
        ..user = {
          ..._user(),
          'nationality': 'Known',
          'businessType': 'Known business',
        };
      final repository = _repository(api);
      await repository.load();
      api.user = {'id': _account, 'bio': 'Updated bio'};
      final partial = await repository.load();
      expect(partial.displayName, 'Test User');
      expect(partial.email, 'test@example.com');
      expect(partial.nationality, 'Known');
      expect(partial.bio, 'Updated bio');
      api.user = {'id': _account, 'nationality': null, 'businessType': null};
      final cleared = await repository.load();
      expect(cleared.nationality, isEmpty);
      expect(cleared.businessType, isEmpty);
      expect(cleared.email, 'test@example.com');
    },
  );

  test('email nationality and business type can intentionally be cleared when confirmed', () async {
    final api = _Api()
      ..user = {
        ..._user(),
        'nationality': 'Known',
        'businessType': 'Known business',
      };
    final repository = _repository(api);
    final previous = await repository.load();
    api.reply = _response({
      ...api.user,
      'email': null,
      'nationality': null,
      'businessType': null,
    });
    api.user = Map<String, dynamic>.from(api.reply!['data'] as Map);
    final saved = await repository.save(
      _edit(previous, {'email': '', 'nationality': '', 'businessType': ''}),
    );
    expect(api.sent, {'email': '', 'nationality': '', 'businessType': ''});
    expect(saved.email, isEmpty);
    expect(saved.nationality, isEmpty);
    expect(saved.businessType, isEmpty);
  });

  test('failed read-back reports verification failure without losing confirmed PATCH values', () async {
    final api = _Api()..patchOmissions.add('nationality');
    final cubit = UserProfileCubit(_repository(api));
    addTearDown(cubit.close);
    await cubit.load();
    api.loadError = _error(type: DioExceptionType.receiveTimeout);
    expect(
      await cubit.save(
        _edit(cubit.state.profile, {
          'firstName': 'Updated',
          'nationality': 'Pending',
        }),
      ),
      isFalse,
    );
    expect(cubit.state.profile.displayName, 'Updated User');
    expect(cubit.state.profile.nationality, isEmpty);
    expect(cubit.state.errorMessage, contains('read-back verification failed'));
    expect(api.saves, 1);
  });

  testWidgets(
    'Profile shows confirmed name bio and business while city stays editable without being displayed',
    (tester) async {
      final api = _Api();
      final profile = UserProfileCubit(_repository(api));
      await profile.load();
      final posts = PostsCubit(_Posts());
      await posts.load();
      final categories = ProfileCategoriesCubit(_Categories());
      final cart = CartCubit(_Cart());
      final notifications = NotificationsCubit(cart);
      addTearDown(profile.close);
      addTearDown(posts.close);
      addTearDown(categories.close);
      addTearDown(cart.close);
      addTearDown(notifications.close);
      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider.value(value: profile),
            BlocProvider.value(value: posts),
            BlocProvider.value(value: categories),
            BlocProvider.value(value: notifications),
          ],
          child: const MaterialApp(home: Scaffold(body: ProfileScreen())),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byType(ProfileAvatar));
      await tester.pumpAndSettle();
      await tester.enterText(_field(ProfileEditStrings.name), 'Updated');
      await tester.enterText(
        _field(ProfileEditStrings.businessType),
        'Backend business',
      );
      await tester.ensureVisible(_field(ProfileEditStrings.city));
      await tester.enterText(_field(ProfileEditStrings.city), 'Updated city');
      await tester.ensureVisible(_field(ProfileEditStrings.bio));
      await tester.enterText(
        _field(ProfileEditStrings.bio),
        'Backend biography',
      );
      await tester.tap(find.byTooltip('Done'));
      await tester.pumpAndSettle();
      expect(find.byType(ProfileEditScreen), findsNothing);
      expect(find.text('Updated User'), findsOneWidget);
      expect(find.text('Backend business'), findsOneWidget);
      expect(find.text('Backend biography'), findsOneWidget);
      expect(find.text('Updated city'), findsNothing);
      expect(profile.state.profile.city, 'Updated city');
      expect(api.saves, 1);
      await tester.tap(find.byType(ProfileAvatar));
      await tester.pumpAndSettle();
      await tester.ensureVisible(_field(ProfileEditStrings.city));
      expect(
        tester
            .widget<TextFormField>(_field(ProfileEditStrings.city))
            .controller!
            .text,
        'Updated city',
      );
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'photo preview stays pending and text saves only after explicit consent',
    (tester) async {
      final directory = await tester.runAsync(
        () => Directory.systemTemp.createTemp('hywork-photo-consent-'),
      );
      final source = File('${directory!.path}/source.png');
      final cropped = File('${directory.path}/crop.png');
      await tester.runAsync(() async {
        final bytes = await File('assets/img1.png').readAsBytes();
        await source.writeAsBytes(bytes);
        await cropped.writeAsBytes(bytes);
      });
      addTearDown(() => directory.delete(recursive: true));
      const cropChannel = MethodChannel('plugins.hunghd.vn/image_cropper');
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      const pickerChannel = MethodChannel('plugins.flutter.io/image_picker');
      messenger.setMockMethodCallHandler(
        pickerChannel,
        (_) async => source.path,
      );
      addTearDown(
        () => messenger.setMockMethodCallHandler(pickerChannel, null),
      );
      messenger.setMockMethodCallHandler(
        cropChannel,
        (_) async => cropped.path,
      );
      addTearDown(() => messenger.setMockMethodCallHandler(cropChannel, null));
      final api = _Api()..uploadError = _error(status: 404);
      final cubit = UserProfileCubit(_repository(api));
      await cubit.load();
      addTearDown(cubit.close);
      await tester.pumpWidget(
        BlocProvider.value(
          value: cubit,
          child: const MaterialApp(home: ProfileEditScreen()),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(_field(ProfileEditStrings.name), 'Draft');
      await tester.runAsync(() async {
        await tester.tap(find.byTooltip(ProfileEditStrings.choosePhoto));
        for (var i = 0; i < 100 && await cropped.exists(); i++) {
          await Future<void>.delayed(const Duration(milliseconds: 10));
        }
        await Future<void>.delayed(Duration.zero);
      });
      await tester.pumpAndSettle();
      final preview = find.byWidgetPredicate(
        (widget) => widget is Image && widget.image is MemoryImage,
      );
      expect(preview, findsOneWidget);
      await tester.tap(find.byTooltip('Done'));
      await tester.pumpAndSettle();
      expect(find.text(ProfileEditStrings.saveTextOnlyTitle), findsOneWidget);
      expect(api.saves, 0);
      await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
      await tester.pumpAndSettle();
      expect(api.saves, 0);
      expect(preview, findsOneWidget);
      await tester.tap(find.byTooltip('Done'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.widgetWithText(FilledButton, ProfileEditStrings.saveTextOnly),
      );
      await tester.pumpAndSettle();
      expect(api.sent, {'name': 'Draft User'});
      expect(api.saves, 1);
      expect(cubit.state.profile.displayName, 'Draft User');
      expect(cubit.state.profile.avatarPath, isEmpty);
      expect(find.byType(ProfileEditScreen), findsOneWidget);
      expect(preview, findsOneWidget);
      expect(await tester.runAsync(source.exists), isTrue);
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpWidget(const SizedBox());
    },
  );

  for (final acknowledgement in [
    {'success': true, 'data': null},
    {
      'success': true,
      'data': {'bio': 'Unidentified data must not be trusted'},
    },
  ]) {
    test(
      'acknowledgement without identity requires authenticated read-back',
      () async {
        final api = _Api();
        final cubit = UserProfileCubit(_repository(api));
        addTearDown(cubit.close);
        await cubit.load();
        final previous = cubit.state.profile;
        api.reply = acknowledgement;
        api.user = {...api.user, 'bio': 'Verified through auth me'};
        expect(
          await cubit.save(
            _edit(previous, {'bio': 'Verified through auth me'}),
          ),
          isTrue,
        );
        expect(api.saves, 1);
        expect(api.loads, 2);
        expect(cubit.state.profile.bio, 'Verified through auth me');
        expect(cubit.state.profile.id, _account);
      },
    );
  }
  test(
    '401 during read-back retains existing session-expiration handling',
    () async {
      var expired = 0;
      final api = _Api()..patchOmissions.add('nationality');
      final cubit = UserProfileCubit(
        _repository(
          api,
          onUnauthorized: () async {
            expired++;
          },
        ),
      );
      addTearDown(cubit.close);
      await cubit.load();
      final previous = cubit.state.profile;
      api.loadError = _error(status: 401);
      expect(
        await cubit.save(
          _edit(previous, {'firstName': 'Updated', 'nationality': 'Pending'}),
        ),
        isFalse,
      );
      expect(expired, 1);
      expect(cubit.state.profile, same(previous));
      expect(cubit.state.errorMessage, ProfileEditStrings.sessionExpired);
    },
  );

  for (final value in [
    '2000-01-15',
    '2000-01-15T00:00:00+14:00',
    '2000-01-15T23:30:00-12:00',
  ]) {
    test('birth-date parsing preserves calendar day for $value', () async {
      final api = _Api()..user = {..._user(), 'birthDate': value};
      final repository = _repository(api);
      final profile = await repository.load();
      expect(profile.birthDate, DateTime.utc(2000, 1, 15));
      final sameDay = _edit(profile, {'birthDate': '2000-01-15T23:59:00'});
      expect(await repository.save(sameDay), same(profile));
      expect(api.saves, 0);
    });
  }
  for (final invalid in ['2000-02-30', '2001-02-29', '2000-13-01']) {
    test(
      'invalid backend birth date $invalid is rejected without rollover',
      () async {
        final api = _Api()..user = {..._user(), 'birthDate': invalid};
        await expectLater(_repository(api).load(), throwsFormatException);
      },
    );
  }
  test(
    'birth date preserves local and UTC calendar dates in date-only requests',
    () async {
      final api = _Api();
      final repository = _repository(api);
      var profile = await repository.load();
      for (final date in [
        DateTime(2000, 1, 15, 23, 59),
        DateTime.utc(2000, 1, 16, 0, 1),
      ]) {
        profile = await repository.save(
          UserProfile.fromJson({
            ...profile.toJson(),
            'birthDate': date.toIso8601String(),
          }),
        );
        expect(api.sent, {
          'birthDate': date.day == 15 ? '2000-01-15' : '2000-01-16',
        });
        expect(profile.birthDate?.day, date.day);
      }
    },
  );
  for (final field in ['birthDate', 'businessType', 'avatarUrl']) {
    test(
      '$field requires authenticated read-back even if PATCH echoes it',
      () async {
        final old = {
          ..._user(),
          'avatarUrl': 'https://example.com/old.jpg',
          'birthDate': '1990-04-21',
          'businessType': 'Previous business',
        };
        final api = _Api()..user = Map<String, dynamic>.of(old);
        final cubit = UserProfileCubit(_repository(api));
        addTearDown(cubit.close);
        await cubit.load();
        final value = switch (field) {
          'birthDate' => '2000-01-15',
          'businessType' => 'New business',
          _ => 'https://example.com/new.jpg',
        };
        api.reply = _response({...old, 'name': 'Updated User', field: value});
        final modelKey = field == 'avatarUrl' ? 'avatarPath' : field;
        expect(
          await cubit.save(
            _edit(cubit.state.profile, {
              'firstName': 'Updated',
              modelKey: value,
            }),
          ),
          isFalse,
        );
        expect(api.loads, 2);
        expect(api.saves, 1);
        expect(cubit.state.profile.avatarPath, old['avatarUrl']);
        expect(cubit.state.profile.birthDate, DateTime.utc(1990, 4, 21));
        expect(cubit.state.profile.businessType, 'Previous business');
      },
    );
  }
  test('failed avatar read-back keeps the previous avatar while confirming other saved fields', () async {
    final api = _Api()
      ..user = {..._user(), 'avatarUrl': 'https://example.com/old.jpg'};
    final cubit = UserProfileCubit(_repository(api));
    addTearDown(cubit.close);
    await cubit.load();
    api.loadError = _error(type: DioExceptionType.connectionError);
    expect(
      await cubit.save(
        _edit(cubit.state.profile, {
          'firstName': 'Updated',
          'avatarPath': 'https://example.com/new.jpg',
        }),
      ),
      isFalse,
    );
    expect(cubit.state.profile.avatarPath, 'https://example.com/old.jpg');
    expect(cubit.state.profile.displayName, 'Updated User');
    expect(cubit.state.errorMessage, contains('read-back verification failed'));
  });
  testWidgets(
    'picker selection reaches PATCH, reloads, and can be cleared without changing picker design',
    (tester) async {
      final api = _Api();
      final cubit = UserProfileCubit(_repository(api));
      addTearDown(cubit.close);
      await cubit.load();
      Widget editor() => BlocProvider.value(
        value: cubit,
        child: const MaterialApp(home: ProfileEditScreen()),
      );
      await tester.pumpWidget(editor());
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextFormField>(_birthField()).controller!.text,
        isEmpty,
      );
      await _chooseBirth(tester, DateTime(2000, 1, 15));
      await tester.tap(find.byTooltip('Done'));
      await tester.pumpAndSettle();
      expect(api.sent, {'birthDate': '2000-01-15'});
      expect(cubit.state.profile.birthDate, DateTime.utc(2000, 1, 15));
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpWidget(const SizedBox());
      await cubit.load();
      await tester.pumpWidget(editor());
      await tester.pumpAndSettle();
      final expected = AppStrings.persianDigits('1378/10/25');
      expect(
        tester.widget<TextFormField>(_birthField()).controller!.text,
        expected,
      );
      await _clearBirth(tester);
      expect(
        tester.widget<TextFormField>(_birthField()).controller!.text,
        isEmpty,
      );
      await tester.tap(find.byTooltip('Done'));
      await tester.pumpAndSettle();
      expect(api.sent, {'birthDate': null});
      expect(cubit.state.profile.birthDate, isNull);
      expect(api.saves, 2);
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'birth field syncs changed initial date and cancel does not clear it',
    (tester) async {
      DateTime? selected;
      var changes = 0;
      Widget host(DateTime? date) => MaterialApp(
        home: Scaffold(
          body: ProfileBirthField(
            initialDate: date,
            onChanged: (value) {
              selected = value;
              changes++;
            },
          ),
        ),
      );
      await tester.pumpWidget(host(DateTime.utc(2000, 1, 15)));
      await tester.pumpAndSettle();
      final original = tester
          .widget<TextFormField>(_birthField())
          .controller!
          .text;
      await tester.pumpWidget(host(DateTime.utc(2001, 2, 16)));
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextFormField>(_birthField()).controller!.text,
        isNot(original),
      );
      await tester.tap(_birthField());
      await tester.pumpAndSettle();
      final labels = MaterialLocalizations.of(
        tester.element(find.byType(AlertDialog)),
      );
      await tester.tap(find.text(labels.cancelButtonLabel));
      await tester.pumpAndSettle();
      expect(changes, 0);
      expect(selected, isNull);
      await tester.pumpWidget(host(null));
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextFormField>(_birthField()).controller!.text,
        isEmpty,
      );
    },
  );
  testWidgets(
    'business draft survives failed confirmation and does not reset selected birth date',
    (tester) async {
      final api = _Api()
        ..patchOmissions.add('businessType')
        ..getOmissions.add('businessType');
      final cubit = UserProfileCubit(_repository(api));
      addTearDown(cubit.close);
      await cubit.load();
      await tester.pumpWidget(
        BlocProvider.value(
          value: cubit,
          child: const MaterialApp(home: ProfileEditScreen()),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        _field(ProfileEditStrings.businessType),
        'Pending business',
      );
      await _chooseBirth(tester, DateTime(2000, 1, 15));
      await tester.tap(find.byTooltip('Done'));
      await tester.pumpAndSettle();
      expect(api.sent, {
        'businessType': 'Pending business',
        'birthDate': '2000-01-15',
      });
      expect(find.byType(ProfileEditScreen), findsOneWidget);
      expect(
        tester
            .widget<TextFormField>(_field(ProfileEditStrings.businessType))
            .controller!
            .text,
        'Pending business',
      );
      expect(cubit.state.profile.businessType, isEmpty);
      expect(cubit.state.profile.birthDate, DateTime.utc(2000, 1, 15));
      expect(
        tester.widget<TextFormField>(_birthField()).controller!.text,
        isNotEmpty,
      );
      expect(
        cubit.state.errorMessage,
        contains(ProfileEditStrings.businessType),
      );
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpWidget(const SizedBox());
    },
  );

  test('profile compression uses the existing compressor without modifying selected bytes', () async {
    final original = Uint8List.fromList([0x89, 0x50, 0x4e, 0x47, 1, 2, 3, 4]);
    final compressed = Uint8List.fromList([0x89, 0x50, 1, 2]);
    final previous = FlutterImageCompressPlatform.instance;
    final plugin = _Compression(compressed);
    FlutterImageCompressPlatform.instance = plugin;
    addTearDown(() => FlutterImageCompressPlatform.instance = previous);
    final result = await MediaCompressor().compressProfilePhoto(original);
    expect(result, compressed);
    expect(original, [0x89, 0x50, 0x4e, 0x47, 1, 2, 3, 4]);
    expect(plugin.requests, [
      {
        'image': original,
        'minWidth': 1024,
        'minHeight': 1024,
        'quality': MediaCompressor.imageQuality,
        'format': CompressFormat.png,
        'keepExif': false,
      },
    ]);
  });
  test('compression failure preserves the selected image bytes', () async {
    final previous = FlutterImageCompressPlatform.instance;
    final original = Uint8List.fromList([1, 2, 3, 4]);
    final plugin = _Compression(Uint8List(0), fail: true);
    FlutterImageCompressPlatform.instance = plugin;
    addTearDown(() => FlutterImageCompressPlatform.instance = previous);
    expect(
      await MediaCompressor().compressProfilePhoto(original),
      same(original),
    );
    expect(plugin.requests, hasLength(1));
  });
  test('backend avatar URLs use the existing network image provider', () {
    final image = profileImageProvider('https://example.com/confirmed.jpg');
    expect(image, isA<NetworkImage>());
    expect((image! as NetworkImage).url, 'https://example.com/confirmed.jpg');
    expect(profileImageProvider(null), isNull);
  });

  test('selected photo uploads once and only its returned URL joins the profile PATCH', () async {
    final api = _Api();
    final cubit = UserProfileCubit(_repository(api));
    addTearDown(cubit.close);
    await cubit.load();
    final bytes = _photoBytes();
    expect(
      await cubit.save(
        _edit(cubit.state.profile, {
          'businessType': 'Software Development',
          'birthDate': '2000-01-15',
        }),
        photo: bytes,
      ),
      isTrue,
    );
    expect(api.uploads, 1);
    expect(api.uploadEndpoint, 'uploads?purpose=avatar');
    expect(api.uploadData!.fields, isEmpty);
    expect(api.uploadData!.files, hasLength(1));
    final file = api.uploadData!.files.single;
    expect(file.key, 'file');
    expect(file.value.filename, 'avatar.png');
    expect(file.value.contentType.toString(), 'image/png');
    expect(
      await file.value.finalize().expand((chunk) => chunk).toList(),
      bytes,
    );
    expect(api.sent, {
      'businessType': 'Software Development',
      'birthDate': '2000-01-15',
      'avatarUrl': api.uploadReply['data']['url'],
    });
    expect(api.saves, 1);
    expect(api.loads, 2);
    expect(cubit.state.profile.avatarPath, api.uploadReply['data']['url']);
    expect(cubit.state.profile.businessType, 'Software Development');
    expect(cubit.state.profile.birthDate, DateTime.utc(2000, 1, 15));
    expect(bytes, _photoBytes());
  });

  test(
    'upload uses compressed image bytes and their actual MIME type',
    () async {
      final previousPlugin = FlutterImageCompressPlatform.instance;
      final compressed = Uint8List.fromList([0xff, 0xd8, 0xff, 1]);
      final plugin = _Compression(compressed);
      FlutterImageCompressPlatform.instance = plugin;
      addTearDown(() => FlutterImageCompressPlatform.instance = previousPlugin);
      final api = _Api();
      final repository = _repository(api);
      final profile = await repository.load();
      await repository.save(profile, photo: _photoBytes());
      final file = api.uploadData!.files.single.value;
      expect(file.contentType.toString(), 'image/jpeg');
      expect(file.filename, 'avatar.jpeg');
      expect(
        await file.finalize().expand((chunk) => chunk).toList(),
        compressed,
      );
      expect(plugin.requests, hasLength(1));
    },
  );

  for (final status in [400, 401, 404, 413, 415, 429, 500]) {
    test(
      'upload HTTP $status preserves the confirmed profile without sending PATCH',
      () async {
        final api = _Api()
          ..user = {..._user(), 'avatarUrl': 'https://example.com/old.jpg'}
          ..uploadError = _error(status: status);
        var expired = 0;
        final cubit = UserProfileCubit(
          _repository(
            api,
            onUnauthorized: () async {
              expired++;
            },
          ),
        );
        addTearDown(cubit.close);
        await cubit.load();
        final previous = cubit.state.profile;
        expect(
          await cubit.save(
            _edit(previous, {'bio': 'Pending draft'}),
            photo: _photoBytes(),
          ),
          isFalse,
        );
        expect(cubit.state.profile, same(previous));
        expect(cubit.state.photoUploadUnavailable, status == 404);
        expect(cubit.state.errorMessage, isNotEmpty);
        expect(expired, status == 401 ? 1 : 0);
        expect(api.uploads, 1);
        expect(api.saves, 0);
      },
    );
  }
  for (final type in [
    DioExceptionType.sendTimeout,
    DioExceptionType.connectionError,
  ]) {
    test('upload $type cannot falsely save the avatar or text', () async {
      final api = _Api()..uploadError = _error(type: type);
      final cubit = UserProfileCubit(_repository(api));
      addTearDown(cubit.close);
      await cubit.load();
      final previous = cubit.state.profile;
      expect(
        await cubit.save(
          _edit(previous, {'bio': 'Pending draft'}),
          photo: _photoBytes(),
        ),
        isFalse,
      );
      expect(cubit.state.profile, same(previous));
      expect(
        cubit.state.errorMessage,
        type == DioExceptionType.sendTimeout
            ? ProfileEditStrings.timeout
            : ProfileEditStrings.connectionFailed,
      );
      expect(api.saves, 0);
    });
  }
  for (final data in [
    null,
    {'url': '/device/local/photo.png'},
    {'url': 'file:///device/local/photo.png'},
    {'url': 'https://example.com/post.png', 'purpose': 'post'},
  ]) {
    test(
      'malformed or incorrect-purpose upload result $data is not used as an avatar',
      () async {
        final api = _Api()..uploadReply = {'success': true, 'data': data};
        final cubit = UserProfileCubit(_repository(api));
        addTearDown(cubit.close);
        await cubit.load();
        expect(
          await cubit.save(cubit.state.profile, photo: _photoBytes()),
          isFalse,
        );
        expect(cubit.state.profile.avatarPath, isEmpty);
        expect(cubit.state.errorMessage, ProfileEditStrings.photoUploadFailed);
        expect(api.saves, 0);
      },
    );
  }
  test(
    'a failed PATCH after successful upload keeps the previous confirmed image',
    () async {
      final api = _Api()
        ..user = {..._user(), 'avatarUrl': 'https://example.com/old.jpg'}
        ..saveError = _error(status: 400);
      final cubit = UserProfileCubit(_repository(api));
      addTearDown(cubit.close);
      await cubit.load();
      final previous = cubit.state.profile;
      expect(await cubit.save(previous, photo: _photoBytes()), isFalse);
      expect(cubit.state.profile, same(previous));
      expect(api.uploads, 1);
      expect(api.saves, 1);
    },
  );
  test('duplicate saves share one upload and retain one credential throughout the operation', () async {
    final api = _Api()..uploadGate = Completer<void>();
    final tokens = _Tokens();
    final cubit = UserProfileCubit(_repository(api, tokens: tokens));
    addTearDown(cubit.close);
    await cubit.load();
    final first = cubit.save(cubit.state.profile, photo: _photoBytes());
    final repeated = cubit.save(cubit.state.profile, photo: _photoBytes());
    while (api.uploads == 0) {
      await Future<void>.delayed(Duration.zero);
    }
    expect(cubit.state.saving, isTrue);
    tokens.value = 'different-synthetic-account-credential';
    api.uploadGate!.complete();
    expect(await first, isTrue);
    expect(await repeated, isTrue);
    expect(api.uploads, 1);
    expect(api.saves, 1);
    expect(api.credentials.toSet(), {'synthetic-test-credential'});
  });
  for (final photo in [
    Uint8List(0),
    Uint8List.fromList([1, 2, 3]),
    Uint8List(5 * 1024 * 1024 + 1),
  ]) {
    test(
      'invalid or oversized photo of ${photo.length} bytes is rejected before upload',
      () async {
        final api = _Api();
        final cubit = UserProfileCubit(_repository(api));
        addTearDown(cubit.close);
        await cubit.load();
        expect(await cubit.save(cubit.state.profile, photo: photo), isFalse);
        expect(api.uploads, 0);
        expect(api.saves, 0);
      },
    );
  }
  for (final invalid in ['X', 'X' * 61]) {
    test(
      'documented business type length rejects ${invalid.length} characters without writing',
      () async {
        final api = _Api();
        final cubit = UserProfileCubit(_repository(api));
        addTearDown(cubit.close);
        await cubit.load();
        expect(
          await cubit.save(
            _edit(cubit.state.profile, {'businessType': invalid}),
          ),
          isFalse,
        );
        expect(
          cubit.state.errorMessage,
          ProfileEditStrings.invalidBusinessType,
        );
        expect(api.saves, 0);
      },
    );
  }

  final localApi = Uri.tryParse(AppConfig.apiBaseUrl);
  test('real Dio sends authenticated JSON PATCH once and a new repository reloads confirmed data', () async {
    final server = await HttpServer.bind(
      InternetAddress.loopbackIPv4,
      localApi!.port,
    );
    addTearDown(() => server.close(force: true));
    var stored = _user();
    final calls = <String>[];
    final errors = <Object>[];
    server.listen((request) async {
      try {
        expect(
          request.headers.value('Authorization'),
          'Bearer synthetic-test-credential',
        );
        expect(request.headers.value('X-Client'), 'mobile');
        calls.add('${request.method} ${request.uri.path}');
        if (request.method == 'POST') {
          expect(request.uri.path, '/api/uploads');
          expect(request.uri.queryParameters, {'purpose': 'avatar'});
          expect(request.headers.contentType!.mimeType, 'multipart/form-data');
          final boundary = request.headers.contentType!.parameters['boundary']!;
          final body = latin1.decode(
            await request.expand((chunk) => chunk).toList(),
          );
          expect(body, startsWith('--$boundary\r\n'));
          expect('name="file"'.allMatches(body), hasLength(1));
          expect(body, contains('filename="avatar.png"'));
          expect(body.toLowerCase(), contains('content-type: image/png'));
          expect(
            body,
            contains(
              '\r\n\r\n${latin1.decode(_photoBytes())}\r\n--$boundary--',
            ),
          );
          request.response.statusCode = HttpStatus.created;
          request.response.headers.contentType = ContentType.json;
          request.response.write(
            jsonEncode(
              _response({
                'url': 'https://example.com/uploaded-avatar.jpg',
                'purpose': 'avatar',
              }),
            ),
          );
          await request.response.close();
          return;
        }
        if (request.method == 'PATCH') {
          final body = jsonDecode(
            await utf8.decoder.bind(request).join(),
          ) as Map<String, dynamic>;
          expect(body, {
            'bio': 'Server confirmed biography',
            'birthDate': '2000-01-15',
            'businessType': 'Server confirmed business',
            'avatarUrl': 'https://example.com/uploaded-avatar.jpg',
          });
          stored = {...stored, ...body};
        }
        request.response.headers.contentType = ContentType.json;
        request.response.write(jsonEncode(_response(stored)));
        await request.response.close();
      } catch (error) {
        errors.add(error);
        request.response.statusCode = 500;
        await request.response.close();
      }
    });
    await HttpOverrides.runWithHttpOverrides(() async {
      final repository = ApiUserProfileRepository(
        ApiClient(),
        _Tokens(),
        userId: _account,
        onUnauthorized: () async {},
      );
      final previous = await repository.load();
      final saved = await repository.save(
        _edit(previous, {
          'bio': 'Server confirmed biography',
          'birthDate': '2000-01-15',
          'businessType': 'Server confirmed business',
        }),
        photo: _photoBytes(),
      );
      expect(saved.bio, 'Server confirmed biography');
      expect(saved.birthDate, DateTime.utc(2000, 1, 15));
      expect(saved.businessType, 'Server confirmed business');
      expect(saved.avatarPath, 'https://example.com/uploaded-avatar.jpg');
      final reloaded = await ApiUserProfileRepository(
        ApiClient(),
        _Tokens(),
        userId: _account,
        onUnauthorized: () async {},
      ).load();
      expect(reloaded.bio, saved.bio);
      expect(reloaded.birthDate, saved.birthDate);
      expect(reloaded.businessType, saved.businessType);
      expect(reloaded.avatarPath, saved.avatarPath);
    }, _RealHttp());
    expect(errors, isEmpty);
    expect(calls, [
      'GET /api/auth/me',
      'POST /api/uploads',
      'PATCH /api/users/me',
      'GET /api/auth/me',
      'GET /api/auth/me',
    ]);
  }, skip: localApi?.host != '127.0.0.1');
}
