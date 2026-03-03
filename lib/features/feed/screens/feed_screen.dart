import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/constants/app_constants.dart';
import '../../../models/post_model.dart';
import '../../../models/user_model.dart';
import '../widgets/post_card.dart';
import '../../messages/screens/messages_screen.dart';
import '../../search/screens/search_screen.dart';
import '../../profile/screens/profile_screen.dart';
import '../../../core/utils/navigation.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final _scrollCtrl = ScrollController();

  List<PostModel> _posts = [];
  List<UserModel> _followingUsers = [];
  bool _loading = true;
  DocumentSnapshot? _lastDoc;
  bool _hasMore = true;
  bool _loadingMore = false;

  @override
  void initState() {
    super.initState();
    _loadFollowingUsers();
    _loadPosts();
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
            _scrollCtrl.position.maxScrollExtent - 200 &&
        !_loadingMore &&
        _hasMore) {
      _loadMorePosts();
    }
  }

  Future<void> _loadFollowingUsers() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    try {
      // Get list of users the current user is following
      final followsSnap = await _firestore
          .collection(AppConstants.colFollows)
          .where('followerId', isEqualTo: uid)
          .limit(20)
          .get();

      final followingIds = followsSnap.docs.map((d) => d['followingId'] as String).toList();

      if (followingIds.isNotEmpty) {
        // Fetch user details for each followed user
        final usersSnap = await _firestore
            .collection(AppConstants.colUsers)
            .where('uid', whereIn: followingIds.take(10).toList())
            .get();

        final users = usersSnap.docs
            .map((d) => UserModel.fromMap(d.data()))
            .toList();

        if (mounted) {
          setState(() {
            _followingUsers = users;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading following users: $e');
    }
  }

  Future<void> _loadPosts() async {
    setState(() => _loading = true);
    try {
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(hours: 24));

      // Get posts from last 24 hours
      final recentSnap = await _firestore
          .collection(AppConstants.colPosts)
          .where('createdAt', isGreaterThanOrEqualTo: yesterday)
          .orderBy('createdAt', descending: true)
          .get();

      List<PostModel> recentPosts = recentSnap.docs
          .map((d) => PostModel.fromMap(d.id, d.data()))
          .toList();

      // Shuffle recent posts for randomness
      recentPosts.shuffle();

      // If we have less than 10 recent posts, get older posts to fill
      if (recentPosts.length < 10) {
        final olderSnap = await _firestore
            .collection(AppConstants.colPosts)
            .where('createdAt', isLessThan: yesterday)
            .orderBy('createdAt', descending: true)
            .limit(20)
            .get();

        final olderPosts = olderSnap.docs
            .map((d) => PostModel.fromMap(d.id, d.data()))
            .where((p) => !recentPosts.any((rp) => rp.id == p.id))
            .toList();

        // Shuffle older posts
        olderPosts.shuffle();

        // Combine: all recent posts first, then older posts
        recentPosts.addAll(olderPosts);
      }

      setState(() {
        _posts = recentPosts;
        _loading = false;
        _hasMore = recentPosts.length >= 10;
      });

      // Set last document for pagination
      if (_posts.isNotEmpty) {
        final lastPostSnap = await _firestore
            .collection(AppConstants.colPosts)
            .doc(_posts.last.id)
            .get();
        _lastDoc = lastPostSnap;
      }
    } catch (e) {
      debugPrint('Error loading posts: $e');
      setState(() => _loading = false);
    }
  }

  Future<void> _loadMorePosts() async {
    if (_lastDoc == null) return;
    setState(() => _loadingMore = true);
    try {
      final snap = await _firestore
          .collection(AppConstants.colPosts)
          .orderBy('createdAt', descending: true)
          .startAfterDocument(_lastDoc!)
          .limit(10)
          .get();

      final newPosts =
          snap.docs.map((d) => PostModel.fromMap(d.id, d.data())).toList();

      setState(() {
        _posts.addAll(newPosts);
        _lastDoc = snap.docs.isNotEmpty ? snap.docs.last : null;
        _hasMore = newPosts.length >= 10;
        _loadingMore = false;
      });
    } catch (e) {
      debugPrint('Error loading more posts: $e');
      setState(() => _loadingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: CustomScrollView(
        controller: _scrollCtrl,
        slivers: [
          // App Bar
          SliverAppBar(
            floating: true,
            backgroundColor: AppTheme.bgDark,
            title: Row(
              children: [
                const EcclesiaLogo(size: 34),
                const SizedBox(width: 10),
                Text(
                  'Ecclesia',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const SearchScreen())),
                icon: const Icon(Icons.search_rounded, color: AppTheme.textPrimary),
              ),
              IconButton(
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const MessagesScreen())),
                icon: const Icon(Icons.mail_outline_rounded,
                    color: AppTheme.textPrimary),
              ),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProfileScreen(
                        userId: FirebaseAuth.instance.currentUser?.uid ?? ''),
                  ),
                ),
                child: Container(
                  margin: const EdgeInsets.only(right: 16),
                  child: UserAvatar(
                    name: 'Me',
                    size: 32,
                    showBorder: true,
                  ),
                ),
              ),
            ],
          ),
          
          // Following Users Row
          SliverToBoxAdapter(
            child: _followingUsers.isEmpty
                ? Container(
                    height: 88,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: const Center(
                      child: Text(
                        'Follow some saints to see them here',
                        style: TextStyle(color: AppTheme.textMuted),
                      ),
                    ),
                  )
                : _FollowingUsersRow(users: _followingUsers),
          ),
          
          // Posts
          _loading
              ? SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: List.generate(
                        3,
                        (_) => const Padding(
                          padding: EdgeInsets.only(bottom: 16),
                          child: ShimmerCard(height: 300),
                        ),
                      ),
                    ),
                  ),
                )
              : _posts.isEmpty
                  ? SliverToBoxAdapter(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(40),
                          child: Column(
                            children: [
                              const Text('✝️', style: TextStyle(fontSize: 48)),
                              const SizedBox(height: 16),
                              Text(
                                'No posts yet',
                                style: GoogleFonts.playfairDisplay(
                                  fontSize: 20,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Be the first to share your faith',
                                style: GoogleFonts.dmSans(
                                    color: AppTheme.textMuted),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  : SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, i) {
                          if (i < _posts.length) {
                            return PostCard(
                              post: _posts[i],
                              onLike: () => _toggleLike(_posts[i]),
                              onComment: () => _openComments(_posts[i]),
                            );
                          }
                          return _loadingMore
                              ? const Padding(
                                  padding: EdgeInsets.all(20),
                                  child: Center(
                                    child: CircularProgressIndicator(
                                        color: AppTheme.primary),
                                  ),
                                )
                              : const SizedBox(height: 80);
                        },
                        childCount: _posts.length + 1,
                      ),
                    ),
        ],
      ),
    );
  }

  Future<void> _toggleLike(PostModel post) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    final likeRef = _firestore
        .collection(AppConstants.colPosts)
        .doc(post.id)
        .collection(AppConstants.colLikes)
        .doc(uid);

    final existing = await likeRef.get();
    if (existing.exists) {
      await likeRef.delete();
      await _firestore.collection(AppConstants.colPosts).doc(post.id).update({
        'likesCount': FieldValue.increment(-1),
      });
    } else {
      await likeRef.set({'userId': uid, 'createdAt': Timestamp.now()});
      await _firestore.collection(AppConstants.colPosts).doc(post.id).update({
        'likesCount': FieldValue.increment(1),
      });
    }
    _loadPosts();
  }

  void _openComments(PostModel post) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.bgCard,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _CommentsSheet(post: post),
    );
  }
}

class _FollowingUsersRow extends StatelessWidget {
  final List<UserModel> users;

  const _FollowingUsersRow({required this.users});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 88,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: users.length,
        itemBuilder: (_, i) {
          final user = users[i];
          return GestureDetector(
            onTap: () => openProfile(context, user.uid),
            child: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Column(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: user.isVerified
                          ? const LinearGradient(
                              colors: [AppTheme.primary, AppTheme.accent],
                            )
                          : null,
                    ),
                    padding: user.isVerified ? const EdgeInsets.all(2) : null,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: !user.isVerified
                            ? Border.all(
                                color: Colors.white.withOpacity(0.1),
                                width: 1.5)
                            : null,
                      ),
                      child: UserAvatar(
                        name: user.name,
                        imageUrl: user.profilePicUrl,
                        size: user.isVerified ? 48 : 52,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.username.length > 8
                        ? '${user.username.substring(0, 8)}...'
                        : user.username,
                    style: GoogleFonts.dmSans(
                        color: AppTheme.textMuted, fontSize: 10),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CommentsSheet extends StatefulWidget {
  final PostModel post;
  const _CommentsSheet({required this.post});

  @override
  State<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<_CommentsSheet> {
  final _ctrl = TextEditingController();
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  Future<void> _sendComment() async {
    if (_ctrl.text.trim().isEmpty) return;
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    // Get user info
    final userDoc = await _firestore.collection(AppConstants.colUsers).doc(uid).get();
    final userData = userDoc.data() ?? {};
    final userName = userData['name'] ?? 'Saint';
    final userUsername = userData['username'] ?? 'saint';

    await _firestore
        .collection(AppConstants.colPosts)
        .doc(widget.post.id)
        .collection(AppConstants.colComments)
        .add({
      'postId': widget.post.id,
      'authorId': uid,
      'authorName': userName,
      'authorUsername': userUsername,
      'authorProfilePic': userData['profilePicUrl'],
      'content': _ctrl.text.trim(),
      'likesCount': 0,
      'createdAt': Timestamp.now(),
    });

    await _firestore.collection(AppConstants.colPosts).doc(widget.post.id).update({
      'commentsCount': FieldValue.increment(1),
    });

    _ctrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.8,
      child: Column(
        children: [
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
                  .doc(widget.post.id)
                  .collection(AppConstants.colComments)
                  .orderBy('createdAt', descending: false)
                  .snapshots(),
              builder: (_, snap) {
                if (!snap.hasData) {
                  return const Center(
                      child: CircularProgressIndicator(color: AppTheme.primary));
                }
                final comments = snap.data!.docs;
                if (comments.isEmpty) {
                  return Center(
                    child: Text('Be the first to comment',
                        style: GoogleFonts.dmSans(color: AppTheme.textMuted)),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: comments.length,
                  itemBuilder: (_, i) {
                    final data = comments[i].data() as Map<String, dynamic>;
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: GestureDetector(
                        onTap: () => openProfile(context, data['authorId'] ?? ''),
                        child: UserAvatar(
                          name: data['authorName'] ?? 'S',
                          imageUrl: data['authorProfilePic'],
                          size: 36,
                        ),
                      ),
                      title: Text(
                        data['authorName'] ?? 'Saint',
                        style: GoogleFonts.dmSans(
                            color: AppTheme.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        data['content'] ?? '',
                        style: GoogleFonts.dmSans(
                            color: AppTheme.textSecondary, fontSize: 13),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          // Input
          Container(
            padding: EdgeInsets.fromLTRB(
                16, 8, 16, MediaQuery.of(context).viewInsets.bottom + 16),
            decoration: BoxDecoration(
              color: AppTheme.bgCard,
              border: Border(top: BorderSide(color: Colors.white.withOpacity(0.06))),
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
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: AppTheme.bgElevated,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _sendComment,
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: const BoxDecoration(
                      color: AppTheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.send_rounded,
                        color: Colors.white, size: 18),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}