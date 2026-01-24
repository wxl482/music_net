import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../modules/player/player_controller/player_controller.dart';
import '../theme/theme.dart';
import '../app.dart';
import '../utils/image_utils.dart';
import 'package:marquee/marquee.dart';

class MiniPlayer extends StatefulWidget {
  const MiniPlayer({super.key});

  @override
  State<MiniPlayer> createState() => _MiniPlayerState();
}

class _MiniPlayerState extends State<MiniPlayer> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<PlayerController>();

    return Obx(() {
      return SizedBox(
        height: _isExpanded ? 200.h : 56.h,
        child: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated.withValues(alpha: 0.8),
              ),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  Get.toNamed(AppRoutes.player);
                },
                onVerticalDragUpdate: (details) {
                  if (details.primaryDelta! > 50) {
                    setState(() => _isExpanded = true);
                  } else if (details.primaryDelta! < -50) {
                    setState(() => _isExpanded = false);
                  }
                },
                child: _isExpanded
                    ? _buildExpandedPlayer()
                    : _buildCompactPlayer(controller),
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildCompactPlayer(PlayerController controller) {
    final currentSong = controller.currentSong.value;

    // 如果没有歌曲，显示占位内容
    if (currentSong == null) {
      return Column(
        children: [
          // 进度条（空）
          SizedBox(
            height: 3.h,
            width: double.infinity,
            child: LinearProgressIndicator(
              value: 0,
              backgroundColor: AppColors.surfaceVariant,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          // 内容区域（占位）
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
            child: Row(
              children: [
                // 占位封面
                Container(
                  width: 40.w,
                  height: 40.w,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                  child: const Icon(Icons.music_note, color: AppColors.onSurfaceSecondary, size: 20),
                ),
                SizedBox(width: 10.w),
                // 占位文字
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '暂无播放',
                        style: AppTextStyles.titleMedium.copyWith(
                          color: AppColors.onSurfaceSecondary,
                          decoration: TextDecoration.none,
                        ),
                      ),
                      Text(
                        '点击选择歌曲',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.onSurfaceSecondary,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 12.w),
                // 占位控制按钮
                Icon(
                  Icons.play_circle_filled,
                  size: 28.sp,
                  color: AppColors.onSurfaceSecondary,
                ),
              ],
            ),
          ),
        ],
      );
    }

    final duration = controller.duration.value.inMilliseconds > 0
        ? controller.position.value.inMilliseconds / controller.duration.value.inMilliseconds
        : 0.0;

    return Column(
      children: [
        // 进度条
        SizedBox(
          height: 3.h,
          width: double.infinity,
          child: LinearProgressIndicator(
            value: duration.clamp(0.0, 1.0),
            backgroundColor: AppColors.surfaceVariant,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
        // 内容区域
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
          child: Row(
            children: [
              // 封面
              ClipRRect(
                borderRadius: BorderRadius.circular(6.r),
                child: currentSong.coverUrl != null
                    ? (currentSong.isLocal
                        ? Image.file(
                            File(currentSong.coverUrl!),
                            width: 40.w,
                            height: 40.w,
                            fit: BoxFit.cover,
                          )
                        : CachedNetworkImage(
                            imageUrl: ImageUtils.replaceImageSize(currentSong.coverUrl!, 40.w),
                            width: 40.w,
                            height: 40.w,
                            fit: BoxFit.cover,
                          ))
                    : Container(
                        width: 40.w,
                        height: 40.w,
                        color: AppColors.surfaceVariant,
                        child: const Icon(Icons.music_note, color: Colors.white),
                      ),
              ),
              SizedBox(width: 10.w),
              // 标题和歌手
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      height: 18.h,
                      child: Marquee(
                        text: currentSong.title,
                        style: AppTextStyles.titleMedium.copyWith(decoration: TextDecoration.none),
                        scrollAxis: Axis.horizontal,
                        blankSpace: 100,
                        velocity: 30,
                      ),
                    ),
                    Text(
                      currentSong.artist,
                      style: AppTextStyles.bodySmall.copyWith(decoration: TextDecoration.none),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              SizedBox(width: 12.w),
              // 控制按钮
              Row(
                children: [
                  IconButton(
                    onPressed: controller.togglePlay,
                    icon: Icon(
                      controller.isPlaying.value
                          ? Icons.pause_circle_filled
                          : Icons.play_circle_filled,
                      size: 28.sp,
                      color: AppColors.primary,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(
                      minWidth: 36.w,
                      minHeight: 36.w,
                    ),
                  ),
                  IconButton(
                    onPressed: controller.seekToNext,
                    icon: const Icon(Icons.skip_next, color: AppColors.onSurface),
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(
                      minWidth: 36.w,
                      minHeight: 36.w,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildExpandedPlayer() {
    return Column(
      children: [
        // 拖动指示器
        Container(
          margin: EdgeInsets.only(top: 8.h),
          width: 40.w,
          height: 4.h,
          decoration: BoxDecoration(
            color: AppColors.onSurfaceSecondary,
            borderRadius: BorderRadius.circular(2.r),
          ),
        ),
        // 展开内容 - 提示点击打开完整播放器
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.keyboard_arrow_up,
                size: 32.sp,
                color: AppColors.onSurfaceSecondary,
              ),
              SizedBox(height: 8.h),
              Text(
                '点击打开完整播放器',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.onSurfaceSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
