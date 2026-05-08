import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:craftbloom/main.dart';

void main() {
  testWidgets('CraftBloom app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: CraftBloomApp()));
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
