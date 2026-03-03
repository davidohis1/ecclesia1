import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:uuid/uuid.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/constants/app_constants.dart';
import '../../../models/other_models.dart';
import '../../../services/bunny_storage_service.dart';
import '../../../services/auth_service.dart';

class ReelsScreen extends StatefulWidget {
  const ReelsScreen({super.key});

  @override
  State<ReelsScreen> createState() => _ReelsScreenState();
}

class _ReelsScreenState extends State<ReelsScreen> {
  final _pageCtrl = PageController();
  final _firestore = FirebaseFirestore.instance;
  List<ReelModel> _reels = [];
  bool _loading = true;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadReels();
  }

  Future<void> _loadReels() async {
    final snap = await _firestore
        .collection(AppConstants.colReels)
        .orderBy('createdAt', descending: true)
        .limit(20)
        .get();
    setState(() {
      _reels = snap.docs.map((d) => ReelModel.fromMap(d.id, d.data())).toList();
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          if (_loading)
            const Center(
                child: CircularProgressIndicator(color: AppTheme.primary))
          else if (_reels.isEmpty)
            _EmptyReels(onUpload: _uploadReel)
          else
            PageView.builder(
              controller: _pageCtrl,
              scrollDirection: Axis.vertical,
              onPageChanged: (i) => setState(() => _currentIndex = i),
              itemCount: _reels.length,
              itemBuilder: (_, i) => _ReelPlayer(reel: _reels[i]),
            ),
          // Top overlay
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Reels',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [Shadow(blurRadius: 10, color: Colors.black54)],
                    ),
                  ),
                  GestureDetector(
                    onTap: _uploadReel,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(50),
                        border: Border.all(
                            color: Colors.white.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.add, color: Colors.white, size: 18),
                          const SizedBox(width: 4),
                          Text('Upload',
                              style: GoogleFonts.dmSans(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600)),
                        ],
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

  Future<void> _uploadReel() async {
    final picker = ImagePicker();
    final file = await picker.pickVideo(source: ImageSource.gallery);
    if (file == null) return;

    final size = await File(file.path).length();
    final sizeMb = size / (1024 * 1024);
    if (sizeMb > AppConstants.maxReelSizeMb) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Reel must be under 50MB'),
            backgroundColor: AppTheme.error));
      }
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.bgCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _UploadReelSheet(
        videoFile: File(file.path),
        onUploaded: () {
          Navigator.pop(context);
          _loadReels();
        },
      ),
    );
  }
}

class _ReelPlayer extends StatefulWidget {
  final ReelModel reel;
  const _ReelPlayer({required this.reel});

  @override
  State<_ReelPlayer> createState() => _ReelPlayerState();
}

class _ReelPlayerState extends State<_ReelPlayer> {
  VideoPlayerController? _controller;
  bool _liked = false;

  @override
  void initState() {
    super.initState();
    if (widget.reel.videoUrl.isNotEmpty) {
      _controller = VideoPlayerController.networkUrl(
          Uri.parse(widget.reel.videoUrl))
        ..initialize().then((_) {
          setState(() {});
          _controller?.play();
          _controller?.setLooping(true);
        });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (_controller?.value.isPlaying == true) {
          _controller?.pause();
        } else {
          _controller?.play();
        }
        setState(() {});
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Video
          Container(color: Colors.black),
          if (_controller?.value.isInitialized == true)
            FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _controller!.value.size.width,
                height: _controller!.value.size.height,
                child: VideoPlayer(_controller!),
              ),
            )
          else if (widget.reel.thumbnailUrl != null)
            Image.network(widget.reel.thumbnailUrl!, fit: BoxFit.cover),

          // Gradient overlay
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.8),
                  ],
                  stops: const [0.5, 1.0],
                ),
              ),
            ),
          ),

          // Right action buttons
          Positioned(
            right: 12,
            bottom: 120,
            child: Column(
              children: [
                _ReelActionBtn(
                  icon: _liked
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  label: '${widget.reel.likesCount}',
                  color: _liked ? AppTheme.rose : Colors.white,
                  onTap: () => setState(() => _liked = !_liked),
                ),
                const SizedBox(height: 20),
                _ReelActionBtn(
                  icon: Icons.chat_bubble_outline_rounded,
                  label: '${widget.reel.commentsCount}',
                  onTap: () {},
                ),
                const SizedBox(height: 20),
                _ReelActionBtn(
                  icon: Icons.share_outlined,
                  label: 'Share',
                  onTap: () {},
                ),
              ],
            ),
          ),

          // Bottom info
          Positioned(
            left: 16,
            right: 80,
            bottom: 40,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    UserAvatar(
                        name: widget.reel.authorName,
                        imageUrl: widget.reel.authorProfilePic,
                        size: 36),
                    const SizedBox(width: 8),
                    Text(
                      '@${widget.reel.authorUsername}',
                      style: GoogleFonts.dmSans(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                if (widget.reel.caption != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    widget.reel.caption!,
                    style: GoogleFonts.dmSans(color: Colors.white70, fontSize: 13),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),

          // Pause indicator
          if (_controller?.value.isInitialized == true &&
              !_controller!.value.isPlaying)
            const Center(
              child: Icon(Icons.play_arrow_rounded,
                  color: Colors.white70, size: 72),
            ),
        ],
      ),
    );
  }
}

class _ReelActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  const _ReelActionBtn({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: color, size: 28,
              shadows: const [Shadow(blurRadius: 8, color: Colors.black54)]),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.dmSans(
                color: Colors.white,
                fontSize: 11,
                shadows: const [Shadow(blurRadius: 6, color: Colors.black)]),
          ),
        ],
      ),
    );
  }
}

class _EmptyReels extends StatelessWidget {
  final VoidCallback onUpload;
  const _EmptyReels({required this.onUpload});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🎬', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 16),
          Text('No reels yet',
              style: GoogleFonts.playfairDisplay(
                  fontSize: 22, color: Colors.white)),
          const SizedBox(height: 8),
          Text('Be the first to post a Christian reel',
              style: GoogleFonts.dmSans(color: Colors.white60)),
          const SizedBox(height: 24),
          GradientButton(label: 'Upload Reel', onTap: onUpload, height: 44),
        ],
      ),
    );
  }
}

class _UploadReelSheet extends StatefulWidget {
  final File videoFile;
  final VoidCallback onUploaded;

  const _UploadReelSheet({required this.videoFile, required this.onUploaded});

  @override
  State<_UploadReelSheet> createState() => _UploadReelSheetState();
}

class _UploadReelSheetState extends State<_UploadReelSheet> {
  final _captionCtrl = TextEditingController();
  final _bunny = BunnyStorageService();
  final _authService = AuthService();
  bool _uploading = false;
  double _progress = 0;

  Future<void> _upload() async {
    setState(() => _uploading = true);
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final user = await _authService.getUserById(uid);
      if (user == null) return;

      final filename = _bunny.generateFilename('reel_$uid', 'mp4');
      final url = await _bunny.uploadFile(
        file: widget.videoFile,
        folder: AppConstants.folderReels,
        filename: filename,
        onProgress: (p) => setState(() => _progress = p),
      );

      if (url == null) throw Exception('Upload failed');

      await FirebaseFirestore.instance.collection(AppConstants.colReels).add({
        'authorId': uid,
        'authorName': user.name,
        'authorUsername': user.username,
        'authorProfilePic': user.profilePicUrl,
        'videoUrl': url,
        'caption': _captionCtrl.text.trim().isEmpty
            ? null
            : _captionCtrl.text.trim(),
        'likesCount': 0,
        'commentsCount': 0,
        'viewsCount': 0,
        'createdAt': Timestamp.now(),
      });

      widget.onUploaded();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.error),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Upload Reel',
              style: GoogleFonts.playfairDisplay(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary)),
          const SizedBox(height: 16),
          EcclesiaTextField(
            hint: 'Add a caption (optional)',
            label: 'Caption',
            controller: _captionCtrl,
            maxLines: 3,
          ),
          if (_uploading) ...[
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: _progress,
              backgroundColor: AppTheme.bgElevated,
              valueColor: const AlwaysStoppedAnimation(AppTheme.primary),
            ),
            const SizedBox(height: 6),
            Text('${(_progress * 100).toInt()}% uploaded',
                style: GoogleFonts.dmSans(
                    color: AppTheme.textMuted, fontSize: 12)),
          ],
          const SizedBox(height: 20),
          GradientButton(
            label: 'Upload Reel',
            onTap: _uploading ? null : _upload,
            loading: _uploading,
          ),
        ],
      ),
    );
  }
}
