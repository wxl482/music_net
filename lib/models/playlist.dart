import 'song.dart';

/// 排行榜项
class RankItem {
  final String id;
  final String name;
  final String? coverUrl;
  final int songCount;

  RankItem({
    required this.id,
    required this.name,
    this.coverUrl,
    this.songCount = 0,
  });
}

/// 歌单详情
class PlaylistDetail {
  final String id;
  final String name;
  final String? description;
  final String? coverUrl;
  final int playCount;
  final int trackCount;
  final String? creatorName;
  final String? creatorAvatar;
  final List<Song> songs;

  PlaylistDetail({
    required this.id,
    required this.name,
    this.description,
    this.coverUrl,
    this.playCount = 0,
    this.trackCount = 0,
    this.creatorName,
    this.creatorAvatar,
    this.songs = const [],
  });
}

class Playlist {
  final String id;
  final String name;
  final String? description;
  final String? coverUrl;
  final String? creatorName;
  final int playCount;
  final int trackCount;
  final List<String> tags;
  final List<Song> songs;
  final DateTime? createTime;
  final bool isLocal;
  final bool isFavorite;

  Playlist({
    required this.id,
    required this.name,
    this.description,
    this.coverUrl,
    this.creatorName,
    this.playCount = 0,
    this.trackCount = 0,
    this.tags = const [],
    this.songs = const [],
    this.createTime,
    this.isLocal = false,
    this.isFavorite = false,
  });

  Duration get totalDuration {
    return songs.fold(
      Duration.zero,
      (sum, song) => sum + song.duration,
    );
  }

  factory Playlist.local({
    required String id,
    required String name,
    String? description,
    String? coverUrl,
    required List<Song> songs,
  }) {
    return Playlist(
      id: id,
      name: name,
      description: description,
      coverUrl: coverUrl,
      songs: songs,
      trackCount: songs.length,
      isLocal: true,
    );
  }

  factory Playlist.online({
    required String id,
    required String name,
    String? description,
    required String coverUrl,
    String? creatorName,
    int playCount = 0,
    int trackCount = 0,
    List<String> tags = const [],
    List<Song> songs = const [],
    DateTime? createTime,
    bool isFavorite = false,
  }) {
    return Playlist(
      id: id,
      name: name,
      description: description,
      coverUrl: coverUrl,
      creatorName: creatorName,
      playCount: playCount,
      trackCount: trackCount,
      tags: tags,
      songs: songs,
      createTime: createTime,
      isLocal: false,
      isFavorite: isFavorite,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'coverUrl': coverUrl,
      'creatorName': creatorName,
      'playCount': playCount,
      'trackCount': trackCount,
      'tags': tags,
      'songs': songs.map((s) => s.toJson()).toList(),
      'createTime': createTime?.toIso8601String(),
      'isLocal': isLocal,
      'isFavorite': isFavorite,
    };
  }

  factory Playlist.fromJson(Map<String, dynamic> json) {
    return Playlist(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      coverUrl: json['coverUrl'],
      creatorName: json['creatorName'],
      playCount: json['playCount'] ?? 0,
      trackCount: json['trackCount'] ?? 0,
      tags: List<String>.from(json['tags'] ?? []),
      songs: (json['songs'] as List?)
              ?.map((s) => Song.fromJson(s))
              .toList() ??
          [],
      createTime: json['createTime'] != null
          ? DateTime.tryParse(json['createTime'])
          : null,
      isLocal: json['isLocal'] ?? false,
      isFavorite: json['isFavorite'] ?? false,
    );
  }

  Playlist copyWith({
    String? id,
    String? name,
    String? description,
    String? coverUrl,
    String? creatorName,
    int? playCount,
    int? trackCount,
    List<String>? tags,
    List<Song>? songs,
    DateTime? createTime,
    bool? isLocal,
    bool? isFavorite,
  }) {
    return Playlist(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      coverUrl: coverUrl ?? this.coverUrl,
      creatorName: creatorName ?? this.creatorName,
      playCount: playCount ?? this.playCount,
      trackCount: trackCount ?? this.trackCount,
      tags: tags ?? this.tags,
      songs: songs ?? this.songs,
      createTime: createTime ?? this.createTime,
      isLocal: isLocal ?? this.isLocal,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}
