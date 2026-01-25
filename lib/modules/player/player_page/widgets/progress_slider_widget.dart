import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../theme/theme.dart';

/// 播放进度条组件 - 美化版
class ProgressSliderWidget extends StatefulWidget {
  final Duration position;
  final Duration duration;
  final ValueChanged<double>? onChanged;
  final ValueChanged<double>? onChangeStart;
  final ValueChanged<double>? onChangeEnd;

  const ProgressSliderWidget({
    super.key,
    required this.position,
    required this.duration,
    this.onChanged,
    this.onChangeStart,
    this.onChangeEnd,
  });

  @override
  State<ProgressSliderWidget> createState() => _ProgressSliderWidgetState();
}

class _ProgressSliderWidgetState extends State<ProgressSliderWidget> {
  // 拖动状态
  bool _isDragging = false;
  double _dragValue = 0.0;

  @override
  Widget build(BuildContext context) {
    final currentPosition = widget.position.inMilliseconds.toDouble();
    final totalDuration = widget.duration.inMilliseconds.toDouble();

    // 如果正在拖动，使用拖动的值；否则使用当前播放位置
    final sliderValue = _isDragging ? _dragValue : currentPosition.clamp(0.0, totalDuration);

    return Row(
        children: [
          // 当前时间
          SizedBox(
            width: 42.w,
            child: _TimeLabel(
              time: Duration(milliseconds: sliderValue.toInt()),
            ),
          ),
          // 进度条
          Expanded(
            child: SliderTheme(
              data: SliderThemeData(
                trackHeight: 3.h,
                thumbShape: RoundSliderThumbShape(
                  enabledThumbRadius: 6.r,
                ),
                activeTrackColor: AppColors.primary,
                inactiveTrackColor: AppColors.surfaceVariant.withValues(alpha: 0.3),
                thumbColor: Colors.white,
                overlayColor: Colors.white.withValues(alpha: 0.2),
              ),
              child: Slider(
                value: sliderValue,
                min: 0,
                max: totalDuration > 0 ? totalDuration : 1.0,
                onChanged: _handleChanged,
                onChangeStart: _handleDragStart,
                onChangeEnd: _handleDragEnd,
              ),
            ),
          ),
          // 总时长
          SizedBox(
            width: 42.w,
            child: _TimeLabel(time: widget.duration),
          ),
        ],
      );
  }

  void _handleDragStart(double value) {
    setState(() {
      _isDragging = true;
      _dragValue = value;
    });
    widget.onChangeStart?.call(value);
  }

  void _handleChanged(double value) {
    if (_isDragging) {
      setState(() {
        _dragValue = value;
      });
    }
    // 不在这里调用 onChanged，避免拖动过程中频繁更新
  }

  void _handleDragEnd(double value) {
    setState(() {
      _isDragging = false;
    });
    // 只在拖动结束时执行回调
    widget.onChanged?.call(value);
    widget.onChangeEnd?.call(value);
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
