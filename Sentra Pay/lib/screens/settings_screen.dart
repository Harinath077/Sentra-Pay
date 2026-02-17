import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../models/settings_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = Theme.of(context).colorScheme.surface;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Settings",
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section

            // Features Section
            Text(
              "FEATURES",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: isDark
                    ? AppTheme.darkTextSecondary
                    : const Color(0xFF64748B),
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 16),

            // Feature Cards
            Consumer<SettingsProvider>(
              builder: (context, settings, child) {
                return Column(
                  children: [
                    _buildFeatureCard(
                      context: context,
                      icon: Icons.history_rounded,
                      title: "Transaction History",
                      description: "View your past transactions and analytics",
                      isUnlocked: settings.historyFeatureUnlocked,
                      onToggle: (value) => settings.toggleHistoryFeature(value),
                      isDark: isDark,
                      cardColor: cardColor,
                      isPremium: true,
                    ),
                    const SizedBox(height: 12),
                    _buildFeatureCard(
                      context: context,
                      icon: Icons.analytics_rounded,
                      title: "Advanced Analytics",
                      description: "Detailed risk insights and patterns",
                      isUnlocked: settings.advancedAnalyticsUnlocked,
                      onToggle: (value) =>
                          settings.toggleAdvancedAnalytics(value),
                      isDark: isDark,
                      cardColor: cardColor,
                      isPremium: true,
                    ),
                    const SizedBox(height: 12),
                    _buildFeatureCard(
                      context: context,
                      icon: Icons.qr_code_scanner_rounded,
                      title: "QR Scanner",
                      description: "Scan QR codes for quick payments",
                      isUnlocked: settings.qrScannerUnlocked,
                      onToggle: (value) => settings.toggleQrScanner(value),
                      isDark: isDark,
                      cardColor: cardColor,
                      isPremium: false,
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 32),

            // Quick Actions Section
            Text(
              "QUICK ACTIONS",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: isDark
                    ? AppTheme.darkTextSecondary
                    : const Color(0xFF64748B),
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 16),

            Consumer<SettingsProvider>(
              builder: (context, settings, child) {
                return Column(
                  children: [
                    _buildActionButton(
                      context: context,
                      icon: Icons.lock_open_rounded,
                      title: "Unlock All Features",
                      subtitle: "Enable all premium features",
                      color: const Color(0xFF10B981),
                      onTap: () async {
                        await settings.unlockAllFeatures();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('All features unlocked! 🎉'),
                              backgroundColor: Color(0xFF10B981),
                            ),
                          );
                        }
                      },
                      isDark: isDark,
                      cardColor: cardColor,
                    ),
                    const SizedBox(height: 12),
                    _buildActionButton(
                      context: context,
                      icon: Icons.restart_alt_rounded,
                      title: "Reset Features",
                      subtitle: "Reset to default settings",
                      color: const Color(0xFFEF4444),
                      onTap: () async {
                        await settings.resetAllFeatures();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Features reset to default'),
                              backgroundColor: Color(0xFFEF4444),
                            ),
                          );
                        }
                      },
                      isDark: isDark,
                      cardColor: cardColor,
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 32),

            // Info Section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark
                      ? AppTheme.darkBorderColor
                      : AppTheme.borderColor,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: isDark
                        ? AppTheme.darkTextSecondary
                        : AppTheme.textSecondary,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "Features can be toggled on/off anytime. Premium features enhance your security experience.",
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark
                            ? AppTheme.darkTextSecondary
                            : AppTheme.textSecondary,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String description,
    required bool isUnlocked,
    required Function(bool) onToggle,
    required bool isDark,
    required Color cardColor,
    required bool isPremium,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUnlocked
              ? const Color(0xFF10B981).withOpacity(0.3)
              : (isDark ? AppTheme.darkBorderColor : AppTheme.borderColor),
          width: isUnlocked ? 2 : 1,
        ),
        boxShadow: [
          if (isUnlocked)
            BoxShadow(
              color: const Color(0xFF10B981).withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => onToggle(!isUnlocked),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isUnlocked
                        ? const Color(0xFF10B981).withOpacity(0.1)
                        : (isDark
                              ? Colors.white.withOpacity(0.05)
                              : Colors.grey.shade100),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: isUnlocked
                        ? const Color(0xFF10B981)
                        : (isDark
                              ? AppTheme.darkTextSecondary
                              : AppTheme.textSecondary),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              title,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? AppTheme.darkTextPrimary
                                    : AppTheme.textPrimary,
                              ),
                            ),
                          ),
                          if (isPremium) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFF59E0B),
                                    Color(0xFFEF4444),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                "PRO",
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark
                              ? AppTheme.darkTextSecondary
                              : AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Switch(
                  value: isUnlocked,
                  onChanged: onToggle,
                  activeThumbColor: const Color(0xFF10B981),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    required bool isDark,
    required Color cardColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppTheme.darkBorderColor : AppTheme.borderColor,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppTheme.darkTextPrimary
                              : AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark
                              ? AppTheme.darkTextSecondary
                              : AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: isDark
                      ? AppTheme.darkTextSecondary
                      : AppTheme.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
