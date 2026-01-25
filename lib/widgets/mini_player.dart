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

class _MiniPlayerState extends State<MiniPlayer>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _heightAnimation;
  late Animation<double> _progressOpacity;
  late Animation<double> _controlsOpacity;

  // 拖动相关
  double _dragStartY = 0;
  double _dragOffset = 0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _heightAnimation = Tween<double>(begin: 56.h, end: 200.h).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );

    _progressOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );

    _controlsOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
        reverseCurve: Curves.easeIn,
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpand() {
    if (_animationController.status == AnimationStatus.completed) {
      _animationController.reverse();
    } else {
      _animationController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<PlayerController>();

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return GestureDetector(
          onVerticalDragStart: (details) {
            _dragStartY = details.globalPosition.dy;
            _dragOffset = 0;
          },
          onVerticalDragUpdate: (details) {
            _dragOffset = details.globalPosition.dy - _dragStartY;
            // 根据拖动距离更新动画值
            final newValue = _animationController.value - (_dragOffset / (200.h - 56.h));
            _animationController.value = newValue.clamp(0.0, 1.0);
          },
          onVerticalDragEnd: (details) {
            // 根据速度和位置决定是展开还是收起
            final velocity = details.velocity.pixelsPerSecond.dy;
            if (velocity > 500) {
              _animationController.reverse();
            } else if (velocity < -500) {
              _animationController.forward();
            } else {
              // 根据当前位置决定
              if (_animationController.value > 0.5) {
                _animationController.forward();
              } else {
                _animationController.reverse();
              }
            }
          },
          onTap: () {
            Get.toNamed(AppRoutes.player);
          },
          child: SizedBox(
            height: _heightAnimation.value,
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated.withValues(alpha: 0.8),
                  ),
                  child: Stack(
                    children: [
                      // 使用 Obx 监听播放器状态变化
                      Obx(() => _buildCompactPlayer(controller)),
                      // 进度条淡出 - 使用 Obx 监听进度变化
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: Obx(() => Opacity(
                          opacity: _progressOpacity.value,
                          child: _buildProgressBarContent(controller),
                        )),
                      ),
                      // 展开后的内容
                      if (_animationController.status == AnimationStatus.completed ||
                          _animationController.status == AnimationStatus.forward)
                        Opacity(
                          opacity: _controlsOpacity.value,
                          child: _buildExpandedContent(),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProgressBarContent(PlayerController controller) {
    final currentSong = controller.currentSong.value;
    if (currentSong == null) return const SizedBox();

    final duration = controller.duration.value.inMilliseconds > 0
        ? controller.position.value.inMilliseconds / controller.duration.value.inMilliseconds
        : 0.0;

    return SizedBox(
      height: 3.h,
      width: double.infinity,
      child: LinearProgressIndicator(
        value: duration.clamp(0.0, 1.0),
        backgroundColor: AppColors.surfaceVariant,
        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
      ),
    );
  }

  Widget _buildCompactPlayer(PlayerController controller) {
    final currentSong = controller.currentSong.value;
    final isPlaying = controller.isPlaying.value;

    // 如果没有歌曲，显示占位内容
    if (currentSong == null) {
      return Column(
        children: [
          SizedBox(height: 3.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
            child: Row(
              children: [
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

    return Padding(
      padding: EdgeInsets.only(top: 3.h),
      child: Padding(
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
                _buildControlButton(
                  icon: isPlaying
                      ? Icons.pause_circle_filled
                      : Icons.play_circle_filled,
                  onPressed: controller.togglePlay,
                  size: 28.sp,
                  color: AppColors.primary,
                ),
                _buildControlButton(
                  icon: Icons.skip_next,
                  onPressed: controller.seekToNext,
                  size: 24.sp,
                  color: AppColors.onSurface,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
    required double size,
    required Color color,
  }) {
    return _AnimatedIconButton(
      icon: icon,
      onPressed: onPressed,
      size: size,
      color: color,
    );
  }

  Widget _buildExpandedContent() {
    return Column(
      children: [
        // 拖动指示器
        Container(
          margin: EdgeInsets.only(top: 8.h),
          width: 40.w,
          height: 4.h,
          decoration: BoxDecoration(
            color: AppColors.onSurfaceSecondary.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(2.r),
          ),
        ),
        // 展开内容 - 提示点击打开完整播放器
        Expanded(
          child: Center(
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
        ),
      ],
    );
  }
}

/// 带缩放动画的图标按钮
class _AnimatedIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final double size;
  final Color color;

  const _AnimatedIconButton({
    required this.icon,
    required this.onPressed,
    required this.size,
    required this.color,
  });

  @override
  State<_AnimatedIconButton> createState() => _AnimatedIconButtonState();
}

class _AnimatedIconButtonState extends State<_AnimatedIconButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.85).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onPressed();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Icon(
              widget.icon,
              size: widget.size,
              color: widget.color,
            ),
          );
        },
      ),
    );
  }
}
