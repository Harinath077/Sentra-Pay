import 'package:flutter/material.dart';

class AppLoadingIndicator extends StatefulWidget {
  final double size;
  final Color? color;
  final String? message; // Optional loading message

  const AppLoadingIndicator({
    super.key,
    this.size = 50,
    this.color,
    this.message,
  });

  @override
  State<AppLoadingIndicator> createState() => _AppLoadingIndicatorState();
}

class _AppLoadingIndicatorState extends State<AppLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Default color uses a safe green if not provided
    final iconColor = widget.color ?? const Color(0xFF10B981);
    
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: iconColor.withOpacity(0.1 + (_controller.value * 0.15)),
                  boxShadow: [
                    BoxShadow(
                      color: iconColor.withOpacity(0.2),
                      blurRadius: 15 + (_controller.value * 10),
                      spreadRadius: _controller.value * 5,
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    Icons.security_rounded, // App-related icon (Security)
                    color: iconColor,
                    size: widget.size * 0.6,
                  ),
                ),
              );
            },
          ),
          if (widget.message != null) ...[
            const SizedBox(height: 16),
            Text(
              widget.message!,
              style: TextStyle(
                color: iconColor,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
