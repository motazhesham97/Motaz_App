import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_idp_server/providers/email.dart';

import '../generated/owner_account.dart';

/// By extending [EmailIdpBaseEndpoint], the email identity provider endpoints
/// are made available on the server and enable the corresponding sign-in widget
/// on the client.
class EmailIdpEndpoint extends EmailIdpBaseEndpoint {
  @override
  Future<UuidValue> startRegistration(
    Session session, {
    required String email,
  }) async {
    if (await OwnerAccount.db.count(session) > 0) {
      throw StateError('OWNER_ALREADY_EXISTS');
    }

    return super.startRegistration(session, email: email);
  }
}
