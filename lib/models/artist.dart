class Artist {
  final String id;
  final String name;
  final String? coverUrl;
  final int albumCount;
  final int songCount;
  final String? description;
  final int fanCount;
  final int musicCount;
  final List<String> aliases;

  Artist({
    required this.id,
    required this.name,
    this.coverUrl,
    this.albumCount = 0,
    this.songCount = 0,
    this.description,
    this.fanCount = 0,
    this.musicCount = 0,
    this.aliases = const [],
  });

  String get formattedFanCount {
    if (fanCount >= 100000000) {
      return '${(fanCount / 100000000).toStringAsFixed(1)}亿';
    } else if (fanCount >= 10000) {
      return '${(fanCount / 10000).toStringAsFixed(1)}万';
    }
    return fanCount.toString();
  }

  factory Artist.fromJson(Map<String, dynamic> json) {
    return Artist(
      id: json['id'].toString(),
      name: json['name'],
      description: json['description'],
      coverUrl: json['picUrl'],
      fanCount: json['fanCount'] ?? 0,
      musicCount: json['musicCount'] ?? 0,
      aliases: List<String>.from(json['alias'] ?? []),
    );
  }

  Artist copyWith({
    String? id,
    String? name,
    String? description,
    String? coverUrl,
    int? fanCount,
    int? musicCount,
    List<String>? aliases,
    int? albumCount,
    int? songCount,
  }) {
    return Artist(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      coverUrl: coverUrl ?? this.coverUrl,
      fanCount: fanCount ?? this.fanCount,
      musicCount: musicCount ?? this.musicCount,
      aliases: aliases ?? this.aliases,
      albumCount: albumCount ?? this.albumCount,
      songCount: songCount ?? this.songCount,
    );
  }
}

/// 歌手详情
class ArtistDetail {
  final String id;
  final String name;
  final String? coverUrl;
  final String? intro;
  final int albumCount;
  final int songCount;
  final int mvCount;

  ArtistDetail({
    required this.id,
    required this.name,
    this.coverUrl,
    this.intro,
    this.albumCount = 0,
    this.songCount = 0,
    this.mvCount = 0,
  });

  ArtistDetail copyWith({
    String? id,
    String? name,
    String? coverUrl,
    String? intro,
    int? albumCount,
    int? songCount,
    int? mvCount,
  }) {
    return ArtistDetail(
      id: id ?? this.id,
      name: name ?? this.name,
      coverUrl: coverUrl ?? this.coverUrl,
      intro: intro ?? this.intro,
      albumCount: albumCount ?? this.albumCount,
      songCount: songCount ?? this.songCount,
      mvCount: mvCount ?? this.mvCount,
    );
  }
}
