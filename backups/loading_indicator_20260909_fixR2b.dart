// core/widgets/loading_indicator.dart
import 'package:flutter/material.dart';
import '../theme/app_dimensions.dart';

/// SPoT: Loading states - single source of truth
class LoadingIndicator extends StatelessWidget {
  final String? message;
  final double size;

  const LoadingIndicator({
    super.key,
    this.message,
    this.size = AppDimensions.buttonHeightSm,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: const CircularProgressIndicator(strokeWidth: 3),
          ),
          if (message != null) ...[
            SizedBox(height: AppDimensions.lg),
            Text(
              message!,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

/// Full-screen loading overlay
class LoadingOverlay extends StatelessWidget {
  final String? message;

  const LoadingOverlay({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black54,
      child: LoadingIndicator(message: message, size: AppDimensions.iconXl),
    );
  }
}
