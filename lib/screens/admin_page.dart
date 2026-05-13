import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../cloudinary.dart';
import '../models/youtube_entry.dart';
import '../theme.dart';
import '../widgets/gradient_background.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key, required this.onExit});

  /// Called when the admin taps "lock again" — parent should re-show the lock.
  final VoidCallback onExit;

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  final _api = CloudinaryApi();
  final _ytController = TextEditingController();
  final _ytTitleController = TextEditingController();

  bool _uploadingImage = false;
  bool _uploadingVideo = false;
  bool _savingYoutube = false;

  String? _lastMessage;
  bool _lastSuccess = true;

  List<YouTubeEntry> _youtube = [];
  bool _loadingYt = true;

  @override
  void initState() {
    super.initState();
    _refreshYoutube();
  }

  @override
  void dispose() {
    _ytController.dispose();
    _ytTitleController.dispose();
    _api.close();
    super.dispose();
  }

  Future<void> _refreshYoutube() async {
    setState(() => _loadingYt = true);
    try {
      final list = await _api.listYoutube();
      if (!mounted) return;
      setState(() {
        _youtube = list;
        _loadingYt = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _youtube = [];
        _loadingYt = false;
      });
      _showMessage('Không tải được danh sách YouTube: $e', success: false);
    }
  }

  void _showMessage(String message, {bool success = true}) {
    setState(() {
      _lastMessage = message;
      _lastSuccess = success;
    });
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.clearSnackBars();
    messenger?.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success ? AppTheme.teal : Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<(Uint8List bytes, String name)?> _pickFile({
    required FileType type,
    List<String>? allowedExtensions,
  }) async {
    final result = await FilePicker.platform.pickFiles(
      type: type,
      allowedExtensions: allowedExtensions,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return null;
    final f = result.files.first;
    final bytes = f.bytes;
    if (bytes == null) {
      _showMessage('Không đọc được nội dung file.', success: false);
      return null;
    }
    return (bytes, f.name);
  }

  Future<void> _onUploadImage() async {
    final picked = await _pickFile(type: FileType.image);
    if (picked == null) return;
    setState(() => _uploadingImage = true);
    try {
      await _api.uploadImage(picked.$1, picked.$2);
      _showMessage('Upload ảnh "${picked.$2}" thành công.');
    } catch (e) {
      _showMessage('Upload ảnh thất bại: $e', success: false);
    } finally {
      if (mounted) setState(() => _uploadingImage = false);
    }
  }

  Future<void> _onUploadVideo() async {
    final picked = await _pickFile(
      type: FileType.video,
    );
    if (picked == null) return;
    setState(() => _uploadingVideo = true);
    try {
      await _api.uploadVideo(picked.$1, picked.$2);
      _showMessage('Upload video "${picked.$2}" thành công.');
    } catch (e) {
      _showMessage('Upload video thất bại: $e', success: false);
    } finally {
      if (mounted) setState(() => _uploadingVideo = false);
    }
  }

  Future<void> _onAddYoutube() async {
    final url = _ytController.text.trim();
    final id = YouTubeEntry.extractId(url);
    if (id == null) {
      _showMessage('URL YouTube không hợp lệ.', success: false);
      return;
    }
    if (_youtube.any((e) => e.id == id)) {
      _showMessage('Video này đã có trong danh sách.', success: false);
      return;
    }
    final entry = YouTubeEntry(
      id: id,
      title: _ytTitleController.text.trim(),
      addedAt: DateTime.now().toUtc(),
    );
    final next = [entry, ..._youtube];
    setState(() => _savingYoutube = true);
    try {
      await _api.saveYoutubeList(next);
      setState(() {
        _youtube = next;
        _ytController.clear();
        _ytTitleController.clear();
      });
      _showMessage('Đã thêm YouTube embed.');
    } catch (e) {
      _showMessage('Không lưu được manifest YouTube: $e', success: false);
    } finally {
      if (mounted) setState(() => _savingYoutube = false);
    }
  }

  Future<void> _onRemoveYoutube(String id) async {
    final next = _youtube.where((e) => e.id != id).toList();
    setState(() => _savingYoutube = true);
    try {
      await _api.saveYoutubeList(next);
      setState(() => _youtube = next);
      _showMessage('Đã xoá khỏi danh sách.');
    } catch (e) {
      _showMessage('Xoá thất bại: $e', success: false);
    } finally {
      if (mounted) setState(() => _savingYoutube = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.rose.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'ADMIN',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              const Text('Quản lý'),
            ],
          ),
          actions: [
            IconButton(
              tooltip: 'Khoá lại',
              onPressed: widget.onExit,
              icon: const Icon(Icons.lock_outline_rounded),
            ),
            const SizedBox(width: 4),
          ],
        ),
        body: SafeArea(
          top: false,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 900;
              final children = <Widget>[
                _UploadCard(
                  title: 'Upload ảnh',
                  subtitle: 'Lưu vào folder ${CloudinaryConfig.imagesFolder}',
                  icon: Icons.photo_library_rounded,
                  color: AppTheme.teal,
                  busy: _uploadingImage,
                  onPick: _onUploadImage,
                  buttonLabel: 'Chọn ảnh',
                ),
                _UploadCard(
                  title: 'Upload video',
                  subtitle: 'Lưu vào folder ${CloudinaryConfig.videosFolder}',
                  icon: Icons.movie_creation_rounded,
                  color: AppTheme.violet,
                  busy: _uploadingVideo,
                  onPick: _onUploadVideo,
                  buttonLabel: 'Chọn video',
                ),
              ];
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                children: [
                  if (wide)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(child: children[0]),
                        const SizedBox(width: 16),
                        Expanded(child: children[1]),
                      ],
                    )
                  else ...[
                    children[0],
                    const SizedBox(height: 14),
                    children[1],
                  ],
                  const SizedBox(height: 14),
                  _YoutubeCard(
                    urlController: _ytController,
                    titleController: _ytTitleController,
                    onAdd: _onAddYoutube,
                    busy: _savingYoutube,
                    loading: _loadingYt,
                    entries: _youtube,
                    onRemove: _onRemoveYoutube,
                  ),
                  if (_lastMessage != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _lastMessage!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _lastSuccess
                            ? Colors.greenAccent.shade100
                            : Colors.red.shade200,
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _UploadCard extends StatelessWidget {
  const _UploadCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.busy,
    required this.onPick,
    required this.buttonLabel,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool busy;
  final VoidCallback onPick;
  final String buttonLabel;

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: busy ? null : onPick,
                style: FilledButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.upload_rounded),
                label: Text(
                  busy ? 'Đang tải lên...' : buttonLabel,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _YoutubeCard extends StatelessWidget {
  const _YoutubeCard({
    required this.urlController,
    required this.titleController,
    required this.onAdd,
    required this.busy,
    required this.loading,
    required this.entries,
    required this.onRemove,
  });

  final TextEditingController urlController;
  final TextEditingController titleController;
  final Future<void> Function() onAdd;
  final bool busy;
  final bool loading;
  final List<YouTubeEntry> entries;
  final Future<void> Function(String id) onRemove;

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF0033),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.smart_display_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Nhúng YouTube',
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      Text(
                        'Dán URL hoặc video ID',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: urlController,
              decoration: const InputDecoration(
                hintText: 'https://youtu.be/...  hoặc  dQw4w9WgXcQ',
                prefixIcon: Icon(Icons.link_rounded, color: Colors.white54),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                hintText: 'Tiêu đề (tuỳ chọn)',
                prefixIcon: Icon(Icons.title_rounded, color: Colors.white54),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: busy ? null : onAdd,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFFF0033),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.add_link_rounded),
                label: Text(
                  busy ? 'Đang lưu...' : 'Thêm vào danh sách',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const Divider(height: 32, color: Colors.white24),
            Row(
              children: [
                Text(
                  'Đã nhúng',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${entries.length}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (loading)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: CircularProgressIndicator(color: Colors.white60),
                ),
              )
            else if (entries.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Chưa có video YouTube nào được nhúng.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ),
              )
            else
              Column(
                children: [
                  for (final e in entries)
                    _YoutubeListRow(
                      entry: e,
                      onRemove: busy ? null : () => onRemove(e.id),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _YoutubeListRow extends StatelessWidget {
  const _YoutubeListRow({required this.entry, required this.onRemove});

  final YouTubeEntry entry;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              'https://i.ytimg.com/vi/${entry.id}/default.jpg',
              width: 80,
              height: 45,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 80,
                height: 45,
                color: Colors.white10,
                child: const Icon(Icons.broken_image_outlined,
                    color: Colors.white38, size: 18),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.title.isEmpty ? entry.id : entry.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'ID: ${entry.id}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.55),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onRemove,
            tooltip: 'Xoá',
            icon: const Icon(Icons.delete_outline_rounded,
                color: Colors.redAccent),
          ),
        ],
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  const _GlassCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white.withValues(alpha: 0.06),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: child,
    );
  }
}
