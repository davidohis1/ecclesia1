import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/constants/app_constants.dart';
import '../../../models/post_model.dart';

class PostCard extends StatefulWidget {
  final PostModel post;
  final VoidCallback? onLike;
  final VoidCallback? onComment;

  const PostCard({
    super.key,
    required this.post,
    this.onLike,
    this.onComment,
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  bool _liked = false;
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _checkLiked();
  }

  Future<void> _checkLiked() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    final doc = await _firestore
        .collection(AppConstants.colPosts)
        .doc(widget.post.id)
        .collection(AppConstants.colLikes)
        .doc(uid)
        .get();
    if (mounted) setState(() => _liked = doc.exists);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 1),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        border: Border(
          bottom: BorderSide(color: Colors.white.withOpacity(0.05)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                UserAvatar(
                  imageUrl: widget.post.authorProfilePic,
                  name: widget.post.authorName,
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
                          Text(
                            widget.post.authorName,
                            style: GoogleFonts.dmSans(
                              color: AppTheme.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (widget.post.isAuthorVerified) ...[
                            const SizedBox(width: 4),
                            const VerifiedBadge(),
                          ],
                        ],
                      ),
                      Text(
                        '@${widget.post.authorUsername} · ${timeago.format(widget.post.createdAt)}',
                        style: GoogleFonts.dmSans(
                            color: AppTheme.textMuted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.more_horiz,
                      color: AppTheme.textMuted, size: 20),
                  onPressed: () {},
                ),
              ],
            ),
          ),
          // Content
          _buildContent(),
          // Actions
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: Row(
              children: [
                _ActionBtn(
                  icon: _liked
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  label: '${widget.post.likesCount}',
                  color: _liked ? AppTheme.rose : AppTheme.textMuted,
                  onTap: () {
                    setState(() => _liked = !_liked);
                    widget.onLike?.call();
                  },
                ),
                const SizedBox(width: 4),
                _ActionBtn(
                  icon: Icons.chat_bubble_outline_rounded,
                  label: '${widget.post.commentsCount}',
                  onTap: widget.onComment,
                ),
                const SizedBox(width: 4),
                _ActionBtn(
                  icon: Icons.share_outlined,
                  label: '${widget.post.sharesCount}',
                  onTap: () {},
                ),
                const Spacer(),
                _ActionBtn(
                  icon: Icons.bookmark_border_rounded,
                  label: '',
                  onTap: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final post = widget.post;

    // Text with background
    if (post.type == PostType.text && post.backgroundGradientId != null &&
        post.backgroundGradientId != 'none') {
      final bg = PostBackgrounds.gradients.firstWhere(
        (g) => g['id'] == post.backgroundGradientId,
        orElse: () => PostBackgrounds.gradients.first,
      );
      final colors = bg['colors'] as List<Color>;
      if (colors.isNotEmpty) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 0),
          height: 240,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: colors),
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                post.textContent ?? '',
                textAlign: TextAlign.center,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 22,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  height: 1.5,
                ),
              ),
            ),
          ),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Text
        if (post.textContent != null && post.textContent!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Text(
              post.textContent!,
              style: GoogleFonts.dmSans(
                color: AppTheme.textPrimary,
                fontSize: 15,
                height: 1.5,
              ),
            ),
          ),
        // Media
        if (post.mediaUrls.isNotEmpty) _buildMedia(),
      ],
    );
  }

  Widget _buildMedia() {
    final urls = widget.post.mediaUrls;
    if (urls.isEmpty) return const SizedBox.shrink();

    if (urls.length == 1) {
      return _MediaItem(url: urls[0]);
    }

    return SizedBox(
      height: 240,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: urls.length,
        itemBuilder: (_, i) => SizedBox(
          width: 220,
          child: _MediaItem(url: urls[i]),
        ),
      ),
    );
  }
}

class _MediaItem extends StatelessWidget {
  final String url;
  const _MediaItem({required this.url});

  bool get _isVideo =>
      url.contains('.mp4') || url.contains('.mov') || url.contains('video');

  @override
  Widget build(BuildContext context) {
    if (_isVideo) {
      return Container(
        color: Colors.black,
        child: const Center(
            child: Icon(Icons.play_circle_filled_rounded,
                color: Colors.white, size: 48)),
      );
    }
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      placeholder: (_, __) => const ShimmerCard(),
      errorWidget: (_, __, ___) => Container(
        color: AppTheme.bgElevated,
        child: const Icon(Icons.broken_image_outlined,
            color: AppTheme.textMuted, size: 40),
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color color;

  const _ActionBtn({
    required this.icon,
    required this.label,
    this.onTap,
    this.color = AppTheme.textMuted,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            if (label.isNotEmpty) ...[
              const SizedBox(width: 4),
              Text(
                label,
                style: GoogleFonts.dmSans(color: color, fontSize: 13),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
