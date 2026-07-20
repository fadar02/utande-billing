import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/providers.dart';
import '../../theme/app_theme.dart';
import '../../models/user_model.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  late PageController _pageController;
  int _currentPhotoIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  UserModel? _getUser() {
    return ModalRoute.of(context)?.settings.arguments as UserModel?;
  }

  void _showMoreMenu(UserModel user) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.flag_outlined, color: AppTheme.warningColor),
                title: const Text('Report User'),
                subtitle: const Text('Inappropriate content or behavior'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/report', arguments: user.id);
                },
              ),
              ListTile(
                leading: const Icon(Icons.block, color: AppTheme.errorColor),
                title: const Text('Block User'),
                subtitle: const Text("They won't be able to see your profile"),
                onTap: () {
                  Navigator.pop(context);
                  _showBlockDialog(user);
                },
              ),
              ListTile(
                leading: const Icon(Icons.share_outlined, color: AppTheme.primaryColor),
                title: const Text('Share Profile'),
                subtitle: const Text('Share this profile with friends'),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showBlockDialog(UserModel user) {
    final auth = context.read<AuthProvider>();
    final safety = context.read<SafetyProvider>();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Block User'),
        content: Text(
          "Are you sure you want to block ${user.name}? They won't be able to see your profile or message you.",
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              if (auth.userId != null) {
                await safety.blockUser(auth.userId!, user.id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${user.name} has been blocked.'),
                      backgroundColor: AppTheme.successColor,
                    ),
                  );
                  Navigator.of(context).pop();
                }
              }
            },
            child: const Text('Block', style: TextStyle(color: AppTheme.errorColor)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _getUser();
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: const Center(child: Text('User not found')),
      );
    }

    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        final currentUser = auth.user;
        final mutualInterests = currentUser != null
            ? user.interests.where((i) => currentUser.interests.contains(i)).toList()
            : <String>[];

        return Scaffold(
          backgroundColor: AppTheme.backgroundColor,
          body: CustomScrollView(
            slivers: [
              _buildAppBar(user),
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildUserInfo(user),
                    const SizedBox(height: 8),
                    _buildPhotoIndicators(user),
                    const SizedBox(height: 16),
                    _buildActionButtons(user),
                    const SizedBox(height: 16),
                    if (user.bio.isNotEmpty) _buildBioSection(user),
                    _buildDetailsSection(user),
                    if (mutualInterests.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _buildMutualInterests(mutualInterests),
                    ],
                    if (user.interests.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _buildInterestsSection(user),
                    ],
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAppBar(UserModel user) {
    return SliverAppBar(
      expandedHeight: MediaQuery.of(context).size.height * 0.55,
      floating: false,
      pinned: true,
      backgroundColor: AppTheme.backgroundColor,
      leading: IconButton(
        onPressed: () => Navigator.of(context).pop(),
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.3),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.arrow_back, color: Colors.white),
        ),
      ),
      title: Text(
        user.name,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          onPressed: () => _showMoreMenu(user),
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.more_vert, color: Colors.white),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: PageView.builder(
          controller: _pageController,
          itemCount: user.photos.isEmpty ? 1 : user.photos.length,
          onPageChanged: (index) => setState(() => _currentPhotoIndex = index),
          itemBuilder: (context, index) {
            if (user.photos.isEmpty) return _buildEmptyPhoto();
            return _buildPhoto(user.photos[index]);
          },
        ),
      ),
    );
  }

  Widget _buildPhoto(String photoUrl) {
    return Stack(
      fit: StackFit.expand,
      children: [
        CachedNetworkImage(
          imageUrl: photoUrl,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            color: AppTheme.primaryColor.withValues(alpha: 0.1),
            child: const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor)),
          ),
          errorWidget: (context, url, error) => Container(
            color: AppTheme.primaryColor.withValues(alpha: 0.1),
            child: const Icon(Icons.person, size: 80, color: AppTheme.primaryColor),
          ),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black.withValues(alpha: 0.5)],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyPhoto() {
    return Container(
      color: AppTheme.primaryColor.withValues(alpha: 0.1),
      child: const Icon(Icons.person, size: 80, color: AppTheme.primaryColor),
    );
  }

  Widget _buildUserInfo(UserModel user) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${user.name}, ${user.age}',
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                ),
              ),
              if (user.isPremiumActive)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFFFA000)]),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 14),
                      SizedBox(width: 4),
                      Text('PRO', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                    ],
                  ),
                ),
              if (user.verified) ...[
                const SizedBox(width: 6),
                const Icon(Icons.verified, size: 20, color: AppTheme.primaryColor),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.location_on, size: 16, color: AppTheme.primaryColor),
              const SizedBox(width: 4),
              Text(user.district, style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
              if (user.occupation.isNotEmpty) ...[
                const SizedBox(width: 12),
                const Icon(Icons.work_outline, size: 16, color: AppTheme.primaryColor),
                const SizedBox(width: 4),
                Text(user.occupation, style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
              ],
            ],
          ),
          if (user.online) ...[
            const SizedBox(height: 4),
            const Row(
              children: [
                Icon(Icons.circle, size: 8, color: AppTheme.successColor),
                SizedBox(width: 4),
                Text('Online', style: TextStyle(fontSize: 12, color: AppTheme.successColor, fontWeight: FontWeight.w500)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPhotoIndicators(UserModel user) {
    if (user.photos.length <= 1) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          user.photos.length,
          (index) => AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: _currentPhotoIndex == index ? 24 : 8,
            height: 4,
            decoration: BoxDecoration(
              color: _currentPhotoIndex == index ? AppTheme.primaryColor : AppTheme.dividerColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(UserModel user) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: GestureDetector(
              onTap: () {},
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [AppTheme.primaryColor, AppTheme.accentColor]),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(color: AppTheme.primaryColor.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4)),
                  ],
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.favorite, color: Colors.white, size: 22),
                    SizedBox(width: 8),
                    Text('Like', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: () {},
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppTheme.primaryColor, width: 2),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.chat_bubble_outline, color: AppTheme.primaryColor, size: 20),
                    SizedBox(width: 6),
                    Text('Message', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.primaryColor)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBioSection(UserModel user) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('About', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
          const SizedBox(height: 8),
          Text(user.bio, style: const TextStyle(fontSize: 15, color: AppTheme.textPrimary, height: 1.5)),
        ],
      ),
    );
  }

  Widget _buildDetailsSection(UserModel user) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        children: [
          _buildDetailTile(Icons.cake_outlined, 'Age', '${user.age}'),
          _buildDetailTile(Icons.work_outline, 'Occupation', user.occupation.isNotEmpty ? user.occupation : 'Not specified'),
          _buildDetailTile(Icons.school_outlined, 'Education', user.education.isNotEmpty ? user.education : 'Not specified'),
          if (user.religion != null && user.religion!.isNotEmpty)
            _buildDetailTile(Icons.church_outlined, 'Religion', user.religion!),
          if (user.tribe != null && user.tribe!.isNotEmpty)
            _buildDetailTile(Icons.groups_outlined, 'Tribe', user.tribe!),
          if (user.height != null && user.height!.isNotEmpty)
            _buildDetailTile(Icons.height, 'Height', user.height!),
          _buildDetailTile(Icons.favorite_outline, 'Relationship Type', user.relationshipType ?? 'Not specified'),
          _buildDetailTile(Icons.person_search, 'Looking For', user.lookingFor),
        ],
      ),
    );
  }

  Widget _buildDetailTile(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppTheme.primaryColor),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
          const Spacer(),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
        ],
      ),
    );
  }

  Widget _buildMutualInterests(List<String> interests) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.people_outline, size: 20, color: AppTheme.primaryColor),
              const SizedBox(width: 6),
              Text(
                'Mutual Interests (${interests.length})',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: interests.map((interest) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.primaryColor, AppTheme.primaryColor.withValues(alpha: 0.8)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(interest, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildInterestsSection(UserModel user) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Interests', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: user.interests.map((interest) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.2)),
                ),
                child: Text(interest, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.primaryColor)),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
