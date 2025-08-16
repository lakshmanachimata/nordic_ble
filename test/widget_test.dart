// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nordic_ble/main.dart';

void main() {
  testWidgets('BLE Scanner app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that the app title is displayed
    expect(find.text('Evolv28'), findsOneWidget);
    
    // Verify that the scan button is present
    expect(find.text('Start Scan'), findsOneWidget);
    
    // Verify that the scan button has the correct icon
    expect(find.byIcon(Icons.search), findsOneWidget);
    
    // Verify that the app bar is present with the correct title
    expect(find.byType(AppBar), findsOneWidget);
  });
}
