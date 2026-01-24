class Album {
  final String id;
  final String name;
  final String? coverUrl;
  final String artist;
  final String artistId;
  final String publishDate;
  final int songCount;
  final String? intro;

  Album({
    required this.id,
    required this.name,
    this.coverUrl,
    this.artist = '未知艺术家',
    this.artistId = '',
    this.publishDate = '',
    this.songCount = 0,
    this.intro,
  });

  String get publishYear {
    if (publishDate.isEmpty) return '';
    try {
      final year = publishDate.substring(0, 4);
      return year;
    } catch (e) {
      return '';
    }
  }

  factory Album.fromJson(Map<String, dynamic> json) {
    return Album(
      id: json['albumid']?.toString() ?? json['id']?.toString() ?? '',
      name: json['albumname'] ?? json['name'] ?? '未知专辑',
      coverUrl: json['imgurl'] ?? json['picUrl'] ?? json['coverUrl'],
      artist: json['singername'] ?? json['artist'] ?? '未知艺术家',
      artistId: json['singerid']?.toString() ?? json['artistId']?.toString() ?? '',
      publishDate: json['publishtime'] ?? json['publishDate'] ?? '',
      songCount: json['songcount'] ?? json['size'] ?? 0,
      intro: json['intro'] ?? json['introduction'],
    );
  }

  Album copyWith({
    String? id,
    String? name,
    String? coverUrl,
    String? artist,
    String? artistId,
    String? publishDate,
    int? songCount,
    String? intro,
  }) {
    return Album(
      id: id ?? this.id,
      name: name ?? this.name,
      coverUrl: coverUrl ?? this.coverUrl,
      artist: artist ?? this.artist,
      artistId: artistId ?? this.artistId,
      publishDate: publishDate ?? this.publishDate,
      songCount: songCount ?? this.songCount,
      intro: intro ?? this.intro,
    );
  }
}
