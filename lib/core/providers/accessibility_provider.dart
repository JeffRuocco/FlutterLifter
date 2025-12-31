import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Accessibility settings state
class AccessibilityState {
  final bool reduceMotion;

  const AccessibilityState({
    this.reduceMotion = false,
  });

  AccessibilityState copyWith({
    bool? reduceMotion,
  }) {
    return AccessibilityState(
      reduceMotion: reduceMotion ?? this.reduceMotion,
    );
  }
}

/// Notifier for managing accessibility settings
class AccessibilityNotifier extends StateNotifier<AccessibilityState> {
  static const String _reduceMotionKey = 'accessibility_reduce_motion';

  AccessibilityNotifier() : super(const AccessibilityState()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final reduceMotion = prefs.getBool(_reduceMotionKey) ?? false;
    state = state.copyWith(reduceMotion: reduceMotion);
  }

  Future<void> setReduceMotion(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_reduceMotionKey, value);
    state = state.copyWith(reduceMotion: value);
  }

  Future<void> toggleReduceMotion() async {
    await setReduceMotion(!state.reduceMotion);
  }
}

/// Provider for accessibility settings
final accessibilityNotifierProvider =
    StateNotifierProvider<AccessibilityNotifier, AccessibilityState>((ref) {
  return AccessibilityNotifier();
});

/// Convenience provider for reduce motion setting
final reduceMotionProvider = Provider<bool>((ref) {
  return ref.watch(accessibilityNotifierProvider).reduceMotion;
});
