import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:just_audio/just_audio.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/constants/app_constants.dart';
import '../../../models/other_models.dart';
import '../../../services/bunny_storage_service.dart';
import '../../../services/auth_service.dart';

class MusicScreen extends StatefulWidget {
  const MusicScreen({super.key});

  @override
  State<MusicScreen> createState() => _MusicScreenState();
}

class _MusicScreenState extends State<MusicScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _searchCtrl = TextEditingController();
  final _player = AudioPlayer();

  List<AudioModel> _audios = [];
  List<AudioModel> _filtered = [];
  bool _loading = true;
  AudioModel? _currentlyPlaying;
  bool _isPlaying = false;
  String _selectedCategory = 'All';

  final List<String> _categories = [
    'All', 'Worship', 'Gospel', 'Hymns', 'Praise', 'Prayer', 'Sermon'
  ];

  @override
  void initState() {
    super.initState();
    _loadAudio();
    _searchCtrl.addListener(_filter);
    _player.playerStateStream.listen((state) {
      setState(() => _isPlaying = state.playing);
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _player.dispose();
    super.dispose();
  }

  Future<void> _loadAudio() async {
    final snap = await _firestore
        .collection(AppConstants.colAudio)
        .orderBy('uploadedAt', descending: true)
        .get();
    setState(() {
      _audios = snap.docs.map((d) => AudioModel.fromMap(d.id, d.data())).toList();
      _filtered = List.from(_audios);
      _loading = false;
    });
  }

  void _filter() {
    final q = _searchCtrl.text.toLowerCase();
    setState(() {
      _filtered = _audios.where((a) {
        final matchQ = q.isEmpty ||
            a.title.toLowerCase().contains(q) ||
            (a.artist?.toLowerCase().contains(q) ?? false);
        final matchCat = _selectedCategory == 'All' || a.category == _selectedCategory;
        return matchQ && matchCat;
      }).toList();
    });
  }

  Future<void> _playAudio(AudioModel audio) async {
    try {
      if (_currentlyPlaying?.id == audio.id && _isPlaying) {
        await _player.pause();
      } else {
        setState(() => _currentlyPlaying = audio);
        await _player.setUrl(audio.audioUrl);
        await _player.play();
        // Increment play count
        _firestore
            .collection(AppConstants.colAudio)
            .doc(audio.id)
            .update({'playCount': FieldValue.increment(1)});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Playback error: $e')));
      }
    }
  }

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: Column(
        children: [
          // Header
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.bgCard, AppTheme.bgDark],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Row(
                      children: [
                        Text('Music',
                            style: GoogleFonts.playfairDisplay(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary)),
                        const Spacer(),
                        IconButton(
                          icon: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                  colors: [AppTheme.primary, AppTheme.primaryDark]),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.upload_rounded,
                                color: Colors.white, size: 18),
                          ),
                          onPressed: _uploadAudio,
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                    child: TextField(
                      controller: _searchCtrl,
                      style: GoogleFonts.dmSans(
                          color: AppTheme.textPrimary, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Search songs, artists...',
                        prefixIcon: const Icon(Icons.search_rounded,
                            color: AppTheme.textMuted, size: 20),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 40,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _categories.length,
                      itemBuilder: (_, i) {
                        final cat = _categories[i];
                        final sel = _selectedCategory == cat;
                        return GestureDetector(
                          onTap: () {
                            setState(() => _selectedCategory = cat);
                            _filter();
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: sel ? AppTheme.primary : AppTheme.bgElevated,
                              borderRadius: BorderRadius.circular(50),
                            ),
                            child: Text(cat,
                                style: GoogleFonts.dmSans(
                                    color: sel ? Colors.white : AppTheme.textMuted,
                                    fontSize: 12,
                                    fontWeight: sel
                                        ? FontWeight.w700
                                        : FontWeight.normal)),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
          // List
          Expanded(
            child: _loading
                ? Center(
                    child: CircularProgressIndicator(color: AppTheme.primary))
                : _filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('🎵', style: TextStyle(fontSize: 52)),
                            const SizedBox(height: 16),
                            Text('No music yet',
                                style: GoogleFonts.playfairDisplay(
                                    fontSize: 20, color: AppTheme.textPrimary)),
                            const SizedBox(height: 8),
                            Text('Upload worship music for the community',
                                style: GoogleFonts.dmSans(
                                    color: AppTheme.textMuted)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: _filtered.length,
                        itemBuilder: (_, i) {
                          final audio = _filtered[i];
                          final isPlaying = _currentlyPlaying?.id == audio.id;
                          return _AudioTile(
                            audio: audio,
                            isPlaying: isPlaying && _isPlaying,
                            isSelected: isPlaying,
                            onTap: () => _playAudio(audio),
                            formatDuration: _formatDuration,
                          );
                        },
                      ),
          ),
          // Mini player
          if (_currentlyPlaying != null) _MiniPlayer(
            audio: _currentlyPlaying!,
            isPlaying: _isPlaying,
            player: _player,
            onToggle: () => _isPlaying ? _player.pause() : _player.play(),
          ),
        ],
      ),
    );
  }

  Future<void> _uploadAudio() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp3', 'wav', 'aac', 'm4a'],
    );
    if (result == null) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.bgCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _UploadAudioSheet(
        file: File(result.files.first.path!),
        onUploaded: () {
          Navigator.pop(context);
          _loadAudio();
        },
      ),
    );
  }
}

class _AudioTile extends StatelessWidget {
  final AudioModel audio;
  final bool isPlaying;
  final bool isSelected;
  final VoidCallback onTap;
  final String Function(int) formatDuration;

  const _AudioTile({
    required this.audio,
    required this.isPlaying,
    required this.isSelected,
    required this.onTap,
    required this.formatDuration,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isSelected
                ? [AppTheme.primary, AppTheme.primaryDark]
                : [AppTheme.bgElevated, AppTheme.bgCard],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: isPlaying
            ? const Icon(Icons.equalizer_rounded, color: Colors.white, size: 22)
            : Icon(Icons.music_note_rounded,
                color: isSelected ? Colors.white : AppTheme.textMuted, size: 22),
      ),
      title: Text(
        audio.title,
        style: GoogleFonts.dmSans(
          color: isSelected ? AppTheme.primaryLight : AppTheme.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        audio.artist ?? audio.uploaderName,
        style: GoogleFonts.dmSans(color: AppTheme.textMuted, fontSize: 12),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            formatDuration(audio.durationSeconds),
            style: GoogleFonts.dmSans(color: AppTheme.textMuted, fontSize: 12),
          ),
          const SizedBox(width: 8),
          Icon(
            isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_filled_rounded,
            color: isSelected ? AppTheme.primary : AppTheme.textMuted,
            size: 28,
          ),
        ],
      ),
    );
  }
}

class _MiniPlayer extends StatelessWidget {
  final AudioModel audio;
  final bool isPlaying;
  final AudioPlayer player;
  final VoidCallback onToggle;

  const _MiniPlayer({
    required this.audio,
    required this.isPlaying,
    required this.player,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [AppTheme.primary, AppTheme.primaryDark]),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.music_note_rounded,
                color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(audio.title,
                    style: GoogleFonts.dmSans(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700),
                    overflow: TextOverflow.ellipsis),
                Text(audio.artist ?? audio.uploaderName,
                    style: GoogleFonts.dmSans(
                        color: Colors.white70, fontSize: 11)),
              ],
            ),
          ),
          IconButton(
            icon: Icon(isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: Colors.white, size: 28),
            onPressed: onToggle,
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 20),
            onPressed: () => player.stop(),
          ),
        ],
      ),
    );
  }
}

class _UploadAudioSheet extends StatefulWidget {
  final File file;
  final VoidCallback onUploaded;

  const _UploadAudioSheet({required this.file, required this.onUploaded});

  @override
  State<_UploadAudioSheet> createState() => _UploadAudioSheetState();
}

class _UploadAudioSheetState extends State<_UploadAudioSheet> {
  final _titleCtrl = TextEditingController();
  final _artistCtrl = TextEditingController();
  final _bunny = BunnyStorageService();
  final _authService = AuthService();
  String _category = 'Worship';
  bool _uploading = false;
  double _progress = 0;

  final List<String> _categories = [
    'Worship', 'Gospel', 'Hymns', 'Praise', 'Prayer', 'Sermon'
  ];

  Future<void> _upload() async {
    if (_titleCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please add a title')));
      return;
    }
    setState(() => _uploading = true);
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final user = await _authService.getUserById(uid);
      final ext = widget.file.path.split('.').last;
      final filename = _bunny.generateFilename('audio_$uid', ext);
      final url = await _bunny.uploadFile(
        file: widget.file,
        folder: AppConstants.folderAudio,
        filename: filename,
        onProgress: (p) => setState(() => _progress = p),
      );
      if (url == null) throw Exception('Upload failed');

      await FirebaseFirestore.instance.collection(AppConstants.colAudio).add({
        'uploaderId': uid,
        'uploaderName': user?.name ?? 'Saint',
        'uploaderProfilePic': user?.profilePicUrl,
        'title': _titleCtrl.text.trim(),
        'artist': _artistCtrl.text.trim().isEmpty ? null : _artistCtrl.text.trim(),
        'audioUrl': url,
        'category': _category,
        'durationSeconds': 0,
        'playCount': 0,
        'downloadCount': 0,
        'uploadedAt': Timestamp.now(),
      });

      widget.onUploaded();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.error));
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
          Text('Upload Audio',
              style: GoogleFonts.playfairDisplay(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary)),
          const SizedBox(height: 16),
          EcclesiaTextField(
            hint: 'Song title',
            label: 'Title *',
            controller: _titleCtrl,
          ),
          const SizedBox(height: 12),
          EcclesiaTextField(
            hint: 'Artist name',
            label: 'Artist',
            controller: _artistCtrl,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _category,
            dropdownColor: AppTheme.bgCard,
            style: GoogleFonts.dmSans(color: AppTheme.textPrimary),
            decoration: const InputDecoration(labelText: 'Category'),
            items: _categories
                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                .toList(),
            onChanged: (v) => setState(() => _category = v!),
          ),
          if (_uploading) ...[
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: _progress,
              backgroundColor: AppTheme.bgElevated,
              valueColor: const AlwaysStoppedAnimation(AppTheme.primary),
            ),
          ],
          const SizedBox(height: 20),
          GradientButton(
              label: 'Upload Audio',
              onTap: _uploading ? null : _upload,
              loading: _uploading),
        ],
      ),
    );
  }
}
