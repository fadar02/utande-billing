import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../../models/user_model.dart';
import '../../l10n/app_localizations.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedHighlight = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      if (auth.user != null) {
        final social = context.read<SocialProvider>();
        social.loadFeed();
        social.loadReels();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, SocialProvider>(
      builder: (context, auth, social, _) {
        final user = auth.user;

        if (user == null) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.primaryColor),
          );
        }

        final userPosts =
            social.posts.where((p) => p.userId == user.id).toList();
        final userReels =
            social.reels.where((r) => r.userId == user.id).toList();

        return Scaffold(
          backgroundColor: AppTheme.backgroundColor,
          body: SafeArea(
            child: CustomScrollView(
              slivers: [
                _buildTopBar(context, user),
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildProfileHeader(context, user),
                      const SizedBox(height: 12),
                      _buildStatsRow(context, userPosts.length),
                      if (user.bio.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _buildBio(user),
                      ],
                      if (user.interests.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _buildInterestChips(user),
                      ],
                      const SizedBox(height: 12),
                      _buildActionButtons(context),
                      const SizedBox(height: 16),
                      _buildHighlightsRow(context),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
                _buildTabBar(),
                if (_tabController.index == 0)
                  _buildGridTab(userPosts, user)
                else if (_tabController.index == 1)
                  _buildReelsTab(userReels, user)
                else
                  _buildTaggedTab(user),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTopBar(BuildContext context, UserModel user) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            GestureDetector(
              onTap: () {},
              child: Row(
                children: [
                  Text(
                    user.name.split(' ').first,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: AppTheme.textPrimary,
                    size: 24,
                  ),
                ],
              ),
            ),
            const Spacer(),
            if (user.isPremiumActive)
              Container(
                margin: const EdgeInsets.only(right: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFD700), Color(0xFFFFA000)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.workspace_premium_rounded,
                        color: Colors.white, size: 14),
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
              ),
            _buildTopIcon(
              icon: Icons.add_box_outlined,
              onTap: () {},
            ),
            const SizedBox(width: 8),
            _buildTopIcon(
              icon: Icons.settings_outlined,
              onTap: () => Navigator.pushNamed(context, '/settings'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopIcon({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, color: AppTheme.textPrimary, size: 20),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, UserModel user) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () {},
                child: Stack(
                  children: [
                    Container(
                      width: 86,
                      height: 86,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: user.isPremiumActive
                              ? const Color(0xFFFFD700)
                              : AppTheme.dividerColor,
                          width: 3,
                        ),
                      ),
                      child: ClipOval(
                        child: user.mainPhoto.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: user.mainPhoto,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  color: AppTheme.primaryLight,
                                  child: const Icon(Icons.person,
                                      size: 40,
                                      color: AppTheme.primaryColor),
                                ),
                                errorWidget: (context, url, error) =>
                                    Container(
                                  color: AppTheme.primaryLight,
                                  child: const Icon(Icons.person,
                                      size: 40,
                                      color: AppTheme.primaryColor),
                                ),
                              )
                            : Container(
                                color: AppTheme.primaryLight,
                                child: const Icon(Icons.person,
                                    size: 40,
                                    color: AppTheme.primaryColor),
                              ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(Icons.camera_alt,
                            color: Colors.white, size: 14),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user.district,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '@${user.name.toLowerCase().replaceAll(' ', '')}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.textHint,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(BuildContext context, int postsCount) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildStatItem('$postsCount', AppLocalizations.t('post')),
            Container(
                width: 1,
                height: 24,
                color: AppTheme.dividerColor),
            _buildStatItem('--', AppLocalizations.t('matches')),
            Container(
                width: 1,
                height: 24,
                color: AppTheme.dividerColor),
            _buildStatItem('--', AppLocalizations.t('like')),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String count, String label) {
    return Column(
      children: [
        Text(
          count,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildBio(UserModel user) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Text(
        user.bio,
        style: const TextStyle(
          fontSize: 14,
          color: AppTheme.textPrimary,
          height: 1.4,
        ),
      ),
    );
  }

  Widget _buildInterestChips(UserModel user) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: user.interests.map((interest) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppTheme.primaryColor.withValues(alpha: 0.2),
              ),
            ),
            child: Text(
              interest,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppTheme.primaryColor,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () =>
                  Navigator.pushNamed(context, '/edit-profile'),
              child: Container(
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.dividerColor),
                ),
                child: const Center(
                  child: Text(
                    'Edit Profile',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: GestureDetector(
              onTap: () {},
              child: Container(
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.dividerColor),
                ),
                child: const Center(
                  child: Text(
                    'Share Profile',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            height: 36,
            width: 36,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.dividerColor),
            ),
            child: const Icon(
              Icons.person_add_outlined,
              size: 18,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHighlightsRow(BuildContext context) {
    final highlights = [
      {'icon': Icons.info_outline, 'label': 'About Me'},
      {'icon': Icons.interests, 'label': 'Interests'},
      {'icon': Icons.favorite_border, 'label': 'Favorites'},
    ];

    return SizedBox(
      height: 80,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: highlights.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final highlight = highlights[index];
          final isSelected = _selectedHighlight == highlight['label'];
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedHighlight =
                    isSelected ? '' : highlight['label'] as String;
              });
            },
            child: Column(
              children: [
                Container(
                  width: 62,
                  height: 62,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected
                        ? AppTheme.primaryColor.withValues(alpha: 0.1)
                        : Colors.white,
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.primaryColor
                          : AppTheme.dividerColor,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    highlight['icon'] as IconData,
                    color: isSelected
                        ? AppTheme.primaryColor
                        : AppTheme.textSecondary,
                    size: 26,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  highlight['label'] as String,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                    color: isSelected
                        ? AppTheme.primaryColor
                        : AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTabBar() {
    return SliverToBoxAdapter(
      child: Container(
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: AppTheme.dividerColor, width: 0.5),
          ),
        ),
        child: TabBar(
          controller: _tabController,
          onTap: (index) => setState(() {}),
          labelColor: AppTheme.textPrimary,
          unselectedLabelColor: AppTheme.textSecondary,
          indicatorColor: AppTheme.textPrimary,
          indicatorWeight: 1,
          tabs: const [
            Tab(icon: Icon(Icons.grid_on_rounded, size: 24)),
            Tab(icon: Icon(Icons.play_circle_outline_rounded, size: 24)),
            Tab(icon: Icon(Icons.assignment_ind_rounded, size: 24)),
          ],
        ),
      ),
    );
  }

  Widget _buildGridTab(List posts, UserModel user) {
    if (posts.isEmpty) {
      return const SliverFillRemaining(
        child: EmptyState(
          icon: Icons.grid_on_rounded,
          title: 'Share your first moment!',
          subtitle: 'Photos and posts you share will appear here.',
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.all(2),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 2,
          crossAxisSpacing: 2,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final post = posts[index];
            final hasImage =
                post.mediaUrls.isNotEmpty;
            return GestureDetector(
              onTap: () {},
              child: Container(
                color: AppTheme.primaryLight,
                child: hasImage
                    ? CachedNetworkImage(
                        imageUrl: post.mediaUrls.first,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: AppTheme.primaryLight,
                          child: const Icon(Icons.image,
                              color: AppTheme.primaryColor),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: AppTheme.primaryLight,
                          child: const Icon(Icons.broken_image,
                              color: AppTheme.primaryColor),
                        ),
                      )
                    : const Center(
                        child: Icon(Icons.image,
                            size: 32, color: AppTheme.primaryColor),
                      ),
              ),
            );
          },
          childCount: posts.length,
        ),
      ),
    );
  }

  Widget _buildReelsTab(List reels, UserModel user) {
    if (reels.isEmpty) {
      return const SliverFillRemaining(
        child: EmptyState(
          icon: Icons.play_circle_outline_rounded,
          title: 'No reels yet',
          subtitle: 'Create reels to share your moments!',
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.all(2),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 2,
          crossAxisSpacing: 2,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final reel = reels[index];
            return GestureDetector(
              onTap: () {},
              child: Container(
                color: AppTheme.primaryLight,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (reel.thumbnailUrl != null)
                      CachedNetworkImage(
                        imageUrl: reel.thumbnailUrl!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        errorWidget: (context, url, error) =>
                            const SizedBox.shrink(),
                      ),
                    Container(
                      color: Colors.black.withValues(alpha: 0.2),
                    ),
                    const Icon(Icons.play_arrow_rounded,
                        color: Colors.white, size: 36),
                    Positioned(
                      bottom: 6,
                      left: 6,
                      child: Row(
                        children: [
                          const Icon(Icons.play_arrow_rounded,
                              color: Colors.white, size: 14),
                          Text(
                            '${reel.viewCount}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
          childCount: reels.length,
        ),
      ),
    );
  }

  Widget _buildTaggedTab(UserModel user) {
    return const SliverFillRemaining(
      child: EmptyState(
        icon: Icons.assignment_ind_rounded,
        title: 'No tagged posts',
        subtitle: 'Posts you are tagged in will appear here.',
      ),
    );
  }
}
