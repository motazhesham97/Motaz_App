import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_core_server/serverpod_auth_core_server.dart';
import 'package:serverpod_auth_idp_server/providers/email.dart';

import '../generated/owner_account.dart';

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
    await session.db.transaction(
      (transaction) async {
        if (await OwnerAccount.db.count(session, transaction: transaction) > 0) {
          throw StateError('OWNER_ALREADY_EXISTS');
        }

        final authUser = await AuthServices.instance.authUsers.create(
          session,
          transaction: transaction,
        );
        await AuthServices.instance.userProfiles.createUserProfile(
          session,
          authUser.id,
          UserProfileData(email: email),
          transaction: transaction,
        );

        try {
          await session.db.unsafeExecute(
            'INSERT INTO "owner_account" ("singletonKey", "authUserId", "createdAt") '
            'VALUES (@singletonKey, @authUserId, @createdAt)',
            transaction: transaction,
            parameters: QueryParameters.named({
              'singletonKey': 1,
              'authUserId': authUser.id,
              'createdAt': DateTime.now().toUtc(),
            }),
          );
        } on DatabaseQueryException catch (error) {
          if (error.code == '23505') {
            throw StateError('OWNER_ALREADY_EXISTS');
          }
          rethrow;
        }

        await emailIdp.admin.createEmailAuthentication(
          session,
          authUserId: authUser.id,
          email: email,
          password: password,
          transaction: transaction,
        );
      },
      settings: const TransactionSettings(
        isolationLevel: IsolationLevel.serializable,
      ),
    );

    return true;
  }
}
