import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../../theme/theme.dart';
import '../../player_controller/player_controller.dart';
import 'playlist_bottom_sheet.dart';

/// 播放控制按钮组件
class ControlButtonsWidget extends StatelessWidget {
  final PlayerController controller;

  const ControlButtonsWidget({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() => Column(
          children: [
            // 播放控制按钮
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // 循环模式
                _buildControlButton(
                  icon: controller.playModeIcon,
                  color: controller.playModeColor,
                  size: 24.sp,
                  onPressed: controller.switchPlayMode,
                ),
                // 上一曲
                _buildControlButton(
                  icon: Icons.skip_previous,
                  color: AppColors.onSurface,
                  size: 36.sp,
                  onPressed: controller.hasPrevious ? controller.seekToPrevious : null,
                ),
                // 播放/暂停
                _buildPlayButton(),
                // 下一曲
                _buildControlButton(
                  icon: Icons.skip_next,
                  color: AppColors.onSurface,
                  size: 36.sp,
                  onPressed: controller.hasNext ? controller.seekToNext : null,
                ),
                // 播放列表（无文字）
                _buildControlButton(
                  icon: Icons.playlist_play,
                  color: AppColors.onSurfaceSecondary,
                  size: 24.sp,
                  onPressed: () => PlaylistBottomSheet.show(Get.context!, controller),
                ),
              ],
            ),
          ],
        ));
  }

  Widget _buildPlayButton() {
    return Obx(() => GestureDetector(
          onTap: controller.togglePlay,
          child: Container(
            width: 72.w,
            height: 72.w,
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.4),
                  blurRadius: 20.r,
                  spreadRadius: 5.r,
                ),
              ],
            ),
            child: Icon(
              controller.isPlaying.value ? Icons.pause : Icons.play_arrow,
              color: AppColors.onPrimary,
              size: 36.sp,
            ),
          ),
        ));
  }

  Widget _buildControlButton({
    required IconData icon,
    required Color color,
    required double size,
    VoidCallback? onPressed,
  }) {
    return IconButton(
      icon: Icon(icon, color: color, size: size),
      onPressed: onPressed,
      padding: EdgeInsets.all(8.w),
      constraints: BoxConstraints(
        minWidth: 48.w,
        minHeight: 48.w,
      ),
    );
  }
}
