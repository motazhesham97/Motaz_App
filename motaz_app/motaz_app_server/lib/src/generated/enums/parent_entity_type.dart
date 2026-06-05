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
import 'package:serverpod/serverpod.dart' as _i1;

enum ParentEntityType implements _i1.SerializableModel {
  SALES_INVOICE,
  SALES_INVOICE_LINE,
  RECEIPT,
  RECEIPT_ALLOCATION,
  PRODUCT,
  CLIENT,
  EXPENSE,
  SALES_RETURN,
  SALES_RETURN_LINE,
  ATTACHMENT_METADATA,
  MONTHLY_DISTRIBUTION,
  PARTY_ADJUSTMENT,
  BENEFICIARY,
  FREE_SAMPLE,
  FREE_SAMPLE_LINE;

  static ParentEntityType fromJson(String name) {
    switch (name) {
      case 'SALES_INVOICE':
        return ParentEntityType.SALES_INVOICE;
      case 'SALES_INVOICE_LINE':
        return ParentEntityType.SALES_INVOICE_LINE;
      case 'RECEIPT':
        return ParentEntityType.RECEIPT;
      case 'RECEIPT_ALLOCATION':
        return ParentEntityType.RECEIPT_ALLOCATION;
      case 'PRODUCT':
        return ParentEntityType.PRODUCT;
      case 'CLIENT':
        return ParentEntityType.CLIENT;
      case 'EXPENSE':
        return ParentEntityType.EXPENSE;
      case 'SALES_RETURN':
        return ParentEntityType.SALES_RETURN;
      case 'SALES_RETURN_LINE':
        return ParentEntityType.SALES_RETURN_LINE;
      case 'ATTACHMENT_METADATA':
        return ParentEntityType.ATTACHMENT_METADATA;
      case 'MONTHLY_DISTRIBUTION':
        return ParentEntityType.MONTHLY_DISTRIBUTION;
      case 'PARTY_ADJUSTMENT':
        return ParentEntityType.PARTY_ADJUSTMENT;
      case 'BENEFICIARY':
        return ParentEntityType.BENEFICIARY;
      case 'FREE_SAMPLE':
        return ParentEntityType.FREE_SAMPLE;
      case 'FREE_SAMPLE_LINE':
        return ParentEntityType.FREE_SAMPLE_LINE;
      default:
        throw ArgumentError(
          'Value "$name" cannot be converted to "ParentEntityType"',
        );
    }
  }

  @override
  String toJson() => name;

  @override
  String toString() => name;
}
