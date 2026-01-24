import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../theme/theme.dart';

/// 播放进度条组件 - 美化版
class ProgressSliderWidget extends StatelessWidget {
  final Duration position;
  final Duration duration;
  final ValueChanged<double>? onChanged;

  const ProgressSliderWidget({
    super.key,
    required this.position,
    required this.duration,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final currentPosition = position.inMilliseconds.toDouble();
    final totalDuration = duration.inMilliseconds.toDouble();

    return Row(
        children: [
          // 当前时间
          SizedBox(
            width: 42.w,
            child: _TimeLabel(time: position),
          ),
          // 进度条
          Expanded(
            child: SliderTheme(
              data: SliderThemeData(
                trackHeight: 4.h,
                thumbShape: RoundSliderThumbShape(
                  enabledThumbRadius: 6.r,
                ),
                activeTrackColor: AppColors.primary,
                inactiveTrackColor: AppColors.surfaceVariant.withValues(alpha: 0.5),
                thumbColor: Colors.white,
                overlayColor: Colors.white.withValues(alpha: 0.2),
              ),
              child: Slider(
                value: currentPosition.clamp(0.0, totalDuration),
                min: 0,
                max: totalDuration > 0 ? totalDuration : 1.0,
                onChanged: onChanged,
              ),
            ),
          ),
          // 总时长
          SizedBox(
            width: 42.w,
            child: _TimeLabel(time: duration),
          ),
        ],
      );
  }
}

/// 时间标签组件
class _TimeLabel extends StatelessWidget {
  final Duration time;

  const _TimeLabel({required this.time});

  @override
  Widget build(BuildContext context) {
    return Text(
      _formatTime(time),
      style: AppTextStyles.bodySmall.copyWith(
        color: AppColors.onSurfaceSecondary,
      ),
    );
  }

  String _formatTime(Duration time) {
    final minutes = time.inMinutes;
    final seconds = time.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
