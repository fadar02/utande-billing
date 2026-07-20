import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/providers.dart';
import '../../theme/app_theme.dart';
import '../../models/story_model.dart';
import '../../l10n/app_localizations.dart';

class StoryCreatorScreen extends StatefulWidget {
  const StoryCreatorScreen({super.key});

  @override
  State<StoryCreatorScreen> createState() => _StoryCreatorScreenState();
}

class _StoryCreatorScreenState extends State<StoryCreatorScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _captionController = TextEditingController();
  final TextEditingController _textStoryController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  File? _selectedMedia;
  bool _isTextMode = false;
  bool _isSharing = false;
  bool _useFrontCamera = true;
  bool _flashEnabled = false;
  int _selectedGradientIndex = 0;
  String _storyAudience = 'Your Story';

  late AnimationController _cameraAnimController;

  static const List<List<Color>> _textGradients = [
    [Color(0xFF833AB4), Color(0xFFFD1D1D), Color(0xFFFFC371)],
    [Color(0xFF00C6FF), Color(0xFF0072FF)],
    [Color(0xFFF7971E), Color(0xFFFFD200)],
    [Color(0xFFE91E63), Color(0xFF9C27B0)],
    [Color(0xFF11998E), Color(0xFF38EF7D)],
    [Color(0xFFFC466B), Color(0xFF3F5EFB)],
    [Color(0xFF0F2027), Color(0xFF2C5364)],
    [Color(0xFFEB3349), Color(0xFFF45C43)],
  ];

  @override
  void initState() {
    super.initState();
    _cameraAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _captionController.dispose();
    _textStoryController.dispose();
    _cameraAnimController.dispose();
    super.dispose();
  }

  Future<void> _pickFromGallery() async {
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1080,
      maxHeight: 1920,
      imageQuality: 85,
    );
    if (image != null) {
      setState(() {
        _selectedMedia = File(image.path);
        _isTextMode = false;
      });
    }
  }

  Future<void> _takePhoto() async {
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: _useFrontCamera
          ? CameraDevice.front
          : CameraDevice.rear,
      maxWidth: 1080,
      maxHeight: 1920,
      imageQuality: 85,
    );
    if (image != null) {
      setState(() {
        _selectedMedia = File(image.path);
        _isTextMode = false;
      });
    }
  }

  void _toggleTextMode() {
    setState(() {
      _isTextMode = !_isTextMode;
      if (_isTextMode) {
        _selectedMedia = null;
      }
    });
  }

  void _toggleCamera() {
    setState(() => _useFrontCamera = !_useFrontCamera);
  }

  void _toggleFlash() {
    setState(() => _flashEnabled = !_flashEnabled);
  }

  Future<void> _shareStory() async {
    if (_isTextMode && _textStoryController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter some text'),
          backgroundColor: AppTheme.warningColor,
        ),
      );
      return;
    }

    if (!_isTextMode && _selectedMedia == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select or take a photo'),
          backgroundColor: AppTheme.warningColor,
        ),
      );
      return;
    }

    final auth = context.read<AuthProvider>();
    final social = context.read<SocialProvider>();
    final userId = auth.userId;

    if (userId == null) return;

    setState(() => _isSharing = true);

    try {
      if (_isTextMode) {
        final tempFile = await _createTextStoryImage();
        if (tempFile != null) {
          await social.createStory(
            userId: userId,
            mediaFile: tempFile,
            caption: _textStoryController.text.trim(),
            type: StoryType.text,
          );
        }
      } else {
        await social.createStory(
          userId: userId,
          mediaFile: _selectedMedia!,
          caption: _captionController.text.trim().isEmpty
              ? null
              : _captionController.text.trim(),
          type: StoryType.image,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Story shared!'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to share: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSharing = false);
      }
    }
  }

  Future<File?> _createTextStoryImage() async {
    final gradient = _textGradients[_selectedGradientIndex];
    final dir = Directory.systemTemp;
    final file = File('${dir.path}/text_story_${DateTime.now().millisecondsSinceEpoch}.png');

    try {
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, 1080, 1920));
      final paint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ).createShader(const Rect.fromLTWH(0, 0, 1080, 1920));

      canvas.drawRect(const Rect.fromLTWH(0, 0, 1080, 1920), paint);

      final picture = recorder.endRecording();
      final img = await picture.toImage(1080, 1920);
      final byteData = await img.toByteData(format: ImageByteFormat.png);
      final bytes = byteData!.buffer.asUint8List();

      await file.writeAsBytes(bytes);
      return file;
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (_isTextMode)
            _buildTextStoryPreview()
          else if (_selectedMedia != null)
            _buildSelectedMediaPreview()
          else
            _buildCameraPreview(),
          _buildTopControls(),
          if (_isTextMode) _buildTextStoryInput(),
          if (!_isTextMode) _buildCaptionOverlay(),
          _buildBottomControls(),
          if (_isSharing)
            Container(
              color: Colors.black.withValues(alpha: 0.5),
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCameraPreview() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.grey.shade900,
            Colors.grey.shade800,
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _useFrontCamera ? Icons.face : Icons.camera_alt,
              size: 80,
              color: Colors.white.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'Tap the capture button',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedMediaPreview() {
    return Image.file(
      _selectedMedia!,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
    );
  }

  Widget _buildTextStoryPreview() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _textGradients[_selectedGradientIndex],
        ),
      ),
      child: _textStoryController.text.isNotEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  _textStoryController.text,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    height: 1.3,
                    shadows: [
                      Shadow(
                        blurRadius: 10,
                        color: Colors.black26,
                        offset: Offset(2, 2),
                      ),
                    ],
                  ),
                ),
              ),
            )
          : Center(
              child: Text(
                'Type something...',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 20,
                ),
              ),
            ),
    );
  }

  Widget _buildTopControls() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 8,
      left: 12,
      right: 12,
      child: Row(
        children: [
          _buildControlButton(
            icon: Icons.close,
            onTap: () => Navigator.pop(context),
          ),
          const Spacer(),
          if (!_isTextMode) ...[
            _buildControlButton(
              icon: _flashEnabled
                  ? Icons.flash_on
                  : Icons.flash_off,
              onTap: _toggleFlash,
              isActive: _flashEnabled,
            ),
            const SizedBox(width: 10),
            _buildControlButton(
              icon: Icons.cameraswitch,
              onTap: _toggleCamera,
            ),
          ],
          const SizedBox(width: 10),
          _buildControlButton(
            icon: Icons.text_fields,
            onTap: _toggleTextMode,
            isActive: _isTextMode,
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isActive
              ? AppTheme.primaryColor.withValues(alpha: 0.8)
              : Colors.black.withValues(alpha: 0.4),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 22,
        ),
      ),
    );
  }

  Widget _buildTextStoryInput() {
    return Positioned(
      bottom: 140,
      left: 24,
      right: 24,
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: TextField(
              controller: _textStoryController,
              textAlign: TextAlign.center,
              maxLines: 4,
              minLines: 1,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                hintText: 'Type your story...',
                hintStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 24,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _textGradients.length,
              itemBuilder: (context, index) {
                final isSelected = index == _selectedGradientIndex;
                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedGradientIndex = index);
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: _textGradients[index],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(color: Colors.white, width: 3)
                          : null,
                    ),
                    child: isSelected
                        ? const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 18,
                          )
                        : null,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCaptionOverlay() {
    if (_selectedMedia == null) return const SizedBox.shrink();

    return Positioned(
      bottom: 140,
      left: 16,
      right: 16,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: TextField(
          controller: _captionController,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
          ),
          decoration: InputDecoration(
            hintText: 'Add a caption...',
            hintStyle: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 15,
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 10),
            prefixIcon: Icon(
              Icons.emoji_emotions_outlined,
              color: Colors.white.withValues(alpha: 0.5),
              size: 22,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomControls() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 16,
          bottom: MediaQuery.of(context).padding.bottom + 16,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.black.withValues(alpha: 0.8),
            ],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildAudienceSelector(),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildBottomAction(
                  icon: Icons.photo_library,
                  label: 'Gallery',
                  onTap: _pickFromGallery,
                ),
                if (!_isTextMode)
                  _buildCaptureButton()
                else
                  _buildShareButton(),
                if (!_isTextMode)
                  _buildBottomAction(
                    icon: Icons.camera_alt,
                    label: 'Camera',
                    onTap: _takePhoto,
                  )
                else
                  _buildBottomAction(
                    icon: Icons.text_fields,
                    label: 'Text',
                    onTap: _toggleTextMode,
                    isActive: true,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAudienceSelector() {
    return GestureDetector(
      onTap: _showAudiencePicker,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _storyAudience == 'Your Story'
                  ? Icons.public
                  : Icons.lock_outline,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              _storyAudience,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down,
              color: Colors.white.withValues(alpha: 0.7),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  void _showAudiencePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
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
            const SizedBox(height: 20),
            const Text(
              'Share to',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.public, color: AppTheme.primaryColor),
              ),
              title: const Text(
                'Your Story',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              subtitle: const Text(
                'Visible to all your matches',
                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
              trailing: _storyAudience == 'Your Story'
                  ? const Icon(Icons.check_circle, color: AppTheme.primaryColor)
                  : null,
              onTap: () {
                setState(() => _storyAudience = 'Your Story');
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.successColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lock_outline, color: AppTheme.successColor),
              ),
              title: const Text(
                'Close Friends',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              subtitle: const Text(
                'Only visible to close friends',
                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
              trailing: _storyAudience == 'Close Friends'
                  ? const Icon(Icons.check_circle, color: AppTheme.primaryColor)
                  : null,
              onTap: () {
                setState(() => _storyAudience = 'Close Friends');
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isActive ? AppTheme.primaryColor : Colors.white,
            size: 28,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isActive
                  ? AppTheme.primaryColor
                  : Colors.white.withValues(alpha: 0.7),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCaptureButton() {
    return GestureDetector(
      onTap: _takePhoto,
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 4),
        ),
        child: Container(
          margin: const EdgeInsets.all(4),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildShareButton() {
    return GestureDetector(
      onTap: _shareStory,
      child: Container(
        width: 64,
        height: 64,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [AppTheme.primaryColor, AppTheme.accentColor],
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor,
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(
          Icons.send,
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }
}
