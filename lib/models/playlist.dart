import 'song.dart';
import 'package:flutter/material.dart';

/// 排行榜项
class RankItem {
  final String id;
  final String name;
  final String? coverUrl;
  final int songCount;
  final String? updateFrequency; // 更新频率描述（中文）
  final String? publishDate; // 发布日期
  final Color? backgroundColor; // 背景颜色

  RankItem({
    required this.id,
    required this.name,
    this.coverUrl,
    this.songCount = 0,
    this.updateFrequency,
    this.publishDate,
    this.backgroundColor,
  });

  /// 获取更新时间描述
  String get updateText {
    if (publishDate != null) {
      // 解析日期 "2026-01-24 08:30:01" -> "01-24 更新"
      final parts = publishDate!.split(' ');
      if (parts.isNotEmpty) {
        final dateParts = parts[0].split('-');
        if (dateParts.length >= 3) {
          final month = dateParts[1];
          final day = dateParts[2];
          return '${month}月${day}日 更新';
        }
      }
    }
    return updateFrequency ?? '定期更新';
  }
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
  final String globalCollectionId; // 用于获取歌单详情
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
    this.globalCollectionId = '',
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
      'globalCollectionId': globalCollectionId,
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
      globalCollectionId: json['globalCollectionId'] ?? '',
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
    String? globalCollectionId,
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
      globalCollectionId: globalCollectionId ?? this.globalCollectionId,
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
