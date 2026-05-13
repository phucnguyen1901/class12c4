import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'models/gallery_item.dart';
import 'models/video_item.dart';
import 'models/youtube_entry.dart';

/// Configuration for the Cloudinary cloud `phucnguyen`.
abstract final class CloudinaryConfig {
  static const String cloudName = 'phucnguyen';
  static const String tag = 'class12c4';
  static const String imagesFolder = 'Images';
  static const String videosFolder = 'Videos';
  static const String unsignedPreset = 'class12c4_unsigned';
  static const String youtubePublicId = 'meta/youtube';

  static const String resBase = 'https://res.cloudinary.com/$cloudName';
  static const String apiBase = 'https://api.cloudinary.com/v1_1/$cloudName';
}

/// URL builders for public Cloudinary delivery (no auth required).
abstract final class CloudinaryUrls {
  static String _encodePublicId(String publicId) =>
      publicId.split('/').map(Uri.encodeComponent).join('/');

  /// Square thumbnail for image grids.
  static String thumb(String publicId) {
    final id = _encodePublicId(publicId);
    return '${CloudinaryConfig.resBase}/image/upload/c_fill,w_500,h_500,g_auto,q_auto,f_auto/$id';
  }

  /// Full-resolution image for viewer.
  static String full(String publicId) {
    final id = _encodePublicId(publicId);
    return '${CloudinaryConfig.resBase}/image/upload/q_auto,f_auto/$id';
  }

  /// Auto-generated still frame thumbnail for a Cloudinary video.
  static String videoThumb(String publicId) {
    final id = _encodePublicId(publicId);
    return '${CloudinaryConfig.resBase}/video/upload/so_auto,c_fill,w_640,h_360,g_auto,q_auto,f_jpg/$id.jpg';
  }

  /// Streamable mp4 URL for a Cloudinary video.
  static String videoStream(String publicId) {
    final id = _encodePublicId(publicId);
    return '${CloudinaryConfig.resBase}/video/upload/q_auto,f_mp4/$id.mp4';
  }
}

/// Runtime client for Cloudinary list-by-tag + unsigned upload endpoints.
class CloudinaryApi {
  CloudinaryApi({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  String _cacheBust() => DateTime.now().millisecondsSinceEpoch.toString();

  Uri _listUri(String resourceType) => Uri.parse(
        '${CloudinaryConfig.resBase}/$resourceType/list/${CloudinaryConfig.tag}.json?_=${_cacheBust()}',
      );

  /// List images tagged `class12c4`, filtered to folder `Images`.
  Future<List<GalleryItem>> listImages() async {
    final resp = await _client.get(_listUri('image'));
    if (resp.statusCode != 200) {
      throw CloudinaryException(
        'List images failed: HTTP ${resp.statusCode}',
      );
    }
    final body = jsonDecode(resp.body) as Map<String, dynamic>;
    final resources = (body['resources'] as List? ?? []).cast<Map<String, dynamic>>();
    final items = <GalleryItem>[];
    for (final r in resources) {
      final pid = r['public_id'] as String?;
      if (pid == null) continue;
      final folder = (r['folder'] as String?) ?? _folderOf(pid);
      if (folder != CloudinaryConfig.imagesFolder) continue;
      items.add(
        GalleryItem(
          publicId: pid,
          w: (r['width'] as num?)?.toInt(),
          h: (r['height'] as num?)?.toInt(),
        ),
      );
    }
    items.sort((a, b) => a.publicId.compareTo(b.publicId));
    return items;
  }

  /// List Cloudinary videos tagged `class12c4`, folder `Videos`.
  Future<List<CloudinaryVideo>> listVideos() async {
    final resp = await _client.get(_listUri('video'));
    if (resp.statusCode == 404) return const [];
    if (resp.statusCode != 200) {
      throw CloudinaryException(
        'List videos failed: HTTP ${resp.statusCode}',
      );
    }
    final body = jsonDecode(resp.body) as Map<String, dynamic>;
    final resources = (body['resources'] as List? ?? []).cast<Map<String, dynamic>>();
    final videos = <CloudinaryVideo>[];
    for (final r in resources) {
      final pid = r['public_id'] as String?;
      if (pid == null) continue;
      final folder = (r['folder'] as String?) ?? _folderOf(pid);
      if (folder != CloudinaryConfig.videosFolder) continue;
      videos.add(CloudinaryVideo.fromListJson(r));
    }
    videos.sort((a, b) => b.sortKey.compareTo(a.sortKey));
    return videos;
  }

  /// Fetch the YouTube embed manifest. Returns `[]` if file does not exist yet.
  Future<List<YouTubeEntry>> listYoutube() async {
    final uri = Uri.parse(
      '${CloudinaryConfig.resBase}/raw/upload/${CloudinaryConfig.youtubePublicId}.json?_=${_cacheBust()}',
    );
    final resp = await _client.get(uri);
    if (resp.statusCode == 404) return const [];
    if (resp.statusCode != 200) {
      throw CloudinaryException(
        'List youtube failed: HTTP ${resp.statusCode}',
      );
    }
    final raw = resp.body.trim();
    if (raw.isEmpty) return const [];
    final list = jsonDecode(raw);
    if (list is! List) return const [];
    return list
        .whereType<Map<String, dynamic>>()
        .map(YouTubeEntry.fromJson)
        .toList()
      ..sort((a, b) => b.addedAt.compareTo(a.addedAt));
  }

  /// Upload an image via unsigned preset. Throws [CloudinaryException] on failure.
  Future<Map<String, dynamic>> uploadImage(
    Uint8List bytes,
    String filename, {
    void Function(double progress)? onProgress,
  }) =>
      _upload(
        resourceType: 'image',
        bytes: bytes,
        filename: filename,
        folder: CloudinaryConfig.imagesFolder,
        onProgress: onProgress,
      );

  /// Upload a video via unsigned preset.
  Future<Map<String, dynamic>> uploadVideo(
    Uint8List bytes,
    String filename, {
    void Function(double progress)? onProgress,
  }) =>
      _upload(
        resourceType: 'video',
        bytes: bytes,
        filename: filename,
        folder: CloudinaryConfig.videosFolder,
        onProgress: onProgress,
      );

  /// Persist the YouTube manifest by overwriting `meta/youtube.json` (raw).
  Future<void> saveYoutubeList(List<YouTubeEntry> entries) async {
    final body = const JsonEncoder.withIndent('  ')
        .convert(entries.map((e) => e.toJson()).toList());
    await _upload(
      resourceType: 'raw',
      bytes: Uint8List.fromList(utf8.encode(body)),
      filename: 'youtube.json',
      folder: null,
      extraFields: {
        'public_id': CloudinaryConfig.youtubePublicId,
        'overwrite': 'true',
        'invalidate': 'true',
        'tags': '${CloudinaryConfig.tag}_meta',
      },
    );
  }

  Future<Map<String, dynamic>> _upload({
    required String resourceType,
    required Uint8List bytes,
    required String filename,
    required String? folder,
    Map<String, String>? extraFields,
    void Function(double progress)? onProgress,
  }) async {
    final uri = Uri.parse(
      '${CloudinaryConfig.apiBase}/$resourceType/upload',
    );
    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = CloudinaryConfig.unsignedPreset;
    if (folder != null) request.fields['folder'] = folder;
    if (extraFields != null) request.fields.addAll(extraFields);
    request.files.add(
      http.MultipartFile.fromBytes('file', bytes, filename: filename),
    );

    onProgress?.call(0);
    final streamed = await _client.send(request);
    final respBody = await streamed.stream.bytesToString();
    onProgress?.call(1);

    if (streamed.statusCode < 200 || streamed.statusCode >= 300) {
      throw CloudinaryException(
        'Upload $resourceType failed: HTTP ${streamed.statusCode} — $respBody',
      );
    }
    return jsonDecode(respBody) as Map<String, dynamic>;
  }

  String _folderOf(String publicId) {
    final i = publicId.lastIndexOf('/');
    return i < 0 ? '' : publicId.substring(0, i);
  }

  void close() => _client.close();
}

class CloudinaryException implements Exception {
  CloudinaryException(this.message);
  final String message;
  @override
  String toString() => message;
}
