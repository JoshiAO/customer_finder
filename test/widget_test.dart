import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kenea_customers/main.dart';
import 'package:kenea_customers/pages/launch_screen.dart';

void main() {
  testWidgets('App launches and shows branded launch screen', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('KENEA.RDSI Project'), findsOneWidget);
  });

  testWidgets('Launch screen triggers onDone callback after delay', (WidgetTester tester) async {
    var didCallOnDone = false;

    await tester.pumpWidget(
      MaterialApp(
        home: LaunchScreen(
          onDone: () {
            didCallOnDone = true;
          },
        ),
      ),
    );

    expect(didCallOnDone, isFalse);
    expect(find.text('KENEA.RDSI Project'), findsOneWidget);

    // LaunchScreen uses a 2800ms timer before calling onDone.
    await tester.pump(const Duration(milliseconds: 2900));
    await tester.pump();

    expect(didCallOnDone, isTrue);
  });
}
