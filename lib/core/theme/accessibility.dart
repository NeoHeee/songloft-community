import 'package:flutter/material.dart';

/// Centralized access to system accessibility preferences used by Songloft.
class AppAccessibility {
  AppAccessibility._();

  static double textScaleOf(BuildContext context) {
    return MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 2.0).toDouble();
  }

  static bool reduceMotionOf(BuildContext context) {
    return MediaQuery.disableAnimationsOf(context);
  }

  static Duration motionDuration(BuildContext context, Duration duration) {
    return reduceMotionOf(context) ? Duration.zero : duration;
  }
}
