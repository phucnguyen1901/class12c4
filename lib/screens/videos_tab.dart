import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

import '../cloudinary.dart';
import '../models/video_item.dart';
import '../models/youtube_entry.dart';
import '../theme.dart';
import 'video_player_card.dart';
import 'youtube_player_card.dart';

class VideosTab extends StatefulWidget {
  const VideosTab({super.key});

  @override
  State<VideosTab> createState() => _VideosTabState();
}

class _VideosTabState extends State<VideosTab> {
  final _api = CloudinaryApi();
  late Future<List<VideoItem>> _future;

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

  Future<List<VideoItem>> _load() async {
    final videosFuture = _api.listVideos().catchError(
          (_) => <CloudinaryVideo>[],
        );
    final youtubeFuture = _api.listYoutube().catchError(
          (_) => <YouTubeEntry>[],
        );
    final videos = await videosFuture;
    final youtubeEntries = await youtubeFuture;
    final youtube = youtubeEntries
        .map((e) => YouTubeVideo(
              id: e.id,
              title: e.title,
              addedAt: e.addedAt,
            ))
        .toList();
    final merged = <VideoItem>[...videos, ...youtube];
    merged.sort((a, b) => b.sortKey.compareTo(a.sortKey));
    return merged;
  }

  Future<void> _refresh() async {
    setState(() => _future = _load());
    await _future;
  }

  int _crossAxisCount(double width) {
    if (width >= 1280) return 4;
    if (width >= 960) return 3;
    if (width >= 640) return 2;
    return 1;
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refresh,
      color: AppTheme.teal,
      child: FutureBuilder<List<VideoItem>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white70),
            );
          }
          if (snapshot.hasError) {
            return _ErrorState(
              message: snapshot.error.toString(),
              onRetry: _refresh,
            );
          }
          final items = snapshot.data ?? const [];
          if (items.isEmpty) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 80),
                _EmptyState(),
              ],
            );
          }
          return LayoutBuilder(
            builder: (context, constraints) {
              final cross = _crossAxisCount(constraints.maxWidth);
              return MasonryGridView.count(
                physics: const AlwaysScrollableScrollPhysics(),
                crossAxisCount: cross,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final v = items[index];
                  if (v is CloudinaryVideo) {
                    return CloudinaryVideoTile(video: v);
                  }
                  if (v is YouTubeVideo) {
                    return YouTubeVideoTile(video: v);
                  }
                  return const SizedBox.shrink();
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppTheme.headerGradient,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.violet.withValues(alpha: 0.4),
                    blurRadius: 28,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(
                Icons.movie_creation_rounded,
                size: 56,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Chưa có video',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Admin có thể upload video hoặc nhúng YouTube\nbằng mật khẩu admin.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.75),
                    height: 1.5,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 80),
        Icon(Icons.cloud_off_rounded,
            size: 56, color: Colors.white.withValues(alpha: 0.6)),
        const SizedBox(height: 12),
        Text(
          'Không tải được video.\n$message',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white70, height: 1.4),
        ),
        const SizedBox(height: 16),
        Center(
          child: FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Thử lại'),
          ),
        ),
      ],
    );
  }
}
