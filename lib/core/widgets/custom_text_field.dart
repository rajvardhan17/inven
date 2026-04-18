import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/app_theme.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final IconData prefixIcon;
  final bool obscureText;
  final Widget? suffixIcon;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final String? prefixText;
  final List<TextInputFormatter>? inputFormatters;
  final TextCapitalization textCapitalization;
  final void Function(String)? onFieldSubmitted;
  final TextInputAction? textInputAction;
  final bool enabled;
  final int maxLines;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.prefixIcon,
    this.obscureText = false,
    this.suffixIcon,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.prefixText,
    this.inputFormatters,
    this.textCapitalization = TextCapitalization.none,
    this.onFieldSubmitted,
    this.textInputAction,
    this.enabled = true,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      textInputAction: textInputAction,
      inputFormatters: inputFormatters,
      onFieldSubmitted: onFieldSubmitted,
      validator: validator,
      enabled: enabled,
      maxLines: maxLines,
      style: const TextStyle(
  color: AppTheme.textPrimary, // ✅ THIS FIXES TEXT VISIBILITY
),
      cursorColor: AppTheme.accent,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(
          color: AppTheme.textMuted,
          fontSize: 13,
        ),
        prefixText: prefixText,
        prefixStyle: const TextStyle(color: AppTheme.textSecondary),
        prefixIcon: Icon(prefixIcon, color: AppTheme.textSecondary, size: 18),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: AppTheme.surface2,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),

        // Borders
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          borderSide: const BorderSide(color: AppTheme.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          borderSide: const BorderSide(color: AppTheme.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          borderSide: const BorderSide(
            color: AppTheme.accent,
            width: 1.4,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          borderSide: const BorderSide(color: AppTheme.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          borderSide: const BorderSide(
            color: AppTheme.red,
            width: 1.4,
          ),
        ),
      ),
    );
  }
}