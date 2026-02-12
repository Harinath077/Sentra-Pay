import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class VerificationCard extends StatelessWidget {
  const VerificationCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 16, bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardSurfaceColor, // #F5F8FF
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor), // #E2E8FF
      ),
      child: Stack(
        children: [
          // Info Row
          Padding(
            padding: const EdgeInsets.only(top: 8.0), // Give space for the top-right label if needed
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Circular bank logo (24x24) or slightly larger for touch target
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(8),
                  // Placeholder for Logo
                  child: const Icon(Icons.account_balance_rounded, size: 20, color: AppTheme.accentColor),
                ),
                const SizedBox(width: 16),
                
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Merchant Store",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // UPI ID  
                      const Text(
                        "merchant@axisbank",
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Verified Status
                      Row(
                        children: const [
                          Icon(
                            Icons.check_circle_rounded,
                            color: AppTheme.successColor,
                            size: 16,
                          ),
                          SizedBox(width: 6),
                          Text(
                            "Verified UPI ID",
                            style: TextStyle(
                              fontSize: 13,
                              color: AppTheme.successColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Bank Verification Label (Top Right)
          Positioned(
            top: 0,
            right: 0,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(
                  Icons.verified_user_outlined, // Shield icon replacement as requested
                  size: 12,
                  color: AppTheme.textPlaceholder,
                ),
                SizedBox(width: 4),
                Text(
                  "Verified by Axis Bank",
                  style: TextStyle(
                    fontSize: 10,
                    color: AppTheme.textPlaceholder, // muted grey #9CA3AF
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
