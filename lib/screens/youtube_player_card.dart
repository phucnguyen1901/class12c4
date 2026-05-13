import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../models/video_item.dart';
import '../theme.dart';

class YouTubeVideoTile extends StatelessWidget {
  const YouTubeVideoTile({super.key, required this.video});

  final YouTubeVideo video;

  @override
  Widget build(BuildContext context) {
    final thumb = 'https://i.ytimg.com/vi/${video.id}/hqdefault.jpg';
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push<void>(
          MaterialPageRoute<void>(
            builder: (_) => YouTubePlayerScreen(video: video),
          ),
        );
      },
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: CachedNetworkImage(
                imageUrl: thumb,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(color: Colors.white10),
                errorWidget: (context, url, error) => Container(
                  color: Colors.black54,
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.smart_display_outlined,
                    color: Colors.white38,
                    size: 40,
                  ),
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.55),
                  ],
                ),
              ),
            ),
            const Center(child: _YouTubePlayBadge()),
            Positioned(
              left: 8,
              top: 8,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF0033).withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.play_arrow_rounded,
                        color: Colors.white, size: 13),
                    SizedBox(width: 2),
                    Text(
                      'YouTube',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (video.title.isNotEmpty)
              Positioned(
                left: 10,
                right: 10,
                bottom: 8,
                child: Text(
                  video.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    shadows: [
                      Shadow(blurRadius: 3, color: Colors.black87),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _YouTubePlayBadge extends StatelessWidget {
  const _YouTubePlayBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 58,
      height: 40,
      decoration: BoxDecoration(
        color: const Color(0xFFFF0033).withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 28),
    );
  }
}

class YouTubePlayerScreen extends StatefulWidget {
  const YouTubePlayerScreen({super.key, required this.video});

  final YouTubeVideo video;

  @override
  State<YouTubePlayerScreen> createState() => _YouTubePlayerScreenState();
}

class _YouTubePlayerScreenState extends State<YouTubePlayerScreen> {
  late final YoutubePlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController.fromVideoId(
      videoId: widget.video.id,
      autoPlay: true,
      params: const YoutubePlayerParams(
        showControls: true,
        showFullscreenButton: true,
        strictRelatedVideos: true,
      ),
    );
  }

  @override
  void dispose() {
    _controller.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.black.withValues(alpha: 0.35),
        foregroundColor: Colors.white,
        title: Text(
          widget.video.title.isEmpty ? 'YouTube' : widget.video.title,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: Center(
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: YoutubePlayer(
            controller: _controller,
            backgroundColor: AppTheme.deepBg,
          ),
        ),
      ),
    );
  }
}
