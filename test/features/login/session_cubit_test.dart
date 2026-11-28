import 'package:flutter_test/flutter_test.dart';
import 'package:hywork/core/network/api_client/api_client.dart';
import 'package:hywork/core/security/secure_token/secure_token.dart';
import 'package:hywork/features/login/data/auth_repo.dart';
import 'package:hywork/features/login/presentation/cubit/session_cubit.dart';

class _Tokens extends SecureTokenStore {
  @override
  Future<String?> getToken() async => 'token';

  @override
  Future<void> deleteToken() async {}
}

class _Auth extends AuthRepository {
  _Auth({this.userId = '0193f0a1-2b3c-7d4e-8f50-6a7b8c9d0e1f'})
    : super(ApiClient(), tokenStore: _Tokens());

  final String? userId;

  @override
  Future<String?> restoreSession() async => userId;
}

void main() {
  test(
    'successful restore bumps accountRevision so account DI rebinds',
    () async {
      final cubit = SessionCubit(_Auth());
      expect(cubit.state.accountRevision, 0);
      await cubit.restore();
      expect(cubit.state.status, SessionStatus.authenticated);
      expect(cubit.state.userId, '0193f0a1-2b3c-7d4e-8f50-6a7b8c9d0e1f');
      expect(cubit.state.accountRevision, 1);
      await cubit.close();
    },
  );

  test('unauthenticated restore keeps accountRevision', () async {
    final cubit = SessionCubit(_Auth(userId: null));
    await cubit.restore();
    expect(cubit.state.status, SessionStatus.unauthenticated);
    expect(cubit.state.accountRevision, 0);
    await cubit.close();
  });
}
