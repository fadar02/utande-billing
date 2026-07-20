import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'l10n/app_localizations.dart';
import 'providers/providers.dart';
import 'services/firestore_service.dart';
import 'services/matching_service.dart';
import 'services/storage_service.dart';
import 'services/social_service.dart';
import 'services/notification_service.dart';
import 'screens/auth/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/otp_screen.dart';
import 'screens/auth/create_profile_screen.dart';
import 'screens/home/discovery_screen.dart';
import 'screens/home/match_screen.dart';
import 'screens/chat/chat_list_screen.dart';
import 'screens/chat/chat_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/profile/edit_profile_screen.dart';
import 'screens/profile/user_profile_screen.dart';
import 'screens/search/search_screen.dart';
import 'screens/notifications/notifications_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/report/report_user_screen.dart';
import 'screens/premium/premium_screen.dart';
import 'screens/admin/admin_dashboard.dart';
import 'screens/feed/feed_screen.dart';
import 'screens/feed/create_post_screen.dart';
import 'screens/stories/story_viewer_screen.dart';
import 'screens/stories/story_creator_screen.dart';
import 'screens/reels/reels_screen.dart';
import 'screens/reels/create_reel_screen.dart';
import 'screens/explore/explore_screen.dart';
import 'widgets/navigation_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  if (!kIsWeb) {
    try {
      await NotificationService().initialize();
    } catch (_) {}
  }
  runApp(const MatchMalawiApp());
}

class MatchMalawiApp extends StatelessWidget {
  const MatchMalawiApp({super.key});

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();
    final storageService = StorageService();
    final matchingService = MatchingService(firestoreService);
    final socialService = SocialService();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(
          create: (_) => DiscoveryProvider(matchingService),
        ),
        ChangeNotifierProvider(create: (_) => ChatProvider(firestoreService)),
        ChangeNotifierProvider(
          create: (_) => SafetyProvider(firestoreService),
        ),
        ChangeNotifierProvider(
          create: (_) => NotificationProvider(firestoreService),
        ),
        ChangeNotifierProvider(
          create: (_) => SocialProvider(socialService, storageService),
        ),
      ],
      child: MaterialApp(
        title: 'Match Malawi',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        initialRoute: '/',
        routes: {
          '/': (context) => const SplashScreen(),
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/otp': (context) => const OtpScreen(),
          '/create-profile': (context) => const CreateProfileScreen(),
          '/main': (context) => const NavigationShell(),
          '/match': (context) => const MatchScreen(),
          '/chat': (context) => const ChatScreen(),
          '/edit-profile': (context) => const EditProfileScreen(),
          '/user-profile': (context) => const UserProfileScreen(),
          '/search': (context) => const SearchScreen(),
          '/notifications': (context) => const NotificationsScreen(),
          '/settings': (context) => const SettingsScreen(),
          '/report': (context) => const ReportUserScreen(),
          '/premium': (context) => const PremiumScreen(),
          '/admin': (context) => const AdminDashboard(),
          '/feed': (context) => const FeedScreen(),
          '/create-post': (context) => const CreatePostScreen(),
          '/story-viewer': (context) => const StoryViewerScreen(),
          '/story-creator': (context) => const StoryCreatorScreen(),
          '/reels': (context) => const ReelsScreen(),
          '/create-reel': (context) => const CreateReelScreen(),
          '/explore': (context) => const ExploreScreen(),
        },
      ),
    );
  }
}
