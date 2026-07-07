import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ruralmap/main.dart';
import 'package:ruralmap/screens/register_site_screen.dart';

void main() {
  testWidgets('app shows dashboard and profile navigation', (tester) async {
    await tester.pumpWidget(const GeoRuraApp());
    await tester.pumpAndSettle();

    expect(find.text('Dashboard Overview'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
  });

  testWidgets('registration wizard opens on the first step', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: RegisterSiteScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Choose Site Type'), findsOneWidget);
  });
}
