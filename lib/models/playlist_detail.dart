/// 歌单详情数据实体
class PlaylistDetailData {
  /// 封面图片 URL
  final String? pic;
  /// 歌单名称
  final String name;
  /// 简介/描述
  final String? intro;
  /// 播放次数
  final int? playCount;
  /// 歌曲数量
  final int? songCount;
  /// 创建者昵称
  final String? nickname;
  /// 标签
  final List<String>? tags;
  /// 歌曲数据
  final PlaylistSongsData? songs;

  PlaylistDetailData({
    this.pic,
    required this.name,
    this.intro,
    this.playCount,
    this.songCount,
    this.nickname,
    this.tags,
    this.songs,
  });

  /// 从 JSON 创建
  factory PlaylistDetailData.fromJson(Map<String, dynamic> json) {
    // 解析标签 (可能是 String 或 List)
    List<String>? tags;
    if (json['tags'] is String) {
      tags = (json['tags'] as String).split(',');
    } else if (json['tags'] is List) {
      tags = (json['tags'] as List).map((e) => e.toString()).toList();
    }

    // 解析封面 URL (取多个可能的字段)
    String? pic = json['pic'] ?? json['imgurl'] ?? json['flexible_cover'];
    if (pic != null && pic.contains('{size}')) {
      pic = pic.replaceAll('{size}', '300');
    }

    return PlaylistDetailData(
      pic: pic,
      name: json['name'] ?? '未知歌单',
      intro: json['intro'] ?? json['description'],
      playCount: json['play_count'] ?? json['playcount'] ?? 0,
      songCount: json['songcount'] ?? json['count'] ?? 0,
      nickname: json['nickname'] ?? json['creator_name'],
      tags: tags,
      songs: json['songs'] != null
          ? PlaylistSongsData.fromJson(json['songs'])
          : null,
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'pic': pic,
      'name': name,
      'intro': intro,
      'play_count': playCount,
      'songcount': songCount,
      'nickname': nickname,
      'tags': tags?.join(','),
      'songs': songs?.toJson(),
    };
  }

  /// 复制并修改部分字段
  PlaylistDetailData copyWith({
    String? pic,
    String? name,
    String? intro,
    int? playCount,
    int? songCount,
    String? nickname,
    List<String>? tags,
    PlaylistSongsData? songs,
  }) {
    return PlaylistDetailData(
      pic: pic ?? this.pic,
      name: name ?? this.name,
      intro: intro ?? this.intro,
      playCount: playCount ?? this.playCount,
      songCount: songCount ?? this.songCount,
      nickname: nickname ?? this.nickname,
      tags: tags ?? this.tags,
      songs: songs ?? this.songs,
    );
  }
}

/// 歌单歌曲数据实体
class PlaylistSongsData {
  /// 起始索引
  final int? beginIdx;
  /// 每页大小
  final int? pageSize;
  /// 总数
  final int? count;
  /// 用户 ID
  final String? userid;
  /// 歌曲列表
  final List<PlaylistSongItem> songs;

  PlaylistSongsData({
    this.beginIdx,
    this.pageSize,
    this.count,
    this.userid,
    required this.songs,
  });

  /// 从 JSON 创建
  factory PlaylistSongsData.fromJson(Map<String, dynamic> json) {
    // 获取歌曲列表数据
    final List<dynamic> songsList = [];

    if (json['songs'] != null && json['songs'] is List) {
      songsList.addAll(json['songs'] as List);
    } else if (json['list'] != null) {
      final listData = json['list'];
      if (listData is Map && listData['info'] != null) {
        songsList.addAll(listData['info'] as List? ?? []);
      } else if (listData is List) {
        songsList.addAll(listData);
      }
    } else if (json['info'] != null && json['info'] is List) {
      songsList.addAll(json['info'] as List);
    }

    return PlaylistSongsData(
      beginIdx: json['begin_idx'],
      pageSize: json['pagesize'],
      count: json['count'],
      userid: json['userid']?.toString(),
      songs: songsList
          .map((e) => PlaylistSongItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'begin_idx': beginIdx,
      'pagesize': pageSize,
      'count': count,
      'userid': userid,
      'songs': songs.map((e) => e.toJson()).toList(),
    };
  }
}

/// 歌单中的歌曲项
class PlaylistSongItem {
  /// 歌曲哈希值
  final String hash;
  /// 歌曲名称
  final String name;
  /// 歌曲时长（毫秒）
  final int duration;
  /// 专辑 ID
  final String? albumId;
  /// 专辑名称
  final String? albumName;
  /// 封面图片 URL
  final String? imgurl;
  /// 歌手列表
  final List<SingerInfo> singers;

  PlaylistSongItem({
    required this.hash,
    required this.name,
    required this.duration,
    this.albumId,
    this.albumName,
    this.imgurl,
    required this.singers,
  });

  /// 从 JSON 创建
  factory PlaylistSongItem.fromJson(Map<String, dynamic> json) {
    // 解析歌手列表 - 从 singerinfo 字段获取（酷狗 API 返回的字段）
    List<SingerInfo> singers = [];
    if (json['singerinfo'] != null && json['singerinfo'] is List) {
      singers = (json['singerinfo'] as List)
          .map((e) => SingerInfo.fromJson(e as Map<String, dynamic>))
          .toList();
    } else if (json['singers'] != null && json['singers'] is List) {
      singers = (json['singers'] as List)
          .map((e) => SingerInfo.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    // 解析专辑信息 - 从 albuminfo 字段获取（酷狗 API 返回的字段）
    String? albumName;
    if (json['albuminfo'] is Map && json['albuminfo']['name'] != null) {
      albumName = json['albuminfo']['name'];
    } else if (json['album'] is String) {
      albumName = json['album'];
    } else if (json['album'] is Map) {
      albumName = json['album']['name'];
    }
    if (albumName == null || albumName.isEmpty) {
      albumName = json['album_name'];
    }

    // 处理封面 URL - 从多个可能的字段获取
    String? imgurl = json['imgurl'] ??
                      json['album_img'] ??
                      json['pic'] ??
                      json['cover'] ??
                      (json['album'] is Map ? (json['album']['imgurl'] ?? json['album']['pic']) : null);

    // 从 trans_param.union_cover 获取封面（酷狗 API 返回的字段）
    if (json['trans_param'] is Map && json['trans_param']['union_cover'] != null) {
      imgurl = json['trans_param']['union_cover'].toString();
    }

    // 不在这里替换 {size}，保留原始 URL，在使用时根据显示尺寸动态替换
    // 这样可以根据实际显示大小请求合适尺寸的图片

    return PlaylistSongItem(
      hash: json['hash'] ?? '',
      name: json['name'] ?? json['audio_name'] ?? '未知歌曲',
      duration: json['timelen'] ?? json['duration'] ?? json['timelength'] ?? 0,
      albumId: json['album_id']?.toString(),
      albumName: albumName,
      imgurl: imgurl,
      singers: singers,
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'hash': hash,
      'name': name,
      'timelen': duration,
      'album_id': albumId,
      'album_name': albumName,
      'imgurl': imgurl,
      'singers': singers.map((e) => e.toJson()).toList(),
    };
  }

  /// 获取歌手名称字符串
  String get artistNames {
    if (singers.isEmpty) {
      return '未知歌手';
    }
    return singers.map((s) => s.name).join(' / ');
  }
}

/// 歌手信息
class SingerInfo {
  final String? name;
  final String? id;

  SingerInfo({
    this.name,
    this.id,
  });

  factory SingerInfo.fromJson(Map<String, dynamic> json) {
    return SingerInfo(
      name: json['name']?.toString(),
      id: json['id']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'id': id,
    };
  }
}
