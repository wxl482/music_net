class Song {
  final String id;
  final String title;
  final String artist;
  final String album;
  final String? coverUrl;
  final String? audioUrl;
  final Duration duration;
  final bool isLocal;

  Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    this.coverUrl,
    this.audioUrl,
    this.duration = Duration.zero,
    this.isLocal = false,
  });

  factory Song.fromLocal({
    required String id,
    required String title,
    required String artist,
    required String album,
    String? coverPath,
    required String audioPath,
    required Duration duration,
  }) {
    return Song(
      id: id,
      title: title,
      artist: artist,
      album: album,
      coverUrl: coverPath,
      audioUrl: audioPath,
      duration: duration,
      isLocal: true,
    );
  }

  factory Song.fromOnline({
    required String id,
    required String title,
    required String artist,
    required String album,
    String? coverUrl,
    String? audioUrl,
    required Duration duration,
  }) {
    return Song(
      id: id,
      title: title,
      artist: artist,
      album: album,
      coverUrl: coverUrl,
      audioUrl: audioUrl,
      duration: duration,
      isLocal: false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'album': album,
      'coverUrl': coverUrl,
      'audioUrl': audioUrl,
      'duration': duration.inMilliseconds,
      'isLocal': isLocal,
    };
  }

  factory Song.fromJson(Map<String, dynamic> json) {
    return Song(
      id: json['id'],
      title: json['title'],
      artist: json['artist'],
      album: json['album'],
      coverUrl: json['coverUrl'],
      audioUrl: json['audioUrl'],
      duration: Duration(milliseconds: json['duration'] ?? 0),
      isLocal: json['isLocal'] ?? false,
    );
  }

  Song copyWith({
    String? id,
    String? title,
    String? artist,
    String? album,
    String? coverUrl,
    String? audioUrl,
    Duration? duration,
    bool? isLocal,
  }) {
    return Song(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      coverUrl: coverUrl ?? this.coverUrl,
      audioUrl: audioUrl ?? this.audioUrl,
      duration: duration ?? this.duration,
      isLocal: isLocal ?? this.isLocal,
    );
  }
}
