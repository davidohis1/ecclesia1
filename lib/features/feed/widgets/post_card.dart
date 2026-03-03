import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/utils/navigation.dart';
import '../../../models/post_model.dart';
import '../../../core/constants/app_constants.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class PostCard extends StatefulWidget {
  final PostModel post;
  final VoidCallback onLike;
  final VoidCallback onComment;

  const PostCard({
    super.key,
    required this.post,
    required this.onLike,
    required this.onComment,
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  bool _liked = false;
  int _likes = 0;

  @override
  void initState() {
    super.initState();
    _likes = widget.post.likesCount;
    _checkLiked();
  }

  Future<void> _checkLiked() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    try {
      final doc = await _firestore
          .collection(AppConstants.colPosts)
          .doc(widget.post.id)
          .collection('likes')
          .doc(uid)
          .get();
      if (mounted) setState(() => _liked = doc.exists);
    } catch (_) {}
  }

  Future<void> _toggleLike() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    final ref = _firestore
        .collection(AppConstants.colPosts)
        .doc(widget.post.id)
        .collection('likes')
        .doc(uid);
    if (_liked) {
      await ref.delete();
      await _firestore
          .collection(AppConstants.colPosts)
          .doc(widget.post.id)
          .update({'likesCount': FieldValue.increment(-1)});
      setState(() { _liked = false; _likes--; });
    } else {
      await ref.set({'uid': uid, 'likedAt': Timestamp.now()});
      await _firestore
          .collection(AppConstants.colPosts)
          .doc(widget.post.id)
          .update({'likesCount': FieldValue.increment(1)});
      setState(() { _liked = true; _likes++; });
    }
  }

  // ── Download Media ──────────────────────────────────────────────
  Future<void> _downloadMedia(String url) async {
  try {
    var status = await Permission.storage.request();
    if (await Permission.storage.isGranted) {
      final response = await http.get(Uri.parse(url));
      
      // Get temporary directory
      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/temp_file';
      
      if (url.endsWith('.mp4') || url.endsWith('.mov')) {
        // For video
        File file = File('$filePath.mp4');
        await file.writeAsBytes(response.bodyBytes);
        final result = await ImageGallerySaver.saveFile(file.path);
        await file.delete(); // Clean up temp file
      } else {
        // For image
        final result = await ImageGallerySaver.saveImage(
          response.bodyBytes,
          quality: 80,
          name: 'ecclesia_${DateTime.now().millisecondsSinceEpoch}',
        );
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Saved to gallery'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Failed to download: $e'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }
}

  // ── Copy Link ──────────────────────────────────────────────────
  void _copyPostLink() {
    final postUrl = 'https://yourapp.com/post/${widget.post.id}';
    Clipboard.setData(ClipboardData(text: postUrl));
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🔗 Post link copied to clipboard'),
        backgroundColor: AppTheme.primary,
        duration: Duration(seconds: 2),
      ),
    );
  }

  // ── Share Post ─────────────────────────────────────────────────
  void _sharePost() {
    final postUrl = 'https://yourapp.com/post/${widget.post.id}';
    final text = widget.post.textContent ?? 'Check out this post on Ecclesia';
    
    Share.share('$text\n\n$postUrl');
  }

  // ── Repost ─────────────────────────────────────────────────────
  Future<void> _repost() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    try {
      // Get current user info
      final userDoc = await _firestore.collection('users').doc(uid).get();
      final userData = userDoc.data() ?? {};

      // Create a repost
      await _firestore.collection(AppConstants.colPosts).add({
        'authorId': uid,
        'authorName': userData['name'] ?? 'Saint',
        'authorUsername': userData['username'] ?? 'saint',
        'authorProfilePic': userData['profilePicUrl'],
        'originalPostId': widget.post.id,
        'originalAuthorId': widget.post.authorId,
        'originalAuthorName': widget.post.authorName,
        'textContent': 'Reposted from @${widget.post.authorUsername}',
        'mediaUrls': widget.post.mediaUrls,
        'backgroundGradientId': widget.post.backgroundGradientId,
        'likesCount': 0,
        'commentsCount': 0,
        'createdAt': Timestamp.now(),
        'isRepost': true,
        'isAuthorVerified': userData['isVerified'] ?? false,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Reposted!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Failed to repost: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  // ── Show Bottom Sheet for Comments ─────────────────────────────
  void _showCommentsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: _CommentsSection(postId: widget.post.id),
      ),
    );
  }

  // ── Show Share Options ─────────────────────────────────────────
  void _showShareOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Share Post',
              style: GoogleFonts.playfairDisplay(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            
            // Share option
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.share_rounded, color: AppTheme.primary),
              ),
              title: Text(
                'Share Post',
                style: GoogleFonts.dmSans(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                'Share via other apps',
                style: GoogleFonts.dmSans(color: AppTheme.textMuted, fontSize: 12),
              ),
              onTap: () {
                Navigator.pop(context);
                _sharePost();
              },
            ),
            
            // Copy link option
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.accent.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.link_rounded, color: AppTheme.accent),
              ),
              title: Text(
                'Copy Link',
                style: GoogleFonts.dmSans(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                'Copy post URL to clipboard',
                style: GoogleFonts.dmSans(color: AppTheme.textMuted, fontSize: 12),
              ),
              onTap: () {
                Navigator.pop(context);
                _copyPostLink();
              },
            ),
            
            // Repost option
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.teal.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.repeat_rounded, color: AppTheme.teal),
              ),
              title: Text(
                'Repost',
                style: GoogleFonts.dmSans(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                'Share to your followers',
                style: GoogleFonts.dmSans(color: AppTheme.textMuted, fontSize: 12),
              ),
              onTap: () {
                Navigator.pop(context);
                _repost();
              },
            ),
            
            // Download option (only if post has media)
            if (widget.post.mediaUrls.isNotEmpty) ...[
              const Divider(color: Colors.white12),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.download_rounded, color: Colors.green),
                ),
                title: Text(
                  'Download Media',
                  style: GoogleFonts.dmSans(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  'Save to your device',
                  style: GoogleFonts.dmSans(color: AppTheme.textMuted, fontSize: 12),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _downloadMedia(widget.post.mediaUrls.first);
                },
              ),
            ],
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
      color: AppTheme.bgCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Author row — tapping opens profile ──────────────────────────────
          GestureDetector(
            onTap: () => openProfile(context, post.authorId),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              child: Row(
                children: [
                  UserAvatar(
                    name: post.authorName,
                    imageUrl: post.authorProfilePic,
                    size: 40,
                    showBorder: true,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(post.authorName,
                                style: GoogleFonts.dmSans(
                                    color: AppTheme.textPrimary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700)),
                            if (post.isAuthorVerified) ...[
                              const SizedBox(width: 4),
                              const VerifiedBadge(),
                            ],
                          ],
                        ),
                        Text(
                          '@${post.authorUsername}  ·  ${timeago.format(post.createdAt, allowFromNow: true)}',
                          style: GoogleFonts.dmSans(
                              color: AppTheme.textMuted, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  // ── Three dots menu ─────────────────────────────────────────
                  GestureDetector(
                    onTap: _showShareOptions,
                    child: Icon(Icons.more_horiz_rounded,
                        color: AppTheme.textMuted, size: 20),
                  ),
                ],
              ),
            ),
          ),

          // ── Post content ───────────────────────────────────────────────────
          _buildContent(post),

          // ── Actions row ────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
            child: Row(
              children: [
                _ActionBtn(
                  icon: _liked
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  label: '$_likes',
                  color: _liked ? AppTheme.error : AppTheme.textMuted,
                  onTap: _toggleLike,
                ),
                const SizedBox(width: 20),
                _ActionBtn(
                  icon: Icons.chat_bubble_outline_rounded,
                  label: '${post.commentsCount}',
                  onTap: _showCommentsSheet, // Now opens bottom sheet
                ),
                const SizedBox(width: 20),
                _ActionBtn(
                  icon: Icons.share_outlined,
                  label: 'Share',
                  onTap: _showShareOptions, // Opens share options
                ),
              ],
            ),
          ),

          Divider(height: 1, color: Colors.white.withOpacity(0.05)),
        ],
      ),
    );
  }

  Widget _buildContent(PostModel post) {
    // Media post
    if (post.mediaUrls.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (post.textContent != null && post.textContent!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: Text(post.textContent!,
                  style: GoogleFonts.dmSans(
                      color: AppTheme.textPrimary, fontSize: 14, height: 1.5)),
            ),
          if (post.mediaUrls.length == 1)
            GestureDetector(
              onTap: _showShareOptions, // Optional: show options on image tap
              child: Image.network(
                post.mediaUrls.first,
                width: double.infinity,
                height: 300,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox(
                  height: 200,
                  child: Center(
                    child: Icon(Icons.broken_image, color: AppTheme.textMuted, size: 40),
                  ),
                ),
              ),
            )
          else
            SizedBox(
              height: 220,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: post.mediaUrls.length,
                itemBuilder: (_, i) => GestureDetector(
                  onTap: _showShareOptions,
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    width: 200,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      image: DecorationImage(
                        image: NetworkImage(post.mediaUrls[i]),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      );
    }

    // Text-only post with gradient background
    final bg = PostBackgrounds.gradients.firstWhere(
      (g) => g['id'] == post.backgroundGradientId,
      orElse: () => {'id': 'none', 'colors': <Color>[]},
    );
    final colors = bg['colors'] as List<Color>;

    if (colors.isNotEmpty) {
      return GestureDetector(
        onTap: _showShareOptions,
        child: Container(
          width: double.infinity,
          height: 240,
          margin: const EdgeInsets.symmetric(horizontal: 0),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: colors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                post.textContent ?? '',
                style: GoogleFonts.playfairDisplay(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      );
    }

    // Plain text
    return GestureDetector(
      onTap: _showShareOptions,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        child: Text(
          post.textContent ?? '',
          style: GoogleFonts.dmSans(
              color: AppTheme.textPrimary, fontSize: 15, height: 1.6),
        ),
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = AppTheme.textMuted,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 5),
          Text(label,
              style: GoogleFonts.dmSans(color: AppTheme.textMuted, fontSize: 13)),
        ],
      ),
    );
  }
}

// ── Comments section (now a separate widget for bottom sheet) ──────────────
class _CommentsSection extends StatefulWidget {
  final String postId;
  const _CommentsSection({required this.postId});

  @override
  State<_CommentsSection> createState() => _CommentsSectionState();
}

class _CommentsSectionState extends State<_CommentsSection> {
  final _ctrl = TextEditingController();
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  Future<void> _addComment() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    // Get user info from Firestore
    final userDoc = await _firestore.collection('users').doc(uid).get();
    final name = userDoc.data()?['name'] ?? 'Saint';
    final username = userDoc.data()?['username'] ?? 'saint';
    final pic = userDoc.data()?['profilePicUrl'];

    await _firestore
        .collection(AppConstants.colPosts)
        .doc(widget.postId)
        .collection('comments')
        .add({
      'authorId': uid,
      'authorName': name,
      'authorUsername': username,
      'authorProfilePic': pic,
      'text': text,
      'createdAt': Timestamp.now(),
    });

    await _firestore
        .collection(AppConstants.colPosts)
        .doc(widget.postId)
        .update({'commentsCount': FieldValue.increment(1)});

    _ctrl.clear();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Handle bar
        Container(
          margin: const EdgeInsets.only(top: 12),
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Comments',
            style: GoogleFonts.playfairDisplay(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
        const Divider(color: Colors.white12),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection(AppConstants.colPosts)
                .doc(widget.postId)
                .collection('comments')
                .orderBy('createdAt', descending: false)
                .limit(50)
                .snapshots(),
            builder: (_, snap) {
              if (!snap.hasData) {
                return const Center(
                    child: CircularProgressIndicator(color: AppTheme.primary));
              }
              final comments = snap.data!.docs;
              if (comments.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('💬', style: TextStyle(fontSize: 40)),
                      const SizedBox(height: 8),
                      Text('No comments yet',
                          style: GoogleFonts.dmSans(
                              color: AppTheme.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text('Be the first to comment 🙏',
                          style: GoogleFonts.dmSans(color: AppTheme.textMuted)),
                    ],
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: comments.length,
                itemBuilder: (_, i) {
                  final c = comments[i].data() as Map<String, dynamic>;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: () => openProfile(context, c['authorId'] ?? ''),
                          child: UserAvatar(
                              name: c['authorName'] ?? 'S',
                              imageUrl: c['authorProfilePic'],
                              size: 36),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(c['authorName'] ?? 'Saint',
                                      style: GoogleFonts.dmSans(
                                          color: AppTheme.textPrimary,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700)),
                                  const SizedBox(width: 6),
                                  Text(
                                    '@${c['authorUsername'] ?? ''}',
                                    style: GoogleFonts.dmSans(
                                        color: AppTheme.textMuted,
                                        fontSize: 11),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(c['text'] ?? '',
                                  style: GoogleFonts.dmSans(
                                      color: AppTheme.textSecondary,
                                      fontSize: 14)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
        // Comment input
        Container(
          padding: EdgeInsets.fromLTRB(
              16, 8, 16, MediaQuery.of(context).viewInsets.bottom + 16),
          decoration: BoxDecoration(
            color: AppTheme.bgCard,
            border: Border(
                top: BorderSide(color: Colors.white.withOpacity(0.06))),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _ctrl,
                  style: GoogleFonts.dmSans(
                      color: AppTheme.textPrimary, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Add a comment...',
                    hintStyle: GoogleFonts.dmSans(
                        color: AppTheme.textMuted, fontSize: 14),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(50),
                        borderSide: BorderSide.none),
                    filled: true,
                    fillColor: AppTheme.bgElevated,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: _addComment,
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: const BoxDecoration(
                      color: AppTheme.primary, shape: BoxShape.circle),
                  child: const Icon(Icons.send_rounded,
                      color: Colors.white, size: 18),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}