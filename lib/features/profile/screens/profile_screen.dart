import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/constants/app_constants.dart';
import '../../../models/user_model.dart';
import '../../../models/post_model.dart';
import '../../../services/auth_service.dart';
import '../../messages/screens/messages_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String userId;
  const ProfileScreen({super.key, required this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final _authService = AuthService();

  UserModel? _user;
  List<PostModel> _posts = [];
  bool _loading = true;
  bool _isFollowing = false;
  bool _isMe = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final myUid = _auth.currentUser?.uid;
    _isMe = myUid == widget.userId;

    try {
      final user = await _authService.getUserById(widget.userId);

      // Load posts — simple single-field orderBy, no compound index needed
      final postsSnap = await _firestore
          .collection(AppConstants.colPosts)
          .where('authorId', isEqualTo: widget.userId)
          .get();

      final posts = postsSnap.docs
          .map((d) => PostModel.fromMap(d.id, d.data()))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

      bool following = false;
      if (myUid != null && !_isMe) {
        try {
          final f = await _firestore
              .collection(AppConstants.colFollows)
              .doc('${myUid}_${widget.userId}')
              .get();
          following = f.exists;
        } catch (_) {}
      }

      setState(() {
        _user = user;
        _posts = posts;
        _isFollowing = following;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _toggleFollow() async {
    final myUid = _auth.currentUser?.uid;
    if (myUid == null) return;
    final followId = '${myUid}_${widget.userId}';
    if (_isFollowing) {
      await _firestore.collection(AppConstants.colFollows).doc(followId).delete();
      await _firestore.collection(AppConstants.colUsers).doc(myUid)
          .update({'followingCount': FieldValue.increment(-1)});
      await _firestore.collection(AppConstants.colUsers).doc(widget.userId)
          .update({'followersCount': FieldValue.increment(-1)});
    } else {
      await _firestore.collection(AppConstants.colFollows).doc(followId).set({
        'followerId': myUid,
        'followingId': widget.userId,
        'createdAt': Timestamp.now(),
      });
      await _firestore.collection(AppConstants.colUsers).doc(myUid)
          .update({'followingCount': FieldValue.increment(1)});
      await _firestore.collection(AppConstants.colUsers).doc(widget.userId)
          .update({'followersCount': FieldValue.increment(1)});
    }
    setState(() => _isFollowing = !_isFollowing);
    _load();
  }

  void _openPostViewer(int startIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PostScrollViewer(
          posts: _posts,
          initialIndex: startIndex,
          userName: _user?.name ?? '',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: AppTheme.bgDark,
        body: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
      );
    }
    if (_user == null) {
      return const Scaffold(
        backgroundColor: AppTheme.bgDark,
        body: Center(child: Text('User not found')),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: CustomScrollView(
        slivers: [
          // ── Collapsing header ──────────────────────────────────────────────
          SliverAppBar(
            pinned: true,
            expandedHeight: 300,
            backgroundColor: AppTheme.bgDark,
            actions: [
              if (_isMe)
                IconButton(
                  icon: const Icon(Icons.logout_rounded,
                      color: AppTheme.textPrimary),
                  onPressed: () async {
                    await _authService.signOut();
                    if (mounted) Navigator.pushNamedAndRemoveUntil(
                        context, AppRoutes.login, (_) => false);
                  },
                ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.pin,
              background: _ProfileHeader(
                user: _user!,
                isMe: _isMe,
                isFollowing: _isFollowing,
                postCount: _posts.length,
                onFollow: _toggleFollow,
                onMessage: () {
                  final myUid = _auth.currentUser?.uid ?? '';
                  final ids = [myUid, widget.userId]..sort();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatScreen(
                        conversationId: ids.join('_'),
                        otherUserId: widget.userId,
                        otherUserName: _user!.name,
                        otherUserPhoto: _user!.profilePicUrl,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // ── Sticky section header ──────────────────────────────────────────
          SliverPersistentHeader(
            pinned: true,
            delegate: _SectionHeader('Posts'),
          ),

          // ── TikTok-style posts grid ────────────────────────────────────────
          _posts.isEmpty
              ? SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('✝️', style: TextStyle(fontSize: 40)),
                        const SizedBox(height: 12),
                        Text(
                          _isMe ? 'Share your first post' : 'No posts yet',
                          style: GoogleFonts.dmSans(
                              color: AppTheme.textMuted, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                )
              : SliverPadding(
                  padding: const EdgeInsets.all(2),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 2,
                      crossAxisSpacing: 2,
                      childAspectRatio: 1,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => _PostGridTile(
                        post: _posts[i],
                        onTap: () => _openPostViewer(i),
                      ),
                      childCount: _posts.length,
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}

// ── Profile header ─────────────────────────────────────────────────────────────
class _ProfileHeader extends StatelessWidget {
  final UserModel user;
  final bool isMe;
  final bool isFollowing;
  final int postCount;
  final VoidCallback onFollow;
  final VoidCallback onMessage;

  const _ProfileHeader({
    required this.user,
    required this.isMe,
    required this.isFollowing,
    required this.postCount,
    required this.onFollow,
    required this.onMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.bgCard, AppTheme.bgDark],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 52, 20, 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Avatar with gradient ring
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                          colors: [AppTheme.primary, AppTheme.accent]),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primary.withOpacity(0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                        )
                      ],
                    ),
                    padding: const EdgeInsets.all(2.5),
                    child: UserAvatar(
                        name: user.name,
                        imageUrl: user.profilePicUrl,
                        size: 78),
                  ),
                  const SizedBox(width: 20),
                  // Stats row
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _Stat(label: 'Posts', value: '$postCount'),
                        _Stat(
                            label: 'Followers',
                            value: '${user.followersCount}'),
                        _Stat(
                            label: 'Following',
                            value: '${user.followingCount}'),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Align(
                alignment: Alignment.centerLeft,
                child: Row(
                  children: [
                    Flexible(
                      child: Text(user.name,
                          style: GoogleFonts.playfairDisplay(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary)),
                    ),
                    if (user.isVerified) ...[
                      const SizedBox(width: 6),
                      const VerifiedBadge(size: 16),
                    ],
                  ],
                ),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: Text('@${user.username}',
                    style: GoogleFonts.dmSans(
                        color: AppTheme.primary, fontSize: 13)),
              ),
              if (user.bio != null && user.bio!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(user.bio!,
                      style: GoogleFonts.dmSans(
                          color: AppTheme.textSecondary, fontSize: 13),
                      maxLines: 2),
                ),
              ],
              if (user.churchAttending != null) ...[
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Row(
                    children: [
                      const Icon(Icons.church_outlined,
                          color: AppTheme.textMuted, size: 13),
                      const SizedBox(width: 4),
                      Text(user.churchAttending!,
                          style: GoogleFonts.dmSans(
                              color: AppTheme.textMuted, fontSize: 12)),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 14),
              if (!isMe)
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: onFollow,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            gradient: isFollowing
                                ? null
                                : const LinearGradient(
                                    colors: [AppTheme.primary, AppTheme.primaryDark]),
                            color: isFollowing ? AppTheme.bgElevated : null,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: isFollowing
                                    ? Colors.white.withOpacity(0.15)
                                    : Colors.transparent),
                          ),
                          child: Center(
                            child: Text(
                              isFollowing ? 'Following' : 'Follow',
                              style: GoogleFonts.dmSans(
                                  color: isFollowing
                                      ? AppTheme.textSecondary
                                      : Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: GestureDetector(
                        onTap: onMessage,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: AppTheme.bgElevated,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.15)),
                          ),
                          child: Center(
                            child: Text('Message',
                                style: GoogleFonts.dmSans(
                                    color: AppTheme.textPrimary,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13)),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label, value;
  const _Stat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: GoogleFonts.dmSans(
                color: AppTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w800)),
        Text(label,
            style: GoogleFonts.dmSans(
                color: AppTheme.textMuted, fontSize: 11)),
      ],
    );
  }
}

// ── Grid tile ──────────────────────────────────────────────────────────────────
class _PostGridTile extends StatelessWidget {
  final PostModel post;
  final VoidCallback onTap;
  const _PostGridTile({required this.post, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: AppTheme.bgElevated,
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    // Image or video thumbnail
    if (post.mediaUrls.isNotEmpty) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            post.mediaUrls.first,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _textPreview(),
          ),
          if (post.mediaUrls.length > 1)
            Positioned(
              top: 6,
              right: 6,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.collections_rounded,
                    color: Colors.white, size: 12),
              ),
            ),
          if (post.type == PostType.video)
            const Center(
              child: Icon(Icons.play_circle_fill_rounded,
                  color: Colors.white70, size: 36),
            ),
        ],
      );
    }
    return _textPreview();
  }

  Widget _textPreview() {
    final bg = PostBackgrounds.gradients.firstWhere(
      (g) => g['id'] == post.backgroundGradientId,
      orElse: () => PostBackgrounds.gradients.first,
    );
    final colors = (bg['colors'] as List<Color>);
    return Container(
      decoration: BoxDecoration(
        gradient: colors.isNotEmpty
            ? LinearGradient(colors: colors)
            : null,
        color: colors.isEmpty ? AppTheme.bgCard : null,
      ),
      padding: const EdgeInsets.all(8),
      child: Center(
        child: Text(
          post.textContent ?? '',
          style: GoogleFonts.dmSans(
              color: Colors.white, fontSize: 11, height: 1.4),
          maxLines: 4,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

// ── Full-screen post scroll viewer (TikTok style) ─────────────────────────────
class PostScrollViewer extends StatefulWidget {
  final List<PostModel> posts;
  final int initialIndex;
  final String userName;

  const PostScrollViewer({
    super.key,
    required this.posts,
    required this.initialIndex,
    required this.userName,
  });

  @override
  State<PostScrollViewer> createState() => _PostScrollViewerState();
}

class _PostScrollViewerState extends State<PostScrollViewer> {
  late PageController _pageCtrl;
  int _currentIndex = 0;
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageCtrl = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageCtrl,
            scrollDirection: Axis.vertical,
            itemCount: widget.posts.length,
            onPageChanged: (i) => setState(() => _currentIndex = i),
            itemBuilder: (_, i) => _FullPostPage(
              post: widget.posts[i],
              firestore: _firestore,
              currentUid: _auth.currentUser?.uid,
            ),
          ),
          // Back button
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 12,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white, size: 18),
              ),
            ),
          ),
          // Post counter
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            right: 16,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.black45,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${_currentIndex + 1} / ${widget.posts.length}',
                style: GoogleFonts.dmSans(
                    color: Colors.white, fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FullPostPage extends StatelessWidget {
  final PostModel post;
  final FirebaseFirestore firestore;
  final String? currentUid;

  const _FullPostPage({
    required this.post,
    required this.firestore,
    required this.currentUid,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: Column(
        children: [
          // Header
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 48, 16, 12),
              child: Row(
                children: [
                  UserAvatar(
                    name: post.authorName,
                    imageUrl: post.authorProfilePic,
                    size: 36,
                    showBorder: true,
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(post.authorName,
                          style: GoogleFonts.dmSans(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 14)),
                      Text('@${post.authorUsername}',
                          style: GoogleFonts.dmSans(
                              color: Colors.white54, fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Content
          Expanded(
            child: _PostContent(post: post),
          ),
          // Actions bar
          Padding(
            padding: EdgeInsets.fromLTRB(
                20, 12, 20, MediaQuery.of(context).padding.bottom + 16),
            child: Row(
              children: [
                _ActionChip(
                    icon: Icons.favorite_outline_rounded,
                    label: '${post.likesCount}',
                    onTap: () {}),
                const SizedBox(width: 16),
                _ActionChip(
                    icon: Icons.chat_bubble_outline_rounded,
                    label: '${post.commentsCount}',
                    onTap: () {}),
                const SizedBox(width: 16),
                _ActionChip(
                    icon: Icons.share_outlined,
                    label: 'Share',
                    onTap: () {}),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PostContent extends StatelessWidget {
  final PostModel post;
  const _PostContent({required this.post});

  @override
  Widget build(BuildContext context) {
    if (post.mediaUrls.isNotEmpty) {
      return PageView.builder(
        itemCount: post.mediaUrls.length,
        itemBuilder: (_, i) => InteractiveViewer(
          child: Image.network(
            post.mediaUrls[i],
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Center(
              child: Icon(Icons.broken_image, color: Colors.white30, size: 60),
            ),
          ),
        ),
      );
    }

    // Text post with gradient background
    final bg = PostBackgrounds.gradients.firstWhere(
      (g) => g['id'] == post.backgroundGradientId,
      orElse: () => PostBackgrounds.gradients.first,
    );
    final colors = bg['colors'] as List<Color>;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        gradient: colors.isNotEmpty ? LinearGradient(colors: colors) : null,
        color: colors.isEmpty ? AppTheme.bgCard : null,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            post.textContent ?? '',
            style: GoogleFonts.playfairDisplay(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w600,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ActionChip(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: Colors.white70, size: 22),
          const SizedBox(width: 6),
          Text(label,
              style: GoogleFonts.dmSans(color: Colors.white70, fontSize: 13)),
        ],
      ),
    );
  }
}

class _SectionHeader extends SliverPersistentHeaderDelegate {
  final String title;
  _SectionHeader(this.title);

  @override
  Widget build(_, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: AppTheme.bgDark,
      child: Column(
        children: [
          Divider(height: 1, color: Colors.white.withOpacity(0.06)),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Icon(Icons.grid_on_rounded,
                      color: AppTheme.primary, size: 18),
                  const SizedBox(width: 8),
                  Text(title,
                      style: GoogleFonts.dmSans(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 13)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  double get maxExtent => 44;
  @override
  double get minExtent => 44;
  @override
  bool shouldRebuild(_) => false;
}