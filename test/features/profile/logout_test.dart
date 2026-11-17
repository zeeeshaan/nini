import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nini/app/app_providers.dart';
import 'package:nini/app/app.dart';
import 'package:nini/core/responsiveness/responsive_config/config.dart';
import 'package:nini/features/splash/presentation/pages/splash_screen.dart';
import 'package:nini/features/login/presentation/pages/login_screen.dart';
import 'package:nini/features/team/domain/team_workspace.dart';
import 'package:nini/features/team/domain/team_request.dart';
import 'package:nini/shared/models/post/post_seller.dart';
import 'package:nini/core/network/api_client.dart';
import 'package:nini/core/config/app_config/app_config.dart';
import 'package:nini/features/chat/data/in_memory_chat_repository.dart';
import 'package:nini/features/chat/domain/models/chat_conversation.dart';
import 'package:nini/features/team/data/in_memory_teams_repository.dart';
import 'package:nini/core/security/secure_token_store.dart';
import 'package:nini/core/theme/theme_cubit.dart';
import 'package:nini/features/login/data/auth_repo.dart';
import 'package:nini/features/login/presentation/cubit/session_cubit.dart';
import 'package:nini/features/posts/presentation/cubit/post_likes_cubit.dart';
import 'package:nini/features/profile/presentation/widgets/settings/profile_settings_list.dart';

class _RealHttpOverrides extends HttpOverrides {}

class _InstallationStorage extends Fake implements FlutterSecureStorage {
  _InstallationStorage(this.values);
  final Map<String, String> values;
  final operations = <String>[];
  bool failDelete = false, failBinding = false;

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    operations.add('read:$key');
    return values[key];
  }

  @override
  Future<void> write({
    required String key,
    required String? value,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    operations.add('write:$key');
    if (key == 'auth_installation' && failBinding) {
      throw StateError('Storage unavailable');
    }
    if (value == null) {
      values.remove(key);
    } else {
      values[key] = value;
    }
  }

  @override
  Future<void> delete({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    operations.add('delete:$key');
    if (failDelete) throw StateError('Storage unavailable');
    values.remove(key);
  }
}

class _TokenStore extends SecureTokenStore {
  String? token = 'test-token';
  int deletions = 0;
  bool failDelete = false;

  @override
  Future<String?> getToken() async => token;

  @override
  Future<void> deleteToken() async {
    if (failDelete) throw StateError('Storage unavailable');
    deletions++;
    token = null;
  }
}

class _ApiClient extends ApiClient {
  int logoutCalls = 0, restoreCalls = 0;
  String account = 'test-account';
  String? receivedToken;
  String? receivedEndpoint;
  Map<String, dynamic>? receivedBody;
  Object? logoutFailure;
  Map<String, dynamic> logoutResponse = {'success': true, 'data': null};
  Completer<void>? logoutGate;
  Completer<void>? restoreGate;

  @override
  Future<Map<String, dynamic>> post(
    String endpoint, {
    Map<String, dynamic>? data,
    String? token,
  }) async {
    receivedEndpoint = endpoint;
    logoutCalls++;
    receivedToken = token;
    receivedBody = data;
    await logoutGate?.future;
    final failure = logoutFailure;
    if (failure != null) throw failure;
    return logoutResponse;
  }

  @override
  Future<Map<String, dynamic>> get(
    String endpoint, {
    required String token,
  }) async {
    restoreCalls++;
    await restoreGate?.future;
    return {
      'success': true,
      'data': {'id': account},
    };
  }
}

Future<SessionCubit> _openSettings(
  WidgetTester tester,
  _TokenStore store, {
  _ApiClient? api,
}) async {
  final session = SessionCubit(
    AuthRepository(api ?? _ApiClient(), tokenStore: store),
  );
  await session.restore();
  addTearDown(session.close);
  await tester.pumpWidget(
    BlocProvider.value(
      value: session,
      child: const MaterialApp(home: Scaffold(body: ProfileSettingsList())),
    ),
  );
  final logout = find.text('Log out');
  await tester.scrollUntilVisible(logout, 300);
  await tester.pumpAndSettle();
  await tester.tap(logout);
  await tester.pumpAndSettle();
  expect(find.text('Are you sure you want to log out?'), findsOneWidget);
  return session;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('installation-bound authentication', () {
    const channel = MethodChannel('hywork/installation');
    late String installation;
    late int nativeCalls;
    late bool nativeFailure;
    setUp(() {
      installation = 'installation-a';
      nativeCalls = 0;
      nativeFailure = false;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            expect(call.method, 'getInstallationId');
            nativeCalls++;
            if (nativeFailure) {
              throw PlatformException(code: 'installation_unavailable');
            }
            return installation;
          });
    });
    tearDown(() {
      debugDefaultTargetPlatformOverride = null;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });
    for (final platform in [TargetPlatform.iOS, TargetPlatform.android]) {
      test(
        'first launch on $platform removes an unbound token before session restoration',
        () async {
          debugDefaultTargetPlatformOverride = platform;
          final storage = _InstallationStorage({
            'auth_token': 'old-synthetic-token',
            'unrelated': 'kept',
          });
          final api = _ApiClient();
          final session = SessionCubit(
            AuthRepository(api, tokenStore: SecureTokenStore(storage: storage)),
          );
          addTearDown(session.close);
          await session.restore();
          expect(session.state.status, SessionStatus.unauthenticated);
          expect(storage.values['auth_token'], isNull);
          expect(storage.values['auth_installation'], installation);
          expect(storage.values['unrelated'], 'kept');
          expect(api.restoreCalls, 0);
        },
      );
      test(
        'reinstall on $platform clears a token belonging to the previous installation',
        () async {
          debugDefaultTargetPlatformOverride = platform;
          final storage = _InstallationStorage({
            'auth_token': 'old-synthetic-token',
            'auth_installation': 'previous-installation',
          });
          final session = SessionCubit(
            AuthRepository(
              _ApiClient(),
              tokenStore: SecureTokenStore(storage: storage),
            ),
          );
          addTearDown(session.close);
          await session.restore();
          expect(session.state.status, SessionStatus.unauthenticated);
          expect(storage.values['auth_token'], isNull);
          expect(storage.values['auth_installation'], installation);
        },
      );
      test(
        'login then normal restart on $platform preserves the token and validates it with the backend',
        () async {
          debugDefaultTargetPlatformOverride = platform;
          final storage = _InstallationStorage({});
          await SecureTokenStore(storage: storage)
              .saveToken('new-synthetic-token');
          final api = _ApiClient();
          final restarted = SessionCubit(
            AuthRepository(api, tokenStore: SecureTokenStore(storage: storage)),
          );
          addTearDown(restarted.close);
          await restarted.restore();
          expect(restarted.state.status, SessionStatus.authenticated);
          expect(storage.values['auth_token'], 'new-synthetic-token');
          expect(
            storage.operations.where((op) => op == 'delete:auth_token'),
            hasLength(1),
          );
          expect(api.restoreCalls, 1);
        },
      );
    }
    test('installation identity failure blocks restoration and can be retried safely', () async {
      final storage = _InstallationStorage({
        'auth_token': 'old-synthetic-token',
      });
      nativeFailure = true;
      final api = _ApiClient();
      final session = SessionCubit(
        AuthRepository(api, tokenStore: SecureTokenStore(storage: storage)),
      );
      addTearDown(session.close);
      await session.restore();
      expect(session.state.status, SessionStatus.failure);
      expect(storage.values['auth_token'], 'old-synthetic-token');
      expect(api.restoreCalls, 0);
      nativeFailure = false;
      await session.restore();
      expect(session.state.status, SessionStatus.unauthenticated);
      expect(storage.values['auth_token'], isNull);
      expect(nativeCalls, 2);
    });
    test(
      'failed stale-token deletion cannot mark the installation initialized',
      () async {
        final storage = _InstallationStorage({
          'auth_token': 'old-synthetic-token',
        })..failDelete = true;
        final store = SecureTokenStore(storage: storage);
        await expectLater(store.getToken(), throwsStateError);
        expect(storage.values['auth_installation'], isNull);
        expect(storage.values['auth_token'], 'old-synthetic-token');
        storage.failDelete = false;
        expect(await store.getToken(), isNull);
        expect(storage.values['auth_installation'], installation);
      },
    );
    test('failed installation binding can be retried without restoring the old token', () async {
      final storage = _InstallationStorage({
        'auth_token': 'old-synthetic-token',
      })..failBinding = true;
      final store = SecureTokenStore(storage: storage);
      await expectLater(store.getToken(), throwsStateError);
      expect(storage.values['auth_token'], isNull);
      storage.failBinding = false;
      await store.saveToken('new-synthetic-token');
      expect(await store.getToken(), 'new-synthetic-token');
    });
    test('overlapping token operations initialize once and cannot erase the new login', () async {
      final storage = _InstallationStorage({
        'auth_token': 'old-synthetic-token',
      });
      final store = SecureTokenStore(storage: storage);
      final reading = store.getToken();
      final saving = store.saveToken('new-synthetic-token');
      await Future.wait([reading, saving]);
      expect(await store.getToken(), 'new-synthetic-token');
      expect(nativeCalls, 1);
      expect(
        storage.operations.where((op) => op == 'delete:auth_token'),
        hasLength(1),
      );
    });
  });

  testWidgets('cancel preserves the saved login', (tester) async {
    final store = _TokenStore();
    final session = await _openSettings(tester, store);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(store.deletions, 0);
    expect(session.state.status, SessionStatus.authenticated);
  });

  testWidgets('confirm removes the credential and ends the session', (
    tester,
  ) async {
    final store = _TokenStore();
    final api = _ApiClient();
    final session = await _openSettings(tester, store, api: api);
    await tester.tap(find.widgetWithText(FilledButton, 'Log out'));
    await tester.pumpAndSettle();
    expect(api.logoutCalls, 1);
    expect(api.receivedEndpoint, 'auth/logout');
    expect(api.receivedToken, 'test-token');
    expect(api.receivedBody, isNull);
    expect(store.token, isNull);
    expect(store.deletions, 1);
    expect(session.state.status, SessionStatus.unauthenticated);
    expect(session.state.userId, isNull);
  });

  testWidgets('storage failure keeps the session and allows retry', (
    tester,
  ) async {
    final store = _TokenStore()..failDelete = true;
    final session = await _openSettings(tester, store);
    await tester.tap(find.widgetWithText(FilledButton, 'Log out'));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Your server session has ended, but the saved login could not be removed. Please retry to finish logging out.',
      ),
      findsOneWidget,
    );
    expect(
      tester
          .widget<TextButton>(find.widgetWithText(TextButton, 'Cancel'))
          .onPressed,
      isNull,
    );
    expect(session.state.status, SessionStatus.authenticated);
    expect(store.token, isNotNull);
    store.failDelete = false;
    await tester.tap(find.widgetWithText(FilledButton, 'Log out'));
    await tester.pumpAndSettle();
    expect(store.token, isNull);
  });

  testWidgets('logout clears navigation and account state, preserving theme', (
    tester,
  ) async {
    final store = _TokenStore();
    final api = _ApiClient();
    late BuildContext accountContext;
    await tester.pumpWidget(
      AppProviders(
        apiClient: api,
        tokenStore: store,
        child: MaterialApp(
          home: Builder(
            builder: (context) {
              accountContext = context;
              context.read<PostLikesCubit>();
              return const Scaffold(body: Text('Root'));
            },
          ),
        ),
      ),
    );
    final session = accountContext.read<SessionCubit>();
    final likes = accountContext.read<PostLikesCubit>()..toggleLike('post-1');
    final theme = accountContext.read<ThemeCubit>();
    await session.restore();
    await tester.pumpAndSettle();
    Navigator.of(accountContext).push(
      MaterialPageRoute<void>(
        builder: (_) => const Scaffold(body: Text('Account route')),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Account route'), findsOneWidget);
    await session.logout();
    await tester.pumpAndSettle();
    expect(find.text('Account route'), findsNothing);
    expect(find.text('Root'), findsOneWidget);
    expect(likes.isClosed, isTrue);
    expect(accountContext.read<PostLikesCubit>().state, isEmpty);
    expect(accountContext.read<ThemeCubit>(), same(theme));
    store.token = 'second-test-token';
    api.account = 'second-account';
    await session.restore();
    await tester.pumpAndSettle();
    expect(session.state.userId, 'second-account');
    expect(accountContext.read<PostLikesCubit>().state, isEmpty);
    expect(accountContext.read<ThemeCubit>(), same(theme));
  });
  test('401 clears a session that is already invalid', () async {
    final store = _TokenStore();
    final api = _ApiClient()
      ..logoutFailure = DioException(
        requestOptions: RequestOptions(),
        response: Response(requestOptions: RequestOptions(), statusCode: 401),
        type: DioExceptionType.badResponse,
      );
    final session = SessionCubit(AuthRepository(api, tokenStore: store));
    await session.restore();
    await session.logout();
    expect(api.logoutCalls, 1);
    expect(store.token, isNull);
    expect(session.state.status, SessionStatus.unauthenticated);
    await session.close();
  });

  test('missing token never sends a Bearer request', () async {
    final store = _TokenStore()..token = null;
    final api = _ApiClient();
    final session = SessionCubit(AuthRepository(api, tokenStore: store));
    await session.logout();
    expect(api.logoutCalls, 0);
    expect(session.state.status, SessionStatus.unauthenticated);
    await session.close();
  });

  test('invalid stored credential is never sent', () async {
    final store = _TokenStore()..token = 'invalid\r\ncredential';
    final api = _ApiClient();
    final session = SessionCubit(AuthRepository(api, tokenStore: store));
    await session.logout();
    expect(api.logoutCalls, 0);
    expect(session.state.logoutError, isNotNull);
    expect(session.state.status, isNot(SessionStatus.unauthenticated));
    await session.close();
  });

  for (final failure in <Object>[
    TimeoutException('Test timeout'),
    DioException(
      requestOptions: RequestOptions(),
      type: DioExceptionType.connectionError,
    ),
    DioException(
      requestOptions: RequestOptions(),
      response: Response(requestOptions: RequestOptions(), statusCode: 503),
      type: DioExceptionType.badResponse,
    ),
  ]) {
    test(
      'uncertain ${failure.runtimeType} preserves login and allows retry',
      () async {
        final store = _TokenStore();
        final api = _ApiClient()..logoutFailure = failure;
        final session = SessionCubit(AuthRepository(api, tokenStore: store));
        await session.restore();
        await session.logout();
        expect(store.deletions, 0);
        expect(session.state.status, SessionStatus.authenticated);
        expect(session.state.logoutError, isNotNull);
        expect(session.state.isLoggingOut, isFalse);
        api.logoutFailure = null;
        await session.logout();
        expect(api.logoutCalls, 2);
        expect(store.token, isNull);
        await session.close();
      },
    );
  }

  test('a false success response cannot erase the token', () async {
    final store = _TokenStore();
    final api = _ApiClient()..logoutResponse = {'success': false};
    final session = SessionCubit(AuthRepository(api, tokenStore: store));
    await session.restore();
    await session.logout();
    expect(store.deletions, 0);
    expect(session.state.status, SessionStatus.authenticated);
    expect(session.state.logoutError, isNotNull);
    await session.close();
  });

  test(
    'local cleanup retry does not revoke twice or restore a revoked session',
    () async {
      final store = _TokenStore()..failDelete = true;
      final api = _ApiClient();
      final session = SessionCubit(AuthRepository(api, tokenStore: store));
      await session.restore();
      await session.logout();
      expect(session.state.logoutCleanupRequired, isTrue);
      await session.restore();
      expect(session.state.logoutCleanupRequired, isTrue);
      store.failDelete = false;
      await session.logout();
      expect(api.logoutCalls, 1);
      expect(store.token, isNull);
      await session.close();
    },
  );

  testWidgets(
    'pending logout disables both buttons and deduplicates requests',
    (tester) async {
      final store = _TokenStore();
      final gate = Completer<void>();
      final api = _ApiClient()..logoutGate = gate;
      final session = await _openSettings(tester, store, api: api);
      await tester.tap(find.widgetWithText(FilledButton, 'Log out'));
      await tester.pump();
      final duplicate = session.logout();
      await tester.pump();
      expect(api.logoutCalls, 1);
      expect(store.token, isNotNull);
      expect(find.text('Logging out…'), findsOneWidget);
      expect(
        tester
            .widget<TextButton>(find.widgetWithText(TextButton, 'Cancel'))
            .onPressed,
        isNull,
      );
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Logging out…'),
            )
            .onPressed,
        isNull,
      );
      gate.complete();
      await duplicate;
      await tester.pumpAndSettle();
      expect(api.logoutCalls, 1);
      expect(store.token, isNull);
    },
  );

  test(
    'fresh app session after logout does not restore authentication',
    () async {
      final store = _TokenStore();
      final api = _ApiClient();
      final first = SessionCubit(AuthRepository(api, tokenStore: store));
      await first.restore();
      await first.logout();
      await first.close();
      final restarted = SessionCubit(AuthRepository(api, tokenStore: store));
      await restarted.restore();
      expect(restarted.state.status, SessionStatus.unauthenticated);
      expect(restarted.state.userId, isNull);
      await restarted.close();
    },
  );

  test(
    'chat and team chat are detached without discarding their owner data',
    () {
      final chat = InMemoryChatRepository.empty();
      final teams = InMemoryTeamsRepository();
      for (final repo in [chat, teams.chats]) {
        repo.useAccount('account-a');
        repo.openConversation(
          ChatConversation(
            id: 'private',
            name: 'Private A',
            lastMessage: 'Draft A',
            lastMessageAt: DateTime(2026),
          ),
        );
        repo.useAccount(null);
        expect(repo.conversations, isEmpty);
        repo.useAccount('account-b');
        expect(repo.conversations, isEmpty);
        repo.useAccount('account-a');
        expect(repo.conversations.single.name, 'Private A');
      }
    },
  );

  test(
    'logout waits for pending restoration and ends unauthenticated',
    () async {
      final store = _TokenStore();
      final gate = Completer<void>();
      final api = _ApiClient()..restoreGate = gate;
      final session = SessionCubit(AuthRepository(api, tokenStore: store));
      final restoring = session.restore();
      final loggingOut = session.logout();
      expect(api.logoutCalls, 0);
      gate.complete();
      await restoring;
      await loggingOut;
      expect(api.logoutCalls, 1);
      expect(session.state.status, SessionStatus.unauthenticated);
      expect(store.token, isNull);
      await session.close();
    },
  );

  test(
    'team work is hidden from the next account and preserved for its owner',
    () {
      final teams = InMemoryTeamsRepository()..useAccount('account-a');
      teams.addPaid(
        TeamWorkspace(
          id: 'a-team',
          name: 'Private A',
          description: '',
          owner: const PostSeller(id: 'a', name: 'A', avatarAsset: ''),
          request: TeamRequest(
            providers: [],
            status: TeamRequestStatus.paid,
            paymentId: 'demo-a',
          ),
          createdAt: DateTime(2026),
          providers: [],
        ),
      );
      teams.useAccount(null);
      expect(teams.teams, isEmpty);
      teams.useAccount('account-b');
      expect(teams.teams, isEmpty);
      teams.useAccount('account-a');
      expect(teams.teams.single.name, 'Private A');
    },
  );

  testWidgets(
    'app opens existing LoginScreen and cannot pop to authenticated routes',
    (tester) async {
      final store = _TokenStore();
      final api = _ApiClient();
      await tester.pumpWidget(
        ResponsiveConfig(
          child: MyApp(apiClient: api, tokenStore: store),
        ),
      );
      final splashContext = tester.element(find.byType(SplashScreen));
      final session = splashContext.read<SessionCubit>();
      await session.restore();
      Navigator.of(splashContext).push(
        MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: Text('Authenticated page')),
        ),
      );
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      expect(find.text('Authenticated page'), findsOneWidget);
      await session.logout();
      await tester.pumpAndSettle();
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.text('Authenticated page'), findsNothing);
      final loginContext = tester.element(find.byType(LoginScreen));
      expect(Navigator.of(loginContext).canPop(), isFalse);
      expect(await Navigator.of(loginContext).maybePop(), isFalse);
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(store.token, isNull);
    },
  );

  testWidgets('pending logout can finish after the dialog is disposed', (
    tester,
  ) async {
    final store = _TokenStore();
    final gate = Completer<void>();
    final api = _ApiClient()..logoutGate = gate;
    final session = await _openSettings(tester, store, api: api);
    final logout = session.logout();
    await tester.pump();
    await tester.pumpWidget(const SizedBox.shrink());
    gate.complete();
    await logout;
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(session.state.status, SessionStatus.unauthenticated);
  });

  final localApi = Uri.tryParse(AppConfig.apiBaseUrl);
  test('real Dio sends authenticated POST without a request body', () async {
    final server = await HttpServer.bind(
      InternetAddress.loopbackIPv4,
      localApi!.port,
    );
    addTearDown(() => server.close(force: true));
    final received = Completer<void>();
    server.listen((request) async {
      try {
        expect(request.method, 'POST');
        expect(request.uri.path, '/api/auth/logout');
        expect(
          request.headers.value('Authorization'),
          'Bearer test-transport-token',
        );
        expect(request.headers.value('X-Client'), 'mobile');
        expect(await utf8.decoder.bind(request).join(), isEmpty);
        request.response.headers.contentType = ContentType.json;
        request.response.write(jsonEncode({'success': true, 'data': null}));
        await request.response.close();
        received.complete();
      } catch (error, stack) {
        received.completeError(error, stack);
      }
    });
    final response = await HttpOverrides.runWithHttpOverrides(
      () => ApiClient().post('auth/logout', token: 'test-transport-token'),
      _RealHttpOverrides(),
    );
    await received.future;
    expect(response['success'], isTrue);
  }, skip: localApi?.host != '127.0.0.1');
}
