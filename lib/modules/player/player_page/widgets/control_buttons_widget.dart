import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../../theme/theme.dart';
import '../../player_controller/player_controller.dart';
import 'playlist_bottom_sheet.dart';

/// 播放控制按钮组件
class ControlButtonsWidget extends StatelessWidget {
  final PlayerController controller;
  final VoidCallback? onPreviousPressed;
  final VoidCallback? onNextPressed;

  const ControlButtonsWidget({
    super.key,
    required this.controller,
    this.onPreviousPressed,
    this.onNextPressed,
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
                  color: Colors.white,
                  size: 24.sp,
                  onPressed: controller.switchPlayMode,
                ),
                // 上一曲
                _buildControlButton(
                  icon: Icons.skip_previous,
                  color: AppColors.onSurface,
                  size: 36.sp,
                  onPressed: controller.hasPrevious
                      ? () {
                          onPreviousPressed?.call();
                          controller.seekToPrevious();
                        }
                      : null,
                ),
                // 播放/暂停
                _buildPlayButton(),
                // 下一曲
                _buildControlButton(
                  icon: Icons.skip_next,
                  color: AppColors.onSurface,
                  size: 36.sp,
                  onPressed: controller.hasNext
                      ? () {
                          onNextPressed?.call();
                          controller.seekToNext();
                        }
                      : null,
                ),
                // 播放列表
                _buildControlButton(
                  icon: Icons.playlist_play,
                  color: Colors.white,
                  size: 24.sp,
                  onPressed: () => PlaylistBottomSheet.show(Get.context!, controller),
                ),
              ],
            ),
          ],
        ));
  }

  /// 播放按钮（带缩放和图标切换动画）
  Widget _buildPlayButton() {
    return _AnimatedPlayButton(
      isPlaying: controller.isPlaying.value,
      onPressed: controller.togglePlay,
    );
  }

  /// 控制按钮
  Widget _buildControlButton({
    required IconData icon,
    required Color color,
    required double size,
    VoidCallback? onPressed,
  }) {
    return Container(
      width: 48.w,
      height: 48.w,
      alignment: Alignment.center,
      child: IconButton(
        icon: Icon(icon, color: color, size: size),
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        splashRadius: 24.sp,
        constraints: BoxConstraints(
          minWidth: 48.w,
          minHeight: 48.w,
        ),
      ),
    );
  }
}

/// 带缩放动画的播放按钮
class _AnimatedPlayButton extends StatefulWidget {
  final bool isPlaying;
  final VoidCallback onPressed;

  const _AnimatedPlayButton({
    required this.isPlaying,
    required this.onPressed,
  });

  @override
  State<_AnimatedPlayButton> createState() => _AnimatedPlayButtonState();
}

class _AnimatedPlayButtonState extends State<_AnimatedPlayButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _scaleController.forward(),
      onTapUp: (_) {
        _scaleController.reverse();
        widget.onPressed();
      },
      onTapCancel: () => _scaleController.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              width: 72.w,
              height: 72.w,
              alignment: Alignment.center,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: ScaleTransition(
                      scale: animation,
                      child: child,
                    ),
                  );
                },
                child: Icon(
                  widget.isPlaying ? Icons.pause : Icons.play_arrow,
                  key: ValueKey(widget.isPlaying),
                  color: Colors.white,
                  size: 36.sp,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
