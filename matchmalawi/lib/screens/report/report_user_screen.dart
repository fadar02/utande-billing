import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../../models/report_model.dart';

class ReportUserScreen extends StatefulWidget {
  const ReportUserScreen({super.key});

  @override
  State<ReportUserScreen> createState() => _ReportUserScreenState();
}

class _ReportUserScreenState extends State<ReportUserScreen> {
  String? _selectedReason;
  final _descriptionController = TextEditingController();
  final _picker = ImagePicker();
  File? _evidenceFile;
  bool _isSubmitting = false;
  bool _submitted = false;

  String? get _reportedUserId =>
      ModalRoute.of(context)?.settings.arguments as String?;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickEvidence() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) {
      setState(() => _evidenceFile = File(picked.path));
    }
  }

  Future<void> _submitReport() async {
    if (_selectedReason == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a reason'), backgroundColor: AppTheme.errorColor),
      );
      return;
    }

    if (_reportedUserId == null) return;

    final auth = context.read<AuthProvider>();
    final safety = context.read<SafetyProvider>();
    final currentUser = auth.user;
    if (currentUser == null) return;

    setState(() => _isSubmitting = true);

    await safety.reportUser(
      reporterId: currentUser.id,
      reportedUserId: _reportedUserId!,
      reason: _selectedReason!,
      description: _descriptionController.text.isNotEmpty ? _descriptionController.text : null,
    );

    setState(() {
      _isSubmitting = false;
      _submitted = true;
    });
  }

  void _blockAndClose() async {
    final auth = context.read<AuthProvider>();
    final safety = context.read<SafetyProvider>();
    if (auth.userId != null && _reportedUserId != null) {
      await safety.blockUser(auth.userId!, _reportedUserId!);
    }
    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User blocked'), backgroundColor: AppTheme.successColor),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_submitted) return _buildSuccessView();

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(title: const Text('Report User')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            const Text('Why are you reporting this user?',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
            const SizedBox(height: 4),
            const Text('Your report will be reviewed by our team.',
                style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
            const SizedBox(height: 16),
            _buildReasonOptions(),
            const SizedBox(height: 24),
            _buildDescriptionField(),
            const SizedBox(height: 20),
            _buildEvidenceSection(),
            const SizedBox(height: 32),
            GradientButton(
              text: 'Submit Report',
              onPressed: _submitReport,
              isLoading: _isSubmitting,
              icon: Icons.flag,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.errorColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.errorColor.withValues(alpha: 0.2)),
      ),
      child: const Row(
        children: [
          Icon(Icons.warning_amber, color: AppTheme.errorColor, size: 28),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Report a User', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                SizedBox(height: 2),
                Text('Help us maintain a safe community.', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReasonOptions() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: Column(
        children: ReportModel.reportReasons.map((reason) {
          final isSelected = _selectedReason == reason;
          final isLast = reason == ReportModel.reportReasons.last;
          return InkWell(
            onTap: () => setState(() => _selectedReason = reason),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                border: isLast ? null : const Border(bottom: BorderSide(color: AppTheme.dividerColor, width: 0.5)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: isSelected ? AppTheme.primaryColor : AppTheme.textHint, width: 2),
                    ),
                    child: isSelected
                        ? const Center(child: Icon(Icons.circle, size: 10, color: AppTheme.primaryColor))
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(reason, style: TextStyle(
                      fontSize: 15,
                      color: isSelected ? AppTheme.primaryColor : AppTheme.textPrimary,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    )),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDescriptionField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Additional Details (Optional)',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
        const SizedBox(height: 8),
        TextField(
          controller: _descriptionController,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'Provide any additional details about this report...',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.dividerColor)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.dividerColor)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2)),
          ),
        ),
      ],
    );
  }

  Widget _buildEvidenceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Evidence (Optional)',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
        const SizedBox(height: 8),
        if (_evidenceFile != null) ...[
          Stack(
            children: [
              Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: AppTheme.dividerColor,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(_evidenceFile!, fit: BoxFit.cover),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: () => setState(() => _evidenceFile = null),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                    child: const Icon(Icons.close, color: Colors.white, size: 16),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
        GestureDetector(
          onTap: _pickEvidence,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.dividerColor, style: BorderStyle.solid),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_photo_alternate_outlined, color: AppTheme.primaryColor),
                SizedBox(width: 8),
                Text('Upload Screenshot', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppTheme.primaryColor)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessView() {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.successColor.withValues(alpha: 0.1),
                ),
                child: const Icon(Icons.check_circle_outline, size: 56, color: AppTheme.successColor),
              ),
              const SizedBox(height: 24),
              const Text('Report Submitted', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
              const SizedBox(height: 8),
              const Text(
                'Thank you for helping keep Match Malawi safe. We will review your report.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _blockAndClose,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.errorColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  ),
                  child: const Text('Block this person too?', style: TextStyle(fontSize: 15, color: Colors.white, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppTheme.dividerColor),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  ),
                  child: const Text('Done', style: TextStyle(fontSize: 15, color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
