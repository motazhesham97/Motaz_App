import 'package:serverpod_client/serverpod_client.dart';

class OwnerAlreadyExistsException implements SerializableException {
  final String message;

  OwnerAlreadyExistsException({this.message = 'OWNER_ALREADY_EXISTS'});

  factory OwnerAlreadyExistsException.fromJson(Map<String, dynamic> json) {
    return OwnerAlreadyExistsException(
      message: json['message'] as String? ?? 'OWNER_ALREADY_EXISTS',
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'motaz_app_server.OwnerAlreadyExistsException',
      'message': message,
    };
  }

  Map<String, dynamic> toJsonForProtocol() => toJson();

  @override
  String toString() => 'OwnerAlreadyExistsException(message: $message)';
}