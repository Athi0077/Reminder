import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:remindly/main.dart' as app;

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('End-to-End User Flow', (WidgetTester tester) async {
    const storage = FlutterSecureStorage();
    await storage.deleteAll();

    app.main();
    await tester.pumpAndSettle();

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final emailA = 'userA.$timestamp@example.com';
    final emailB = 'userB.$timestamp@example.com';
    final password = 'Password@123';

    Future<void> enterText(String hintTextToFind, String input) async {
      try {
        final field = find.byWidgetPredicate((widget) {
          if (widget is TextField) {
            return widget.decoration?.labelText == hintTextToFind || 
                   widget.decoration?.hintText == hintTextToFind;
          }
          return false;
        });
        await tester.enterText(field, input);
        await tester.pumpAndSettle();
      } catch (e) {
        print('FAILED TO ENTER TEXT "$hintTextToFind"');
        rethrow;
      }
    }

    Future<void> tapButton(String text) async {
      try {
        final btn = find.widgetWithText(ElevatedButton, text);
        if (btn.evaluate().isNotEmpty) {
          await tester.tap(btn);
        } else {
          await tester.tap(find.text(text).last);
        }
        await tester.pumpAndSettle();
      } catch (e) {
        final texts = find.byType(Text).evaluate().map((e) => (e.widget as Text).data).toList();
        print('FAILED TO TAP BUTTON "$text". TEXTS ON SCREEN: $texts');
        rethrow;
      }
    }

    Future<void> tapText(String text) async {
      try {
        await tester.tap(find.text(text).last);
        await tester.pumpAndSettle();
      } catch (e) {
        final texts = find.byType(Text).evaluate().map((e) => (e.widget as Text).data).toList();
        print('FAILED TO TAP "$text". TEXTS ON SCREEN: $texts');
        rethrow;
      }
    }

    Future<void> doLogout() async {
      await tapText('Profile');
      await tester.tap(find.byIcon(Icons.settings_outlined));
      await tester.pumpAndSettle();
      await tapText('Logout'); // Tap on settings list
      await tapButton('Logout'); // Tap on dialog confirmation
      await tester.pumpAndSettle(const Duration(seconds: 2));
    }

    Future<void> loginAs(String email, String password) async {
      if (find.text('I already have an account').evaluate().isNotEmpty) {
        await tapText('I already have an account');
      } else if (find.text('Sign In').evaluate().isNotEmpty) {
        await tapText('Sign In');
      }
      await enterText('Enter your email', email);
      await enterText('Enter your password', password);
      await tapButton('Sign In');
      await tester.pumpAndSettle(const Duration(seconds: 2));
    }

    // 1. Create Account A
    if (find.text('Get Started').evaluate().isNotEmpty) {
      await tapText('Get Started');
    } else {
      await tapText('Create Account');
    }
    
    await enterText('Enter your full name', 'User A');
    await enterText('Enter your email', emailA);
    await enterText('Enter your password', password);
    await enterText('Confirm your password', password);
    await tapButton('Create Account');
    
    // Wait for navigation to home
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // 6. Logout
    await doLogout();

    // 7. Create/Login Account B
    if (find.text('Create Account').evaluate().isNotEmpty) {
      await tapText('Create Account');
    } else {
      await tapText('Get Started');
    }
    await enterText('Enter your full name', 'User B');
    await enterText('Enter your email', emailB);
    await enterText('Enter your password', password);
    await enterText('Confirm your password', password);
    await tapButton('Create Account');
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // B Logout
    await doLogout();

    // 2. Login as Account A
    if (find.text('I already have an account').evaluate().isNotEmpty) {
      await tapText('I already have an account');
    } else if (find.text('Sign In').evaluate().isNotEmpty) {
      await tapText('Sign In');
    }
    await enterText('Enter your email', emailA);
    await enterText('Enter your password', password);
    await tapButton('Sign In'); // Usually Sign In instead of Login
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // 3. Search for Account B
    await tapText('Friends');
    await tapButton('Add Friend');
    await enterText('Search by name or email', emailB);
    await tester.pumpAndSettle(const Duration(seconds: 2)); // wait for debounce

    // 4. Send Friend Request
    await tester.tap(find.byIcon(Icons.person_add));
    await tester.pumpAndSettle();

    // 5. Verify "Request Sent"
    expect(find.text('Request Sent'), findsOneWidget);

    // 6. Logout
    await doLogout();

    // 7. Login Account B
    await loginAs(emailB, password);

    // 8. Verify notification badge & Open Notification Center
    await tester.tap(find.byIcon(Icons.notifications));
    await tester.pumpAndSettle();

    // 10. Verify Friend Request
    expect(find.text('New Friend Request'), findsOneWidget);

    // 11. Open Friends -> Requests
    await tester.tap(find.byIcon(Icons.arrow_back)); // back from notifications
    await tester.pumpAndSettle();
    
    await tester.tap(find.text('Friends'));
    await tester.pumpAndSettle();
    
    await tester.tap(find.text('Requests'));
    await tester.pumpAndSettle();

    // 12. Accept Friend Request
    await tapButton('Accept');
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // 13. Verify User A appears in My Friends
    await tester.tap(find.text('My Friends'));
    await tester.pumpAndSettle();
    expect(find.text('User A'), findsWidgets);

    // 14. Logout
    await doLogout();

    // 15. Login as User A
    await loginAs(emailA, password);

    // 16. Verify User B appears in My Friends
    await tester.tap(find.text('Friends'));
    await tester.pumpAndSettle();
    expect(find.text('User B'), findsWidgets);

    // 17. Create an Event/Reminder
    await tester.tap(find.text('Calendar'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    await enterText('e.g. Project submission', 'Integration Test Event');
    await enterText('Add more details...', 'This is an automated test event');
    await tapButton('Create Reminder');
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // 18. Share it with User B
    // Need to find the event first
    await tester.tap(find.text('Integration Test Event').last);
    await tester.pumpAndSettle();
    
    await tapButton('Share');
    await tester.pumpAndSettle();

    await tester.tap(find.text('User B').last);
    await tester.pumpAndSettle();
    
    await tapButton('Confirm Share');
    await tester.pumpAndSettle(const Duration(seconds: 2));
    
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    // 19. Logout
    await doLogout();

    // 20. Login as User B
    await loginAs(emailB, password);

    // 21. Verify shared-event notification
    await tester.tap(find.byIcon(Icons.notifications));
    await tester.pumpAndSettle();
    expect(find.text('New Shared Reminder'), findsOneWidget);

    // 23. Accept the shared event
    await tapButton('Accept');
    await tester.pumpAndSettle(const Duration(seconds: 2));
    
    await tester.tap(find.byIcon(Icons.arrow_back)); // back from notifications
    await tester.pumpAndSettle();

    // 24. Open Shared With Me
    await tester.tap(find.text('Calendar'));
    await tester.pumpAndSettle();
    
    // There should be a "Shared" tab or similar
    await tester.tap(find.text('Shared'));
    await tester.pumpAndSettle();

    // 25. Verify the event exists
    expect(find.text('Integration Test Event'), findsWidgets);
  });
}
