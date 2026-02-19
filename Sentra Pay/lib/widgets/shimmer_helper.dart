import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ShimmerHelper {
  static Widget buildShimmer({
    required double width,
    required double height,
    required bool isDark,
    double radius = 12,
  }) {
    return Shimmer.fromColors(
      baseColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
      highlightColor: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }

  static Widget buildListShimmer({required bool isDark, int itemCount = 6}) {
    return ListView.builder(
      itemCount: itemCount,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            children: [
              buildShimmer(width: 48, height: 48, isDark: isDark, radius: 24),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    buildShimmer(width: double.infinity, height: 16, isDark: isDark),
                    const SizedBox(height: 8),
                    buildShimmer(width: 120, height: 12, isDark: isDark),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                   buildShimmer(width: 60, height: 16, isDark: isDark),
                   const SizedBox(height: 8),
                   buildShimmer(width: 40, height: 12, isDark: isDark),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  static Widget buildDashboardShimmer({required bool isDark}) {
      return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                  buildShimmer(width: 180, height: 32, isDark: isDark),
                  const SizedBox(height: 24),
                  Row(
                      children: [
                          Expanded(child: buildShimmer(width: double.infinity, height: 100, isDark: isDark)),
                          const SizedBox(width: 16),
                          Expanded(child: buildShimmer(width: double.infinity, height: 100, isDark: isDark)),
                      ],
                  ),
                  const SizedBox(height: 24),
                  buildShimmer(width: double.infinity, height: 250, isDark: isDark),
                  const SizedBox(height: 24),
                  buildListShimmer(isDark: isDark, itemCount: 4),
              ],
          ),
      );
  }
}
