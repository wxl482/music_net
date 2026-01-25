import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../player_controller/player_controller.dart' show PlayerController, AudioQuality;
import 'widgets/album_art_widget.dart';
import 'widgets/progress_slider_widget.dart';
import 'widgets/control_buttons_widget.dart';
import 'widgets/lyric_widget.dart';
import '../../../../theme/theme.dart';
import '../../../../models/song.dart';

/// 播放器页面
class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  bool _showLyric = false;
  bool _isChangingTrack = false;
  bool _isNextTrack = true;

  void _toggleView() {
    setState(() {
      _showLyric = !_showLyric;
    });
  }

  /// 切歌动画开始
  void _startTrackChangeAnimation(bool isNext) {
    setState(() {
      _isChangingTrack = true;
      _isNextTrack = isNext;
    });

    // 动画完成后重置状态
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        setState(() {
          _isChangingTrack = false;
        });
      }
    });
  }

  /// 获取音质标签
  String _getQualityLabel(AudioQuality quality) {
    switch (quality) {
      case AudioQuality.standard:
        return 'SQ';
      case AudioQuality.high:
        return 'HQ';
      case AudioQuality.lossless:
        return '无损';
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<PlayerController>();

    return Obx(() {
      final currentSong = controller.currentSong.value;

      if (currentSong == null) {
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.keyboard_arrow_down,
                  color: AppColors.onSurface),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.music_note,
                  size: 80.sp,
                  color: AppColors.onSurfaceSecondary,
                ),
                SizedBox(height: 16.h),
                Text(
                  '暂时无法播放~',
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.onSurfaceSecondary,
                  ),
                ),
              ],
            ),
          ),
        );
      }

      return _buildPlayerContent(currentSong, controller);
    });
  }

  Widget _buildPlayerContent(Song currentSong, PlayerController controller) {
    return Scaffold(
      body: Stack(
        children: [
          // 背景图片
          Positioned.fill(
            child: currentSong.coverUrl != null && currentSong.coverUrl!.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: currentSong.coverUrl!,
                    fit: BoxFit.cover,
                    fadeInDuration: const Duration(milliseconds: 400),
                    fadeOutDuration: const Duration(milliseconds: 200),
                    errorWidget: (context, url, error) => Container(
                      color: AppColors.background,
                    ),
                  )
                : Container(
                    color: AppColors.background,
                  ),
          ),
          // 毛玻璃效果层 - 加重模糊
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.background.withValues(alpha: 0.6),
                ),
              ),
            ),
          ),
          // 内容
          Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              scrolledUnderElevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios,
                    color: AppColors.onSurface),
                onPressed: () => Navigator.pop(context),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.more_vert, color: AppColors.onSurface),
                  onPressed: () {
                    // TODO: 显示更多选项
                  },
                ),
              ],
            ),
            body: SafeArea(
              child: Column(
                children: [
                  // 中间内容区域：封面或歌词（可点击切换）- 撑满剩余空间
                  Expanded(
                    child: GestureDetector(
                      onTap: _toggleView,
                      child: _showLyric
                          ? LyricWidget(songHash: currentSong.id)
                          : Center(
                              child: AlbumArtWidget(
                                song: currentSong,
                                isPlaying: controller.isPlaying.value,
                                rotationAnimation: CurvedAnimation(
                                  parent: controller.rotationController,
                                  curve: Curves.linear,
                                ),
                                isChangingTrack: _isChangingTrack,
                                isNextTrack: _isNextTrack,
                              ),
                            ),
                    ),
                  ),
                  // 歌曲信息和进度条 - 自适应内容高度
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    child: Column(
                      children: [
                        // 歌曲标题、歌手、收藏和评论按钮横向排列
                        GestureDetector(
                          onTap: _toggleView,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      currentSong.title,
                                      style: AppTextStyles.titleLarge,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    SizedBox(height: 4.h),
                                    Text(
                                      currentSong.artist,
                                      style: AppTextStyles.bodyMedium.copyWith(
                                        color: AppColors.onSurfaceSecondary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(width: 8.w),
                              // 收藏按钮
                              IconButton(
                                icon: const Icon(Icons.favorite_border),
                                color: AppColors.onSurface,
                                onPressed: () {},
                              ),
                              // 评论按钮
                              IconButton(
                                icon: const Icon(Icons.comment),
                                color: AppColors.onSurface,
                                onPressed: () {},
                              ),
                              // 音质选择按钮
                              Obx(() => IconButton(
                                icon: Text(
                                  _getQualityLabel(controller.audioQuality.value),
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.onSurface,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                onPressed: controller.switchAudioQuality,
                                tooltip: '切换音质',
                              )),
                            ],
                          ),
                        ),
                        SizedBox(height: 16.h),
                        // 进度条
                        Obx(() => ProgressSliderWidget(
                          position: controller.position.value,
                          duration: controller.duration.value,
                          onChangeStart: (value) {
                            // 拖动开始，可以在这里暂停进度更新
                          },
                          onChangeEnd: (value) {
                            // 拖动结束时才执行 seek
                            controller.seek(
                              Duration(milliseconds: value.toInt()),
                            );
                          },
                        )),
                        SizedBox(height: 24.h),
                      ],
                    ),
                  ),
                  // 控制按钮
                  ControlButtonsWidget(
                    controller: controller,
                    onPreviousPressed: () => _startTrackChangeAnimation(false),
                    onNextPressed: () => _startTrackChangeAnimation(true),
                  ),
                  SizedBox(height: 16.h),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
