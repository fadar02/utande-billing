import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../providers/providers.dart';
import '../../models/user_model.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

class CreateProfileScreen extends StatefulWidget {
  const CreateProfileScreen({super.key});

  @override
  State<CreateProfileScreen> createState() => _CreateProfileScreenState();
}

class _CreateProfileScreenState extends State<CreateProfileScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  static const int _totalSteps = 5;

  final _nameController = TextEditingController();
  double _age = 25;
  String? _gender;
  String? _district;
  String? _occupation;
  String? _education;
  String? _religion;
  String? _tribe;
  String? _height;
  final Set<String> _interests = {};
  final _bioController = TextEditingController();
  final List<File> _photos = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      if (auth.user?.name != null) {
        _nameController.text = auth.user!.name!;
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (!_validateCurrentStep()) return;
    if (_currentStep < _totalSteps - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0:
        if (_nameController.text.trim().isEmpty) {
          _showError('Name is required');
          return false;
        }
        if (_gender == null) {
          _showError('Please select your gender');
          return false;
        }
        if (_district == null) {
          _showError('Please select your district');
          return false;
        }
        return true;
      case 2:
        if (_interests.length < 3) {
          _showError('Select at least 3 interests');
          return false;
        }
        return true;
      case 3:
        if (_bioController.text.trim().isEmpty) {
          _showError('Please write a bio');
          return false;
        }
        return true;
      case 4:
        return true;
      default:
        return true;
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final remaining = 6 - _photos.length;
    if (remaining <= 0) return;

    final picked = await picker.pickMultiImage(imageQuality: 80);
    final toAdd = picked.take(remaining).map((x) => File(x.path)).toList();
    setState(() => _photos.addAll(toAdd));
  }

  void _removePhoto(int index) {
    setState(() => _photos.removeAt(index));
  }

  Future<void> _handleDone() async {
    if (!_validateCurrentStep()) return;
    final auth = context.read<AuthProvider>();

    final profileData = {
      'name': _nameController.text.trim(),
      'age': _age.round(),
      'gender': _gender,
      'district': _district,
      'occupation': _occupation,
      'education': _education,
      'religion': _religion,
      'tribe': _tribe,
      'height': _height,
      'interests': _interests.toList(),
      'bio': _bioController.text.trim(),
    };

    final profileUpdated = await auth.updateProfile(profileData);
    if (!profileUpdated) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(auth.error ?? 'Failed to update profile'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    if (_photos.isNotEmpty) {
      final photosUploaded = await auth.uploadPhotos(_photos);
      if (!photosUploaded) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(auth.error ?? 'Failed to upload photos'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
    }

    if (mounted) {
      Navigator.pushReplacementNamed(context, '/main');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Profile'),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Row(
              children: List.generate(_totalSteps, (i) {
                final isActive = i <= _currentStep;
                return Expanded(
                  child: Container(
                    height: 4,
                    margin: EdgeInsets.only(right: i < _totalSteps - 1 ? 6 : 0),
                    decoration: BoxDecoration(
                      color: isActive
                          ? AppTheme.primaryColor
                          : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              }),
            ),
          ),
          Text(
            'Step ${_currentStep + 1} of $_totalSteps',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (i) => setState(() => _currentStep = i),
              children: [
                _buildStep1(),
                _buildStep2(),
                _buildStep3(),
                _buildStep4(),
                _buildStep5(),
              ],
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Row(
                children: [
                  if (_currentStep > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _prevStep,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Back'),
                      ),
                    ),
                  if (_currentStep > 0) const SizedBox(width: 12),
                  if (_currentStep == _totalSteps - 1)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: auth.isLoading ? () {} : () => _handleDone(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Skip'),
                      ),
                    ),
                  if (_currentStep == _totalSteps - 1) const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: GradientButton(
                      text: _currentStep == _totalSteps - 1 ? 'Done' : 'Next',
                      onPressed: auth.isLoading
                          ? () {}
                          : _currentStep == _totalSteps - 1
                              ? () => _handleDone()
                              : () => _nextStep(),
                      isLoading: auth.isLoading,
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

  Widget _buildStep1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Let's start with the basics",
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _nameController,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: 'Name',
              prefixIcon: const Icon(Icons.person_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Age: ${_age.round()}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Slider(
            value: _age,
            min: 18,
            max: 60,
            divisions: 42,
            activeColor: AppTheme.primaryColor,
            onChanged: (v) => setState(() => _age = v),
          ),
          const SizedBox(height: 16),
          Text(
            'Gender',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ChoiceChip(
                  label: const Text('Male'),
                  selected: _gender == 'Male',
                  selectedColor: AppTheme.primaryColor.withValues(alpha: 0.2),
                  onSelected: (_) => setState(() => _gender = 'Male'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ChoiceChip(
                  label: const Text('Female'),
                  selected: _gender == 'Female',
                  selectedColor: AppTheme.primaryColor.withValues(alpha: 0.2),
                  onSelected: (_) => setState(() => _gender = 'Female'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          DropdownButtonFormField<String>(
            value: _district,
            decoration: InputDecoration(
              labelText: 'District',
              prefixIcon: const Icon(Icons.location_on_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            items: UserModel.districts
                .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                .toList(),
            onChanged: (v) => setState(() => _district = v),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildStep2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tell us more about you',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 24),
          DropdownButtonFormField<String>(
            value: _occupation,
            decoration: InputDecoration(
              labelText: 'Occupation',
              prefixIcon: const Icon(Icons.work_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            items: UserModel.occupationsList
                .map((o) => DropdownMenuItem(value: o, child: Text(o)))
                .toList(),
            onChanged: (v) => setState(() => _occupation = v),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _education,
            decoration: InputDecoration(
              labelText: 'Education',
              prefixIcon: const Icon(Icons.school_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            items: UserModel.educationList
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged: (v) => setState(() => _education = v),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _religion,
            decoration: InputDecoration(
              labelText: 'Religion',
              prefixIcon: const Icon(Icons.church_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            items: UserModel.religionsList
                .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                .toList(),
            onChanged: (v) => setState(() => _religion = v),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _tribe,
            decoration: InputDecoration(
              labelText: 'Tribe',
              prefixIcon: const Icon(Icons.group_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            items: UserModel.tribesList
                .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                .toList(),
            onChanged: (v) => setState(() => _tribe = v),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _height,
            decoration: InputDecoration(
              labelText: 'Height',
              prefixIcon: const Icon(Icons.height),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            items: UserModel.heightsList
                .map((h) => DropdownMenuItem(value: h, child: Text(h)))
                .toList(),
            onChanged: (v) => setState(() => _height = v),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildStep3() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select your interests',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose at least 3',
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: UserModel.interestsList.map((interest) {
              final selected = _interests.contains(interest);
              return FilterChip(
                label: Text(interest),
                selected: selected,
                selectedColor: AppTheme.primaryColor.withValues(alpha: 0.2),
                checkmarkColor: AppTheme.primaryColor,
                onSelected: (val) {
                  setState(() {
                    if (val) {
                      _interests.add(interest);
                    } else {
                      _interests.remove(interest);
                    }
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Text(
            '${_interests.length} selected',
            style: TextStyle(
              color:
                  _interests.length >= 3 ? Colors.green : Colors.grey.shade500,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildStep4() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Write about yourself',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'This will be shown on your profile',
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _bioController,
            maxLines: 6,
            maxLength: 500,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: 'Tell others about yourself, your hobbies, what you enjoy...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${_bioController.text.length}/500',
            style: TextStyle(
              color: _bioController.text.length > 500
                  ? Colors.red
                  : Colors.grey.shade500,
              fontSize: 13,
            ),
            textAlign: TextAlign.end,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildStep5() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Add your photos',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add up to 6 photos (optional)',
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: _photos.length + (_photos.length < 6 ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == _photos.length) {
                return GestureDetector(
                  onTap: _pickPhoto,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.grey.shade300,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_a_photo_outlined,
                          size: 32,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Add',
                          style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      _photos[index],
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () => _removePhoto(index),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  if (index == 0)
                    Positioned(
                      bottom: 4,
                      left: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Main',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
