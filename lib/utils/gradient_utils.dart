import 'package:flutter/material.dart';
import '../theme/theme.dart';

/// 渐变工具类 - 提供常用的渐变装饰和样式
class GradientUtils {
  /// 主渐变（绿色系）- 用于主要按钮、强调元素
  static BoxDecoration get primaryGradient => BoxDecoration(
        gradient: const LinearGradient(
          colors: AppColors.primaryGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      );

  /// 紫粉渐变 - 用于热门、推荐内容
  static BoxDecoration get purplePinkGradient => BoxDecoration(
        gradient: const LinearGradient(
          colors: AppColors.purplePinkGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      );

  /// 紫橙渐变 - 用于活力、运动风格
  static BoxDecoration get purpleOrangeGradient => BoxDecoration(
        gradient: const LinearGradient(
          colors: AppColors.purpleOrangeGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      );

  /// 紫青渐变 - 用于排行榜、热门榜单
  static BoxDecoration get purpleTealGradient => BoxDecoration(
        gradient: const LinearGradient(
          colors: AppColors.purpleTealGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      );

  /// 深邃渐变 - 用于背景、卡片
  static BoxDecoration get deepGradient => BoxDecoration(
        gradient: const LinearGradient(
          colors: AppColors.deepGradient,
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      );

  /// 玻璃渐变 - 用于半透明覆盖层
  static BoxDecoration get glassGradient => BoxDecoration(
        gradient: const LinearGradient(
          colors: AppColors.glassGradient,
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      );

  /// 卡片渐变 - 用于卡片背景
  static BoxDecoration get cardGradient => BoxDecoration(
        gradient: const LinearGradient(
          colors: AppColors.cardGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      );

  /// 创建自定义线性渐变
  static LinearGradient createLinearGradient({
    required List<Color> colors,
    Alignment begin = Alignment.topLeft,
    Alignment end = Alignment.bottomRight,
    List<double>? stops,
    TileMode tileMode = TileMode.clamp,
  }) {
    return LinearGradient(
      colors: colors,
      begin: begin,
      end: end,
      stops: stops,
      tileMode: tileMode,
    );
  }

  /// 创建径向渐变
  static RadialGradient createRadialGradient({
    required Color color,
    required double radius,
    Alignment center = Alignment.center,
  }) {
    return RadialGradient(
      colors: [color, color.withValues(alpha: 0)],
      center: center,
      radius: radius,
    );
  }

  /// 创建阴影 + 渐变组合（用于立体效果）
  static BoxDecoration get elevatedGradient {
    return BoxDecoration(
      gradient: const LinearGradient(
        colors: AppColors.primaryGradient,
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      boxShadow: [
        BoxShadow(
          color: AppColors.primary.withValues(alpha: 0.3),
          blurRadius: 12,
          offset: const Offset(0, 6),
        ),
      ],
    );
  }

  /// 获取渐变色文字样式
  static TextStyle getGradientTextStyle({
    required BuildContext context,
    required List<Color> colors,
    required TextStyle textStyle,
  }) {
    return textStyle.copyWith(
      foreground: Paint()
        ..shader = LinearGradient(
          colors: colors,
        ).createShader(
          const Rect.fromLTWH(0, 0, 200, 20),
        ),
    );
  }
}

/// 渐变装饰类 - 为特定元素提供渐变效果
class GradientDecoration {
  /// 按钮渐变装饰
  static BoxDecoration button({
    List<Color>? colors,
    double radius = 12,
  }) {
    return BoxDecoration(
      gradient: LinearGradient(
        colors: colors ?? AppColors.primaryGradient,
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(radius),
      boxShadow: [
        BoxShadow(
          color: (colors?.first ?? AppColors.primary).withValues(alpha: 0.3),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  /// 卡片渐变装饰
  static BoxDecoration card({
    List<Color>? colors,
    double radius = 16,
  }) {
    return BoxDecoration(
      gradient: LinearGradient(
        colors: colors ?? AppColors.cardGradient,
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: Colors.white.withValues(alpha: 0.1),
        width: 0.5,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.06),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  /// 图标背景渐变装饰
  static BoxDecoration iconBackground({
    Color? color,
    double size = 40,
  }) {
    return BoxDecoration(
      gradient: RadialGradient(
        colors: [
          (color ?? AppColors.primary).withValues(alpha: 0.2),
          (color ?? AppColors.primary).withValues(alpha: 0.05),
        ],
      ),
      shape: BoxShape.circle,
    );
  }
}
