import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/constants/app_constants.dart';
import '../../../models/user_model.dart';
import '../../../models/post_model.dart';
import '../../profile/screens/profile_screen.dart';
import '../../feed/widgets/post_card.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with SingleTickerProviderStateMixin {
  final _searchCtrl = TextEditingController();
  final _firestore = FirebaseFirestore.instance;
  late TabController _tabCtrl;

  List<UserModel> _users = [];
  List<PostModel> _posts = [];
  bool _loading = false;
  bool _hasSearched = false;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _search(String q) async {
    if (q.trim().isEmpty) {
      setState(() {
        _users = [];
        _posts = [];
        _hasSearched = false;
      });
      return;
    }

    setState(() {
      _loading = true;
      _hasSearched = true;
    });

    final lower = q.toLowerCase().trim();

    try {
      // Search users by name prefix
      final usersSnap = await _firestore
          .collection(AppConstants.colUsers)
          .orderBy('name')
          .startAt([lower])
          .endAt(['$lower\uf8ff'])
          .limit(20)
          .get();

      final usernameSnap = await _firestore
          .collection(AppConstants.colUsers)
          .orderBy('username')
          .startAt([lower])
          .endAt(['$lower\uf8ff'])
          .limit(10)
          .get();

      final allUserDocs = {
        ...usersSnap.docs.map((d) => d.id),
        ...usernameSnap.docs.map((d) => d.id),
      };

      final users = [
        ...usersSnap.docs,
        ...usernameSnap.docs
            .where((d) => !usersSnap.docs.any((u) => u.id == d.id)),
      ]
          .map((d) => UserModel.fromMap(d.data() as Map<String, dynamic>))
          .toList();

      // Search posts by text content
      final postsSnap = await _firestore
          .collection(AppConstants.colPosts)
          .orderBy('createdAt', descending: true)
          .limit(30)
          .get();

      final posts = postsSnap.docs
          .map((d) => PostModel.fromMap(d.id, d.data()))
          .where((p) =>
              (p.textContent?.toLowerCase().contains(lower) ?? false) ||
              p.authorName.toLowerCase().contains(lower) ||
              p.authorUsername.toLowerCase().contains(lower))
          .toList();

      setState(() {
        _users = users;
        _posts = posts;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        backgroundColor: AppTheme.bgDark,
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(right: 16),
          child: TextField(
            controller: _searchCtrl,
            autofocus: true,
            style: GoogleFonts.dmSans(
                color: AppTheme.textPrimary, fontSize: 14),
            onChanged: (v) {
              if (v.length >= 2 || v.isEmpty) _search(v);
            },
            decoration: InputDecoration(
              hintText: 'Search saints, posts...',
              prefixIcon: const Icon(Icons.search_rounded,
                  color: AppTheme.textMuted, size: 20),
              suffixIcon: _searchCtrl.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close,
                          color: AppTheme.textMuted, size: 18),
                      onPressed: () {
                        _searchCtrl.clear();
                        _search('');
                      },
                    )
                  : null,
            ),
          ),
        ),
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: AppTheme.primary,
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.textMuted,
          labelStyle: GoogleFonts.dmSans(
              fontWeight: FontWeight.w700, fontSize: 13),
          tabs: [
            Tab(
                text:
                    'Saints${_users.isNotEmpty ? ' (${_users.length})' : ''}'),
            Tab(
                text:
                    'Posts${_posts.isNotEmpty ? ' (${_posts.length})' : ''}'),
          ],
        ),
      ),
      body: !_hasSearched
          ? _SearchSuggestions()
          : _loading
              ? const Center(
                  child:
                      CircularProgressIndicator(color: AppTheme.primary))
              : TabBarView(
                  controller: _tabCtrl,
                  children: [
                    // Saints tab
                    _users.isEmpty
                        ? _EmptyResult(message: 'No saints found')
                        : ListView.builder(
                            itemCount: _users.length,
                            itemBuilder: (_, i) => _UserResultTile(
                                user: _users[i]),
                          ),
                    // Posts tab
                    _posts.isEmpty
                        ? _EmptyResult(message: 'No posts found')
                        : ListView.builder(
                            itemCount: _posts.length,
                            itemBuilder: (_, i) => PostCard(
                              post: _posts[i],
                              onLike: () {},
                              onComment: () {},
                            ),
                          ),
                  ],
                ),
    );
  }
}

class _SearchSuggestions extends StatelessWidget {
  final List<String> _topics = [
    'Prayer', 'Worship', 'Scripture', 'Testimony',
    'Faith', 'Grace', 'Healing', 'Devotional',
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Explore Topics',
            style: GoogleFonts.playfairDisplay(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _topics
                .map(
                  (t) => Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppTheme.bgCard,
                      borderRadius: BorderRadius.circular(50),
                      border: Border.all(
                          color: Colors.white.withOpacity(0.08)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('✝️',
                            style: TextStyle(fontSize: 13)),
                        const SizedBox(width: 6),
                        Text(
                          t,
                          style: GoogleFonts.dmSans(
                            color: AppTheme.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _UserResultTile extends StatelessWidget {
  final UserModel user;
  const _UserResultTile({required this.user});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => ProfileScreen(userId: user.uid)),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: UserAvatar(
          name: user.name, imageUrl: user.profilePicUrl, size: 48),
      title: Row(
        children: [
          Text(user.name,
              style: GoogleFonts.dmSans(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 14)),
          if (user.isVerified) ...[
            const SizedBox(width: 4),
            const VerifiedBadge(),
          ],
        ],
      ),
      subtitle: Text(
        '@${user.username}  ·  ${user.followersCount} followers',
        style: GoogleFonts.dmSans(
            color: AppTheme.textMuted, fontSize: 12),
      ),
      trailing: user.churchAttending != null
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.church_outlined,
                    color: AppTheme.textMuted, size: 13),
                const SizedBox(width: 4),
                Text(user.churchAttending!,
                    style: GoogleFonts.dmSans(
                        color: AppTheme.textMuted, fontSize: 11)),
              ],
            )
          : null,
    );
  }
}

class _EmptyResult extends StatelessWidget {
  final String message;
  const _EmptyResult({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🔍', style: TextStyle(fontSize: 44)),
          const SizedBox(height: 12),
          Text(message,
              style: GoogleFonts.dmSans(
                  color: AppTheme.textMuted, fontSize: 14)),
        ],
      ),
    );
  }
}
