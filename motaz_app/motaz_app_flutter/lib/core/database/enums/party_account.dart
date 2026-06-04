// ignore_for_file: constant_identifier_names

import 'package:drift/drift.dart';

enum PartyAccount {
  OWNER,
  PARTNER,
  MARGIN,
}

extension PartyAccountLabels on PartyAccount {
  String get displayName {
    return switch (this) {
      PartyAccount.OWNER => 'امي',
      PartyAccount.PARTNER => 'معتز',
      PartyAccount.MARGIN => 'الهامش',
    };
  }

  String get balanceTitle => 'رصيد $displayName';

  String get routeKey {
    return switch (this) {
      PartyAccount.OWNER => 'owner',
      PartyAccount.PARTNER => 'partner',
      PartyAccount.MARGIN => 'margin',
    };
  }
}

PartyAccount partyAccountFromRouteKey(String value) {
  return switch (value.toLowerCase()) {
    'partner' => PartyAccount.PARTNER,
    'margin' => PartyAccount.MARGIN,
    _ => PartyAccount.OWNER,
  };
}

class PartyAccountConverter extends TypeConverter<PartyAccount, int> {
  const PartyAccountConverter();

  @override
  PartyAccount fromSql(int fromDb) {
    if (fromDb >= 0 && fromDb < PartyAccount.values.length) {
      return PartyAccount.values[fromDb];
    }
    assert(false, 'Unknown PartyAccount database value: $fromDb');
    return PartyAccount.OWNER;
  }

  @override
  int toSql(PartyAccount value) {
    return value.index;
  }
}
