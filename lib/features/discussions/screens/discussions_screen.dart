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

class DiscussionsScreen extends StatefulWidget {
  const DiscussionsScreen({super.key});

  @override
  State<DiscussionsScreen> createState() => _DiscussionsScreenState();
}

class _DiscussionsScreenState extends State<DiscussionsScreen> {
  final _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        backgroundColor: AppTheme.bgDark,
        title: Text('Discussions',
            style: GoogleFonts.playfairDisplay(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary)),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [AppTheme.primary, AppTheme.primaryDark]),
                borderRadius: BorderRadius.circular(10),
              ),
              child:
                  const Icon(Icons.add_rounded, color: Colors.white, size: 18),
            ),
            onPressed: _createDiscussion,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection(AppConstants.colDiscussions)
            .where('isActive', isEqualTo: true)
            .orderBy('lastMessageAt', descending: true)
            .snapshots(),
        builder: (_, snap) {
          if (!snap.hasData) {
            return const Center(
                child: CircularProgressIndicator(color: AppTheme.primary));
          }
          final docs = snap.data!.docs;

          // Auto-close stale discussions
          _checkAndCloseStale(docs);

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('💬', style: TextStyle(fontSize: 52)),
                  const SizedBox(height: 16),
                  Text('No active discussions',
                      style: GoogleFonts.playfairDisplay(
                          fontSize: 20, color: AppTheme.textPrimary)),
                  const SizedBox(height: 8),
                  Text('Start a conversation about faith',
                      style: GoogleFonts.dmSans(color: AppTheme.textMuted)),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: GradientButton(
                        label: 'Start Discussion',
                        onTap: _createDiscussion),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (_, i) {
              final discussion =
                  DiscussionModel.fromMap(docs[i].id, docs[i].data() as Map<String, dynamic>);
              return _DiscussionTile(
                discussion: discussion,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => DiscussionRoomScreen(
                          discussion: discussion)),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _checkAndCloseStale(List<QueryDocumentSnapshot> docs) {
    final now = DateTime.now();
    for (final doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final lastMsg = data['lastMessageAt'] != null
          ? (data['lastMessageAt'] as Timestamp).toDate()
          : (data['createdAt'] as Timestamp).toDate();
      final diff = now.difference(lastMsg).inHours;
      if (diff >= AppConstants.discussionExpiryHours) {
        // Close and delete messages
        _firestore.collection(AppConstants.colDiscussions).doc(doc.id).update({'isActive': false});
        _firestore
            .collection(AppConstants.colDiscussions)
            .doc(doc.id)
            .collection('messages')
            .get()
            .then((snap) {
          for (final msg in snap.docs) {
            msg.reference.delete();
          }
        });
      }
    }
  }

  void _createDiscussion() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.bgCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _CreateDiscussionSheet(),
    );
  }
}

class _DiscussionTile extends StatelessWidget {
  final DiscussionModel discussion;
  final VoidCallback onTap;

  const _DiscussionTile({required this.discussion, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final timeLeft = discussion.lastMessageAt != null
        ? AppConstants.discussionExpiryHours -
            DateTime.now().difference(discussion.lastMessageAt!).inHours
        : AppConstants.discussionExpiryHours;
    final isExpiringSoon = timeLeft <= 2;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isExpiringSoon
                ? AppTheme.warning.withOpacity(0.3)
                : Colors.white.withOpacity(0.06),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    discussion.title,
                    style: GoogleFonts.dmSans(
                      color: AppTheme.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (isExpiringSoon)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.warning.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Text(
                      '${timeLeft}h left',
                      style: GoogleFonts.dmSans(
                          color: AppTheme.warning,
                          fontSize: 10,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
              ],
            ),
            if (discussion.description != null) ...[
              const SizedBox(height: 4),
              Text(
                discussion.description!,
                style: GoogleFonts.dmSans(
                    color: AppTheme.textMuted, fontSize: 13),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                UserAvatar(
                    name: discussion.creatorName,
                    imageUrl: discussion.creatorProfilePic,
                    size: 24),
                const SizedBox(width: 6),
                Text(
                  discussion.creatorName,
                  style: GoogleFonts.dmSans(
                      color: AppTheme.textSecondary, fontSize: 12),
                ),
                const Spacer(),
                Icon(Icons.people_outline,
                    color: AppTheme.textMuted, size: 14),
                const SizedBox(width: 4),
                Text(
                  '${discussion.membersCount}',
                  style: GoogleFonts.dmSans(
                      color: AppTheme.textMuted, fontSize: 12),
                ),
                const SizedBox(width: 12),
                Icon(Icons.chat_bubble_outline,
                    color: AppTheme.textMuted, size: 14),
                const SizedBox(width: 4),
                Text(
                  '${discussion.messagesCount}',
                  style: GoogleFonts.dmSans(
                      color: AppTheme.textMuted, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class DiscussionRoomScreen extends StatefulWidget {
  final DiscussionModel discussion;
  const DiscussionRoomScreen({super.key, required this.discussion});

  @override
  State<DiscussionRoomScreen> createState() => _DiscussionRoomScreenState();
}

class _DiscussionRoomScreenState extends State<DiscussionRoomScreen> {
  final _msgCtrl = TextEditingController();
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final _bunny = BunnyStorageService();
  final _authService = AuthService();
  final _scrollCtrl = ScrollController();
  bool _joined = false;

  @override
  void initState() {
    super.initState();
    _checkJoined();
  }

  Future<void> _checkJoined() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    final doc = await _firestore
        .collection(AppConstants.colDiscussions)
        .doc(widget.discussion.id)
        .collection('members')
        .doc(uid)
        .get();
    setState(() => _joined = doc.exists);
  }

  Future<void> _join() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    await _firestore
        .collection(AppConstants.colDiscussions)
        .doc(widget.discussion.id)
        .collection('members')
        .doc(uid)
        .set({'joinedAt': Timestamp.now()});
    await _firestore
        .collection(AppConstants.colDiscussions)
        .doc(widget.discussion.id)
        .update({'membersCount': FieldValue.increment(1)});
    setState(() => _joined = true);
  }

  Future<void> _sendMessage({String? text, String? imageUrl}) async {
    if ((text == null || text.isEmpty) && imageUrl == null) return;
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    final user = await _authService.getUserById(uid);

    await _firestore
        .collection(AppConstants.colDiscussions)
        .doc(widget.discussion.id)
        .collection('messages')
        .add({
      'discussionId': widget.discussion.id,
      'senderId': uid,
      'senderName': user?.name ?? 'Saint',
      'senderProfilePic': user?.profilePicUrl,
      'text': text,
      'imageUrl': imageUrl,
      'sentAt': Timestamp.now(),
    });

    await _firestore
        .collection(AppConstants.colDiscussions)
        .doc(widget.discussion.id)
        .update({
      'messagesCount': FieldValue.increment(1),
      'lastMessageAt': Timestamp.now(),
    });

    _msgCtrl.clear();
    Future.delayed(const Duration(milliseconds: 200), () {
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
    final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (file == null) return;

    final uid = _auth.currentUser?.uid ?? 'user';
    final filename = _bunny.generateFilename('disc_$uid', 'jpg');
    final url = await _bunny.uploadFile(
      file: File(file.path),
      folder: AppConstants.folderMessages,
      filename: filename,
    );
    if (url != null) await _sendMessage(imageUrl: url);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        backgroundColor: AppTheme.bgCard,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.discussion.title,
                style: GoogleFonts.dmSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary)),
            Text(
                '${widget.discussion.membersCount} members · closes in 24h of inactivity',
                style: GoogleFonts.dmSans(
                    color: AppTheme.textMuted, fontSize: 10)),
          ],
        ),
      ),
      body: Column(
        children: [
          if (!_joined)
            Container(
              padding: const EdgeInsets.all(16),
              color: AppTheme.bgCard,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Join to participate in this discussion',
                      style: GoogleFonts.dmSans(
                          color: AppTheme.textSecondary, fontSize: 13),
                    ),
                  ),
                  GestureDetector(
                    onTap: _join,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            colors: [AppTheme.primary, AppTheme.primaryDark]),
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Text('Join',
                          style: GoogleFonts.dmSans(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 13)),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection(AppConstants.colDiscussions)
                  .doc(widget.discussion.id)
                  .collection('messages')
                  .orderBy('sentAt', descending: false)
                  .snapshots(),
              builder: (_, snap) {
                if (!snap.hasData) {
                  return const Center(
                      child: CircularProgressIndicator(color: AppTheme.primary));
                }
                final messages = snap.data!.docs;
                return ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (_, i) {
                    final msg = messages[i].data() as Map<String, dynamic>;
                    final isMe = msg['senderId'] == _auth.currentUser?.uid;
                    return _MessageBubble(data: msg, isMe: isMe);
                  },
                );
              },
            ),
          ),
          if (_joined)
            Container(
              padding: EdgeInsets.fromLTRB(
                  12, 8, 12, MediaQuery.of(context).padding.bottom + 8),
              decoration: BoxDecoration(
                color: AppTheme.bgCard,
                border: Border(
                    top: BorderSide(color: Colors.white.withOpacity(0.06))),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.image_outlined,
                        color: AppTheme.textMuted),
                    onPressed: _sendImage,
                  ),
                  Expanded(
                    child: TextField(
                      controller: _msgCtrl,
                      style: GoogleFonts.dmSans(
                          color: AppTheme.textPrimary, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Share your thoughts...',
                        hintStyle: GoogleFonts.dmSans(
                            color: AppTheme.textMuted, fontSize: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(50),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: AppTheme.bgElevated,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _sendMessage(text: _msgCtrl.text.trim()),
                    child: Container(
                      width: 40,
                      height: 40,
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
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool isMe;

  const _MessageBubble({required this.data, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe) ...[
            UserAvatar(
                name: data['senderName'] ?? 'S',
                imageUrl: data['senderProfilePic'],
                size: 28),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!isMe)
                  Text(
                    data['senderName'] ?? 'Saint',
                    style: GoogleFonts.dmSans(
                        color: AppTheme.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w600),
                  ),
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.68,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isMe ? AppTheme.primary : AppTheme.bgElevated,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isMe ? 16 : 4),
                      bottomRight: Radius.circular(isMe ? 4 : 16),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (data['imageUrl'] != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(data['imageUrl'],
                              width: 200, fit: BoxFit.cover),
                        ),
                      if (data['text'] != null && data['text']!.isNotEmpty)
                        Text(
                          data['text'],
                          style: GoogleFonts.dmSans(
                              color: isMe ? Colors.white : AppTheme.textPrimary,
                              fontSize: 14),
                        ),
                    ],
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

class _CreateDiscussionSheet extends StatefulWidget {
  @override
  State<_CreateDiscussionSheet> createState() => _CreateDiscussionSheetState();
}

class _CreateDiscussionSheetState extends State<_CreateDiscussionSheet> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _firestore = FirebaseFirestore.instance;
  final _authService = AuthService();
  bool _loading = false;

  Future<void> _create() async {
    if (_titleCtrl.text.trim().isEmpty) return;
    setState(() => _loading = true);
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final user = await _authService.getUserById(uid);
      await _firestore.collection(AppConstants.colDiscussions).add({
        'creatorId': uid,
        'creatorName': user?.name ?? 'Saint',
        'creatorProfilePic': user?.profilePicUrl,
        'title': _titleCtrl.text.trim(),
        'description': _descCtrl.text.trim().isEmpty
            ? null
            : _descCtrl.text.trim(),
        'membersCount': 1,
        'messagesCount': 0,
        'createdAt': Timestamp.now(),
        'lastMessageAt': Timestamp.now(),
        'isActive': true,
      });
      Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _loading = false);
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
          Text('Start a Discussion',
              style: GoogleFonts.playfairDisplay(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary)),
          const SizedBox(height: 6),
          Text(
            'Discussion closes automatically after 24h of inactivity',
            style: GoogleFonts.dmSans(color: AppTheme.textMuted, fontSize: 12),
          ),
          const SizedBox(height: 20),
          EcclesiaTextField(
            hint: 'e.g. Understanding Grace and Faith',
            label: 'Topic Title *',
            controller: _titleCtrl,
          ),
          const SizedBox(height: 12),
          EcclesiaTextField(
            hint: 'Brief context for the discussion',
            label: 'Description',
            controller: _descCtrl,
            maxLines: 3,
          ),
          const SizedBox(height: 20),
          GradientButton(
              label: 'Start Discussion', onTap: _create, loading: _loading),
        ],
      ),
    );
  }
}
