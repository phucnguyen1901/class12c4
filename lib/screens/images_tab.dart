import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

import '../cloudinary.dart';
import '../models/gallery_item.dart';
import '../theme.dart';
import 'photo_viewer.dart';

class ImagesTab extends StatefulWidget {
  const ImagesTab({super.key});

  @override
  State<ImagesTab> createState() => _ImagesTabState();
}

class _ImagesTabState extends State<ImagesTab> {
  final _api = CloudinaryApi();
  late Future<List<GalleryItem>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void dispose() {
    _api.close();
    super.dispose();
  }

  /// Tries the live Cloudinary list endpoint; falls back to bundled manifest
  /// on failure so the visitor never sees an empty grid.
  Future<List<GalleryItem>> _load() async {
    try {
      final live = await _api.listImages();
      if (live.isNotEmpty) return live;
      return _loadFallback();
    } catch (e, st) {
      debugPrint('listImages failed, using manifest fallback: $e\n$st');
      return _loadFallback();
    }
  }

  Future<List<GalleryItem>> _loadFallback() async {
    final raw = await rootBundle.loadString('assets/manifest.json');
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => GalleryItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> _refresh() async {
    setState(() => _future = _load());
    await _future;
  }

  int _crossAxisCount(double width) {
    if (width >= 1200) return 5;
    if (width >= 900) return 4;
    if (width >= 600) return 3;
    return 2;
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refresh,
      color: AppTheme.teal,
      child: FutureBuilder<List<GalleryItem>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(24),
              children: [
                const SizedBox(height: 80),
                Text(
                  'Không tải được danh sách ảnh.\n${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.red.shade200,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: FilledButton.icon(
                    onPressed: _refresh,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Thử lại'),
                  ),
                ),
              ],
            );
          }
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white70),
            );
          }
          final items = snapshot.data!;
          if (items.isEmpty) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 120),
                Center(child: Text('Chưa có ảnh.')),
              ],
            );
          }
          return LayoutBuilder(
            builder: (context, constraints) {
              final cross = _crossAxisCount(constraints.maxWidth);
              return MasonryGridView.count(
                physics: const AlwaysScrollableScrollPhysics(),
                crossAxisCount: cross,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  final w = (item.w ?? 1).toDouble();
                  final h = (item.h ?? 1).toDouble();
                  final thumb = CloudinaryUrls.thumb(item.publicId);
                  return GestureDetector(
                    onTap: () {
                      Navigator.of(context).push<void>(
                        MaterialPageRoute<void>(
                          builder: (_) => PhotoViewerScreen(
                            items: items,
                            initialIndex: index,
                          ),
                        ),
                      );
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: AspectRatio(
                        aspectRatio: w / h,
                        child: CachedNetworkImage(
                          imageUrl: thumb,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => _ShimmerBox(
                            aspectRatio: w / h,
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: Colors.white10,
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.broken_image_outlined,
                              color: Colors.white38,
                              size: 40,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _ShimmerBox extends StatefulWidget {
  const _ShimmerBox({required this.aspectRatio});

  final double aspectRatio;

  @override
  State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: widget.aspectRatio,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, child) {
          final t = _c.value;
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment(-1 + 2 * t, 0),
                end: Alignment(2 * t, 0),
                colors: [
                  const Color(0xFF1E293B),
                  const Color(0xFF334155),
                  const Color(0xFF1E293B),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
