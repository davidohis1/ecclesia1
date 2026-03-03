import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/constants/app_constants.dart';
import '../../../models/post_model.dart';
import '../widgets/post_card.dart';
import '../../messages/screens/messages_screen.dart';
import '../../search/screens/search_screen.dart';
import '../../profile/screens/profile_screen.dart';

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
  bool _loading = true;
  DocumentSnapshot? _lastDoc;
  bool _hasMore = true;
  bool _loadingMore = false;

  @override
  void initState() {
    super.initState();
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

  Future<void> _loadPosts() async {
    setState(() => _loading = true);
    try {
      final uid = _auth.currentUser?.uid;
      List<PostModel> posts = [];

      if (uid != null) {
        // Get followed saints posts first
        final followsSnap = await _firestore
            .collection(AppConstants.colFollows)
            .where('followerId', isEqualTo: uid)
            .get();
        final followedIds = followsSnap.docs.map((d) => d['followingId'] as String).toList();

        if (followedIds.isNotEmpty) {
          final ids = followedIds.take(10).toList();
          final snap = await _firestore
              .collection(AppConstants.colPosts)
              .where('authorId', whereIn: ids)
              .orderBy('createdAt', descending: true)
              .limit(10)
              .get();
          posts = snap.docs
              .map((d) => PostModel.fromMap(d.id, d.data()))
              .toList();
          if (snap.docs.isNotEmpty) _lastDoc = snap.docs.last;
        }
      }

      // Fill with random posts if not enough
      if (posts.length < 10) {
        final snap = await _firestore
            .collection(AppConstants.colPosts)
            .orderBy('createdAt', descending: true)
            .limit(20)
            .get();
        final randomPosts = snap.docs
            .map((d) => PostModel.fromMap(d.id, d.data()))
            .where((p) => !posts.any((ep) => ep.id == p.id))
            .toList();
        posts.addAll(randomPosts);
        if (snap.docs.isNotEmpty) _lastDoc = snap.docs.last;
      }

      setState(() {
        _posts = posts;
        _loading = false;
        _hasMore = posts.length >= 10;
      });
    } catch (e) {
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
          // Stories Row
          SliverToBoxAdapter(
            child: _StoriesRow(),
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

class _StoriesRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 88,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 8,
        itemBuilder: (_, i) {
          if (i == 0) {
            return Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Column(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppTheme.bgElevated,
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: Colors.white.withOpacity(0.1), width: 1.5),
                    ),
                    child: const Icon(Icons.add, color: AppTheme.primary, size: 22),
                  ),
                  const SizedBox(height: 4),
                  Text('Add',
                      style: GoogleFonts.dmSans(
                          color: AppTheme.textMuted, fontSize: 10)),
                ],
              ),
            );
          }
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Column(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        [AppTheme.primary, AppTheme.accent],
                        [AppTheme.rose, AppTheme.accent],
                        [AppTheme.teal, AppTheme.primary],
                        [AppTheme.accent, AppTheme.rose],
                      ][i % 4],
                    ),
                  ),
                  padding: const EdgeInsets.all(2),
                  child: Container(
                    decoration: const BoxDecoration(
                      color: AppTheme.bgDark,
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(2),
                    child: const CircleAvatar(
                      backgroundColor: AppTheme.bgElevated,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text('Saint ${i}',
                    style: GoogleFonts.dmSans(
                        color: AppTheme.textMuted, fontSize: 10)),
              ],
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

    await _firestore
        .collection(AppConstants.colPosts)
        .doc(widget.post.id)
        .collection(AppConstants.colComments)
        .add({
      'postId': widget.post.id,
      'authorId': uid,
      'authorName': 'You',
      'authorUsername': 'you',
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
                      leading: UserAvatar(
                          name: data['authorName'] ?? 'S', size: 36),
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
