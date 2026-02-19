import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isPrimary;
  final bool isSecondary;
  final IconData? icon;
  final double? width;
  final Color? color;
  final bool isLoading;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isPrimary = true,
    this.isSecondary = false,
    this.icon,
    this.width,
    this.color,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool useSolid = isPrimary && !isSecondary;
    
    return SizedBox(
      width: width ?? double.infinity,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color ?? (useSolid ? AppTheme.primaryColor : Colors.white),
          foregroundColor: useSolid ? Colors.white : AppTheme.textSecondary,
          elevation: useSolid ? 4 : 0,
          shadowColor: useSolid ? AppTheme.primaryColor.withOpacity(0.4) : null,
          padding: const EdgeInsets.symmetric(vertical: 18), // Taller touch target
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: useSolid 
                ? BorderSide.none 
                : const BorderSide(color: AppTheme.borderColor, width: 1.5),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(
                      icon, 
                      size: 20, 
                      color: useSolid ? Colors.white : AppTheme.textSecondary,
                    ),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    text,
                    style: const TextStyle(
                      fontSize: 18, // Larger text
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
