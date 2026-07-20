import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../../models/user_model.dart';
import '../../l10n/app_localizations.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  final _picker = ImagePicker();

  late double _age;
  late String _gender;
  late String _district;
  late String _occupation;
  late String _education;
  String? _religion;
  String? _tribe;
  String? _height;
  late List<String> _interests;
  late String _lookingFor;
  late String _relationshipType;
  late RangeValues _ageRange;
  late double _distance;
  late List<String> _photos;
  final List<File> _newPhotos = [];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    if (user != null) {
      _nameController.text = user.name;
      _bioController.text = user.bio;
      _age = user.age.toDouble().clamp(18, 60);
      _gender = user.gender;
      _district = user.district;
      _occupation = user.occupation;
      _education = user.education;
      _religion = user.religion;
      _tribe = user.tribe;
      _height = user.height;
      _interests = List<String>.from(user.interests);
      _lookingFor = user.lookingFor;
      _relationshipType = user.relationshipType ?? 'Serious relationship';
      _ageRange = RangeValues(
        double.tryParse(user.ageRangeMin ?? '18') ?? 18,
        double.tryParse(user.ageRangeMax ?? '35') ?? 35,
      );
      _distance = double.tryParse(user.distancePreference ?? '20') ?? 20;
      _photos = List<String>.from(user.photos);
    } else {
      _age = 25;
      _gender = 'Male';
      _district = '';
      _occupation = '';
      _education = '';
      _interests = [];
      _lookingFor = 'Female';
      _relationshipType = 'Serious relationship';
      _ageRange = const RangeValues(18, 35);
      _distance = 20;
      _photos = [];
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    if (_photos.length + _newPhotos.length >= 6) return;
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked != null) {
      setState(() {
        _newPhotos.add(File(picked.path));
      });
    }
  }

  void _removeExistingPhoto(int index) {
    setState(() {
      _photos.removeAt(index);
    });
  }

  void _removeNewPhoto(int index) {
    setState(() {
      _newPhotos.removeAt(index);
    });
  }

  void _toggleInterest(String interest) {
    setState(() {
      if (_interests.contains(interest)) {
        _interests.remove(interest);
      } else {
        _interests.add(interest);
      }
    });
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final auth = context.read<AuthProvider>();

    if (_newPhotos.isNotEmpty) {
      await auth.uploadPhotos(_newPhotos);
    }

    final data = {
      'name': _nameController.text.trim(),
      'bio': _bioController.text.trim(),
      'age': _age.round(),
      'gender': _gender,
      'district': _district,
      'occupation': _occupation,
      'education': _education,
      'religion': _religion,
      'tribe': _tribe,
      'height': _height,
      'interests': _interests,
      'lookingFor': _lookingFor,
      'relationshipType': _relationshipType,
      'ageRangeMin': _ageRange.start.round().toString(),
      'ageRangeMax': _ageRange.end.round().toString(),
      'distancePreference': _distance.round().toString(),
      'photos': _photos,
    };

    final success = await auth.updateProfile(data);

    setState(() => _isSaving = false);

    if (mounted && success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully!'),
          backgroundColor: AppTheme.successColor,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalPhotos = _photos.length + _newPhotos.length;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveProfile,
            child: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.primaryColor,
                    ),
                  )
                : const Text(
                    'Done',
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
          Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPhotoSection(totalPhotos),
                  const SizedBox(height: 24),
                  _buildFormSection(),
                  const SizedBox(height: 20),
                  _buildInterestsSection(),
                  const SizedBox(height: 20),
                  _buildLookingForSection(),
                  const SizedBox(height: 20),
                  _buildRelationshipSection(),
                  const SizedBox(height: 20),
                  _buildPreferencesSection(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
          if (_isSaving) const LoadingOverlay(message: 'Saving profile...'),
        ],
      ),
    );
  }

  Widget _buildPhotoSection(int totalPhotos) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: GestureDetector(
            onTap: _pickImage,
            child: Stack(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.primaryLight,
                  ),
                  child: ClipOval(
                    child: _newPhotos.isNotEmpty
                        ? Image.file(
                            _newPhotos.first,
                            fit: BoxFit.cover,
                          )
                        : (_photos.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: _photos.first,
                                fit: BoxFit.cover,
                                errorWidget: (context, url, error) =>
                                    const Icon(Icons.person,
                                        size: 50,
                                        color: AppTheme.primaryColor),
                              )
                            : const Icon(Icons.person,
                                size: 50,
                                color: AppTheme.primaryColor)),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(Icons.camera_alt,
                        color: Colors.white, size: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
        const Center(
          child: Text(
            'Change Photo',
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (totalPhotos < 6)
          Center(
            child: GestureDetector(
              onTap: _pickImage,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppTheme.primaryColor.withValues(alpha: 0.3),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_photo_alternate_outlined,
                        size: 18, color: AppTheme.primaryColor),
                    SizedBox(width: 6),
                    Text(
                      'Add Photo',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        const SizedBox(height: 16),
        SizedBox(
          height: 80,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: totalPhotos,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final isExisting = index < _photos.length;
              return Stack(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: AppTheme.primaryLight,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: isExisting
                          ? CachedNetworkImage(
                              imageUrl: _photos[index],
                              fit: BoxFit.cover,
                              errorWidget: (context, url, error) =>
                                  const Icon(Icons.image,
                                      color: AppTheme.primaryColor),
                            )
                          : Image.file(
                              _newPhotos[index - _photos.length],
                              fit: BoxFit.cover,
                            ),
                    ),
                  ),
                  Positioned(
                    top: 2,
                    right: 2,
                    child: GestureDetector(
                      onTap: () {
                        if (isExisting) {
                          _removeExistingPhoto(index);
                        } else {
                          _removeNewPhoto(index - _photos.length);
                        }
                      },
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close,
                            color: Colors.white, size: 14),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFormSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Basic Info'),
        const SizedBox(height: 12),
        _buildTextField(
          controller: _nameController,
          label: AppLocalizations.t('name'),
          icon: Icons.person_outline,
          validator: (v) =>
              v == null || v.trim().isEmpty ? 'Name is required' : null,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _bioController,
          label: AppLocalizations.t('bio'),
          icon: Icons.info_outline,
          maxLines: 3,
          counter: '${_bioController.text.length}/150',
        ),
        const SizedBox(height: 16),
        _buildSectionTitle('Details'),
        const SizedBox(height: 12),
        _buildAgeSlider(),
        const SizedBox(height: 16),
        _buildGenderSelector(),
        const SizedBox(height: 16),
        _buildDropdown(
          label: AppLocalizations.t('district'),
          value: _district.isEmpty ? null : _district,
          items: UserModel.districts,
          onChanged: (v) => setState(() => _district = v ?? ''),
        ),
        const SizedBox(height: 16),
        _buildDropdown(
          label: AppLocalizations.t('occupation'),
          value: _occupation.isEmpty ? null : _occupation,
          items: UserModel.occupationsList,
          onChanged: (v) => setState(() => _occupation = v ?? ''),
        ),
        const SizedBox(height: 16),
        _buildDropdown(
          label: AppLocalizations.t('education'),
          value: _education.isEmpty ? null : _education,
          items: UserModel.educationList,
          onChanged: (v) => setState(() => _education = v ?? ''),
        ),
        const SizedBox(height: 16),
        _buildDropdown(
          label: AppLocalizations.t('religion'),
          value: _religion,
          items: UserModel.religionsList,
          onChanged: (v) => setState(() => _religion = v),
        ),
        const SizedBox(height: 16),
        _buildDropdown(
          label: AppLocalizations.t('tribe'),
          value: _tribe,
          items: UserModel.tribesList,
          onChanged: (v) => setState(() => _tribe = v),
        ),
        const SizedBox(height: 16),
        _buildDropdown(
          label: AppLocalizations.t('height'),
          value: _height,
          items: UserModel.heightsList,
          onChanged: (v) => setState(() => _height = v),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: AppTheme.textPrimary,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    String? counter,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppTheme.primaryColor),
        suffixText: counter,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.dividerColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.dividerColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: AppTheme.primaryColor, width: 2),
        ),
      ),
    );
  }

  Widget _buildAgeSlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              AppLocalizations.t('age'),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.primaryLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_age.round()} years',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
          ],
        ),
        Slider(
          value: _age,
          min: 18,
          max: 60,
          divisions: 42,
          activeColor: AppTheme.primaryColor,
          inactiveColor: AppTheme.dividerColor,
          onChanged: (v) => setState(() => _age = v),
        ),
      ],
    );
  }

  Widget _buildGenderSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.t('gender'),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildRadioOption(
              title: AppLocalizations.t('male'),
              value: 'Male',
              groupValue: _gender,
              onChanged: (v) => setState(() => _gender = v!),
            ),
            const SizedBox(width: 12),
            _buildRadioOption(
              title: AppLocalizations.t('female'),
              value: 'Female',
              groupValue: _gender,
              onChanged: (v) => setState(() => _gender = v!),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRadioOption({
    required String title,
    required String value,
    required String groupValue,
    required ValueChanged<String?> onChanged,
  }) {
    final isSelected = value == groupValue;
    return Expanded(
      child: GestureDetector(
        onTap: () => onChanged(value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.primaryColor.withValues(alpha: 0.08)
                : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppTheme.primaryColor : AppTheme.dividerColor,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected
                    ? AppTheme.primaryColor
                    : AppTheme.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.dividerColor),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: value,
              hint: Text(
                'Select $label',
                style: const TextStyle(color: AppTheme.textHint),
              ),
              icon: const Icon(Icons.keyboard_arrow_down,
                  color: AppTheme.textSecondary),
              items: items.map((item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(item),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInterestsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(AppLocalizations.t('interests')),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: UserModel.interestsList.map((interest) {
            final isSelected = _interests.contains(interest);
            return GestureDetector(
              onTap: () => _toggleInterest(interest),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primaryColor : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? AppTheme.primaryColor
                        : AppTheme.dividerColor,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      interest,
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : AppTheme.textPrimary,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.normal,
                        fontSize: 13,
                      ),
                    ),
                    if (isSelected) ...[
                      const SizedBox(width: 4),
                      const Icon(Icons.check,
                          size: 14, color: Colors.white),
                    ],
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildLookingForSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(AppLocalizations.t('looking_for')),
        const SizedBox(height: 12),
        Row(
          children: ['Male', 'Female', 'Both'].map((option) {
            final isSelected = _lookingFor == option;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _lookingFor = option),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.primaryColor
                        : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.primaryColor
                          : AppTheme.dividerColor,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      option,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? Colors.white
                            : AppTheme.textPrimary,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildRelationshipSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(AppLocalizations.t('relationship_type')),
        const SizedBox(height: 12),
        ...UserModel.relationshipTypes.map((type) {
          final isSelected = _relationshipType == type;
          return GestureDetector(
            onTap: () => setState(() => _relationshipType = type),
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.primaryColor.withValues(alpha: 0.08)
                    : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? AppTheme.primaryColor
                      : AppTheme.dividerColor,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? AppTheme.primaryColor
                            : AppTheme.textHint,
                        width: 2,
                      ),
                    ),
                    child: isSelected
                        ? const Center(
                            child: Icon(Icons.circle,
                                size: 10, color: AppTheme.primaryColor),
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    type,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isSelected
                          ? AppTheme.primaryColor
                          : AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildPreferencesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Preferences'),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              AppLocalizations.t('age_range'),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.primaryLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_ageRange.start.round()} - ${_ageRange.end.round()}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
          ],
        ),
        RangeSlider(
          values: _ageRange,
          min: 18,
          max: 60,
          divisions: 42,
          activeColor: AppTheme.primaryColor,
          inactiveColor: AppTheme.dividerColor,
          onChanged: (v) => setState(() => _ageRange = v),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              AppLocalizations.t('distance'),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.primaryLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_distance.round()} km',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
          ],
        ),
        Slider(
          value: _distance,
          min: 1,
          max: 100,
          divisions: 99,
          activeColor: AppTheme.primaryColor,
          inactiveColor: AppTheme.dividerColor,
          onChanged: (v) => setState(() => _distance = v),
        ),
      ],
    );
  }
}
