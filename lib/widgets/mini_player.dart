import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/player_provider.dart';
import '../theme/theme.dart';
import '../app.dart';
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
    final playerProvider = Provider.of<PlayerProvider>(context);
    final currentSong = playerProvider.currentSong;

    if (currentSong == null) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () {
        // 导航到完整播放器页面
        Get.toNamed(AppRoutes.PLAYER);
      },
      onVerticalDragUpdate: (details) {
        if (details.primaryDelta! > 50) {
          setState(() => _isExpanded = true);
        } else if (details.primaryDelta! < -50) {
          setState(() => _isExpanded = false);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        height: _isExpanded ? 300.h : 64.h,
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: _isExpanded
              ? BorderRadius.vertical(top: Radius.circular(16.r))
              : BorderRadius.circular(0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 10.r,
              offset: Offset(0, -2.h),
            ),
          ],
        ),
        child: _isExpanded
            ? _buildExpandedPlayer(context)
            : _buildCompactPlayer(context),
      ),
    );
  }

  Widget _buildCompactPlayer(BuildContext context) {
    final playerProvider = Provider.of<PlayerProvider>(context);
    final currentSong = playerProvider.currentSong!;

    return Column(
      children: [
        // 进度条
        SizedBox(
          height: 3.h,
          child: LinearProgressIndicator(
            value: playerProvider.duration.inMilliseconds > 0
                ? playerProvider.position.inMilliseconds /
                    playerProvider.duration.inMilliseconds
                : 0,
            backgroundColor: AppColors.surfaceVariant,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
        Expanded(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            child: Row(
              children: [
                // 封面
                ClipRRect(
                  borderRadius: BorderRadius.circular(8.r),
                  child: currentSong.coverUrl != null
                      ? (currentSong.isLocal
                          ? Image.file(
                              File(currentSong.coverUrl!),
                              width: 48.w,
                              height: 48.w,
                              fit: BoxFit.cover,
                            )
                          : CachedNetworkImage(
                              imageUrl: currentSong.coverUrl!,
                              width: 48.w,
                              height: 48.w,
                              fit: BoxFit.cover,
                            ))
                      : Container(
                          width: 48.w,
                          height: 48.w,
                          color: AppColors.surfaceVariant,
                          child: const Icon(Icons.music_note, color: Colors.white),
                        ),
                ),
                SizedBox(width: 12.w),
                // 标题和歌手
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        height: 20.h,
                        child: Marquee(
                          text: currentSong.title,
                          style: AppTextStyles.titleMedium,
                          scrollAxis: Axis.horizontal,
                          blankSpace: 100,
                          velocity: 30,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        currentSong.artist,
                        style: AppTextStyles.bodySmall,
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
                      onPressed: playerProvider.togglePlay,
                      icon: Icon(
                        playerProvider.isPlaying
                            ? Icons.pause_circle_filled
                            : Icons.play_circle_filled,
                        size: 32.sp,
                        color: AppColors.primary,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(
                        minWidth: 40.w,
                        minHeight: 40.w,
                      ),
                    ),
                    IconButton(
                      onPressed: playerProvider.seekToNext,
                      icon: const Icon(Icons.skip_next, color: AppColors.onSurface),
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(
                        minWidth: 40.w,
                        minHeight: 40.w,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExpandedPlayer(BuildContext context) {
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
