import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/providers.dart';
import '../../theme/app_theme.dart';
import '../../models/reel_model.dart';

class ReelsScreen extends StatefulWidget {
  const ReelsScreen({super.key});

  @override
  State<ReelsScreen> createState() => _ReelsScreenState();
}

class _ReelsScreenState extends State<ReelsScreen>
    with SingleTickerProviderStateMixin {
  late PageController _pageController;
  bool _showHeart = false;
  late AnimationController _heartAnimController;
  late Animation<double> _heartScaleAnimation;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _heartAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _heartScaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.2)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.2, end: 0.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 60,
      ),
    ]).animate(_heartAnimController);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SocialProvider>().loadReels();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _heartAnimController.dispose();
    super.dispose();
  }

  void _onDoubleTap(ReelModel reel) {
    final auth = context.read<AuthProvider>();
    final social = context.read<SocialProvider>();
    if (auth.userId == null) return;

    if (!reel.isLikedBy(auth.userId!)) {
      social.toggleLikeReel(reel.id, auth.userId!);
    }

    _heartAnimController.forward(from: 0.0);
    setState(() => _showHeart = true);
    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) setState(() => _showHeart = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Consumer2<AuthProvider, SocialProvider>(
        builder: (context, auth, social, _) {
          if (social.isLoading && social.reels.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          }

          if (social.reels.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.videocam_off,
                      size: 80, color: Colors.white.withValues(alpha: 0.5)),
                  const SizedBox(height: 16),
                  Text(
                    'No reels yet',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Be the first to create a reel!',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 14),
                  ),
                ],
              ),
            );
          }

          return Stack(
            children: [
              PageView.builder(
                controller: _pageController,
                scrollDirection: Axis.vertical,
                itemCount: social.reels.length,
                itemBuilder: (context, index) {
                  final reel = social.reels[index];
                  return _ReelItem(
                    reel: reel,
                    onDoubleTap: () => _onDoubleTap(reel),
                    auth: auth,
                    social: social,
                  );
                },
              ),
              if (_showHeart)
                Center(
                  child: AnimatedBuilder(
                    animation: _heartScaleAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _heartScaleAnimation.value,
                        child: child,
                      );
                    },
                    child: const Icon(
                      Icons.favorite,
                      color: Colors.red,
                      size: 100,
                    ),
                  ),
                ),
              Positioned(
                top: MediaQuery.of(context).padding.top + 12,
                left: 16,
                right: 16,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Reels',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.primaryColor,
        onPressed: () {
          Navigator.pushNamed(context, '/create-reel');
        },
        child: const Icon(Icons.camera_alt, color: Colors.white),
      ),
    );
  }
}

class _ReelItem extends StatelessWidget {
  final ReelModel reel;
  final VoidCallback onDoubleTap;
  final AuthProvider auth;
  final SocialProvider social;

  const _ReelItem({
    required this.reel,
    required this.onDoubleTap,
    required this.auth,
    required this.social,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTap: onDoubleTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CachedNetworkImage(
            imageUrl: reel.thumbnailUrl ?? '',
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              color: Colors.black87,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
            errorWidget: (context, url, error) => Container(
              color: Colors.black87,
              child: const Icon(Icons.error, color: Colors.white, size: 40),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.8),
                ],
                stops: const [0.0, 0.6, 1.0],
              ),
            ),
          ),
          Center(
            child: Icon(
              Icons.play_circle_fill,
              color: Colors.white.withValues(alpha: 0.6),
              size: 70,
            ),
          ),
          Positioned(
            right: 12,
            bottom: 120,
            child: _ActionColumn(reel: reel, auth: auth, social: social),
          ),
          Positioned(
            left: 16,
            bottom: 80,
            right: 80,
            child: _ReelInfo(reel: reel),
          ),
          Positioned(
            right: 16,
            bottom: 80,
            child: _SpinningDisc(thumbnailUrl: reel.thumbnailUrl ?? ''),
          ),
        ],
      ),
    );
  }
}

class _ActionColumn extends StatelessWidget {
  final ReelModel reel;
  final AuthProvider auth;
  final SocialProvider social;

  const _ActionColumn({
    required this.reel,
    required this.auth,
    required this.social,
  });

  @override
  Widget build(BuildContext context) {
    final isLiked = auth.userId != null && reel.isLikedBy(auth.userId!);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () {
            if (auth.userId != null) {
              Navigator.pushNamed(
                context,
                '/user-profile',
                arguments: reel.userId,
              );
            }
          },
          child: CircleAvatar(
            radius: 24,
            backgroundColor: AppTheme.primaryColor,
            child: const Icon(Icons.person, color: Colors.white, size: 28),
          ),
        ),
        const SizedBox(height: 20),
        GestureDetector(
          onTap: () {
            if (auth.userId != null) {
              social.toggleLikeReel(reel.id, auth.userId!);
            }
          },
          child: Column(
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Icon(
                  isLiked ? Icons.favorite : Icons.favorite_border,
                  key: ValueKey(isLiked),
                  color: isLiked ? Colors.red : Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _formatCount(reel.likes.length),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        GestureDetector(
          onTap: () {
            // Navigate to comments
          },
          child: Column(
            children: [
              const Icon(Icons.comment_rounded,
                  color: Colors.white, size: 32),
              const SizedBox(height: 4),
              Text(
                _formatCount(reel.commentCount),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        GestureDetector(
          onTap: () {
            // Share reel
          },
          child: const Column(
            children: [
              Icon(Icons.share, color: Colors.white, size: 32),
              SizedBox(height: 4),
              Text(
                'Share',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        GestureDetector(
          onTap: () {
            // Bookmark reel
          },
          child: const Column(
            children: [
              Icon(Icons.bookmark_border, color: Colors.white, size: 32),
              SizedBox(height: 4),
              Text(
                'Save',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }
}

class _ReelInfo extends StatelessWidget {
  final ReelModel reel;

  const _ReelInfo({required this.reel});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '@username',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          reel.caption,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
          ),
        ),
        if (reel.caption.length > 50)
          GestureDetector(
            onTap: () {
              // Expand caption
            },
            child: const Text(
              '...more',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.music_note, color: Colors.white, size: 16),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                reel.audio ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SpinningDisc extends StatefulWidget {
  final String thumbnailUrl;

  const _SpinningDisc({required this.thumbnailUrl});

  @override
  State<_SpinningDisc> createState() => _SpinningDiscState();
}

class _SpinningDiscState extends State<_SpinningDisc>
    with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _rotationController,
      builder: (context, child) {
        return Transform.rotate(
          angle: _rotationController.value * 2 * 3.14159265,
          child: child,
        );
      },
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 2),
        ),
        child: ClipOval(
          child: CachedNetworkImage(
            imageUrl: widget.thumbnailUrl,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              color: Colors.grey[800],
              child: const Icon(Icons.music_note, color: Colors.white, size: 20),
            ),
            errorWidget: (context, url, error) => Container(
              color: Colors.grey[800],
              child: const Icon(Icons.music_note, color: Colors.white, size: 20),
            ),
          ),
        ),
      ),
    );
  }
}
