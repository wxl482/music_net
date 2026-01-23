import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
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
                  '暂无播放',
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
        backgroundColor: AppColors.background,
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
                flex: 4,
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
                flex: 2,
                child: Column(
                  children: [
                    // 歌曲标题和歌手
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 32.w),
                      child: Column(
                        children: [
                          Text(
                            currentSong.title,
                            style: AppTextStyles.headlineMedium,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            currentSong.artist,
                            style: AppTextStyles.bodyLarge.copyWith(
                              color: AppColors.onSurfaceSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
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
              // 控制按钮
              ControlButtonsWidget(controller: controller),
              SizedBox(height: 32.h),
            ],
          ),
        ),
      );
    });
  }
}
