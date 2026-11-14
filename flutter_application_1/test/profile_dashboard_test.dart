import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_application_1/screens/account_settings_screen.dart';
import 'package:flutter_application_1/screens/customer_home_screen.dart';
import 'package:flutter_application_1/screens/profile_placeholder_screen.dart';
import 'package:flutter_application_1/widgets/profile/profile_header.dart';

void main() {
  testWidgets('profile shows customer details and dashboard options', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    await tester.pumpWidget(
      const MaterialApp(
        home: CustomerHomeScreen(
          customerName: 'Nadia Hassan',
          customerEmail: 'nadia@example.com',
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();

    expect(find.text('My Account'), findsOneWidget);
    expect(find.byType(ProfileHeader), findsOneWidget);
    expect(find.text('Nadia Hassan'), findsOneWidget);
    expect(find.text('nadia@example.com'), findsOneWidget);
    expect(find.text('Personal Information'), findsOneWidget);
    expect(find.text('My Orders'), findsOneWidget);
    expect(find.text('My Investments'), findsOneWidget);
    expect(find.text('My Favorites'), findsOneWidget);
    expect(find.text('Account Settings'), findsOneWidget);
    expect(find.text('Help and Support'), findsOneWidget);
    expect(find.text('About Khan'), findsOneWidget);
    expect(find.text('Privacy Policy'), findsOneWidget);
    expect(find.text('Terms and Conditions'), findsOneWidget);
    expect(find.text('Log out of Khan'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('personal information placeholder uses signed-in data', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    await tester.pumpWidget(
      const MaterialApp(
        home: CustomerHomeScreen(
          customerName: 'Nadia Hassan',
          customerEmail: 'nadia@example.com',
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();

    final personalInfo = find.text('Personal Information');
    await tester.ensureVisible(personalInfo);
    await tester.tap(personalInfo);
    await tester.pumpAndSettle();

    expect(find.byType(ProfilePlaceholderScreen), findsOneWidget);
    expect(find.text('Nadia Hassan'), findsOneWidget);
    expect(find.text('nadia@example.com'), findsOneWidget);
    expect(find.text('Phone number'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('account settings preferences are local UI controls', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: AccountSettingsScreen()));

    expect(find.text('Account Settings'), findsOneWidget);
    expect(find.byType(SwitchListTile), findsNWidgets(2));
    expect(
      find.text('These preview preferences are kept on this screen only.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
