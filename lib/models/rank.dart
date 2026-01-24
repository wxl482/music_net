import 'song.dart';

/// 排行榜模型
class Rank {
  final String rankId;
  final String rankName;
  final String rankCid;
  final String? bannerUrl;
  final String? imgUrl;
  final String? tablePlaque;
  final String? shareBg;
  final String? customLogo;
  final String? intro;
  final int? countDown;
  final int? newCycle;
  final String? updateVideoUrl;
  final int? allTotal;
  final int? newTotal;
  final List<RankSongInfo>? songInfo;

  Rank({
    required this.rankId,
    required this.rankName,
    required this.rankCid,
    this.bannerUrl,
    this.imgUrl,
    this.tablePlaque,
    this.shareBg,
    this.customLogo,
    this.intro,
    this.countDown,
    this.newCycle,
    this.updateVideoUrl,
    this.allTotal,
    this.newTotal,
    this.songInfo,
  });

  factory Rank.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? json;
    final extra = data['extra'];
    final resp = extra?['resp'];

    return Rank(
      rankId: data['rankid']?.toString() ?? '',
      rankName: data['rankname'] ?? '',
      rankCid: data['rank_cid']?.toString() ?? '',
      bannerUrl: data['bannerurl'],
      imgUrl: data['imgurl'] ?? data['img_9'],
      tablePlaque: data['table_plaque'],
      shareBg: data['share_bg'],
      customLogo: data['custom_logo'],
      intro: data['intro'],
      countDown: data['count_down'],
      newCycle: data['new_cycle'],
      updateVideoUrl: data['update_video_url'],
      allTotal: resp?['all_total'],
      newTotal: resp?['new_total'],
      songInfo: data['songinfo'] != null
          ? (data['songinfo'] as List)
              .map((e) => RankSongInfo.fromJson(e))
              .toList()
          : null,
    );
  }

  Rank copyWith({
    String? rankId,
    String? rankName,
    String? rankCid,
    String? bannerUrl,
    String? imgUrl,
    String? tablePlaque,
    String? shareBg,
    String? customLogo,
    String? intro,
    int? countDown,
    int? newCycle,
    String? updateVideoUrl,
    int? allTotal,
    int? newTotal,
    List<RankSongInfo>? songInfo,
  }) {
    return Rank(
      rankId: rankId ?? this.rankId,
      rankName: rankName ?? this.rankName,
      rankCid: rankCid ?? this.rankCid,
      bannerUrl: bannerUrl ?? this.bannerUrl,
      imgUrl: imgUrl ?? this.imgUrl,
      tablePlaque: tablePlaque ?? this.tablePlaque,
      shareBg: shareBg ?? this.shareBg,
      customLogo: customLogo ?? this.customLogo,
      intro: intro ?? this.intro,
      countDown: countDown ?? this.countDown,
      newCycle: newCycle ?? this.newCycle,
      updateVideoUrl: updateVideoUrl ?? this.updateVideoUrl,
      allTotal: allTotal ?? this.allTotal,
      newTotal: newTotal ?? this.newTotal,
      songInfo: songInfo ?? this.songInfo,
    );
  }
}

/// 排行榜推荐歌曲信息（简化版）
class RankSongInfo {
  final String? albumAudioId;
  final String? albumCover;
  final String songName;

  RankSongInfo({
    this.albumAudioId,
    this.albumCover,
    required this.songName,
  });

  factory RankSongInfo.fromJson(Map<String, dynamic> json) {
    return RankSongInfo(
      albumAudioId: json['album_audio_id']?.toString(),
      albumCover: json['album_cover'],
      songName: json['songname'] ?? '',
    );
  }
}

/// 排行榜歌曲（完整版，用于歌曲列表）
class RankSong {
  final String hash;
  final String songName;
  final String authorName;
  final String? coverUrl;
  final String? albumAudioId;
  final int? audioId;
  final int? duration;

  RankSong({
    required this.hash,
    required this.songName,
    required this.authorName,
    this.coverUrl,
    this.albumAudioId,
    this.audioId,
    this.duration,
  });

  factory RankSong.fromJson(Map<String, dynamic> json) {
    // 从 hash_128, hash_320 或 mvdata 中获取 hash
    String? hash;
    if (json['audio_info'] != null) {
      final audioInfo = json['audio_info'];
      hash = audioInfo['hash_128'] ??
             audioInfo['hash_320'] ??
             audioInfo['hash_flac'];
    }
    // 从 mvdata 获取 hash
    if (hash == null && json['mvdata'] != null && json['mvdata'] is List && json['mvdata'].isNotEmpty) {
      hash = json['mvdata'][0]['hash'];
    }
    // 从 trans_param 获取 ogg_128_hash
    if (hash == null && json['trans_param'] != null) {
      hash = json['trans_param']['ogg_128_hash'];
    }

    // 获取封面
    String? coverUrl = json['trans_param']?['union_cover'] ?? json['album_cover'];

    // 获取时长
    int? duration;
    if (json['audio_info'] != null) {
      final audioInfo = json['audio_info'];
      // duration_128 是毫秒，需要转换为秒
      final durationMs = audioInfo['duration_128'] ?? audioInfo['duration_320'] ?? audioInfo['duration_flac'];
      if (durationMs != null) {
        duration = (durationMs / 1000).round();
      }
    }

    return RankSong(
      hash: hash ?? json['hash'] ?? '',
      songName: json['songname'] ?? '',
      authorName: json['author_name'] ?? '',
      coverUrl: coverUrl,
      albumAudioId: json['album_audio_id']?.toString(),
      audioId: json['audio_id'],
      duration: duration,
    );
  }

  /// 转换为 Song 模型
  Song toSong() {
    return Song(
      id: hash,
      title: songName,
      artist: authorName,
      album: '',
      coverUrl: coverUrl,
      duration: duration != null ? Duration(seconds: duration!) : Duration.zero,
      isLocal: false,
    );
  }
}

/// 排行榜歌曲列表响应
class RankSongsResponse {
  final int total;
  final List<RankSong> songs;

  RankSongsResponse({
    required this.total,
    required this.songs,
  });

  factory RankSongsResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    final songlist = data['songlist'] as List? ?? [];

    return RankSongsResponse(
      total: json['total'] ?? data['total'] ?? 0,
      songs: songlist.map((e) => RankSong.fromJson(e)).toList(),
    );
  }
}
