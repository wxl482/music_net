/// 歌词行数据模型
class LyricLine {
  /// 时间点
  final Duration time;
  /// 歌词文本
  final String text;

  const LyricLine({
    required this.time,
    required this.text,
  });

  @override
  String toString() => '[${time.inMinutes.toString().padLeft(2, '0')}:${(time.inSeconds % 60).toString().padLeft(2, '0')}.${time.inMilliseconds % 1000}] $text';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LyricLine &&
          other.time == time &&
          other.text == text;

  @override
  int get hashCode => time.hashCode ^ text.hashCode;
}

/// 歌词数据模型
class Lyrics {
  /// 歌词行列表（按时间排序）
  final List<LyricLine> lines;

  const Lyrics({required this.lines});

  /// 空歌词
  static const empty = Lyrics(lines: []);

  /// 是否为空
  bool get isEmpty => lines.isEmpty;

  /// 获取总时长
  Duration get duration => lines.isEmpty ? Duration.zero : lines.last.time;

  /// 根据时间获取当前应该高亮的歌词索引
  int getIndexAt(Duration position) {
    if (isEmpty) return 0;

    for (int i = 0; i < lines.length; i++) {
      if (lines[i].time > position) {
        return i > 0 ? i - 1 : 0;
      }
    }
    return lines.length - 1;
  }

  /// 获取指定索引的歌词
  LyricLine? getLineAt(int index) {
    if (index < 0 || index >= lines.length) return null;
    return lines[index];
  }
}
