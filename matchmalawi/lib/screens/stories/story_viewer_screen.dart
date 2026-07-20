import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../providers/providers.dart';
import '../../theme/app_theme.dart';
import '../../models/story_model.dart';

class StoryViewerScreen extends StatefulWidget {
  const StoryViewerScreen({super.key});

  @override
  State<StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends State<StoryViewerScreen>
    with SingleTickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _progressController;
  List<StoryModel> _stories = [];
  int _currentIndex = 0;
  bool _isPaused = false;
  bool _viewedCurrent = false;
  Timer? _autoAdvanceTimer;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );
    _progressController.addStatusListener(_onProgressStatus);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map<String, dynamic>) {
        _stories = args['stories'] as List<StoryModel>;
        final initialIndex = args['initialIndex'] as int? ?? 0;
        _currentIndex = initialIndex;
        _pageController = PageController(initialPage: initialIndex);
        _startStoryTimer();
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _progressController.dispose();
    _autoAdvanceTimer?.cancel();
    super.dispose();
  }

  void _startStoryTimer() {
    _viewedCurrent = false;
    _progressController.reset();
    _progressController.forward();
  }

  void _onProgressStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      _autoAdvanceTimer?.cancel();
      if (_currentIndex < _stories.length - 1) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      } else {
        Navigator.of(context).pop();
      }
    }
  }

  void _onPageChanged(int index) {
    if (index == _currentIndex) return;
    setState(() {
      _currentIndex = index;
    });
    _startStoryTimer();
  }

  void _markStoryViewed() {
    if (_viewedCurrent) return;
    _viewedCurrent = true;
    final auth = context.read<AuthProvider>();
    final social = context.read<SocialProvider>();
    final userId = auth.userId;
    if (userId != null && _currentIndex < _stories.length) {
      social.viewStory(_stories[_currentIndex].id, userId);
    }
  }

  void _onTapDown(TapDownDetails details) {
    final screenWidth = MediaQuery.of(context).size.width;
    final tapX = details.globalPosition.dx;

    if (tapX < screenWidth * 0.3) {
      if (_currentIndex > 0) {
        _pageController.previousPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    } else if (tapX > screenWidth * 0.7) {
      if (_currentIndex < _stories.length - 1) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      } else {
        Navigator.of(context).pop();
      }
    }
  }

  void _onLongPressStart(LongPressStartDetails _) {
    setState(() => _isPaused = true);
    _progressController.stop();
  }

  void _onLongPressEnd(LongPressEndDetails _) {
    setState(() => _isPaused = false);
    _progressController.forward();
  }

  @override
  Widget build(BuildContext context) {
    if (_stories.isEmpty) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTapDown: _onTapDown,
        onLongPressStart: _onLongPressStart,
        onLongPressEnd: _onLongPressEnd,
        onVerticalDragEnd: (details) {
          if (details.primaryVelocity != null && details.primaryVelocity! > 300) {
            Navigator.of(context).pop();
          }
        },
        child: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              itemCount: _stories.length,
              onPageChanged: _onPageChanged,
              itemBuilder: (context, index) {
                return _buildStoryPage(_stories[index]);
              },
            ),
            _buildProgressBars(),
            _buildTopBar(),
            _buildBottomSection(),
            if (_isPaused)
              Center(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.4),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.pause,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoryPage(StoryModel story) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _markStoryViewed();
    });

    if (story.type == StoryType.text) {
      return _buildTextStory(story);
    }
    return _buildMediaStory(story);
  }

  Widget _buildMediaStory(StoryModel story) {
    return Stack(
      fit: StackFit.expand,
      children: [
        CachedNetworkImage(
          imageUrl: story.mediaUrl,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            color: Colors.black,
            child: const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            ),
          ),
          errorWidget: (context, url, error) => Container(
            color: Colors.black,
            child: const Center(
              child: Icon(Icons.broken_image, color: Colors.white54, size: 48),
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.3),
                Colors.transparent,
                Colors.transparent,
                Colors.black.withValues(alpha: 0.5),
              ],
              stops: const [0.0, 0.2, 0.7, 1.0],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextStory(StoryModel story) {
    final gradients = [
      [const Color(0xFF833AB4), const Color(0xFFFD1D1D), const Color(0xFFFFC371)],
      [const Color(0xFF00C6FF), const Color(0xFF0072FF)],
      [const Color(0xFFF7971E), const Color(0xFFFFD200)],
      [const Color(0xFFE91E63), const Color(0xFF9C27B0)],
      [const Color(0xFF11998E), const Color(0xFF38EF7D)],
    ];
    final gradient = gradients[story.id.hashCode.abs() % gradients.length];

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            story.caption ?? '',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              height: 1.3,
              shadows: [
                Shadow(
                  blurRadius: 8,
                  color: Colors.black26,
                  offset: Offset(2, 2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBars() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 8,
      left: 12,
      right: 12,
      child: Row(
        children: List.generate(_stories.length, (index) {
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: AnimatedBuilder(
                animation: _progressController,
                builder: (context, _) {
                  double fill;
                  if (index < _currentIndex) {
                    fill = 1.0;
                  } else if (index == _currentIndex) {
                    fill = _progressController.value;
                  } else {
                    fill = 0.0;
                  }
                  return Container(
                    height: 3,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: fill,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildTopBar() {
    if (_currentIndex >= _stories.length) return const SizedBox.shrink();
    final story = _stories[_currentIndex];
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    final isOwnStory = story.userId == auth.userId;
    final displayName = isOwnStory
        ? (user?.name ?? 'You')
        : 'User';

    return Positioned(
      top: MediaQuery.of(context).padding.top + 18,
      left: 12,
      right: 12,
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              image: user?.mainPhoto.isNotEmpty == true
                  ? DecorationImage(
                      image: NetworkImage(user!.mainPhoto),
                      fit: BoxFit.cover,
                    )
                  : null,
              color: user?.mainPhoto.isNotEmpty != true
                  ? AppTheme.primaryColor
                  : null,
            ),
            child: user?.mainPhoto.isNotEmpty != true
                ? const Icon(Icons.person, color: Colors.white, size: 20)
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  displayName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  timeago.format(story.createdAt, locale: 'en_short'),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, color: Colors.white, size: 28),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSection() {
    if (_currentIndex >= _stories.length) return const SizedBox.shrink();
    final story = _stories[_currentIndex];

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).padding.bottom + 16,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.black.withValues(alpha: 0.6),
            ],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (story.caption != null && story.caption!.isNotEmpty) ...[
              Text(
                story.caption!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 12),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.remove_red_eye,
                  color: Colors.white.withValues(alpha: 0.7),
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  '${story.viewCount}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Reply to story...',
                        hintStyle: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 14,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(
                      Icons.send,
                      color: AppTheme.primaryColor,
                      size: 22,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
