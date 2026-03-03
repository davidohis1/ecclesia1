import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/constants/app_constants.dart';
import '../../../models/other_models.dart';
import '../../../services/bunny_storage_service.dart';
import '../../../services/auth_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MESSAGES SCREEN  (conversations list)
// ─────────────────────────────────────────────────────────────────────────────
class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    final uid = _auth.currentUser?.uid;

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        backgroundColor: AppTheme.bgDark,
        title: Text(
          'Messages',
          style: GoogleFonts.playfairDisplay(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.people_outline_rounded,
                color: AppTheme.textPrimary),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const SaintsScreen())),
            tooltip: 'Find Saints',
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined,
                color: AppTheme.textPrimary),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const SaintsScreen())),
            tooltip: 'New Message',
          ),
        ],
      ),
      body: uid == null
          ? const Center(child: Text('Not logged in'))
          : StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection(AppConstants.colMessages)
                  .where('participantIds', arrayContains: uid)
                  .orderBy('lastMessageAt', descending: true)
                  .snapshots(),
              builder: (_, snap) {
                if (!snap.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppTheme.primary),
                  );
                }

                final convos = snap.data!.docs;

                if (convos.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 90,
                            height: 90,
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withOpacity(0.12),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.mail_outline_rounded,
                                color: AppTheme.primary, size: 42),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'No Messages Yet',
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Connect with saints and start spreading the Word',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.dmSans(
                                color: AppTheme.textMuted, fontSize: 14),
                          ),
                          const SizedBox(height: 28),
                          GradientButton(
                            label: 'Find Saints',
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const SaintsScreen()),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  itemCount: convos.length,
                  separatorBuilder: (_, __) => Divider(
                      color: Colors.white.withOpacity(0.04),
                      height: 1),
                  itemBuilder: (_, i) {
                    final data =
                        convos[i].data() as Map<String, dynamic>;
                    final convo =
                        ChatConversation.fromMap(convos[i].id, data);
                    final otherId = convo.participantIds.firstWhere(
                        (id) => id != uid,
                        orElse: () => uid);
                    final otherName =
                        convo.participantNames[otherId] ?? 'Saint';
                    final otherPhoto =
                        convo.participantPhotos[otherId];
                    final unread = convo.unreadCounts[uid] ?? 0;

                    return ListTile(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatScreen(
                            conversationId: convo.id,
                            otherUserId: otherId,
                            otherUserName: otherName,
                            otherUserPhoto: otherPhoto,
                          ),
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      leading: Stack(
                        children: [
                          UserAvatar(
                            name: otherName,
                            imageUrl: otherPhoto,
                            size: 52,
                            showBorder: unread > 0,
                            borderColor: AppTheme.primary,
                          ),
                          if (unread > 0)
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                width: 16,
                                height: 16,
                                decoration: const BoxDecoration(
                                  color: AppTheme.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    '$unread',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      title: Text(
                        otherName,
                        style: GoogleFonts.dmSans(
                          color: AppTheme.textPrimary,
                          fontSize: 15,
                          fontWeight: unread > 0
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                      subtitle: Text(
                        convo.lastMessage ?? 'Tap to start chatting',
                        style: GoogleFonts.dmSans(
                          color: unread > 0
                              ? AppTheme.textSecondary
                              : AppTheme.textMuted,
                          fontSize: 13,
                          fontWeight: unread > 0
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: convo.lastMessageAt != null
                          ? Text(
                              timeago.format(convo.lastMessageAt!,
                                  allowFromNow: true),
                              style: GoogleFonts.dmSans(
                                color: unread > 0
                                    ? AppTheme.primary
                                    : AppTheme.textMuted,
                                fontSize: 11,
                              ),
                            )
                          : null,
                    );
                  },
                );
              },
            ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CHAT SCREEN  (1-on-1 conversation)
// ─────────────────────────────────────────────────────────────────────────────
class ChatScreen extends StatefulWidget {
  final String conversationId;
  final String otherUserId;
  final String otherUserName;
  final String? otherUserPhoto;

  const ChatScreen({
    super.key,
    required this.conversationId,
    required this.otherUserId,
    required this.otherUserName,
    this.otherUserPhoto,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _msgCtrl = TextEditingController();
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final _bunny = BunnyStorageService();
  final _authService = AuthService();
  final _scrollCtrl = ScrollController();
  bool _sendingImage = false;

  @override
  void initState() {
    super.initState();
    _markRead();
  }

  Future<void> _markRead() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    await _firestore
        .collection(AppConstants.colMessages)
        .doc(widget.conversationId)
        .set({'unreadCounts': {uid: 0}}, SetOptions(merge: true));
  }

  Future<void> _send({String? text, String? imageUrl}) async {
    if ((text == null || text.trim().isEmpty) && imageUrl == null) return;
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    final user = await _authService.getUserById(uid);

    final convRef = _firestore
        .collection(AppConstants.colMessages)
        .doc(widget.conversationId);

    await convRef.collection('chats').add({
      'chatId': widget.conversationId,
      'senderId': uid,
      'text': text?.trim(),
      'imageUrl': imageUrl,
      'sentAt': Timestamp.now(),
      'isRead': false,
    });

    await convRef.set({
      'participantIds': [uid, widget.otherUserId],
      'participantNames': {
        uid: user?.name ?? 'You',
        widget.otherUserId: widget.otherUserName,
      },
      'participantPhotos': {
        uid: user?.profilePicUrl,
        widget.otherUserId: widget.otherUserPhoto,
      },
      'lastMessage': imageUrl != null ? '📷 Image' : text?.trim(),
      'lastMessageAt': Timestamp.now(),
      'unreadCounts': {
        widget.otherUserId: FieldValue.increment(1),
      },
    }, SetOptions(merge: true));

    _msgCtrl.clear();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 250), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendImage() async {
    final picker = ImagePicker();
    final file =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 75);
    if (file == null) return;

    setState(() => _sendingImage = true);
    try {
      final uid = _auth.currentUser?.uid ?? 'user';
      final filename =
          _bunny.generateFilename('msg_${uid}_chat', 'jpg');
      final url = await _bunny.uploadFile(
        file: File(file.path),
        folder: AppConstants.folderMessages,
        filename: filename,
      );
      if (url != null) await _send(imageUrl: url);
    } finally {
      if (mounted) setState(() => _sendingImage = false);
    }
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uid = _auth.currentUser?.uid;

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        backgroundColor: AppTheme.bgCard,
        titleSpacing: 0,
        title: Row(
          children: [
            UserAvatar(
              name: widget.otherUserName,
              imageUrl: widget.otherUserPhoto,
              size: 38,
              showBorder: true,
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.otherUserName,
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  'Saint · Ecclesia',
                  style: GoogleFonts.dmSans(
                      color: AppTheme.textMuted, fontSize: 11),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.call_outlined,
                color: AppTheme.textPrimary, size: 22),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.videocam_outlined,
                color: AppTheme.textPrimary, size: 22),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection(AppConstants.colMessages)
                  .doc(widget.conversationId)
                  .collection('chats')
                  .orderBy('sentAt', descending: false)
                  .snapshots(),
              builder: (_, snap) {
                if (!snap.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(
                        color: AppTheme.primary),
                  );
                }

                final msgs = snap.data!.docs;

                if (msgs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('🕊️',
                            style: TextStyle(fontSize: 40)),
                        const SizedBox(height: 12),
                        Text(
                          'Say hello to ${widget.otherUserName}',
                          style: GoogleFonts.dmSans(
                              color: AppTheme.textMuted, fontSize: 14),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  itemCount: msgs.length,
                  itemBuilder: (_, i) {
                    final data =
                        msgs[i].data() as Map<String, dynamic>;
                    final isMe = data['senderId'] == uid;
                    return _ChatBubble(data: data, isMe: isMe);
                  },
                );
              },
            ),
          ),

          // Input bar
          Container(
            padding: EdgeInsets.fromLTRB(
              12,
              8,
              12,
              MediaQuery.of(context).padding.bottom + 8,
            ),
            decoration: BoxDecoration(
              color: AppTheme.bgCard,
              border: Border(
                top: BorderSide(
                    color: Colors.white.withOpacity(0.06)),
              ),
            ),
            child: Row(
              children: [
                // Image button
                GestureDetector(
                  onTap: _sendingImage ? null : _sendImage,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppTheme.bgElevated,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: _sendingImage
                        ? const Padding(
                            padding: EdgeInsets.all(10),
                            child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppTheme.primary),
                          )
                        : const Icon(Icons.image_outlined,
                            color: AppTheme.textMuted, size: 20),
                  ),
                ),
                const SizedBox(width: 10),
                // Text input
                Expanded(
                  child: TextField(
                    controller: _msgCtrl,
                    style: GoogleFonts.dmSans(
                        color: AppTheme.textPrimary, fontSize: 14),
                    maxLines: null,
                    textCapitalization:
                        TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText: 'Message...',
                      hintStyle: GoogleFonts.dmSans(
                          color: AppTheme.textMuted, fontSize: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: AppTheme.bgElevated,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Send button
                GestureDetector(
                  onTap: () => _send(text: _msgCtrl.text),
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppTheme.primary, AppTheme.primaryDark],
                      ),
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

// Chat bubble widget
class _ChatBubble extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool isMe;

  const _ChatBubble({required this.data, required this.isMe});

  @override
  Widget build(BuildContext context) {
    final sentAt = data['sentAt'] != null
        ? (data['sentAt'] as Timestamp).toDate()
        : DateTime.now();

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Flexible(
            child: Column(
              crossAxisAlignment: isMe
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.7,
                  ),
                  padding:
                      data['imageUrl'] != null && data['text'] == null
                          ? EdgeInsets.zero
                          : const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isMe
                        ? AppTheme.primary
                        : AppTheme.bgElevated,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft:
                          Radius.circular(isMe ? 18 : 4),
                      bottomRight:
                          Radius.circular(isMe ? 4 : 18),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (data['imageUrl'] != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.network(
                            data['imageUrl'],
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const Icon(Icons.broken_image,
                                    color: AppTheme.textMuted),
                          ),
                        ),
                      if (data['text'] != null &&
                          (data['text'] as String).isNotEmpty)
                        Padding(
                          padding: data['imageUrl'] != null
                              ? const EdgeInsets.fromLTRB(14, 8, 14, 10)
                              : EdgeInsets.zero,
                          child: Text(
                            data['text'],
                            style: GoogleFonts.dmSans(
                              color: isMe
                                  ? Colors.white
                                  : AppTheme.textPrimary,
                              fontSize: 14,
                              height: 1.4,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  timeago.format(sentAt, allowFromNow: true),
                  style: GoogleFonts.dmSans(
                      color: AppTheme.textMuted, fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SAINTS SCREEN  (find / follow users)
// ─────────────────────────────────────────────────────────────────────────────
class SaintsScreen extends StatefulWidget {
  const SaintsScreen({super.key});

  @override
  State<SaintsScreen> createState() => _SaintsScreenState();
}

class _SaintsScreenState extends State<SaintsScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final _searchCtrl = TextEditingController();

  List<Map<String, dynamic>> _saints = [];
  List<Map<String, dynamic>> _filtered = [];
  Set<String> _followingIds = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSaints();
    _searchCtrl.addListener(_filter);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSaints() async {
    final uid = _auth.currentUser?.uid;
    final snap = await _firestore
        .collection(AppConstants.colUsers)
        .limit(50)
        .get();

    // Load who current user follows
    Set<String> following = {};
    if (uid != null) {
      final followSnap = await _firestore
          .collection(AppConstants.colFollows)
          .where('followerId', isEqualTo: uid)
          .get();
      following = followSnap.docs
          .map((d) => d['followingId'] as String)
          .toSet();
    }

    final saints = snap.docs
        .where((d) => d.id != uid)
        .map((d) => {'id': d.id, ...d.data()})
        .toList();

    setState(() {
      _saints = saints;
      _filtered = List.from(saints);
      _followingIds = following;
      _loading = false;
    });
  }

  void _filter() {
    final q = _searchCtrl.text.toLowerCase();
    setState(() {
      _filtered = _saints.where((s) {
        return q.isEmpty ||
            (s['name'] as String? ?? '')
                .toLowerCase()
                .contains(q) ||
            (s['username'] as String? ?? '')
                .toLowerCase()
                .contains(q);
      }).toList();
    });
  }

  Future<void> _toggleFollow(String targetId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final followId = '${uid}_$targetId';
    final followRef = _firestore
        .collection(AppConstants.colFollows)
        .doc(followId);

    if (_followingIds.contains(targetId)) {
      await followRef.delete();
      await _firestore
          .collection(AppConstants.colUsers)
          .doc(uid)
          .update({'followingCount': FieldValue.increment(-1)});
      await _firestore
          .collection(AppConstants.colUsers)
          .doc(targetId)
          .update({'followersCount': FieldValue.increment(-1)});
      setState(() => _followingIds.remove(targetId));
    } else {
      await followRef.set({
        'followerId': uid,
        'followingId': targetId,
        'createdAt': Timestamp.now(),
      });
      await _firestore
          .collection(AppConstants.colUsers)
          .doc(uid)
          .update({'followingCount': FieldValue.increment(1)});
      await _firestore
          .collection(AppConstants.colUsers)
          .doc(targetId)
          .update({'followersCount': FieldValue.increment(1)});
      setState(() => _followingIds.add(targetId));
    }
  }

  Future<void> _startChat(Map<String, dynamic> saint) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    final targetId = saint['id'] as String;
    final ids = [uid, targetId]..sort();
    final convoId = ids.join('_');

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          conversationId: convoId,
          otherUserId: targetId,
          otherUserName: saint['name'] ?? 'Saint',
          otherUserPhoto: saint['profilePicUrl'],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        backgroundColor: AppTheme.bgDark,
        title: Text(
          'Find Saints',
          style: GoogleFonts.playfairDisplay(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: TextField(
              controller: _searchCtrl,
              style: GoogleFonts.dmSans(
                  color: AppTheme.textPrimary, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search saints by name or @username',
                prefixIcon: const Icon(Icons.search_rounded,
                    color: AppTheme.textMuted, size: 20),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close,
                            color: AppTheme.textMuted, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          _filter();
                        },
                      )
                    : null,
              ),
            ),
          ),
          // Saints list
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(
                        color: AppTheme.primary))
                : _filtered.isEmpty
                    ? Center(
                        child: Text(
                          'No saints found',
                          style: GoogleFonts.dmSans(
                              color: AppTheme.textMuted),
                        ),
                      )
                    : ListView.builder(
                        padding:
                            const EdgeInsets.symmetric(vertical: 4),
                        itemCount: _filtered.length,
                        itemBuilder: (_, i) {
                          final saint = _filtered[i];
                          final id = saint['id'] as String;
                          final isFollowing =
                              _followingIds.contains(id);
                          return _SaintTile(
                            saint: saint,
                            isFollowing: isFollowing,
                            onFollow: () => _toggleFollow(id),
                            onMessage: () => _startChat(saint),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _SaintTile extends StatelessWidget {
  final Map<String, dynamic> saint;
  final bool isFollowing;
  final VoidCallback onFollow;
  final VoidCallback onMessage;

  const _SaintTile({
    required this.saint,
    required this.isFollowing,
    required this.onFollow,
    required this.onMessage,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: UserAvatar(
        name: saint['name'] ?? 'S',
        imageUrl: saint['profilePicUrl'],
        size: 50,
        showBorder: true,
      ),
      title: Row(
        children: [
          Text(
            saint['name'] ?? 'Saint',
            style: GoogleFonts.dmSans(
              color: AppTheme.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (saint['isVerified'] == true) ...[
            const SizedBox(width: 4),
            const VerifiedBadge(),
          ],
        ],
      ),
      subtitle: Text(
        '@${saint['username'] ?? ''}  ·  ${saint['followersCount'] ?? 0} followers',
        style:
            GoogleFonts.dmSans(color: AppTheme.textMuted, fontSize: 12),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Message button
          GestureDetector(
            onTap: onMessage,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.bgElevated,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: Colors.white.withOpacity(0.08)),
              ),
              child: const Icon(Icons.mail_outline_rounded,
                  color: AppTheme.primary, size: 18),
            ),
          ),
          const SizedBox(width: 8),
          // Follow button
          GestureDetector(
            onTap: onFollow,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isFollowing
                    ? AppTheme.bgElevated
                    : AppTheme.primary,
                borderRadius: BorderRadius.circular(50),
                border: Border.all(
                  color: isFollowing
                      ? Colors.white.withOpacity(0.15)
                      : AppTheme.primary,
                ),
              ),
              child: Text(
                isFollowing ? 'Following' : 'Follow',
                style: GoogleFonts.dmSans(
                  color: isFollowing
                      ? AppTheme.textSecondary
                      : Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
