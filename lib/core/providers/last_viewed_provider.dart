import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/last_viewed_service.dart';

/// SharedPreferences Provider
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPreferencesProvider must be overridden');
});

/// LastViewedService Provider
final lastViewedServiceProvider = Provider<LastViewedService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return LastViewedService(prefs);
});
