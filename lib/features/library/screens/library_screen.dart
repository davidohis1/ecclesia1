import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/constants/app_constants.dart';
import '../../../models/other_models.dart';
import '../../../services/bunny_storage_service.dart';
import '../../../services/auth_service.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _searchCtrl = TextEditingController();

  List<LibraryDoc> _docs = [];
  List<LibraryDoc> _filtered = [];
  bool _loading = true;
  String _selectedCategory = 'All';

  final List<String> _categories = [
    'All', 'Bible Study', 'Devotional', 'Theology', 'Prayer', 'Testimony', 'General'
  ];

  @override
  void initState() {
    super.initState();
    _loadDocs();
    _searchCtrl.addListener(_filter);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadDocs() async {
    final snap = await _firestore
        .collection(AppConstants.colLibrary)
        .orderBy('uploadedAt', descending: true)
        .get();
    setState(() {
      _docs = snap.docs.map((d) => LibraryDoc.fromMap(d.id, d.data())).toList();
      _filtered = List.from(_docs);
      _loading = false;
    });
  }

  void _filter() {
    final query = _searchCtrl.text.toLowerCase();
    setState(() {
      _filtered = _docs.where((d) {
        final matchesQuery = query.isEmpty ||
            d.title.toLowerCase().contains(query) ||
            (d.description?.toLowerCase().contains(query) ?? false) ||
            d.uploaderName.toLowerCase().contains(query);
        final matchesCategory =
            _selectedCategory == 'All' || d.category == _selectedCategory;
        return matchesQuery && matchesCategory;
      }).toList();
    });
  }

  void _selectCategory(String cat) {
    setState(() => _selectedCategory = cat);
    _filter();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: AppTheme.bgDark,
            title: Text('Library',
                style: GoogleFonts.playfairDisplay(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary)),
            actions: [
              IconButton(
                icon: const Icon(Icons.upload_file_outlined,
                    color: AppTheme.textPrimary),
                onPressed: _uploadDoc,
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(120),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                    child: TextField(
                      controller: _searchCtrl,
                      style: GoogleFonts.dmSans(
                          color: AppTheme.textPrimary, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Search books, devotionals...',
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
                  // Category filter
                  SizedBox(
                    height: 40,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _categories.length,
                      itemBuilder: (_, i) {
                        final cat = _categories[i];
                        final isSelected = _selectedCategory == cat;
                        return GestureDetector(
                          onTap: () => _selectCategory(cat),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppTheme.primary
                                  : AppTheme.bgElevated,
                              borderRadius: BorderRadius.circular(50),
                            ),
                            child: Text(
                              cat,
                              style: GoogleFonts.dmSans(
                                color: isSelected
                                    ? Colors.white
                                    : AppTheme.textMuted,
                                fontSize: 12,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.normal,
                              ),
                            ),
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
          _loading
              ? SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: List.generate(
                          4,
                          (_) => const Padding(
                                padding: EdgeInsets.only(bottom: 12),
                                child: ShimmerCard(height: 90),
                              )),
                    ),
                  ),
                )
              : _filtered.isEmpty
                  ? SliverToBoxAdapter(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(40),
                          child: Column(
                            children: [
                              const Text('📚',
                                  style: TextStyle(fontSize: 48)),
                              const SizedBox(height: 16),
                              Text('No documents found',
                                  style: GoogleFonts.playfairDisplay(
                                      color: AppTheme.textPrimary,
                                      fontSize: 18)),
                            ],
                          ),
                        ),
                      ),
                    )
                  : SliverPadding(
                      padding: const EdgeInsets.all(16),
                      sliver: SliverGrid(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 0.72,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (_, i) => _DocCard(
                            doc: _filtered[i],
                            onTap: () => _openDoc(_filtered[i]),
                          ),
                          childCount: _filtered.length,
                        ),
                      ),
                    ),
        ],
      ),
    );
  }

  void _openDoc(LibraryDoc doc) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => _PdfViewerScreen(doc: doc)),
    );
  }

  Future<void> _uploadDoc() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result == null || result.files.isEmpty) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.bgCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _UploadDocSheet(
        file: File(result.files.first.path!),
        onUploaded: () {
          Navigator.pop(context);
          _loadDocs();
        },
      ),
    );
  }
}

class _DocCard extends StatelessWidget {
  final LibraryDoc doc;
  final VoidCallback onTap;

  const _DocCard({required this.doc, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(16)),
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primary.withOpacity(0.6),
                      AppTheme.primaryDark,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Center(
                  child: Icon(Icons.picture_as_pdf_rounded,
                      color: Colors.white, size: 40),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    doc.title,
                    style: GoogleFonts.dmSans(
                      color: AppTheme.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    doc.uploaderName,
                    style: GoogleFonts.dmSans(
                        color: AppTheme.textMuted, fontSize: 11),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Text(
                      doc.category,
                      style: GoogleFonts.dmSans(
                          color: AppTheme.primaryLight, fontSize: 10),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PdfViewerScreen extends StatelessWidget {
  final LibraryDoc doc;
  const _PdfViewerScreen({required this.doc});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        backgroundColor: AppTheme.bgCard,
        title: Text(
          doc.title,
          style: GoogleFonts.dmSans(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_outlined, color: AppTheme.primary),
            onPressed: () {},
          ),
        ],
      ),
      body: SfPdfViewer.network(
        doc.pdfUrl,
        onDocumentLoadFailed: (e) {},
      ),
    );
  }
}

class _UploadDocSheet extends StatefulWidget {
  final File file;
  final VoidCallback onUploaded;

  const _UploadDocSheet({required this.file, required this.onUploaded});

  @override
  State<_UploadDocSheet> createState() => _UploadDocSheetState();
}

class _UploadDocSheetState extends State<_UploadDocSheet> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _bunny = BunnyStorageService();
  final _authService = AuthService();
  String _category = 'General';
  bool _uploading = false;
  double _progress = 0;

  final List<String> _categories = [
    'General', 'Bible Study', 'Devotional', 'Theology', 'Prayer', 'Testimony'
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
      if (user == null) return;

      final filename = _bunny.generateFilename('pdf_$uid', 'pdf');
      final url = await _bunny.uploadFile(
        file: widget.file,
        folder: AppConstants.folderLibrary,
        filename: filename,
        onProgress: (p) => setState(() => _progress = p),
      );

      if (url == null) throw Exception('Upload failed');

      await FirebaseFirestore.instance.collection(AppConstants.colLibrary).add({
        'uploaderId': uid,
        'uploaderName': user.name,
        'title': _titleCtrl.text.trim(),
        'description': _descCtrl.text.trim().isEmpty
            ? null
            : _descCtrl.text.trim(),
        'pdfUrl': url,
        'category': _category,
        'pages': 0,
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
          Text('Upload Document',
              style: GoogleFonts.playfairDisplay(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary)),
          const SizedBox(height: 16),
          EcclesiaTextField(
            hint: 'Document title',
            label: 'Title *',
            controller: _titleCtrl,
          ),
          const SizedBox(height: 12),
          EcclesiaTextField(
            hint: 'Brief description',
            label: 'Description',
            controller: _descCtrl,
            maxLines: 2,
          ),
          const SizedBox(height: 12),
          Text('Category',
              style: GoogleFonts.dmSans(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _category,
            dropdownColor: AppTheme.bgCard,
            style: GoogleFonts.dmSans(color: AppTheme.textPrimary),
            decoration: const InputDecoration(),
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
            label: 'Upload Document',
            onTap: _uploading ? null : _upload,
            loading: _uploading,
          ),
        ],
      ),
    );
  }
}
