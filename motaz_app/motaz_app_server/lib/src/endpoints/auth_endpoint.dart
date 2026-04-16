import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_core_server/serverpod_auth_core_server.dart';
import 'package:serverpod_auth_idp_server/providers/email.dart';

import '../generated/owner_account.dart';

class OwnerAlreadyExistsException implements SerializableException {
  @override
  Map<String, dynamic> toJson() => {
    '__className__': 'motaz_app_server.OwnerAlreadyExistsException',
    'message': 'OWNER_ALREADY_EXISTS',
  };

  Map<String, dynamic> toJsonForProtocol() => toJson();

  @override
  String toString() => 'OwnerAlreadyExistsException: OWNER_ALREADY_EXISTS';
}

class AuthEndpoint extends Endpoint {
  /// Returns true if an owner account exists in the system.
  /// Uses the owner_account table as the single source of truth.
  Future<bool> hasOwnerAccount(Session session) async {
    final count = await OwnerAccount.db.count(session);
    return count > 0;
  }

  /// Registers the owner account.
  /// Throws OwnerAlreadyExistsException if an owner already exists.
  /// Returns true on successful registration.
  Future<bool> registerOwner(
    Session session, {
    required String email,
    required String password,
  }) async {
    final emailIdp = AuthServices.getIdentityProvider<EmailIdp>();

    try {
      await session.db.transaction((transaction) async {
        session.log('registerOwner: checking existing owner for $email');

        final ownerCount = await OwnerAccount.db.count(
          session,
          transaction: transaction,
        );
        if (ownerCount > 0) {
          throw OwnerAlreadyExistsException();
        }

        session.log('registerOwner: creating auth user for $email');
        final authUser = await AuthServices.instance.authUsers.create(
          session,
          transaction: transaction,
        );

        session.log('registerOwner: creating email authentication for $email');
        await emailIdp.admin.createEmailAuthentication(
          session,
          authUserId: authUser.id,
          email: email,
          password: password,
          transaction: transaction,
        );

        session.log('registerOwner: creating user profile for $email');
        await AuthServices.instance.userProfiles.createUserProfile(
          session,
          authUser.id,
          UserProfileData(email: email),
          transaction: transaction,
        );

        session.log('registerOwner: creating owner row for $email');
        await OwnerAccount.db.insertRow(
          session,
          OwnerAccount(
            authUserId: authUser.id,
            createdAt: DateTime.now().toUtc(),
          ),
          transaction: transaction,
        );
      });
    } catch (error, stackTrace) {
      session.log('registerOwner failed for $email: $error\n$stackTrace');
      rethrow;
    }

    return true;
  }
}
