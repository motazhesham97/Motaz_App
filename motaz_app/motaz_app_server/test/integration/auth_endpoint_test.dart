import 'package:serverpod_auth_core_server/serverpod_auth_core_server.dart';
import 'package:serverpod_auth_idp_server/providers/email.dart';
import 'package:test/test.dart';

import 'test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('Given Auth endpoint', (sessionBuilder, endpoints) {
    setUpAll(() {
      AuthServices.set(
        tokenManagerBuilders: [JwtConfigFromPasswords()],
        identityProviderBuilders: [
          EmailIdpConfigFromPasswords(
            sendRegistrationVerificationCode:
                (
                  _, {
                  required String email,
                  required accountRequestId,
                  required String verificationCode,
                  required transaction,
                }) {},
            sendPasswordResetVerificationCode:
                (
                  _, {
                  required String email,
                  required passwordResetRequestId,
                  required String verificationCode,
                  required transaction,
                }) {},
          ),
        ],
      );
    });

    test(
      'when registering the first owner then account is created and login works',
      () async {
        final email = 'owner@example.com';
        final password = 'password123';

        expect(await endpoints.auth.hasOwnerAccount(sessionBuilder), isFalse);

        final registered = await endpoints.auth.registerOwner(
          sessionBuilder,
          email: email,
          password: password,
        );

        expect(registered, isTrue);
        expect(await endpoints.auth.hasOwnerAccount(sessionBuilder), isTrue);

        final authSuccess = await endpoints.emailIdp.login(
          sessionBuilder,
          email: email,
          password: password,
        );
        final authSuccessJson = authSuccess.toJson();

        expect(authSuccessJson, isNotEmpty);
      },
    );

    test(
      'when owner already exists then a second registration is rejected',
      () async {
        await endpoints.auth.registerOwner(
          sessionBuilder,
          email: 'owner@example.com',
          password: 'password123',
        );

        await expectLater(
          () => endpoints.auth.registerOwner(
            sessionBuilder,
            email: 'second@example.com',
            password: 'password123',
          ),
          throwsA(
            predicate(
              (error) => error.toString().contains('OWNER_ALREADY_EXISTS'),
            ),
          ),
        );
      },
    );
  });
}
