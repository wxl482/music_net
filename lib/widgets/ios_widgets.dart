import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../theme/theme.dart';

/// Apple Music 风格毛玻璃卡片
class IOSGlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? borderRadius;
  final double? height;
  final double? width;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final bool blurred;

  const IOSGlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius,
    this.height,
    this.width,
    this.onTap,
    this.backgroundColor,
    this.blurred = true,
  });

  @override
  Widget build(BuildContext context) {
    final cardContent = Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.surface.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(borderRadius ?? AppDimensions.cardRadius),
        border: Border.all(
          color: AppColors.separator.withValues(alpha: 0.5),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: padding ?? EdgeInsets.all(AppDimensions.paddingLarge),
        child: child,
      ),
    );

    if (!blurred) {
      return GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: cardContent,
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius ?? AppDimensions.cardRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: cardContent,
        ),
      ),
    );
  }
}

/// iOS 17+ 风格列表项
class IOSListItem extends StatelessWidget {
  final Widget? leading;
  final Widget title;
  final Widget? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;

  const IOSListItem({
    super.key,
    this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.padding,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor ?? AppColors.surface,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: padding ??
              EdgeInsets.symmetric(
                horizontal: AppDimensions.paddingLarge,
                vertical: AppDimensions.paddingMedium,
              ),
          constraints: const BoxConstraints(minHeight: AppDimensions.listItemHeight),
          child: Row(
            children: [
              if (leading != null) ...[
                leading!,
                SizedBox(width: AppDimensions.paddingMedium),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    title,
                    if (subtitle != null) ...[
                      SizedBox(height: 2.h),
                      subtitle!,
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[
                SizedBox(width: AppDimensions.paddingMedium),
                trailing!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// iOS 17+ 风格分组列表
class IOSGroupedList extends StatelessWidget {
  final List<Widget> children;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;

  const IOSGroupedList({
    super.key,
    required this.children,
    this.padding,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor ?? AppColors.background,
      padding: padding ?? EdgeInsets.symmetric(vertical: AppDimensions.paddingMedium),
      child: Column(
        children: children,
      ),
    );
  }
}

/// iOS 17+ 风格按钮
class IOSButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final IOSButtonType type;
  final IOSButtonSize size;
  final IconData? icon;
  final bool expanded;

  const IOSButton({
    super.key,
    required this.text,
    this.onPressed,
    this.type = IOSButtonType.filled,
    this.size = IOSButtonSize.medium,
    this.icon,
    this.expanded = false,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = onPressed != null;

    Color backgroundColor;
    Color foregroundColor;

    switch (type) {
      case IOSButtonType.filled:
        backgroundColor = isEnabled ? AppColors.primary : AppColors.systemGray3;
        foregroundColor = AppColors.onPrimary;
        break;
      case IOSButtonType.tinted:
        backgroundColor = isEnabled ? AppColors.primary.withValues(alpha: 0.15) : AppColors.systemGray5;
        foregroundColor = isEnabled ? AppColors.primary : AppColors.systemGray2;
        break;
      case IOSButtonType.light:
        backgroundColor = AppColors.surface;
        foregroundColor = AppColors.primary;
        break;
    }

    final height = size == IOSButtonSize.large ? 50.0 : 44.0;
    final fontSize = size == IOSButtonSize.large ? 17.0 : 15.0;
    final padding = size == IOSButtonSize.small
        ? EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h)
        : EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h);

    final button = Container(
      height: height,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        border: type == IOSButtonType.light
            ? Border.all(color: AppColors.separator.withValues(alpha: 0.5))
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isEnabled ? onPressed : null,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          child: Padding(
            padding: padding,
            child: Row(
              mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 16, color: foregroundColor),
                  SizedBox(width: 8.w),
                ],
                Text(
                  text,
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.w600,
                    color: foregroundColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (expanded) {
      return SizedBox(width: double.infinity, child: button);
    }
    return button;
  }
}

enum IOSButtonType { filled, tinted, light }
enum IOSButtonSize { small, medium, large }

/// Apple Music 风格导航栏
class IOSNavBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool largeTitle;
  final Widget? flexibleSpace;

  const IOSNavBar({
    super.key,
    this.title,
    this.actions,
    this.leading,
    this.largeTitle = false,
    this.flexibleSpace,
  });

  @override
  Size get preferredSize => const Size.fromHeight(AppDimensions.navBarHeight);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.85),
        border: Border(
          bottom: BorderSide(
            color: AppColors.separator.withValues(alpha: 0.3),
            width: 0.5,
          ),
        ),
      ),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: leading,
            title: largeTitle ? null : title != null ? Text(title!, style: AppTextStyles.title3) : null,
            actions: actions,
            flexibleSpace: flexibleSpace,
          ),
        ),
      ),
    );
  }
}

/// iOS 17+ 风格底部标签栏
class IOSTabBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<IOSTabBarItem> items;

  const IOSTabBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.9),
        border: Border(
          top: BorderSide(
            color: AppColors.separator.withValues(alpha: 0.3),
            width: 0.5,
          ),
        ),
      ),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: AppDimensions.tabBarHeight,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: items.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  final isSelected = index == currentIndex;

                  return Expanded(
                    child: InkWell(
                      onTap: () => onTap(index),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            item.icon,
                            color: isSelected ? AppColors.primary : AppColors.systemGray,
                            size: 24,
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            item.label,
                            style: AppTextStyles.caption2.copyWith(
                              color: isSelected ? AppColors.primary : AppColors.systemGray,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class IOSTabBarItem {
  final IconData icon;
  final String label;

  const IOSTabBarItem({
    required this.icon,
    required this.label,
  });
}
