import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/providers.dart';
import '../screens/home/discovery_screen.dart';
import '../screens/explore/explore_screen.dart';
import '../screens/feed/feed_screen.dart';
import '../screens/reels/reels_screen.dart';
import '../screens/profile/profile_screen.dart';

class NavigationShell extends StatefulWidget {
  const NavigationShell({super.key});

  @override
  State<NavigationShell> createState() => _NavigationShellState();
}

class _NavigationShellState extends State<NavigationShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const DiscoveryScreen(),
    const ExploreScreen(),
    const FeedScreen(),
    const ReelsScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      if (auth.user != null) {
        context.read<NotificationProvider>().loadNotifications(auth.userId!);
        context.read<SocialProvider>().loadFeed();
        context.read<SocialProvider>().loadReels();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: AppTheme.primaryColor,
        unselectedItemColor: AppTheme.textSecondary,
        selectedFontSize: 10,
        unselectedFontSize: 10,
        elevation: 12,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.favorite_border, size: 26),
            activeIcon: Icon(Icons.favorite, size: 26),
            label: 'Discover',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.explore_outlined, size: 26),
            activeIcon: Icon(Icons.explore, size: 26),
            label: 'Explore',
          ),
          BottomNavigationBarItem(
            icon: Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primaryColor, AppTheme.accentColor],
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 20),
            ),
            label: '',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.movie_filter_outlined, size: 26),
            activeIcon: Icon(Icons.movie_filter, size: 26),
            label: 'Reels',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person_outline, size: 26),
            activeIcon: Icon(Icons.person, size: 26),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
