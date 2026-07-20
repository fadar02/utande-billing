import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/providers.dart';
import '../../theme/app_theme.dart';

class CreateReelScreen extends StatefulWidget {
  const CreateReelScreen({super.key});

  @override
  State<CreateReelScreen> createState() => _CreateReelScreenState();
}

class _CreateReelScreenState extends State<CreateReelScreen> {
  final _captionController = TextEditingController();
  final _imagePicker = ImagePicker();
  File? _selectedVideo;
  String _selectedAudio = 'Select a song';
  final List<String> _selectedTags = [];
  bool _isUploading = false;

  final List<Map<String, String>> _availableSongs = [
    {'title': 'Zunguza', 'artist': 'Billy Kaunda'},
    {'title': 'Cholapanyo', 'artist': 'Gwamba'},
    {'title': 'Tikuferanji', 'artist': 'Saulos Chilima'},
    {'title': 'Ndine Wanga', 'artist': 'Faith Mussa'},
    {'title': 'Mphatso', 'artist': 'Lucius Banda'},
    {'title': 'Ndale', 'artist': 'Hyphen'},
    {'title': 'Ndakayamba', 'artist': 'Scammer'},
    {'title': 'Wosakhala', 'artist': 'Lilongwe Boys'},
    {'title': 'Ndiwe Wokongola', 'artist': 'Henry Kamwendo'},
    {'title': 'Malawi', 'artist': 'Mafunyane Band'},
  ];

  Future<void> _pickVideo() async {
    final picked = await _imagePicker.pickVideo(
      source: ImageSource.gallery,
      maxDuration: const Duration(seconds: 60),
    );
    if (picked != null) {
      setState(() {
        _selectedVideo = File(picked.path);
      });
    }
  }

  void _showAudioPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          height: MediaQuery.of(context).size.height * 0.5,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[600],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Select Audio',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: _availableSongs.length,
                  itemBuilder: (context, index) {
                    final song = _availableSongs[index];
                    final isSelected =
                        _selectedAudio == '${song['title']} - ${song['artist']}';
                    return ListTile(
                      leading: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.primaryColor
                              : Colors.grey[800],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.music_note,
                          color:
                              isSelected ? Colors.white : Colors.grey[400],
                        ),
                      ),
                      title: Text(
                        song['title']!,
                        style: TextStyle(
                          color: isSelected
                              ? AppTheme.primaryColor
                              : Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: Text(
                        song['artist']!,
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 13,
                        ),
                      ),
                      trailing: isSelected
                          ? Icon(Icons.check_circle,
                              color: AppTheme.primaryColor)
                          : null,
                      onTap: () {
                        setState(() {
                          _selectedAudio =
                              '${song['title']} - ${song['artist']}';
                        });
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showTagDialog() {
    final tagController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.cardColor,
          title: const Text(
            'Add Tag',
            style: TextStyle(color: Colors.white),
          ),
          content: TextField(
            controller: tagController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Enter tag...',
              hintStyle: TextStyle(color: Colors.grey[400]),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: AppTheme.primaryColor),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.grey[400]),
              ),
            ),
            TextButton(
              onPressed: () {
                if (tagController.text.isNotEmpty) {
                  setState(() {
                    _selectedTags.add('#${tagController.text.trim()}');
                  });
                  Navigator.pop(context);
                }
              },
              child: Text(
                'Add',
                style: TextStyle(color: AppTheme.primaryColor),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _createReel() async {
    final auth = context.read<AuthProvider>();
    final social = context.read<SocialProvider>();

    if (_selectedVideo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a video')),
      );
      return;
    }

    if (_captionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add a caption')),
      );
      return;
    }

    if (auth.userId == null) return;

    setState(() => _isUploading = true);

    try {
      await social.createReel(
        userId: auth.userId!,
        videoFile: _selectedVideo!,
        caption: _captionController.text.trim(),
        audio: _selectedAudio,
        tags: _selectedTags,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reel created successfully!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Create Reel',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _isUploading ? null : _createReel,
            child: Text(
              'Share',
              style: TextStyle(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: _pickVideo,
                  child: Container(
                    height: 400,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppTheme.primaryColor.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: _selectedVideo != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Image.file(
                                  _selectedVideo!,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
                                ),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.5),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.play_arrow,
                                    color: Colors.white,
                                    size: 40,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_a_photo,
                                size: 64,
                                color: AppTheme.primaryColor,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Tap to select video',
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Max 60 seconds',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _captionController,
                  maxLines: 3,
                  maxLength: 300,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Write a caption...',
                    hintStyle: TextStyle(color: Colors.grey[500]),
                    filled: true,
                    fillColor: Colors.grey[900],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppTheme.primaryColor),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: _showAudioPicker,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.music_note,
                            color: AppTheme.primaryColor, size: 22),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _selectedAudio,
                            style: TextStyle(
                              color: _selectedAudio == 'Select a song'
                                  ? Colors.grey[500]
                                  : Colors.white,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        Icon(Icons.chevron_right,
                            color: Colors.grey[500], size: 22),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: _showTagDialog,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.tag,
                            color: AppTheme.primaryColor, size: 22),
                        const SizedBox(width: 12),
                        Text(
                          'Tag people',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_selectedTags.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _selectedTags.map((tag) {
                      return Chip(
                        label: Text(tag),
                        backgroundColor:
                            AppTheme.primaryColor.withValues(alpha: 0.2),
                        labelStyle: TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                        deleteIcon: Icon(
                          Icons.close,
                          size: 18,
                          color: AppTheme.primaryColor,
                        ),
                        onDeleted: () {
                          setState(() {
                            _selectedTags.remove(tag);
                          });
                        },
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
          if (_isUploading)
            Container(
              color: Colors.black.withValues(alpha: 0.7),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: AppTheme.primaryColor),
                    SizedBox(height: 16),
                    Text(
                      'Uploading reel...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
