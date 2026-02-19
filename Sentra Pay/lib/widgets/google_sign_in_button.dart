import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class GoogleSignInButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isLoading;

  const GoogleSignInButton({
    super.key,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    // Google Brand Colors & Styles
    // Light Mode: White background, gray border, dark text
    // Dark Mode: Dark background (Google uses #131314 or similar), white text, no border usually, but can add subtle if needed
    
    final Color backgroundColor = isDarkMode 
        ? const Color(0xFF131314) // Standard Google Dark background
        : Colors.white;
        
    final Color foregroundColor = isDarkMode 
        ? Colors.white 
        : Colors.black.withOpacity(0.54); // Standard Google text color (approx)

    final Color borderColor = isDarkMode ? Colors.white24 : const Color(0xFF747775);

    final TextStyle textStyle = theme.textTheme.bodyLarge!.copyWith(
      color: foregroundColor,
      fontWeight: FontWeight.w500,
      fontFamily: 'Roboto', // Google Sans or Roboto is standard, using app default or Roboto if updated
      fontSize: 20, 
    );
    
    // Using ElevatedButton for shadow/elevation support
    return SizedBox(
      height: 50, // Standard touch target
      width: double.infinity, // Responsive width
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          elevation: 2, // Smooth elevation
          shadowColor: Colors.black.withOpacity(0.2), // Subtle shadow
          shape: const StadiumBorder(), // Pill shape
          side: BorderSide(
            color: borderColor,
            width: 1,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        child: isLoading 
          ? SizedBox(
              height: 24, 
              width: 24, 
              child: CircularProgressIndicator(
                strokeWidth: 2, 
                valueColor: AlwaysStoppedAnimation<Color>(foregroundColor),
              ),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min, // Wrap content if not full width
              children: [
                // Google Logo
                SvgPicture.asset(
                  'assets/images/google_logo.svg',
                  height: 34,
                  width: 34,
                ),
                const SizedBox(width: 12), // Spacing
                Text(
                  'Sign in with Google',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: isDarkMode ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.w500,
                    fontSize: 18, // readable and prominent
                  ),
                ),
              ],
            ),
      ),
    );
  }
}
