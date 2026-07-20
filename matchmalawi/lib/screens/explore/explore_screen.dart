import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../../models/user_model.dart';
import '../../models/reel_model.dart';


enum ExploreCategory { all, posts, reels, people, nearMe }

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final _searchController = TextEditingController();
  ExploreCategory _selectedCategory = ExploreCategory.all;
  String _searchQuery = '';

  final List<String> _trendingDistricts = [
    'Lilongwe',
    'Blantyre',
    'Mzuzu',
    'Zomba',
    'Mangochi',
    'Karonga',
    'Mwanza',
    'Nkhotakota',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SocialProvider>().loadExplore('Lilongwe');
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchQuery = value.trim().toLowerCase();
    });
  }

  List<UserModel> _filterUsers(List<UserModel> users) {
    if (_searchQuery.isEmpty) return users;
    return users.where((user) {
      final name = user.name.toLowerCase();
      final district = user.district.toLowerCase();
      final interests = user.interests.join(' ').toLowerCase();
      return name.contains(_searchQuery) ||
          district.contains(_searchQuery) ||
          interests.contains(_searchQuery);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchBar(),
            _buildCategoryChips(),
            Expanded(
              child: _buildContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Search people, interests, places...',
          hintStyle: TextStyle(color: Colors.grey[500]),
          prefixIcon:
              Icon(Icons.search, color: Colors.grey[500], size: 22),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, color: Colors.grey[500], size: 20),
                  onPressed: () {
                    _searchController.clear();
                    _onSearchChanged('');
                  },
                )
              : null,
          filled: true,
          fillColor: Colors.grey[900],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: AppTheme.primaryColor),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildCategoryChips() {
    final categories = [
      {'label': 'All', 'icon': Icons.grid_view, 'category': ExploreCategory.all},
      {'label': 'Posts', 'icon': Icons.article, 'category': ExploreCategory.posts},
      {'label': 'Reels', 'icon': Icons.videocam, 'category': ExploreCategory.reels},
      {'label': 'People', 'icon': Icons.person, 'category': ExploreCategory.people},
      {'label': 'Near Me', 'icon': Icons.location_on, 'category': ExploreCategory.nearMe},
    ];

    return SizedBox(
      height: 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final cat = categories[index];
          final isSelected = _selectedCategory == cat['category'];
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedCategory = cat['category'] as ExploreCategory;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.primaryColor
                    : Colors.grey[900],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? AppTheme.primaryColor
                      : Colors.grey[800]!,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    cat['icon'] as IconData,
                    color: isSelected ? Colors.white : Colors.grey[400],
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    cat['label'] as String,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey[400],
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildContent() {
    return Consumer3<AuthProvider, SocialProvider, DiscoveryProvider>(
      builder: (context, auth, social, discovery, _) {
        if (social.isLoading && social.reels.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.primaryColor),
          );
        }

        final filteredUsers = _filterUsers(discovery.users);

        return RefreshIndicator(
          color: AppTheme.primaryColor,
          onRefresh: () async {
            await social.loadExplore('Lilongwe');
          },
          child: CustomScrollView(
            slivers: [
              if (_searchQuery.isEmpty &&
                  _selectedCategory == ExploreCategory.all) ...[
                _buildTrendingLocations(),
              ],
              if (_selectedCategory == ExploreCategory.all ||
                  _selectedCategory == ExploreCategory.posts) ...[
                _buildPostsSection(social),
              ],
              if (_selectedCategory == ExploreCategory.all ||
                  _selectedCategory == ExploreCategory.reels) ...[
                _buildReelsSection(social),
              ],
              if (_selectedCategory == ExploreCategory.people ||
                  _selectedCategory == ExploreCategory.nearMe) ...[
                _buildPeopleSection(filteredUsers),
              ],
              if (_selectedCategory == ExploreCategory.all ||
                  _selectedCategory == ExploreCategory.posts) ...[
                _buildPostsGrid(social),
              ],
              if (_selectedCategory == ExploreCategory.all) ...[
                _buildMoreExplore(),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildTrendingLocations() {
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Trending Locations',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  child: Text(
                    'See all',
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _trendingDistricts.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final district = _trendingDistricts[index];
                return GestureDetector(
                  onTap: () {
                    context.read<SocialProvider>().loadExplore(district);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.location_on,
                            color: AppTheme.primaryColor, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          district,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostsSection(SocialProvider social) {
    return const SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 20, 16, 8),
        child: Text(
          'Posts',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildReelsSection(SocialProvider social) {
    if (social.reels.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());

    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 20, 16, 8),
            child: Text(
              'Reels',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(
            height: 200,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: social.reels.length.clamp(0, 10),
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final reel = social.reels[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(context, '/reels');
                  },
                  child: Container(
                    width: 120,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.grey[900],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          CachedNetworkImage(
                            imageUrl: reel.thumbnailUrl ?? '',
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: Colors.grey[800],
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: Colors.grey[800],
                              child: const Icon(Icons.error,
                                  color: Colors.white),
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withValues(alpha: 0.7),
                                ],
                              ),
                            ),
                          ),
                          const Center(
                            child: Icon(Icons.play_circle_fill,
                                color: Colors.white, size: 36),
                          ),
                          Positioned(
                            bottom: 8,
                            left: 8,
                            child: Row(
                              children: [
                                const Icon(Icons.favorite,
                                    color: Colors.white, size: 14),
                                const SizedBox(width: 4),
                                Text(
                                  '${reel.likes.length}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeopleSection(List<UserModel> users) {
    if (users.isEmpty) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Center(
            child: Text(
              'No people found',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final user = users[index];
            return _PersonCard(user: user);
          },
          childCount: users.length,
        ),
      ),
    );
  }

  Widget _buildPostsGrid(SocialProvider social) {
    final mockPosts = List.generate(12, (i) => i);
    if (mockPosts.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());

    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 4,
          mainAxisSpacing: 4,
          childAspectRatio: 1,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final isLarge = index % 5 == 0;
            return GestureDetector(
              onTap: () {
                // Navigate to post detail
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CachedNetworkImage(
                        imageUrl:
                            'https://picsum.photos/seed/${index + 100}/400/400',
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: Colors.grey[800],
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: Colors.grey[800],
                          child: const Icon(Icons.image,
                              color: Colors.grey, size: 30),
                        ),
                      ),
                      if (isLarge)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Icon(Icons.camera_alt,
                                color: Colors.white, size: 14),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
          childCount: mockPosts.length,
        ),
      ),
    );
  }

  Widget _buildMoreExplore() {
    final categories = [
      {'label': 'Popular Near You', 'icon': Icons.trending_up},
      {'label': 'New Members', 'icon': Icons.person_add},
      {'label': 'Active Now', 'icon': Icons.circle, 'color': Colors.green},
    ];

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Explore More',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...categories.map((cat) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      cat['icon'] as IconData,
                      color: (cat['color'] as Color?) ?? AppTheme.primaryColor,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      cat['label'] as String,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    Icon(Icons.chevron_right, color: Colors.grey[600]),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _PersonCard extends StatelessWidget {
  final UserModel user;

  const _PersonCard({required this.user});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, '/user-profile', arguments: user.id);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.2),
              backgroundImage: user.mainPhoto != null
                  ? CachedNetworkImageProvider(user.mainPhoto!)
                  : null,
              child: user.mainPhoto == null
                  ? Text(
                      user.name.isNotEmpty
                          ? user.name[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        color: AppTheme.primaryColor,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                      user.district,
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 13,
                      ),
                    ),
                  if (user.interests.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: user.interests
                            .take(3)
                            .map((interest) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color:
                                  AppTheme.primaryColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              interest,
                              style: TextStyle(
                                color: AppTheme.primaryColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey[600]),
          ],
        ),
      ),
    );
  }
}
