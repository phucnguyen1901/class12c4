class GalleryItem {
  const GalleryItem({
    required this.publicId,
    this.w,
    this.h,
  });

  final String publicId;
  final int? w;
  final int? h;

  factory GalleryItem.fromJson(Map<String, dynamic> json) {
    return GalleryItem(
      publicId: json['public_id'] as String,
      w: json['w'] as int?,
      h: json['h'] as int?,
    );
  }
}
