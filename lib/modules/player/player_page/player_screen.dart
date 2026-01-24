import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../player_controller/player_controller.dart';
import 'widgets/album_art_widget.dart';
import 'widgets/progress_slider_widget.dart';
import 'widgets/control_buttons_widget.dart';
import '../../../../theme/theme.dart';

/// 播放器页面
class PlayerScreen extends GetView<PlayerController> {
  const PlayerScreen({super.key});

  @override
  Widget build(BuildContext context) {
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

      return Scaffold(
        body: Stack(
          children: [
            // 背景图片
            Positioned.fill(
              child: currentSong.coverUrl != null && currentSong.coverUrl!.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: currentSong.coverUrl!,
                      fit: BoxFit.cover,
                      errorWidget: (context, url, error) => Container(
                        color: AppColors.background,
                      ),
                    )
                  : Container(
                      color: AppColors.background,
                    ),
            ),
            // 毛玻璃效果层
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.background.withValues(alpha: 0.5),
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
                leading: IconButton(
                  icon: const Icon(Icons.keyboard_arrow_down,
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
                    // 专辑封面
                    Expanded(
                      flex: 2,
                      child: Center(
                        child: AlbumArtWidget(
                          song: currentSong,
                          isPlaying: controller.isPlaying.value,
                          rotationAnimation: CurvedAnimation(
                            parent: controller.rotationController,
                            curve: Curves.linear,
                          ),
                        ),
                      ),
                    ),
                    // 歌曲信息和进度条
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20.w),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // 歌曲标题、歌手、收藏和评论按钮横向排列
                            Row(
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
                              ],
                            ),
                            SizedBox(height: 16.h),
                            // 进度条
                            ProgressSliderWidget(
                              position: controller.position.value,
                              duration: controller.duration.value,
                              onChanged: (value) {
                                controller.seek(
                                  Duration(milliseconds: value.toInt()),
                                );
                              },
                            ),
                            SizedBox(height: 24.h),
                          ],
                        ),
                      ),
                    ),
                    // 控制按钮
                    ControlButtonsWidget(controller: controller),
                    SizedBox(height: 16.h),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}
