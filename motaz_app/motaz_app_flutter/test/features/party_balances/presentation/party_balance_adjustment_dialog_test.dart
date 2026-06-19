import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motaz_app_flutter/core/database/enums/party_account.dart';
import 'package:motaz_app_flutter/features/party_balances/application/party_balance_providers.dart';
import 'package:motaz_app_flutter/features/party_balances/presentation/party_balance_detail_screen.dart';

void main() {
  testWidgets(
    'party balance add amount dialog closes safely after cancel',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 720));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            partyBalanceProvider(
              PartyAccount.OWNER,
            ).overrideWith((ref) async => 0),
            partyBalanceTransactionsProvider(
              PartyAccount.OWNER,
            ).overrideWith((ref) async => const []),
          ],
          child: const MaterialApp(
            home: Directionality(
              textDirection: TextDirection.rtl,
              child: PartyBalanceDetailScreen(party: PartyAccount.OWNER),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.add_rounded));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);

      await tester.tap(find.byType(TextField).first);
      await tester.enterText(find.byType(TextField).first, '1000');
      await tester.pump();

      await tester.tap(find.byType(TextButton).first);
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1));
    },
  );
}
