import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../theme/theme.dart';
import '../../../models/song.dart';
import '../../../services/playback/playback_history_service.dart';
import '../../../modules/player/player_controller/player_controller.dart';

/// 播放历史页面
class PlaybackHistoryScreen extends StatelessWidget {
  const PlaybackHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final historyService = Get.find<PlaybackHistoryService>();
    final playerController = Get.find<PlayerController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '播放历史',
          style: AppTextStyles.titleLarge,
        ),
        actions: [
          Obx(() => historyService.history.isNotEmpty
              ? TextButton(
                  onPressed: () async {
                    final confirmed = await Get.dialog<bool>(
                      AlertDialog(
                        backgroundColor: AppColors.surface,
                        title: Text(
                          '清空历史',
                          style: AppTextStyles.titleMedium,
                        ),
                        content: Text(
                          '确定要清空所有播放历史吗？',
                          style: AppTextStyles.bodyMedium,
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Get.back(result: false),
                            child: Text('取消', style: AppTextStyles.bodyMedium),
                          ),
                          TextButton(
                            onPressed: () => Get.back(result: true),
                            child: Text(
                              '确定',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                    if (confirmed == true) {
                      await historyService.clearHistory();
                    }
                  },
                  child: Text(
                    '清空',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                )
              : const SizedBox.shrink()),
        ],
      ),
      body: Obx(() {
        final history = historyService.history;

        if (history.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.history,
                  size: 80.sp,
                  color: AppColors.onSurfaceSecondary,
                ),
                SizedBox(height: 16.h),
                Text(
                  '暂无播放历史',
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.onSurfaceSecondary,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  '播放歌曲后会显示在这里',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.onSurfaceSecondary,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.only(bottom: 80.h),
          itemCount: history.length,
          itemBuilder: (context, index) {
            final song = history[index];
            return _buildHistoryItem(
              song,
              index + 1,
              playerController,
              historyService,
            );
          },
        );
      }),
    );
  }

  Widget _buildHistoryItem(
    Song song,
    int index,
    PlayerController playerController,
    PlaybackHistoryService historyService,
  ) {
    return InkWell(
      onTap: () => playerController.playSong(song),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        child: Row(
          children: [
            // 序号
            SizedBox(
              width: 32.w,
              child: Text(
                index.toString().padLeft(2, '0'),
                style: AppTextStyles.titleMedium.copyWith(
                  color: AppColors.onSurfaceSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(width: 12.w),
            // 封面
            ClipRRect(
              borderRadius: BorderRadius.circular(8.r),
              child: song.coverUrl != null && song.coverUrl!.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: song.coverUrl!,
                      width: 48.w,
                      height: 48.w,
                      fit: BoxFit.cover,
                      errorWidget: (context, url, error) => Container(
                        width: 48.w,
                        height: 48.w,
                        color: AppColors.surfaceVariant,
                        child: Icon(
                          Icons.music_note,
                          color: AppColors.onSurfaceSecondary,
                          size: 24.sp,
                        ),
                      ),
                    )
                  : Container(
                      width: 48.w,
                      height: 48.w,
                      color: AppColors.surfaceVariant,
                      child: Icon(
                        Icons.music_note,
                        color: AppColors.onSurfaceSecondary,
                        size: 24.sp,
                      ),
                    ),
            ),
            SizedBox(width: 12.w),
            // 歌曲信息
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    song.title,
                    style: AppTextStyles.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    song.artist,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.onSurfaceSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // 删除按钮
            IconButton(
              icon: Icon(
                Icons.close,
                color: AppColors.onSurfaceSecondary,
                size: 20.sp,
              ),
              onPressed: () => historyService.removeFromHistory(song.id),
            ),
          ],
        ),
      ),
    );
  }
}
