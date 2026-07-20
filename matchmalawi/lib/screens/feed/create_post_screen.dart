import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/providers.dart';
import '../../theme/app_theme.dart';
import '../../models/user_model.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final TextEditingController _captionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  final List<File> _selectedImages = [];
  String? _selectedLocation;
  bool _shareToFeed = true;
  bool _isPosting = false;
  int _currentPreviewIndex = 0;

  @override
  void dispose() {
    _captionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final remaining = 10 - _selectedImages.length;
    if (remaining <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Maximum 10 photos allowed'),
          backgroundColor: AppTheme.warningColor,
        ),
      );
      return;
    }

    final List<XFile> images = await _imagePicker.pickMultiImage(
      maxWidth: 1080,
      maxHeight: 1080,
      imageQuality: 85,
    );

    if (images.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(
          images.take(remaining).map((xfile) => File(xfile.path)),
        );
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
      if (_currentPreviewIndex >= _selectedImages.length &&
          _selectedImages.isNotEmpty) {
        _currentPreviewIndex = _selectedImages.length - 1;
      }
    });
  }

  Future<void> _sharePost() async {
    if (_selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one photo'),
          backgroundColor: AppTheme.warningColor,
        ),
      );
      return;
    }

    final auth = context.read<AuthProvider>();
    final social = context.read<SocialProvider>();
    final userId = auth.userId;

    if (userId == null) return;

    setState(() => _isPosting = true);

    try {
      await social.createPost(
        userId: userId,
        mediaFiles: _selectedImages,
        caption: _captionController.text.trim().isEmpty
            ? null
            : _captionController.text.trim(),
        location: _selectedLocation,
        tags: _extractTags(_captionController.text),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Post shared successfully!'),
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
        setState(() => _isPosting = false);
      }
    }
  }

  List<String> _extractTags(String text) {
    final tagRegex = RegExp(r'#(\w+)');
    return tagRegex
        .allMatches(text)
        .map((match) => match.group(1)!)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceColor,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back_ios,
            color: AppTheme.textPrimary,
            size: 22,
          ),
        ),
        title: const Text(
          'New Post',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _isPosting ? null : _sharePost,
            child: _isPosting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: AppTheme.primaryColor,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'Share',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryColor,
                    ),
                  ),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_selectedImages.isNotEmpty) _buildImagePreview(),
          if (_selectedImages.isEmpty) _buildImagePickerGrid(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildCaptionField(),
                const SizedBox(height: 16),
                _buildLocationPicker(),
                const SizedBox(height: 16),
                _buildTagPeople(),
                const SizedBox(height: 16),
                _buildShareToFeedToggle(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreview() {
    return Container(
      height: MediaQuery.of(context).size.width,
      width: double.infinity,
      color: Colors.black,
      child: Stack(
        children: [
          PageView.builder(
            itemCount: _selectedImages.length,
            onPageChanged: (index) {
              setState(() => _currentPreviewIndex = index);
            },
            itemBuilder: (context, index) {
              return Image.file(
                _selectedImages[index],
                fit: BoxFit.contain,
                width: double.infinity,
                height: double.infinity,
              );
            },
          ),
          Positioned(
            top: 12,
            right: 12,
            child: GestureDetector(
              onTap: () => _removeImage(_currentPreviewIndex),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
          if (_selectedImages.length > 1)
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_currentPreviewIndex + 1}/${_selectedImages.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          if (_selectedImages.length > 1)
            Positioned(
              bottom: 12,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _selectedImages.length.clamp(0, 10),
                  (index) => Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: index == _currentPreviewIndex
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.4),
                    ),
                  ),
                ),
              ),
            ),
          Positioned(
            bottom: 12,
            right: 12,
            child: GestureDetector(
              onTap: _pickImages,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_photo_alternate, color: Colors.white, size: 18),
                    SizedBox(width: 6),
                    Text(
                      'Add',
                      style: TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePickerGrid() {
    return Container(
      height: 200,
      color: AppTheme.surfaceColor,
      child: Center(
        child: GestureDetector(
          onTap: _pickImages,
          child: Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              color: AppTheme.backgroundColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.dividerColor,
                width: 2,
                style: BorderStyle.solid,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add_photo_alternate_outlined,
                  size: 48,
                  color: AppTheme.primaryColor.withValues(alpha: 0.6),
                ),
                const SizedBox(height: 8),
                Text(
                  'Add Photos',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.primaryColor.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Up to 10',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCaptionField() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(12),
      child: TextField(
        controller: _captionController,
        maxLines: 5,
        minLines: 3,
        textCapitalization: TextCapitalization.sentences,
        style: const TextStyle(
          fontSize: 15,
          color: AppTheme.textPrimary,
          height: 1.4,
        ),
        decoration: const InputDecoration(
          hintText: 'Write a caption...',
          hintStyle: TextStyle(color: AppTheme.textHint),
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
        onChanged: (value) {
          setState(() {});
        },
      ),
    );
  }

  Widget _buildLocationPicker() {
    return GestureDetector(
      onTap: _showLocationPicker,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.location_on_outlined,
              color: AppTheme.primaryColor,
              size: 22,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _selectedLocation ?? 'Add location',
                style: TextStyle(
                  fontSize: 14,
                  color: _selectedLocation != null
                      ? AppTheme.textPrimary
                      : AppTheme.textSecondary,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: AppTheme.textSecondary,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  void _showLocationPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.85,
        expand: false,
        builder: (context, scrollController) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Select Location',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    if (_selectedLocation != null)
                      TextButton(
                        onPressed: () {
                          setState(() => _selectedLocation = null);
                          Navigator.pop(context);
                        },
                        child: const Text(
                          'Clear',
                          style: TextStyle(color: AppTheme.errorColor),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: UserModel.districts.length,
                  itemBuilder: (context, index) {
                    final district = UserModel.districts[index];
                    final isSelected = _selectedLocation == district;
                    return ListTile(
                      leading: Icon(
                        Icons.location_on,
                        color: isSelected
                            ? AppTheme.primaryColor
                            : AppTheme.textSecondary,
                      ),
                      title: Text(
                        district,
                        style: TextStyle(
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.normal,
                          color: isSelected
                              ? AppTheme.primaryColor
                              : AppTheme.textPrimary,
                        ),
                      ),
                      trailing: isSelected
                          ? const Icon(Icons.check_circle, color: AppTheme.primaryColor)
                          : null,
                      onTap: () {
                        setState(() => _selectedLocation = district);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTagPeople() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.person_add_outlined,
            color: AppTheme.primaryColor,
            size: 22,
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Tag people',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          Icon(
            Icons.chevron_right,
            color: AppTheme.textSecondary,
            size: 22,
          ),
        ],
      ),
    );
  }

  Widget _buildShareToFeedToggle() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.feed_outlined,
            color: AppTheme.primaryColor,
            size: 22,
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Share to Feed',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          Switch(
            value: _shareToFeed,
            onChanged: (value) {
              setState(() => _shareToFeed = value);
            },
            activeColor: Colors.white,
            activeTrackColor: AppTheme.primaryColor,
          ),
        ],
      ),
    );
  }
}
