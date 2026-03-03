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
import '../../feed/widgets/post_card.dart';
import '../../messages/screens/messages_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String userId;
  const ProfileScreen({super.key, required this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final _authService = AuthService();

  UserModel? _user;
  List<PostModel> _posts = [];
  bool _loading = true;
  bool _isFollowing = false;
  bool _isMe = false;
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _loadProfile();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() => _loading = true);
    final myUid = _auth.currentUser?.uid;
    _isMe = myUid == widget.userId;

    final user = await _authService.getUserById(widget.userId);

    // Load posts
    final postsSnap = await _firestore
        .collection(AppConstants.colPosts)
        .where('authorId', isEqualTo: widget.userId)
        .orderBy('createdAt', descending: true)
        .get();
    final posts = postsSnap.docs
        .map((d) => PostModel.fromMap(d.id, d.data()))
        .toList();

    // Check follow status
    bool following = false;
    if (myUid != null && !_isMe) {
      final followDoc = await _firestore
          .collection(AppConstants.colFollows)
          .doc('${myUid}_${widget.userId}')
          .get();
      following = followDoc.exists;
    }

    setState(() {
      _user = user;
      _posts = posts;
      _isFollowing = following;
      _loading = false;
    });
  }

  Future<void> _toggleFollow() async {
    final myUid = _auth.currentUser?.uid;
    if (myUid == null) return;
    final followId = '${myUid}_${widget.userId}';

    if (_isFollowing) {
      await _firestore
          .collection(AppConstants.colFollows)
          .doc(followId)
          .delete();
      await _firestore
          .collection(AppConstants.colUsers)
          .doc(myUid)
          .update({'followingCount': FieldValue.increment(-1)});
      await _firestore
          .collection(AppConstants.colUsers)
          .doc(widget.userId)
          .update({'followersCount': FieldValue.increment(-1)});
    } else {
      await _firestore
          .collection(AppConstants.colFollows)
          .doc(followId)
          .set({
        'followerId': myUid,
        'followingId': widget.userId,
        'createdAt': Timestamp.now(),
      });
      await _firestore
          .collection(AppConstants.colUsers)
          .doc(myUid)
          .update({'followingCount': FieldValue.increment(1)});
      await _firestore
          .collection(AppConstants.colUsers)
          .doc(widget.userId)
          .update({'followersCount': FieldValue.increment(1)});
    }
    setState(() => _isFollowing = !_isFollowing);
    _loadProfile();
  }

  Future<void> _signOut() async {
    await _authService.signOut();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(
          context, AppRoutes.login, (_) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: AppTheme.bgDark,
        body: Center(
            child: CircularProgressIndicator(color: AppTheme.primary)),
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
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            backgroundColor: AppTheme.bgDark,
            actions: [
              if (_isMe)
                IconButton(
                  icon: const Icon(Icons.logout_rounded,
                      color: AppTheme.textPrimary),
                  onPressed: _signOut,
                ),
              if (_isMe)
                IconButton(
                  icon: const Icon(Icons.settings_outlined,
                      color: AppTheme.textPrimary),
                  onPressed: () {},
                ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: _ProfileHeader(
                user: _user!,
                isMe: _isMe,
                isFollowing: _isFollowing,
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
          SliverPersistentHeader(
            pinned: true,
            delegate: _TabBarDelegate(
              TabBar(
                controller: _tabCtrl,
                indicatorColor: AppTheme.primary,
                indicatorWeight: 2,
                labelColor: AppTheme.primary,
                unselectedLabelColor: AppTheme.textMuted,
                labelStyle: GoogleFonts.dmSans(
                    fontWeight: FontWeight.w700, fontSize: 13),
                tabs: const [
                  Tab(text: 'Posts'),
                  Tab(text: 'About'),
                ],
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabCtrl,
          children: [
            // Posts tab
            _posts.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('✝️',
                              style: TextStyle(fontSize: 40)),
                          const SizedBox(height: 12),
                          Text(
                            _isMe
                                ? 'Share your first post'
                                : 'No posts yet',
                            style: GoogleFonts.dmSans(
                                color: AppTheme.textMuted),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: _posts.length,
                    itemBuilder: (_, i) => PostCard(
                      post: _posts[i],
                      onLike: () {},
                      onComment: () {},
                    ),
                  ),
            // About tab
            _AboutTab(user: _user!),
          ],
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final UserModel user;
  final bool isMe;
  final bool isFollowing;
  final VoidCallback onFollow;
  final VoidCallback onMessage;

  const _ProfileHeader({
    required this.user,
    required this.isMe,
    required this.isFollowing,
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
          padding: const EdgeInsets.fromLTRB(20, 48, 20, 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Avatar + stats row
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Avatar
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [AppTheme.primary, AppTheme.accent],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primary.withOpacity(0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(2.5),
                    child: UserAvatar(
                      name: user.name,
                      imageUrl: user.profilePicUrl,
                      size: 78,
                    ),
                  ),
                  const SizedBox(width: 20),
                  // Stats
                  Expanded(
                    child: Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceAround,
                      children: [
                        _StatItem(
                            label: 'Posts',
                            value: '${user.postsCount}'),
                        _StatItem(
                            label: 'Followers',
                            value: '${user.followersCount}'),
                        _StatItem(
                            label: 'Following',
                            value: '${user.followingCount}'),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // Name + username
              Align(
                alignment: Alignment.centerLeft,
                child: Row(
                  children: [
                    Text(
                      user.name,
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
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
                child: Text(
                  '@${user.username}',
                  style: GoogleFonts.dmSans(
                      color: AppTheme.primary, fontSize: 13),
                ),
              ),
              if (user.bio != null && user.bio!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    user.bio!,
                    style: GoogleFonts.dmSans(
                        color: AppTheme.textSecondary, fontSize: 13),
                    maxLines: 2,
                  ),
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
                      Text(
                        user.churchAttending!,
                        style: GoogleFonts.dmSans(
                            color: AppTheme.textMuted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 14),
              // Action buttons
              if (!isMe)
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: onFollow,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                              vertical: 10),
                          decoration: BoxDecoration(
                            gradient: isFollowing
                                ? null
                                : const LinearGradient(
                                    colors: [
                                      AppTheme.primary,
                                      AppTheme.primaryDark
                                    ],
                                  ),
                            color: isFollowing
                                ? AppTheme.bgElevated
                                : null,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isFollowing
                                  ? Colors.white.withOpacity(0.15)
                                  : Colors.transparent,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              isFollowing ? 'Following' : 'Follow',
                              style: GoogleFonts.dmSans(
                                color: isFollowing
                                    ? AppTheme.textSecondary
                                    : Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
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
                          padding: const EdgeInsets.symmetric(
                              vertical: 10),
                          decoration: BoxDecoration(
                            color: AppTheme.bgElevated,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.15)),
                          ),
                          child: Center(
                            child: Text(
                              'Message',
                              style: GoogleFonts.dmSans(
                                color: AppTheme.textPrimary,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
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

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.dmSans(
            color: AppTheme.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.dmSans(
              color: AppTheme.textMuted, fontSize: 11),
        ),
      ],
    );
  }
}

class _AboutTab extends StatelessWidget {
  final UserModel user;
  const _AboutTab({required this.user});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _AboutRow(
            icon: Icons.person_outline,
            label: 'Gender',
            value: user.gender ?? 'Not specified',
          ),
          _AboutRow(
            icon: Icons.cake_outlined,
            label: 'Date of Birth',
            value: user.dateOfBirth != null
                ? DateFormat('MMMM d, yyyy').format(user.dateOfBirth!)
                : 'Not specified',
          ),
          _AboutRow(
            icon: Icons.church_outlined,
            label: 'Church',
            value: user.churchAttending ?? 'Not specified',
          ),
          _AboutRow(
            icon: Icons.favorite_outline,
            label: 'Given life to Christ',
            value: user.givenLifeToChrist ? 'Yes 🙏' : 'Not yet',
            valueColor: user.givenLifeToChrist
                ? AppTheme.success
                : AppTheme.textMuted,
          ),
          _AboutRow(
            icon: Icons.calendar_today_outlined,
            label: 'Member since',
            value: DateFormat('MMMM yyyy').format(user.createdAt),
          ),
        ],
      ),
    );
  }
}

class _AboutRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _AboutRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppTheme.primary, size: 18),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: GoogleFonts.dmSans(
                      color: AppTheme.textMuted, fontSize: 11)),
              Text(
                value,
                style: GoogleFonts.dmSans(
                  color: valueColor ?? AppTheme.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  _TabBarDelegate(this.tabBar);

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: AppTheme.bgDark,
      child: tabBar,
    );
  }

  @override
  double get maxExtent => tabBar.preferredSize.height;
  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  bool shouldRebuild(_) => false;
}
