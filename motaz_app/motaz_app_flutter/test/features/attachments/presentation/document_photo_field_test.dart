import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motaz_app_flutter/features/attachments/presentation/document_photo_field.dart';

void main() {
  testWidgets(
    'document photo field replaces capture button with selected photo preview',
    (tester) async {
      var captureCalls = 0;
      var removeCalls = 0;
      const label = 'Add invoice photo';
      const selectedPath = r'C:\fastika\captured-invoice-photo.png';

      Widget buildField(String? path) {
        return MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: DocumentPhotoField(
                label: label,
                localPath: path,
                onCapture: () {
                  captureCalls += 1;
                },
                onRemove: () {
                  removeCalls += 1;
                },
              ),
            ),
          ),
        );
      }

      await tester.pumpWidget(buildField(null));

      expect(find.text(label), findsOneWidget);
      expect(find.byType(Image), findsNothing);

      await tester.tap(find.text(label));
      await tester.pump();

      expect(captureCalls, 1);

      await tester.pumpWidget(buildField(selectedPath));
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text(label), findsNothing);
      expect(find.byType(Image), findsOneWidget);

      final removeButton = tester.widget<IconButton>(find.byType(IconButton));
      removeButton.onPressed!();
      await tester.pump();

      expect(removeCalls, 1);
      expect(tester.takeException(), isNull);
    },
  );
}
