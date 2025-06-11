import 'package:flutter/foundation.dart';

class CurrentLocation {
  static double? latitude;
  static double? longitude;

  /// Whether GPS tracking is currently enabled
  static bool isTrackingEnabled = false;

  /// Notifier to let other widgets listen for changes
  static final ValueNotifier<bool> trackingNotifier =
  ValueNotifier<bool>(isTrackingEnabled);

  static void enableTracking() {
    isTrackingEnabled = true;
    trackingNotifier.value = true;
  }

  static void disableTracking() {
    isTrackingEnabled = false;
    trackingNotifier.value = false;
  }
}