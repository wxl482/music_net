import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../models/song.dart';
import '../../../../theme/theme.dart';

class SongItem extends StatelessWidget {
  final Song song;
  final int index;
  final VoidCallback onTap;
  final bool showIndex;

  const SongItem({
    super.key,
    required this.song,
    required this.index,
    required this.onTap,
    this.showIndex = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 8.h),
        child: Row(
          children: [
            // Index or number
            if (showIndex)
              SizedBox(
                width: 32.w,
                child: Text(
                  index.toString().padLeft(2, '0'),
                  style: index <= 3
                      ? AppTextStyles.titleLarge.copyWith(
                          color: AppColors.primary,
                        )
                      : AppTextStyles.titleMedium.copyWith(
                          color: AppColors.onSurfaceSecondary,
                        ),
                  textAlign: TextAlign.center,
                ),
              ),
            SizedBox(width: 12.w),
            // Cover
            ClipRRect(
              borderRadius: BorderRadius.circular(8.r),
              child: (song.coverUrl != null && song.coverUrl!.isNotEmpty)
                  ? song.isLocal
                      ? Image.file(
                          File(song.coverUrl!),
                          width: 48.w,
                          height: 48.w,
                          fit: BoxFit.cover,
                        )
                      : CachedNetworkImage(
                          imageUrl: song.coverUrl!,
                          width: 48.w,
                          height: 48.w,
                          fit: BoxFit.cover,
                          errorWidget: (context, url, error) => Container(
                            width: 48.w,
                            height: 48.w,
                            color: AppColors.surfaceVariant,
                            child: const Icon(Icons.music_note, color: Colors.white),
                          ),
                        )
                  : Container(
                      width: 48.w,
                      height: 48.w,
                      color: AppColors.surfaceVariant,
                      child: const Icon(Icons.music_note, color: Colors.white),
                    ),
            ),
            SizedBox(width: 12.w),
            // Title and artist
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
                    '${song.artist} - ${song.album}',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.onSurfaceSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Duration
            Text(
              _formatDuration(song.duration),
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.onSurfaceSecondary,
              ),
            ),
            SizedBox(width: 8.w),
            // More button
            IconButton(
              icon: const Icon(Icons.more_vert, color: AppColors.onSurfaceSecondary),
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}
