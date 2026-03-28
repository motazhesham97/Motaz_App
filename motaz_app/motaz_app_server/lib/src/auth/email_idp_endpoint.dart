import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_core_server/serverpod_auth_core_server.dart';
import 'package:serverpod_auth_idp_server/providers/email.dart';

class EmailIdpEndpoint extends EmailIdpBaseEndpoint {
  Future<AuthSuccess> register(
    Session session, {
    required String email,
    required String password,
  }) async {
    final accountExists = await hasAccount(session);
    if (accountExists) {
      throw Exception(
        'حساب موجود بالفعل. لا يمكن إنشاء أكثر من حساب واحد.',
      );
    }

    final authUser = await AuthServices.instance.authUsers.create(session);

    await emailIdp.admin.createEmailAuthentication(
      session,
      authUserId: authUser.id,
      email: email,
      password: password,
    );

    await AuthServices.instance.userProfiles.createUserProfile(
      session,
      authUser.id,
      UserProfileData(email: email),
    );

    return AuthServices.instance.tokenManager.issueToken(
      session,
      authUserId: authUser.id,
      method: EmailIdp.method,
      scopes: authUser.scopes,
    );
  }

  @override
  Future<UuidValue> startRegistration(
    Session session, {
    required String email,
  }) async {
    final accountExists = await hasAccount(session);
    if (accountExists) {
      throw Exception(
        'حساب موجود بالفعل. لا يمكن إنشاء أكثر من حساب واحد.',
      );
    }
    return await super.startRegistration(session, email: email);
  }

  @override
  Future<AuthSuccess> finishRegistration(
    Session session, {
    required String registrationToken,
    required String password,
  }) async {
    final accountExists = await hasAccount(session);
    if (accountExists) {
      throw Exception(
        'حساب موجود بالفعل. لا يمكن إنشاء أكثر من حساب واحد.',
      );
    }

    return super.finishRegistration(
      session,
      registrationToken: registrationToken,
      password: password,
    );
  }
}
