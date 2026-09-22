import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/auth/login/login_screen.dart';
import '../../features/auth/signup/signup_screen.dart';
import '../../features/auth/forgot_password/forgot_password_screen.dart';
import '../../features/app_shell.dart';
import '../../features/home/home_screen.dart';
import '../../features/calendar/calendar_screen.dart';
import '../../features/friends/friends_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/reminders/create_reminder_screen.dart';
import '../../features/reminders/reminder_details_screen.dart';
import '../../features/reminders/shared_with_me_screen.dart';
import '../../features/reminders/shared_reminder_details_screen.dart';
import '../../features/friends/add_friend_screen.dart';
import '../../features/friends/friend_details_screen.dart';
import '../../features/profile/edit_profile_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/settings/notification_settings_screen.dart';
import '../../features/settings/change_password_screen.dart';
import '../../features/settings/about_screen.dart';
import '../../features/settings/legal_screens.dart';
import '../../features/home/notification_screen.dart';
final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'shell');

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/signup',
      builder: (context, state) => const SignupScreen(),
    ),
    GoRoute(
      path: '/forgot-password',
      builder: (context, state) => const ForgotPasswordScreen(),
    ),
    GoRoute(
      path: '/create-reminder',
      builder: (context, state) => const CreateReminderScreen(),
    ),
    GoRoute(
      path: '/reminder/:id',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return ReminderDetailsScreen(reminderId: id);
      },
    ),
    GoRoute(
      path: '/edit-reminder/:id',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return CreateReminderScreen(editReminderId: id);
      },
    ),
    GoRoute(
      path: '/create-shared-reminder',
      builder: (context, state) {
        final friendId = state.uri.queryParameters['friendId'];
        return CreateReminderScreen(initialFriendId: friendId);
      },
    ),
    GoRoute(
      path: '/shared-reminders',
      builder: (context, state) => const SharedWithMeScreen(),
    ),
    GoRoute(
      path: '/shared-reminder/:id',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return SharedReminderDetailsScreen(reminderId: id);
      },
    ),
    GoRoute(
      path: '/add-friend',
      builder: (context, state) => const AddFriendScreen(),
    ),
    GoRoute(
      path: '/friends/:id',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return FriendDetailsScreen(friendId: id);
      },
    ),
    GoRoute(
      path: '/profile/edit',
      builder: (context, state) => const EditProfileScreen(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: '/settings/notifications',
      builder: (context, state) => const NotificationSettingsScreen(),
    ),
    GoRoute(
      path: '/settings/change-password',
      builder: (context, state) => const ChangePasswordScreen(),
    ),
    GoRoute(
      path: '/settings/about',
      builder: (context, state) => const AboutScreen(),
    ),
    GoRoute(
      path: '/privacy',
      builder: (context, state) => const PrivacyPolicyScreen(),
    ),
    GoRoute(
      path: '/notifications',
      builder: (context, state) => const NotificationScreen(),
    ),
    GoRoute(
      path: '/terms',
      builder: (context, state) => const TermsOfServiceScreen(),
    ),
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) {
        return AppShell(child: child);
      },
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: '/calendar',
          builder: (context, state) => const CalendarScreen(),
        ),
        GoRoute(
          path: '/friends',
          builder: (context, state) => const FriendsScreen(),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfileScreen(),
        ),
      ],
    ),
  ],
);
