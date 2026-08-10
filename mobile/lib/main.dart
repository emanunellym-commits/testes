import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'core/network/api_client.dart';
import 'core/notifications/notification_service.dart';
import 'core/theme/theme_controller.dart';
import 'features/auth/login_page.dart';
import 'features/settings/account_security_page.dart';
import 'features/support/support_page.dart';
import 'features/settings/sessions_page.dart';
import 'features/settings/phone_verification_page.dart';
import 'features/settings/two_factor_page.dart';
import 'features/auth/forgot_password_page.dart';
import 'features/onboarding/onboarding_page.dart';
import 'features/settings/about_page.dart';
import 'features/auth/register_page.dart';
import 'features/chat/chat_page.dart';
import 'features/chat/chat_search_page.dart';
import 'features/groups/create_group_page.dart';
import 'features/home/home_page.dart';
import 'features/home/archived_conversations_page.dart';
import 'features/profile/profile_page.dart';
import 'features/settings/privacy_notifications_page.dart';
import 'features/settings/theme_page.dart';
import 'features/stories/stories_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await NotificationService.instance.init();
  } catch (_) {}

  final themeController = LiveChatThemeController();
  await themeController.load();

  final token = await ApiClient.instance.token();
  const storage = FlutterSecureStorage();
  final onboardingDone = await storage.read(key: 'onboarding_done');

  runApp(
    LiveChatApp(
      initialLocation: onboardingDone == null ? '/onboarding' : (token == null ? '/login' : '/home'),
      themeController: themeController,
    ),
  );
}

class LiveChatApp extends StatelessWidget {
  const LiveChatApp({
    super.key,
    required this.initialLocation,
    required this.themeController,
  });

  final String initialLocation;
  final LiveChatThemeController themeController;

  @override
  Widget build(BuildContext context) {
    final router = GoRouter(
      initialLocation: initialLocation,
      routes: [
        GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingPage()),
        GoRoute(path: '/login', builder: (_, __) => const LoginPage()),
        GoRoute(path: '/forgot-password', builder: (_, __) => const ForgotPasswordPage()),
        GoRoute(path: '/register', builder: (_, __) => const RegisterPage()),
        GoRoute(path: '/home', builder: (_, __) => const HomePage()),
        GoRoute(path: '/archived', builder: (_, __) => const ArchivedConversationsPage()),
        GoRoute(path: '/profile', builder: (_, __) => const ProfilePage()),
        GoRoute(path: '/about', builder: (_, __) => const AboutPage()),
        GoRoute(path: '/settings/account-security', builder: (_, __) => const AccountSecurityPage()),
        GoRoute(path: '/settings/2fa', builder: (_, __) => const TwoFactorPage()),
        GoRoute(path: '/settings/phone', builder: (_, __) => const PhoneVerificationPage()),
        GoRoute(path: '/settings/sessions', builder: (_, __) => const SessionsPage()),
        GoRoute(path: '/support', builder: (_, __) => const SupportPage()),
        GoRoute(path: '/stories', builder: (_, __) => const StoriesPage()),
        GoRoute(
          path: '/settings/privacy',
          builder: (_, __) => const PrivacyNotificationsPage(),
        ),
        GoRoute(
          path: '/settings/themes',
          builder: (_, __) => ThemePage(controller: themeController),
        ),
        GoRoute(
          path: '/groups/create',
          builder: (_, __) => const CreateGroupPage(),
        ),
        GoRoute(
          path: '/chat-search/:conversationId',
          builder: (_, state) => ChatSearchPage(
            conversationId: state.pathParameters['conversationId']!,
            title: state.uri.queryParameters['name'] ?? 'Conversa',
          ),
        ),
        GoRoute(
          path: '/chat/:conversationId',
          builder: (_, state) => ChatPage(
            conversationId: state.pathParameters['conversationId']!,
            contactName: state.uri.queryParameters['name'] ?? 'Contato',
            isGroup: state.uri.queryParameters['group'] == '1',
          ),
        ),
      ],
    );

    return AnimatedBuilder(
      animation: themeController,
      builder: (_, __) => MaterialApp.router(
        title: 'LiveChat Messenger',
        debugShowCheckedModeBanner: false,
        theme: themeController.theme,
        routerConfig: router,
      ),
    );
  }
}
