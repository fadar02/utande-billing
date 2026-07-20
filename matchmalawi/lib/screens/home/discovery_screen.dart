import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:card_swiper/card_swiper.dart';
import '../../providers/providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../../models/user_model.dart';
import '../../services/matching_service.dart';
import '../../l10n/app_localizations.dart';

class DiscoveryScreen extends StatefulWidget {
  const DiscoveryScreen({super.key});

  @override
  State<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends State<DiscoveryScreen>
    with SingleTickerProviderStateMixin {
  SwiperController? _swiperController;
  late AnimationController _bannerAnimController;

  @override
  void initState() {
    super.initState();
    _swiperController = SwiperController();
    _bannerAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initDiscovery();
    });
  }

  @override
  void dispose() {
    _swiperController?.dispose();
    _bannerAnimController.dispose();
    super.dispose();
  }

  void _initDiscovery() {
    final auth = context.read<AuthProvider>();
    final discovery = context.read<DiscoveryProvider>();
    if (auth.user != null) {
      discovery.loadUsers(auth.user!);
    }
  }

  void _onLike() {
    final auth = context.read<AuthProvider>();
    final discovery = context.read<DiscoveryProvider>();
    if (auth.user == null || !discovery.hasMoreUsers) return;
    discovery.like(auth.user!).then((_) {
      if (!mounted) return;
      _checkMatchResult(discovery);
    });
  }

  void _onSuperLike() {
    final auth = context.read<AuthProvider>();
    final discovery = context.read<DiscoveryProvider>();
    if (auth.user == null || !discovery.hasMoreUsers) return;
    discovery.superLike(auth.user!).then((_) {
      if (!mounted) return;
      _checkMatchResult(discovery);
    });
  }

  void _onPass() {
    context.read<DiscoveryProvider>().pass();
  }

  void _checkMatchResult(DiscoveryProvider discovery) {
    if (discovery.lastResult == MatchResult.newMatch &&
        discovery.matchedUser != null) {
      Navigator.pushNamed(
        context,
        '/match',
        arguments: discovery.matchedUser!,
      ).then((_) {
        if (mounted) {
          context.read<DiscoveryProvider>().clearMatchResult();
        }
      });
    }
  }

  void _onIndexChanged(int index) {}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Consumer2<AuthProvider, DiscoveryProvider>(
          builder: (context, auth, discovery, child) {
            if (discovery.isLoading) {
              return const Center(
                child: CircularProgressIndicator(color: AppTheme.primaryColor),
              );
            }

            if (discovery.users.isEmpty) {
              return _buildEmptyState();
            }

            return Column(
              children: [
                _buildTopBar(),
                _buildTsogoloBanner(),
                _buildStoriesRow(),
                const SizedBox(height: 4),
                Expanded(
                  child: _buildCardSwiper(discovery),
                ),
                _buildActionButtons(),
                const SizedBox(height: 16),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.primaryColor, AppTheme.accentColor],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.favorite, color: Colors.white, size: 18),
                SizedBox(width: 4),
                Text(
                  'MM',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          _buildTopBarIcon(
            icon: Icons.search_rounded,
            onTap: () => Navigator.pushNamed(context, '/search'),
          ),
          const SizedBox(width: 8),
          _buildTopBarIcon(
            icon: Icons.tune_rounded,
            onTap: () => _showFilterSheet(),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBarIcon({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, color: AppTheme.textPrimary, size: 22),
      ),
    );
  }

  Widget _buildTsogoloBanner() {
    return AnimatedBuilder(
      animation: _bannerAnimController,
      builder: (context, child) {
        final glow = 0.15 + _bannerAnimController.value * 0.15;
        return GestureDetector(
          onTap: () {},
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFFFD700),
                  const Color(0xFFFFA000),
                  const Color(0xFFFFD700),
                ],
                stops: [
                  0.0,
                  0.5 + _bannerAnimController.value * 0.2,
                  1.0,
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFD700).withValues(alpha: glow),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.t('tsogolo_daily'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Your special match of the day is waiting!',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white.withValues(alpha: 0.8),
                  size: 16,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStoriesRow() {
    return SizedBox(
      height: 90,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          _buildYourStory(),
          ...List.generate(6, (index) => _buildStoryCircle(index)),
        ],
      ),
    );
  }

  Widget _buildYourStory() {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: GestureDetector(
        onTap: () {},
        child: Column(
          children: [
            Stack(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.primaryLight,
                  ),
                  child: const Icon(
                    Icons.person,
                    size: 30,
                    color: AppTheme.primaryColor,
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.add,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Your Story',
              style: TextStyle(fontSize: 10, color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoryCircle(int index) {
    final colors = [
      AppTheme.primaryColor,
      AppTheme.accentColor,
      AppTheme.secondaryColor,
      Colors.teal,
      Colors.orange,
      Colors.blue,
    ];
    final color = colors[index % colors.length];
    final hasStory = index < 3;

    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: GestureDetector(
        onTap: () {},
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: hasStory
                    ? LinearGradient(
                        colors: [
                          color,
                          color.withValues(alpha: 0.5),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                border: hasStory
                    ? null
                    : Border.all(
                        color: AppTheme.dividerColor,
                        width: 2,
                      ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: 0.15),
                ),
                child: Icon(
                  Icons.person,
                  size: 28,
                  color: color.withValues(alpha: 0.6),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'User ${index + 1}',
              style: const TextStyle(
                fontSize: 10,
                color: AppTheme.textSecondary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardSwiper(DiscoveryProvider discovery) {
    final remaining = discovery.users.length - discovery.currentIndex;
    if (remaining <= 0) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Swiper(
        controller: _swiperController,
        itemCount: remaining,
        onIndexChanged: _onIndexChanged,
        loop: false,
        layout: SwiperLayout.STACK,
        itemWidth: MediaQuery.of(context).size.width - 32,
        itemHeight: MediaQuery.of(context).size.height * 0.58,
        pagination: SwiperPagination(
          alignment: Alignment.bottomCenter,
          margin: const EdgeInsets.only(bottom: 8),
          builder: DotSwiperPaginationBuilder(
            color: Colors.white.withValues(alpha: 0.4),
            activeColor: Colors.white,
            size: 7,
            activeSize: 9,
          ),
        ),
        itemBuilder: (context, index) {
          final userIndex = discovery.currentIndex + index;
          if (userIndex >= discovery.users.length) {
            return const SizedBox.shrink();
          }
          final user = discovery.users[userIndex];
          return GestureDetector(
            onTap: () {
              Navigator.pushNamed(
                context,
                '/user-profile',
                arguments: user,
              );
            },
            child: DiscoverySwipingCard(user: user),
          );
        },
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildCircleButton(
            icon: Icons.close_rounded,
            color: AppTheme.passColor,
            size: 56,
            iconSize: 28,
            onTap: _onPass,
            shadowColor: AppTheme.passColor,
          ),
          _buildCircleButton(
            icon: Icons.star_rounded,
            color: AppTheme.superLikeColor,
            size: 48,
            iconSize: 24,
            onTap: _onSuperLike,
            shadowColor: AppTheme.superLikeColor,
          ),
          _buildCircleButton(
            icon: Icons.favorite_rounded,
            color: AppTheme.likeColor,
            size: 56,
            iconSize: 28,
            onTap: _onLike,
            shadowColor: AppTheme.likeColor,
          ),
        ],
      ),
    );
  }

  Widget _buildCircleButton({
    required IconData icon,
    required Color color,
    required double size,
    required double iconSize,
    required VoidCallback onTap,
    required Color shadowColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: shadowColor.withValues(alpha: 0.25),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, color: color, size: iconSize),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primaryColor.withValues(alpha: 0.08),
              ),
              child: Icon(
                Icons.explore_off_rounded,
                size: 56,
                color: AppTheme.primaryColor.withValues(alpha: 0.4),
              ),
            ),
            const SizedBox(height: 28),
            Text(
              AppLocalizations.t('no_users'),
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              AppLocalizations.t('try_adjusting'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 32),
            GestureDetector(
              onTap: _initDiscovery,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.primaryColor, AppTheme.accentColor],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.refresh_rounded, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Refresh',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return Padding(
            padding: const EdgeInsets.all(20),
            child: ListView(
              controller: scrollController,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.dividerColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Filters',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 24),
                _buildFilterOption('Distance', '20 km'),
                _buildFilterOption('Age Range', '18 - 35'),
                _buildFilterOption('Looking For', 'Everyone'),
                _buildFilterOption('Relationship Type', 'Serious relationship'),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  child: const Text(
                    'Apply Filters',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterOption(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              color: AppTheme.textPrimary,
            ),
          ),
          Row(
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppTheme.textSecondary,
                size: 20,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class DiscoverySwipingCard extends StatelessWidget {
  final UserModel user;

  const DiscoverySwipingCard({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Stack(
        fit: StackFit.expand,
        children: [
          _buildPhoto(),
          _buildTopGradient(),
          _buildBottomGradient(),
          _buildUserInfo(),
          if (user.premium)
            Positioned(
              top: 16,
              right: 16,
              child: _buildPremiumBadge(),
            ),
          if (user.verified)
            Positioned(
              top: 16,
              left: 16,
              child: _buildVerifiedBadge(),
            ),
          _buildPhotoIndicators(),
        ],
      ),
    );
  }

  Widget _buildPhoto() {
    if (user.photos.isNotEmpty) {
      return Image.network(
        user.photos.first,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, __, ___) => _buildPlaceholder(),
      );
    }
    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor.withValues(alpha: 0.15),
            AppTheme.primaryColor.withValues(alpha: 0.05),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.person_rounded,
          size: 100,
          color: AppTheme.primaryColor.withValues(alpha: 0.25),
        ),
      ),
    );
  }

  Widget _buildTopGradient() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withValues(alpha: 0.4),
              Colors.transparent,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomGradient() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        height: 220,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.black.withValues(alpha: 0.85),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserInfo() {
    return Positioned(
      bottom: 24,
      left: 20,
      right: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Flexible(
                child: Text(
                  '${user.name}, ${user.age}',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        blurRadius: 6,
                        color: Colors.black45,
                        offset: Offset(1, 1),
                      ),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(
                Icons.location_on_rounded,
                size: 16,
                color: Colors.white70,
              ),
              const SizedBox(width: 4),
              Text(
                user.district,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
          if (user.occupation.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(
                  Icons.work_outline_rounded,
                  size: 16,
                  color: Colors.white70,
                ),
                const SizedBox(width: 4),
                Text(
                  user.occupation,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ],
          if (user.interests.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: user.interests.take(3).map((interest) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Text(
                    interest,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.white,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPremiumBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFD700), Color(0xFFFFA000)],
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFD700).withValues(alpha: 0.4),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 14),
          SizedBox(width: 4),
          Text(
            'PRO',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerifiedBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.4),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified_rounded, color: Colors.white, size: 14),
          SizedBox(width: 4),
          Text(
            'Verified',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoIndicators() {
    if (user.photos.length <= 1) return const SizedBox.shrink();

    return Positioned(
      top: 8,
      left: 16,
      right: 16,
      child: Row(
        children: List.generate(
          user.photos.length,
          (index) => Expanded(
            child: Container(
              height: 3,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: index == 0
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
