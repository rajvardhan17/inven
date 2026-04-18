import 'package:flutter/material.dart';
import '../../core/app_theme.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Color? color;
  final Color? textColor;
  final double height;
  final double borderRadius;
  final IconData? leadingIcon;
  final bool isOutlined;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.color,
    this.textColor,
    this.height = 50,
    this.borderRadius = AppTheme.radiusSm,
    this.leadingIcon,
    this.isOutlined = false,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = color ?? AppTheme.accent;
    final fgColor = textColor ?? AppTheme.bg;

    return SizedBox(
      width: double.infinity,
      height: height,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isOutlined ? Colors.transparent : bgColor,
          foregroundColor: isOutlined ? bgColor : fgColor,
          disabledBackgroundColor: bgColor.withOpacity(0.5),
          elevation: isOutlined ? 0 : 4,
          shadowColor: isOutlined ? Colors.transparent : bgColor.withOpacity(0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            side: isOutlined
                ? BorderSide(color: bgColor, width: 1.2)
                : BorderSide.none,
          ),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: isLoading
              ? SizedBox(
                  key: const ValueKey("loader"),
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: isOutlined ? bgColor : fgColor,
                  ),
                )
              : Row(
                  key: const ValueKey("text"),
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (leadingIcon != null) ...[
                      Icon(leadingIcon, size: 18),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      text,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}