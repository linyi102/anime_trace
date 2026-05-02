import 'dart:ui';

extension ColorExtensions on Color {
  Color withOpacityFactor(double opacity) {
    return withValues(alpha: opacity);
  }
}
