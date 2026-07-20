import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/providers.dart';
import '../../theme/app_theme.dart';
import '../../models/user_model.dart';
import '../../l10n/app_localizations.dart';

class MatchScreen extends StatefulWidget {
  const MatchScreen({super.key});

  @override
  State<MatchScreen> createState() => _MatchScreenState();
}

class _MatchScreenState extends State<MatchScreen>
    with TickerProviderStateMixin {
  late AnimationController _mainAnimController;
  late AnimationController _pulseAnimController;
  late AnimationController _heartsAnimController;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;
  late Animation<double> _pulseAnim;
  final List<_HeartParticle> _hearts = [];
  final List<_ConfettiParticle> _confetti = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();

    _mainAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _pulseAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _heartsAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    )..repeat();

    _scaleAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainAnimController,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );

    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainAnimController,
        curve: const Interval(0.0, 0.3, curve: Curves.easeIn),
      ),
    );

    _pulseAnim = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(
        parent: _pulseAnimController,
        curve: Curves.easeInOut,
      ),
    );

    _generateConfetti();
    _generateHearts();
    _mainAnimController.forward();
  }

  void _generateConfetti() {
    for (int i = 0; i < 60; i++) {
      _confetti.add(_ConfettiParticle(
        x: _random.nextDouble(),
        startY: -0.1 - _random.nextDouble() * 0.3,
        color: [
          AppTheme.primaryColor,
          const Color(0xFFFFD700),
          AppTheme.likeColor,
          AppTheme.superLikeColor,
          AppTheme.accentColor,
          Colors.pink,
          Colors.orange,
        ][_random.nextInt(7)],
        size: _random.nextDouble() * 10 + 4,
        speed: _random.nextDouble() * 3 + 1,
        angle: _random.nextDouble() * pi * 2,
        rotationSpeed: _random.nextDouble() * 4 - 2,
        shape: _random.nextInt(3),
      ));
    }
  }

  void _generateHearts() {
    for (int i = 0; i < 15; i++) {
      _hearts.add(_HeartParticle(
        x: _random.nextDouble(),
        startY: 1.0 + _random.nextDouble() * 0.5,
        size: _random.nextDouble() * 16 + 10,
        speed: _random.nextDouble() * 0.4 + 0.2,
        wobbleAmp: _random.nextDouble() * 30 + 10,
        wobbleSpeed: _random.nextDouble() * 3 + 2,
        delay: _random.nextDouble(),
        color: [
          AppTheme.primaryColor,
          Colors.pink,
          const Color(0xFFFF6B8A),
          Colors.redAccent,
        ][_random.nextInt(4)],
      ));
    }
  }

  @override
  void dispose() {
    _mainAnimController.dispose();
    _pulseAnimController.dispose();
    _heartsAnimController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final matchedUser = _getMatchedUser();
    if (matchedUser == null) {
      Navigator.of(context).pop();
      return;
    }
    Navigator.of(context).pushReplacementNamed(
      '/chat',
      arguments: {
        'otherUser': matchedUser,
      },
    );
  }

  void _keepSwiping() {
    Navigator.of(context).pop();
  }

  UserModel? _getMatchedUser() {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is UserModel) return args;
    final discovery = context.read<DiscoveryProvider>();
    return discovery.matchedUser;
  }

  @override
  Widget build(BuildContext context) {
    final matchedUser = _getMatchedUser();
    final currentUser = context.read<AuthProvider>().user;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          _buildBackground(),
          _buildConfettiLayer(),
          _buildHeartsLayer(),
          _buildContent(currentUser, matchedUser),
        ],
      ),
    );
  }

  Widget _buildBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFE91E63),
            Color(0xFFC2185B),
            Color(0xFFAD1457),
            Color(0xFF880E4F),
          ],
          stops: [0.0, 0.3, 0.7, 1.0],
        ),
      ),
    );
  }

  Widget _buildConfettiLayer() {
    return AnimatedBuilder(
      animation: _mainAnimController,
      builder: (context, child) {
        return CustomPaint(
          painter: _ConfettiPainter(
            particles: _confetti,
            progress: _mainAnimController.value,
          ),
          size: Size.infinite,
        );
      },
    );
  }

  Widget _buildHeartsLayer() {
    return AnimatedBuilder(
      animation: _heartsAnimController,
      builder: (context, child) {
        return CustomPaint(
          painter: _HeartsPainter(
            hearts: _hearts,
            progress: _heartsAnimController.value,
          ),
          size: Size.infinite,
        );
      },
    );
  }

  Widget _buildContent(UserModel? currentUser, UserModel? matchedUser) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: ScaleTransition(
        scale: _scaleAnim,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 36),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildMatchText(),
                const SizedBox(height: 12),
                _buildSubtitle(matchedUser),
                const SizedBox(height: 40),
                _buildProfilePhotos(currentUser, matchedUser),
                const SizedBox(height: 16),
                _buildPhotoLabels(currentUser, matchedUser),
                const SizedBox(height: 48),
                _buildSendButton(),
                const SizedBox(height: 16),
                _buildKeepSwipingButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMatchText() {
    return AnimatedBuilder(
      animation: _pulseAnim,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnim.value,
          child: Text(
            AppLocalizations.t('its_a_match'),
            style: const TextStyle(
              fontSize: 42,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 1.2,
              shadows: [
                Shadow(
                  blurRadius: 20,
                  color: Colors.black26,
                  offset: Offset(2, 4),
                ),
                Shadow(
                  blurRadius: 40,
                  color: Color(0x33FFFFFF),
                  offset: Offset(0, 0),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSubtitle(UserModel? matchedUser) {
    return Text(
      matchedUser != null
          ? 'You and ${matchedUser.name} liked each other!'
          : 'Mudzakhala oyenerana!',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 16,
        color: Colors.white.withValues(alpha: 0.9),
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildProfilePhotos(UserModel? currentUser, UserModel? matchedUser) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildPhotoCircle(
          currentUser?.photos.isNotEmpty == true
              ? currentUser!.photos.first
              : null,
        ),
        const SizedBox(width: 16),
        _buildHeartConnector(),
        const SizedBox(width: 16),
        _buildPhotoCircle(
          matchedUser?.photos.isNotEmpty == true
              ? matchedUser!.photos.first
              : null,
        ),
      ],
    );
  }

  Widget _buildPhotoCircle(String? imageUrl) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 0),
          ),
        ],
      ),
      child: ClipOval(
        child: imageUrl != null && imageUrl.isNotEmpty
            ? Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildPhotoPlaceholder(),
              )
            : _buildPhotoPlaceholder(),
      ),
    );
  }

  Widget _buildPhotoPlaceholder() {
    return Container(
      color: Colors.white.withValues(alpha: 0.2),
      child: const Icon(
        Icons.person_rounded,
        size: 48,
        color: Colors.white,
      ),
    );
  }

  Widget _buildHeartConnector() {
    return AnimatedBuilder(
      animation: _pulseAnim,
      builder: (context, child) {
        return Transform.scale(
          scale: 0.9 + _pulseAnim.value * 0.2,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.3),
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(
              Icons.favorite_rounded,
              color: AppTheme.primaryColor,
              size: 26,
            ),
          ),
        );
      },
    );
  }

  Widget _buildPhotoLabels(UserModel? currentUser, UserModel? matchedUser) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            currentUser?.name ?? 'You',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 76),
        SizedBox(
          width: 120,
          child: Text(
            matchedUser?.name ?? '',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildSendButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _sendMessage,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: AppTheme.primaryColor,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          elevation: 8,
          shadowColor: Colors.black.withValues(alpha: 0.2),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_rounded, size: 22),
            SizedBox(width: 10),
            Text(
              'Send Message',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKeepSwipingButton() {
    return GestureDetector(
      onTap: _keepSwiping,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          AppLocalizations.t('keep_swiping'),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white.withValues(alpha: 0.8),
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

class _HeartParticle {
  final double x;
  final double startY;
  final double size;
  final double speed;
  final double wobbleAmp;
  final double wobbleSpeed;
  final double delay;
  final Color color;

  _HeartParticle({
    required this.x,
    required this.startY,
    required this.size,
    required this.speed,
    required this.wobbleAmp,
    required this.wobbleSpeed,
    required this.delay,
    required this.color,
  });
}

class _HeartsPainter extends CustomPainter {
  final List<_HeartParticle> hearts;
  final double progress;

  _HeartsPainter({required this.hearts, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (final heart in hearts) {
      final t = ((progress - heart.delay) % 1.0).clamp(0.0, 1.0);
      if (t <= 0) continue;

      final opacity = (1.0 - t).clamp(0.0, 1.0);
      final paint = Paint()
        ..color = heart.color.withValues(alpha: opacity * 0.7)
        ..style = PaintingStyle.fill;

      final dx = heart.x * size.width +
          sin(t * heart.wobbleSpeed * pi) * heart.wobbleAmp;
      final dy = heart.startY * size.height - t * size.height * heart.speed;

      if (dy < -heart.size || dy > size.height + heart.size) continue;

      final s = heart.size * (0.6 + t * 0.4);
      _drawHeart(canvas, Offset(dx, dy), s, paint);
    }
  }

  void _drawHeart(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path();
    final w = size / 2;
    final h = size / 2.5;

    path.moveTo(center.dx, center.dy + h * 0.6);
    path.cubicTo(
      center.dx - w,
      center.dy - h * 0.2,
      center.dx - w * 0.6,
      center.dy - h,
      center.dx,
      center.dy - h * 0.4,
    );
    path.cubicTo(
      center.dx + w * 0.6,
      center.dy - h,
      center.dx + w,
      center.dy - h * 0.2,
      center.dx,
      center.dy + h * 0.6,
    );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _HeartsPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _ConfettiParticle {
  final double x;
  final double startY;
  final Color color;
  final double size;
  final double speed;
  final double angle;
  final double rotationSpeed;
  final int shape;

  _ConfettiParticle({
    required this.x,
    required this.startY,
    required this.color,
    required this.size,
    required this.speed,
    required this.angle,
    required this.rotationSpeed,
    required this.shape,
  });
}

class _ConfettiPainter extends CustomPainter {
  final List<_ConfettiParticle> particles;
  final double progress;

  _ConfettiPainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final fadeOut = (1.2 - progress * 1.5).clamp(0.0, 1.0);
      final paint = Paint()
        ..color = p.color.withValues(alpha: fadeOut)
        ..style = PaintingStyle.fill;

      final dx = p.x * size.width +
          cos(p.angle + progress * p.rotationSpeed) * 40;
      final dy = (p.startY + progress * p.speed) * size.height;

      if (dy > size.height * 1.1) continue;

      final rotation = progress * p.rotationSpeed * pi;
      canvas.save();
      canvas.translate(dx, dy);
      canvas.rotate(rotation);

      switch (p.shape) {
        case 0:
          canvas.drawOval(
            Rect.fromCenter(
              center: Offset.zero,
              width: p.size,
              height: p.size * 0.5,
            ),
            paint,
          );
          break;
        case 1:
          final rect = Rect.fromCenter(
            center: Offset.zero,
            width: p.size * 0.7,
            height: p.size * 0.7,
          );
          canvas.drawRect(rect, paint);
          break;
        case 2:
          final path = Path();
          path.moveTo(0, -p.size * 0.4);
          path.lineTo(p.size * 0.35, p.size * 0.3);
          path.lineTo(-p.size * 0.35, p.size * 0.3);
          path.close();
          canvas.drawPath(path, paint);
          break;
      }

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
