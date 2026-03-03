import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/constants/app_constants.dart';
import '../../../services/auth_service.dart';
import '../../../services/bunny_storage_service.dart';
import '../../../models/user_model.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _authService = AuthService();
  final _bunny = BunnyStorageService();
  final _bioCtrl = TextEditingController();
  final _churchCtrl = TextEditingController();

  File? _profileImage;
  String? _gender;
  DateTime? _dob;
  bool? _givenLifeToChrist;
  bool _loading = false;
  double _uploadProgress = 0;

  final List<String> _genders = ['Male', 'Female', 'Prefer not to say'];

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
        source: ImageSource.gallery, imageQuality: 80, maxWidth: 800);
    if (picked != null) {
      setState(() => _profileImage = File(picked.path));
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(1990, 1, 1),
      firstDate: DateTime(1920),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 13)),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppTheme.primary,
            surface: AppTheme.bgCard,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _dob = picked);
  }

  Future<void> _save() async {
    if (_givenLifeToChrist == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please answer all required questions'),
          backgroundColor: AppTheme.error));
      return;
    }

    setState(() => _loading = true);

    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      String? picUrl;

      // Upload profile picture to Bunny
      if (_profileImage != null) {
        final filename = _bunny.generateFilename(uid, 'jpg');
        picUrl = await _bunny.uploadFile(
          file: _profileImage!,
          folder: AppConstants.folderProfiles,
          filename: filename,
          onProgress: (p) => setState(() => _uploadProgress = p),
        );
      }

      final currentUser = await _authService.getUserById(uid);
      if (currentUser == null) return;

      final updated = currentUser.copyWith(
        profilePicUrl: picUrl,
        bio: _bioCtrl.text.trim().isEmpty ? null : _bioCtrl.text.trim(),
        gender: _gender,
        dateOfBirth: _dob,
        churchAttending:
            _churchCtrl.text.trim().isEmpty ? null : _churchCtrl.text.trim(),
        givenLifeToChrist: _givenLifeToChrist ?? false,
      );

      await _authService.updateUserProfile(updated);

      if (mounted) {
        Navigator.pushReplacementNamed(context, AppRoutes.home);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Error: $e'), backgroundColor: AppTheme.error));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _bioCtrl.dispose();
    _churchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 180,
            backgroundColor: AppTheme.bgDark,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.primary, AppTheme.teal],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          'Complete Your Profile',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Help the community know you',
                          style: GoogleFonts.dmSans(
                              color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Picture
                  Center(
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: _pickImage,
                          child: Stack(
                            children: [
                              Container(
                                width: 110,
                                height: 110,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: const LinearGradient(
                                    colors: [
                                      AppTheme.primary,
                                      AppTheme.primaryLight
                                    ],
                                  ),
                                  border: Border.all(
                                      color: AppTheme.primary, width: 3),
                                ),
                                child: ClipOval(
                                  child: _profileImage != null
                                      ? Image.file(_profileImage!,
                                          fit: BoxFit.cover)
                                      : const Icon(Icons.person,
                                          color: Colors.white70, size: 50),
                                ),
                              ),
                              Positioned(
                                bottom: 4,
                                right: 4,
                                child: Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: AppTheme.accent,
                                    shape: BoxShape.circle,
                                    border:
                                        Border.all(color: AppTheme.bgDark, width: 2),
                                  ),
                                  child: const Icon(Icons.camera_alt,
                                      color: Colors.black, size: 16),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Add Profile Picture',
                          style: GoogleFonts.dmSans(
                            color: AppTheme.primaryLight,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Bio
                  EcclesiaTextField(
                    hint: 'Share a little about your faith journey...',
                    label: 'Bio',
                    controller: _bioCtrl,
                    maxLines: 3,
                    prefix: const Padding(
                      padding: EdgeInsets.only(bottom: 44),
                      child: Icon(Icons.edit_outlined,
                          color: AppTheme.textMuted, size: 18),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Gender
                  _SectionLabel(label: 'Gender'),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    children: _genders
                        .map((g) => GestureDetector(
                              onTap: () => setState(() => _gender = g),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 18, vertical: 10),
                                decoration: BoxDecoration(
                                  color: _gender == g
                                      ? AppTheme.primary
                                      : AppTheme.bgElevated,
                                  borderRadius: BorderRadius.circular(50),
                                  border: Border.all(
                                    color: _gender == g
                                        ? AppTheme.primary
                                        : Colors.white.withOpacity(0.1),
                                  ),
                                ),
                                child: Text(
                                  g,
                                  style: GoogleFonts.dmSans(
                                    color: _gender == g
                                        ? Colors.white
                                        : AppTheme.textSecondary,
                                    fontSize: 13,
                                    fontWeight: _gender == g
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 20),
                  // Date of Birth
                  _SectionLabel(label: 'Date of Birth'),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: _pickDate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 16),
                      decoration: BoxDecoration(
                        color: AppTheme.bgElevated,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white.withOpacity(0.08)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today_outlined,
                              color: AppTheme.textMuted, size: 18),
                          const SizedBox(width: 12),
                          Text(
                            _dob != null
                                ? DateFormat('MMMM d, yyyy').format(_dob!)
                                : 'Select your date of birth',
                            style: GoogleFonts.dmSans(
                              color: _dob != null
                                  ? AppTheme.textPrimary
                                  : AppTheme.textMuted,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Church
                  EcclesiaTextField(
                    hint: 'Name of your church',
                    label: 'Church Attending',
                    controller: _churchCtrl,
                    prefix: const Icon(Icons.church_outlined,
                        color: AppTheme.textMuted, size: 18),
                  ),
                  const SizedBox(height: 24),
                  // Given life to Christ
                  _SectionLabel(label: 'Have you given your life to Christ? *'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _YesNoButton(
                        label: 'Yes, I have! 🙏',
                        selected: _givenLifeToChrist == true,
                        onTap: () =>
                            setState(() => _givenLifeToChrist = true),
                      ),
                      const SizedBox(width: 12),
                      _YesNoButton(
                        label: 'Not yet',
                        selected: _givenLifeToChrist == false,
                        onTap: () =>
                            setState(() => _givenLifeToChrist = false),
                        isNo: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 36),
                  if (_loading && _uploadProgress > 0)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Column(
                        children: [
                          LinearProgressIndicator(
                            value: _uploadProgress,
                            backgroundColor: AppTheme.bgElevated,
                            valueColor: const AlwaysStoppedAnimation(AppTheme.primary),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Uploading... ${(_uploadProgress * 100).toInt()}%',
                            style: GoogleFonts.dmSans(
                                color: AppTheme.textMuted, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  GradientButton(
                    label: 'Complete Setup',
                    onTap: _save,
                    loading: _loading,
                    colors: const [AppTheme.primary, AppTheme.teal],
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: TextButton(
                      onPressed: () =>
                          Navigator.pushReplacementNamed(context, AppRoutes.home),
                      child: Text(
                        'Skip for now',
                        style: GoogleFonts.dmSans(
                            color: AppTheme.textMuted, fontSize: 13),
                      ),
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

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: GoogleFonts.dmSans(
        color: AppTheme.textSecondary,
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

class _YesNoButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool isNo;

  const _YesNoButton({
    required this.label,
    required this.selected,
    required this.onTap,
    this.isNo = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: selected
                ? (isNo ? AppTheme.bgElevated : AppTheme.primary)
                : AppTheme.bgElevated,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? (isNo ? AppTheme.textMuted : AppTheme.primary)
                  : Colors.white.withOpacity(0.08),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(
              color: selected ? Colors.white : AppTheme.textMuted,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
