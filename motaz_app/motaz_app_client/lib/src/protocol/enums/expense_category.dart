/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:serverpod_client/serverpod_client.dart' as _i1;

enum ExpenseCategory implements _i1.SerializableModel {
  OWNER_DRAW,
  PARTNER_DRAW,
  MARGIN_DRAW,
  OPERATIONAL,
  PRODUCTION;

  static ExpenseCategory fromJson(String name) {
    switch (name) {
      case 'OWNER_DRAW':
        return ExpenseCategory.OWNER_DRAW;
      case 'PARTNER_DRAW':
        return ExpenseCategory.PARTNER_DRAW;
      case 'MARGIN_DRAW':
        return ExpenseCategory.MARGIN_DRAW;
      case 'OPERATIONAL':
        return ExpenseCategory.OPERATIONAL;
      case 'PRODUCTION':
        return ExpenseCategory.PRODUCTION;
      default:
        throw ArgumentError(
          'Value "$name" cannot be converted to "ExpenseCategory"',
        );
    }
  }

  @override
  String toJson() => name;

  @override
  String toString() => name;
}
