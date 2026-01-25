import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../../models/lyric.dart';
import '../../../../theme/theme.dart';
import '../../../../services/api/kugou_api_service.dart';
import '../../player_controller/player_controller.dart';

/// 歌词显示组件
class LyricWidget extends StatefulWidget {
  final String songHash;

  const LyricWidget({
    super.key,
    required this.songHash,
  });

  @override
  State<LyricWidget> createState() => _LyricWidgetState();
}

class _LyricWidgetState extends State<LyricWidget> {
  final ScrollController _scrollController = ScrollController();
  final KugouApiService _api = KugouApiService();

  Lyrics _lyrics = Lyrics.empty;
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadLyrics();
  }

  @override
  void didUpdateWidget(LyricWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.songHash != widget.songHash) {
      _loadLyrics();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadLyrics() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      if (widget.songHash.isEmpty) {
        setState(() {
          _errorMessage = '歌曲ID为空';
          _isLoading = false;
        });
        return;
      }

      // 从API获取歌词
      final lyricText = await _api.getLyric(widget.songHash);

      if (lyricText.isEmpty) {
        setState(() {
          _lyrics = Lyrics.empty;
          _errorMessage = '暂无歌词';
          _isLoading = false;
        });
        return;
      }

      // 解析歌词
      final lyricLines = _api.parseLyric(lyricText);
      setState(() {
        _lyrics = Lyrics(lines: lyricLines);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _lyrics = Lyrics.empty;
        _errorMessage = '歌词加载失败';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<PlayerController>();

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
                strokeWidth: 2,
              ),
            )
          : _lyrics.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.lyrics_outlined,
                        size: 48.sp,
                        color: AppColors.onSurfaceSecondary,
                      ),
                      SizedBox(height: 16.h),
                      Text(
                        _errorMessage.isEmpty ? '暂无歌词' : _errorMessage,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.onSurfaceSecondary,
                        ),
                      ),
                      if (_errorMessage.isEmpty) ...[
                        SizedBox(height: 8.h),
                        Text(
                          '试试其他歌曲吧',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.onSurfaceSecondary.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ],
                  ),
                )
              : Obx(() {
                  final currentIndex = _lyrics.getIndexAt(controller.position.value);

                  // 自动滚动到当前歌词
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (_scrollController.hasClients) {
                      final double offset = currentIndex * 40.h - 200.h;
                      _scrollController.animateTo(
                        offset.clamp(0.0, _scrollController.position.maxScrollExtent),
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    }
                  });

                  return ListView.builder(
                    controller: _scrollController,
                    physics: const BouncingScrollPhysics(),
                    itemCount: _lyrics.lines.length,
                    itemBuilder: (context, index) {
                      final line = _lyrics.lines[index];
                      final isCurrent = index == currentIndex;

                      return Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.h),
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 200),
                          style: TextStyle(
                            fontSize: isCurrent ? 18.sp : 15.sp,
                            fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
                            color: isCurrent ? AppColors.primary : AppColors.onSurfaceSecondary,
                            height: 1.5,
                          ),
                          child: Text(
                            line.text,
                            textAlign: TextAlign.center,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      );
                    },
                  );
                }),
    );
  }
}
