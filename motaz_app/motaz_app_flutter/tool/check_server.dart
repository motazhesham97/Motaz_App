import 'package:motaz_app_client/motaz_app_client.dart';

Future<void> main(List<String> args) async {
  final host = args.isNotEmpty ? args.first : 'http://192.168.8.142:8080';
  final client = Client(host);
  final email = args.length > 1 ? args[1] : 'owner_test@example.com';
  final password = args.length > 2 ? args[2] : 'password123';

  try {
    final ping = await client.health.ping();
    print('health.ping => $ping');
  } catch (error) {
    print('health.ping failed => $error');
  }

  try {
    final hasOwner = await client.auth.hasOwnerAccount();
    print('auth.hasOwnerAccount => $hasOwner');
  } catch (error) {
    print('auth.hasOwnerAccount failed => $error');
  }

  try {
    final requestId = await client.emailIdp.startRegistration(email: email);
    print('emailIdp.startRegistration => $requestId');
  } catch (error, stackTrace) {
    print('emailIdp.startRegistration failed => $error');
    print(stackTrace);
  }

  try {
    final registered = await client.auth.registerOwner(
      email: email,
      password: password,
    );
    print('auth.registerOwner => $registered');
  } catch (error, stackTrace) {
    print('auth.registerOwner failed => $error');
    print(stackTrace);
  }
}
