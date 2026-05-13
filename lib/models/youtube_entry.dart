class YouTubeEntry {
  const YouTubeEntry({
    required this.id,
    required this.title,
    required this.addedAt,
  });

  final String id;
  final String title;
  final DateTime addedAt;

  factory YouTubeEntry.fromJson(Map<String, dynamic> json) {
    return YouTubeEntry(
      id: json['id'] as String,
      title: (json['title'] as String?) ?? '',
      addedAt: DateTime.tryParse((json['addedAt'] as String?) ?? '') ??
          DateTime.now().toUtc(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'addedAt': addedAt.toUtc().toIso8601String(),
      };

  /// Parse common YouTube URL formats; returns null if no ID can be extracted.
  static String? extractId(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return null;
    final idPattern = RegExp(r'^[A-Za-z0-9_-]{11}$');
    if (idPattern.hasMatch(trimmed)) return trimmed;

    Uri? uri;
    try {
      uri = Uri.parse(trimmed);
    } catch (_) {
      return null;
    }
    if (uri.host.contains('youtu.be')) {
      final segs = uri.pathSegments.where((s) => s.isNotEmpty).toList();
      if (segs.isNotEmpty && idPattern.hasMatch(segs.first)) return segs.first;
    }
    if (uri.host.contains('youtube.com')) {
      final v = uri.queryParameters['v'];
      if (v != null && idPattern.hasMatch(v)) return v;
      final segs = uri.pathSegments.where((s) => s.isNotEmpty).toList();
      for (var i = 0; i < segs.length; i++) {
        if ((segs[i] == 'embed' || segs[i] == 'shorts' || segs[i] == 'live') &&
            i + 1 < segs.length &&
            idPattern.hasMatch(segs[i + 1])) {
          return segs[i + 1];
        }
      }
    }
    return null;
  }
}
