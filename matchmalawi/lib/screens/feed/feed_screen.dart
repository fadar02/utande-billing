import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../providers/providers.dart';
import '../../theme/app_theme.dart';
import '../../models/post_model.dart';
import '../../l10n/app_localizations.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SocialProvider>().loadFeed();
    });
  }

  Future<void> _refreshFeed() async {
    context.read<SocialProvider>().loadFeed();
  }

  void _navigateToCreatePost() {
    Navigator.pushNamed(context, '/create-post');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceColor,
        elevation: 0,
        title: Text(
          AppLocalizations.t('feed'),
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            onPressed: _navigateToCreatePost,
            icon: const Icon(
              Icons.camera_alt_outlined,
              color: AppTheme.textPrimary,
              size: 26,
            ),
          ),
        ],
      ),
      body: Consumer2<AuthProvider, SocialProvider>(
        builder: (context, auth, social, child) {
          if (social.isLoading && social.posts.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            );
          }

          if (social.posts.isEmpty) {
            return _buildEmptyState();
          }

          return RefreshIndicator(
            onRefresh: _refreshFeed,
            color: AppTheme.primaryColor,
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 100),
              itemCount: social.posts.length,
              itemBuilder: (context, index) {
                return _buildPostCard(
                  post: social.posts[index],
                  auth: auth,
                  social: social,
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildPostCard({
    required PostModel post,
    required AuthProvider auth,
    required SocialProvider social,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      color: AppTheme.surfaceColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPostHeader(post, auth),
          if (post.mediaUrls.isNotEmpty) _buildPostImageCarousel(post),
          _buildActionRow(post, auth, social),
          _buildLikeCount(post),
          if (post.caption.isNotEmpty) _buildCaption(post),
          if (post.location != null && post.location!.isNotEmpty)
            _buildLocation(post),
          if (post.commentCount > 0) _buildViewComments(post, social),
          _buildCommentInput(post, auth, social),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildPostHeader(PostModel post, AuthProvider auth) {
    final isOwnPost = post.userId == auth.userId;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryColor.withValues(alpha: 0.3),
                  AppTheme.accentColor.withValues(alpha: 0.3),
                ],
              ),
            ),
            padding: const EdgeInsets.all(2),
            child: Container(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
              child: const Icon(
                Icons.person,
                size: 18,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isOwnPost ? (auth.user?.name ?? 'You') : 'User',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                if (!isOwnPost)
                  Text(
                    timeago.format(post.createdAt, locale: 'en_short'),
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          if (isOwnPost)
            PopupMenuButton<String>(
              padding: EdgeInsets.zero,
              icon: const Icon(
                Icons.more_vert,
                color: AppTheme.textSecondary,
                size: 22,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              onSelected: (value) {
                if (value == 'delete') {
                  _confirmDeletePost(post, auth);
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, color: AppTheme.errorColor, size: 20),
                      const SizedBox(width: 8),
                      const Text('Delete', style: TextStyle(color: AppTheme.errorColor)),
                    ],
                  ),
                ),
              ],
            )
          else
            IconButton(
              onPressed: () {},
              icon: const Icon(
                Icons.more_vert,
                color: AppTheme.textSecondary,
                size: 22,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }

  Widget _buildPostImageCarousel(PostModel post) {
    if (post.mediaUrls.length == 1) {
      return CachedNetworkImage(
        imageUrl: post.mediaUrls.first,
        width: double.infinity,
        height: MediaQuery.of(context).size.width,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          width: double.infinity,
          height: MediaQuery.of(context).size.width,
          color: AppTheme.primaryLight.withValues(alpha: 0.3),
          child: const Center(
            child: CircularProgressIndicator(
              color: AppTheme.primaryColor,
              strokeWidth: 2,
            ),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          width: double.infinity,
          height: MediaQuery.of(context).size.width,
          color: AppTheme.primaryLight.withValues(alpha: 0.3),
          child: const Icon(
            Icons.broken_image,
            size: 48,
            color: AppTheme.textHint,
          ),
        ),
      );
    }

    return SizedBox(
      height: MediaQuery.of(context).size.width,
      child: PageView.builder(
        itemCount: post.mediaUrls.length.clamp(1, 10),
        itemBuilder: (context, index) {
          return Stack(
            children: [
              CachedNetworkImage(
                imageUrl: post.mediaUrls[index],
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: AppTheme.primaryLight.withValues(alpha: 0.3),
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.primaryColor,
                      strokeWidth: 2,
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: AppTheme.primaryLight.withValues(alpha: 0.3),
                  child: const Icon(
                    Icons.broken_image,
                    size: 48,
                    color: AppTheme.textHint,
                  ),
                ),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${index + 1}/${post.mediaUrls.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildActionRow(PostModel post, AuthProvider auth, SocialProvider social) {
    final userId = auth.userId ?? '';
    final isLiked = post.isLikedBy(userId);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => social.toggleLikePost(post.id, userId),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(6),
              child: Icon(
                isLiked ? Icons.favorite : Icons.favorite_border,
                color: isLiked ? AppTheme.errorColor : AppTheme.textPrimary,
                size: 28,
              ),
            ),
          ),
          const SizedBox(width: 16),
          GestureDetector(
            onTap: () {},
            child: const Icon(
              Icons.chat_bubble_outline,
              color: AppTheme.textPrimary,
              size: 26,
            ),
          ),
          const SizedBox(width: 16),
          GestureDetector(
            onTap: () {},
            child: const Icon(
              Icons.send_outlined,
              color: AppTheme.textPrimary,
              size: 26,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () {},
            child: const Icon(
              Icons.bookmark_border,
              color: AppTheme.textPrimary,
              size: 26,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLikeCount(PostModel post) {
    if (post.likeCount == 0) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Text(
        '${post.likeCount} ${post.likeCount == 1 ? "like" : "likes"}',
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppTheme.textPrimary,
        ),
      ),
    );
  }

  Widget _buildCaption(PostModel post) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: RichText(
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
        text: TextSpan(
          style: const TextStyle(
            fontSize: 14,
            color: AppTheme.textPrimary,
            height: 1.3,
          ),
          children: [
            const TextSpan(
              text: 'User ',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(text: post.caption),
          ],
        ),
      ),
    );
  }

  Widget _buildLocation(PostModel post) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Row(
        children: [
          const Icon(Icons.location_on, size: 14, color: AppTheme.textSecondary),
          const SizedBox(width: 4),
          Text(
            post.location!,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewComments(PostModel post, SocialProvider social) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: GestureDetector(
        onTap: () {},
        child: Text(
          AppLocalizations.t('view_all') != 'view_all'
              ? '${AppLocalizations.t('view_all')} ${post.commentCount} ${AppLocalizations.t('comment')}'
              : 'View all ${post.commentCount} comment${post.commentCount == 1 ? '' : 's'}',
          style: const TextStyle(
            fontSize: 13,
            color: AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildCommentInput(PostModel post, AuthProvider auth, SocialProvider social) {
    final commentController = TextEditingController();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          const Icon(
            Icons.emoji_emotions_outlined,
            size: 22,
            color: AppTheme.textSecondary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: commentController,
              style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
              decoration: InputDecoration(
                hintText: AppLocalizations.t('comment'),
                hintStyle: const TextStyle(
                  color: AppTheme.textHint,
                  fontSize: 13,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                isDense: true,
              ),
              onSubmitted: (text) {
                if (text.trim().isNotEmpty) {
                  final userId = auth.userId;
                  if (userId != null) {
                    social.addComment(post.id, userId, text.trim());
                    commentController.clear();
                  }
                }
              },
            ),
          ),
          GestureDetector(
            onTap: () {
              final text = commentController.text.trim();
              if (text.isNotEmpty) {
                final userId = auth.userId;
                if (userId != null) {
                  social.addComment(post.id, userId, text);
                  commentController.clear();
                }
              }
            },
            child: const Text(
              'Post',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
        ],
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
                Icons.photo_library_outlined,
                size: 56,
                color: AppTheme.primaryColor.withValues(alpha: 0.4),
              ),
            ),
            const SizedBox(height: 28),
            const Text(
              'No posts yet',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Share your first moment!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 32),
            GestureDetector(
              onTap: _navigateToCreatePost,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
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
                    Icon(Icons.add_photo_alternate_outlined, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Create Post',
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

  void _confirmDeletePost(PostModel post, AuthProvider auth) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Post'),
        content: const Text('Are you sure you want to delete this post?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<SocialProvider>().deletePost(post.id);
            },
            child: const Text('Delete', style: TextStyle(color: AppTheme.errorColor)),
          ),
        ],
      ),
    );
  }
}
