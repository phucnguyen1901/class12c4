/// Unified video tile across Cloudinary uploads and YouTube embeds.
sealed class VideoItem {
  const VideoItem({required this.sortKey});

  /// Used to sort newest-first across sources.
  final DateTime sortKey;
}

class CloudinaryVideo extends VideoItem {
  CloudinaryVideo({
    required this.publicId,
    required this.format,
    this.width,
    this.height,
    this.duration,
    required DateTime createdAt,
  }) : super(sortKey: createdAt);

  final String publicId;
  final String format;
  final int? width;
  final int? height;
  final double? duration;

  factory CloudinaryVideo.fromListJson(Map<String, dynamic> r) {
    return CloudinaryVideo(
      publicId: r['public_id'] as String,
      format: (r['format'] as String?) ?? 'mp4',
      width: (r['width'] as num?)?.toInt(),
      height: (r['height'] as num?)?.toInt(),
      duration: (r['duration'] as num?)?.toDouble(),
      createdAt: DateTime.tryParse(
            (r['created_at'] ?? r['uploaded_at'] ?? '') as String,
          ) ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

class YouTubeVideo extends VideoItem {
  YouTubeVideo({
    required this.id,
    required this.title,
    required DateTime addedAt,
  }) : super(sortKey: addedAt);

  final String id;
  final String title;
}
