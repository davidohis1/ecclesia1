import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/constants/app_constants.dart';
import '../../../models/post_model.dart';
import '../../../services/bunny_storage_service.dart';
import '../../../services/auth_service.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _textCtrl = TextEditingController();
  final _picker = ImagePicker();
  final _bunny = BunnyStorageService();
  final _firestore = FirebaseFirestore.instance;
  final _authService = AuthService();

  List<File> _mediaFiles = [];
  String? _selectedBg;
  bool _loading = false;
  double _uploadProgress = 0;
  bool _isVideo = false;

  Future<void> _pickImages() async {
    final files = await _picker.pickMultiImage(imageQuality: 80);
    if (files.isNotEmpty) {
      setState(() {
        _mediaFiles = files.map((f) => File(f.path)).toList();
        _isVideo = false;
        _selectedBg = null;
      });
    }
  }

  Future<void> _pickVideo() async {
    final file = await _picker.pickVideo(
      source: ImageSource.gallery,
      maxDuration: const Duration(minutes: 5),
    );
    if (file != null) {
      final size = await File(file.path).length();
      final sizeMb = size / (1024 * 1024);
      if (sizeMb > AppConstants.maxReelSizeMb) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Video must be under 50MB')),
        );
        return;
      }
      setState(() {
        _mediaFiles = [File(file.path)];
        _isVideo = true;
        _selectedBg = null;
      });
    }
  }

  Future<void> _post() async {
    if (_textCtrl.text.trim().isEmpty && _mediaFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add text or media to post')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final user = await _authService.getUserById(uid);
      if (user == null) return;

      List<String> mediaUrls = [];
      double fileCount = _mediaFiles.length.toDouble();

      for (int i = 0; i < _mediaFiles.length; i++) {
        final ext = _isVideo ? 'mp4' : 'jpg';
        final filename = _bunny.generateFilename('post_${uid}_$i', ext);
        final url = await _bunny.uploadFile(
          file: _mediaFiles[i],
          folder: AppConstants.folderPosts,
          filename: filename,
          onProgress: (p) =>
              setState(() => _uploadProgress = (i + p) / fileCount),
        );
        if (url != null) mediaUrls.add(url);
      }

      PostType type;
      if (_mediaFiles.isEmpty) {
        type = PostType.text;
      } else if (_isVideo) {
        type = PostType.video;
      } else if (mediaUrls.length == 1) {
        type = PostType.image;
      } else {
        type = PostType.mixed;
      }

      final post = PostModel(
        id: '',
        authorId: uid,
        authorName: user.name,
        authorUsername: user.username,
        authorProfilePic: user.profilePicUrl,
        textContent: _textCtrl.text.trim().isEmpty ? null : _textCtrl.text.trim(),
        mediaUrls: mediaUrls,
        type: type,
        backgroundGradientId: _selectedBg,
        createdAt: DateTime.now(),
        isAuthorVerified: user.isVerified,
      );

      await _firestore.collection(AppConstants.colPosts).add(post.toMap());
      await _firestore.collection(AppConstants.colUsers).doc(uid).update({
        'postsCount': FieldValue.increment(1),
      });

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.error),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        backgroundColor: AppTheme.bgCard,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Create Post',
          style: GoogleFonts.playfairDisplay(
            fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GradientButton(
              label: 'Share',
              onTap: _post,
              loading: _loading,
              height: 38,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Upload progress
          if (_loading && _uploadProgress > 0)
            LinearProgressIndicator(
              value: _uploadProgress,
              backgroundColor: AppTheme.bgElevated,
              valueColor: const AlwaysStoppedAnimation(AppTheme.primary),
            ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Warning banner
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.accent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppTheme.accent.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Text('✝️', style: TextStyle(fontSize: 18)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Please ensure your post is Christ-centred and edifying to the Body of Christ.',
                            style: GoogleFonts.dmSans(
                              color: AppTheme.accent,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Text field with bg preview
                  _buildTextArea(),
                  const SizedBox(height: 20),
                  // Background color picker (for text posts)
                  if (_mediaFiles.isEmpty) _buildBgPicker(),
                  // Media preview
                  if (_mediaFiles.isNotEmpty) _buildMediaPreview(),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          // Bottom toolbar
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildTextArea() {
    if (_selectedBg != null && _selectedBg != 'none' && _mediaFiles.isEmpty) {
      final bg = PostBackgrounds.gradients.firstWhere(
          (g) => g['id'] == _selectedBg, orElse: () => PostBackgrounds.gradients.first);
      final colors = bg['colors'] as List<Color>;
      if (colors.isNotEmpty) {
        return Container(
          height: 220,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: colors),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: IntrinsicWidth(
              child: TextField(
                controller: _textCtrl,
                maxLines: null,
                textAlign: TextAlign.center,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 20,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Share a word of faith...',
                  hintStyle: TextStyle(color: Colors.white60, fontSize: 18),
                  fillColor: Colors.transparent,
                  filled: false,
                ),
              ),
            ),
          ),
        );
      }
    }

    return TextField(
      controller: _textCtrl,
      maxLines: null,
      style: GoogleFonts.dmSans(color: AppTheme.textPrimary, fontSize: 16, height: 1.6),
      decoration: InputDecoration(
        hintText: "What's on your heart today?",
        hintStyle: GoogleFonts.dmSans(color: AppTheme.textMuted, fontSize: 16),
        border: InputBorder.none,
        fillColor: Colors.transparent,
        filled: false,
      ),
    );
  }

  Widget _buildBgPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Post Background',
          style: GoogleFonts.dmSans(
              color: AppTheme.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 44,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: PostBackgrounds.gradients.length,
            itemBuilder: (_, i) {
              final bg = PostBackgrounds.gradients[i];
              final isSelected = _selectedBg == bg['id'];
              final colors = bg['colors'] as List<Color>;

              return GestureDetector(
                onTap: () => setState(() => _selectedBg = bg['id'] as String),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(right: 10),
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: colors.isNotEmpty
                        ? LinearGradient(colors: colors)
                        : null,
                    color: colors.isEmpty ? AppTheme.bgElevated : null,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? Colors.white : Colors.transparent,
                      width: 2.5,
                    ),
                  ),
                  child: colors.isEmpty
                      ? const Icon(Icons.not_interested_rounded,
                          color: AppTheme.textMuted, size: 18)
                      : null,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMediaPreview() {
    return Stack(
      children: [
        Container(
          height: 200,
          decoration: BoxDecoration(
            color: AppTheme.bgElevated,
            borderRadius: BorderRadius.circular(16),
          ),
          child: _isVideo
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.videocam, color: AppTheme.primary, size: 48),
                      SizedBox(height: 8),
                      Text('Video selected',
                          style: TextStyle(color: AppTheme.textSecondary)),
                    ],
                  ),
                )
              : ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.all(8),
                  itemCount: _mediaFiles.length,
                  itemBuilder: (_, i) => Container(
                    margin: const EdgeInsets.only(right: 8),
                    width: 180,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      image: DecorationImage(
                        image: FileImage(_mediaFiles[i]),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: GestureDetector(
            onTap: () => setState(() {
              _mediaFiles = [];
              _isVideo = false;
            }),
            child: Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                  color: Colors.black54, shape: BoxShape.circle),
              child: const Icon(Icons.close, color: Colors.white, size: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.06))),
      ),
      child: Row(
        children: [
          _ToolBtn(
            icon: Icons.image_outlined,
            label: 'Photo',
            onTap: _pickImages,
          ),
          const SizedBox(width: 8),
          _ToolBtn(
            icon: Icons.videocam_outlined,
            label: 'Video',
            onTap: _pickVideo,
          ),
          const SizedBox(width: 8),
          _ToolBtn(
            icon: Icons.text_fields_rounded,
            label: 'Text BG',
            onTap: () => setState(() {
              _mediaFiles = [];
              _selectedBg = _selectedBg == null ? 'royal' : null;
            }),
          ),
        ],
      ),
    );
  }
}

class _ToolBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ToolBtn({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.bgElevated,
          borderRadius: BorderRadius.circular(50),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppTheme.primary, size: 18),
            const SizedBox(width: 6),
            Text(label,
                style: GoogleFonts.dmSans(
                    color: AppTheme.textSecondary, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
