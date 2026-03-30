import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_core_server/serverpod_auth_core_server.dart';
import 'package:serverpod_auth_idp_server/providers/email.dart';

class AuthEndpoint extends Endpoint {
  Future<bool> hasOwnerAccount(Session session) async {
    final emailIdp = AuthServices.getIdentityProvider<EmailIdp>();
    return emailIdp.hasAccount(session);
  }

  Future<bool> registerOwner(
    Session session, {
    required String email,
    required String password,
  }) async {
    final emailIdp = AuthServices.getIdentityProvider<EmailIdp>();
    if (await emailIdp.hasAccount(session)) {
      throw StateError('OWNER_ALREADY_EXISTS');
    }

    final authUser = await AuthServices.instance.authUsers.create(session);
    await AuthServices.instance.userProfiles.createUserProfile(
      session,
      authUser.id,
      UserProfileData(email: email),
    );
    await emailIdp.admin.createEmailAuthentication(
      session,
      authUserId: authUser.id,
      email: email,
      password: password,
    );

    return true;
  }
}
