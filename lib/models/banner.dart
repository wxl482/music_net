/// 轮播图项模型（基于推荐歌单）
class BannerItem {
  final String id;
  final String title;
  final String imageUrl;
  final String url;
  final String description;
  final int playCount;

  const BannerItem({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.url,
    this.description = '',
    this.playCount = 0,
  });

  factory BannerItem.fromJson(Map<String, dynamic> json) {
    // 处理封面图片 URL
    String? coverUrl = json['imgurl'] ?? json['flexible_cover'] ?? json['pic'];
    if (coverUrl != null && coverUrl.contains('{size}')) {
      coverUrl = coverUrl.replaceAll('{size}', '600');
    }

    return BannerItem(
      id: json['specialid']?.toString() ?? json['id']?.toString() ?? '',
      title: json['specialname'] ?? json['show'] ?? json['title'] ?? '',
      imageUrl: coverUrl ?? json['code'] ?? '',
      url: json['global_collection_id']?.toString() ?? json['url'] ?? '',
      description: json['intro'] ?? '',
      playCount: json['play_count'] ?? 0,
    );
  }
}
