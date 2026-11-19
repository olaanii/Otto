import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otto_frontend/app.dart';

void main() {
  testWidgets('OttoApp smoke test renders authenticated or login UI', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: OttoApp(),
      ),
    );
    await tester.pump();
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
