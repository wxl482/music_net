import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../models/song.dart';
import '../../../theme/theme.dart';
import '../../../utils/image_utils.dart';

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
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            // Index or number
            if (showIndex)
              SizedBox(
                width: 32,
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
            const SizedBox(width: 12),
            // Cover
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: (song.coverUrl != null && song.coverUrl!.isNotEmpty)
                  ? song.isLocal
                      ? Image.file(
                          File(song.coverUrl!),
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                        )
                      : CachedNetworkImage(
                          imageUrl: ImageUtils.replaceImageSize(song.coverUrl!, 48),
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                          errorWidget: (context, url, error) => Container(
                            width: 48,
                            height: 48,
                            color: AppColors.surfaceVariant,
                            child: const Icon(Icons.music_note, color: Colors.white),
                          ),
                        )
                  : Container(
                      width: 48,
                      height: 48,
                      color: AppColors.surfaceVariant,
                      child: const Icon(Icons.music_note, color: Colors.white),
                    ),
            ),
            const SizedBox(width: 12),
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
                  const SizedBox(height: 4),
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
            const SizedBox(width: 8),
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
