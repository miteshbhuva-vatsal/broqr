import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cpapp/features/auth/presentation/providers/auth_providers.dart';

const _kCityKey = 'feed_city_filter';

class CityPreferenceNotifier extends StateNotifier<String?> {
  CityPreferenceNotifier(this._ref) : super(null) {
    _initFuture = _init();
  }

  final Ref _ref;
  late final Future<void> _initFuture;

  /// Completes once SharedPreferences has been read on first build.
  Future<void> get initializationFuture => _initFuture;

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_kCityKey);
    if (saved != null) {
      state = saved;
    } else {
      // Default to the user's profile city on first launch
      final profileCity =
          _ref.read(authStateChangesProvider).valueOrNull?.city;
      if (profileCity != null && profileCity.isNotEmpty) {
        state = profileCity;
        await prefs.setString(_kCityKey, profileCity);
      }
    }
  }

  Future<void> setCity(String city) async {
    state = city;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kCityKey, city);
  }

  /// Called when user dismisses the first-login city prompt without selecting.
  /// Saves '' so the prompt is not shown again, but no city filter is applied.
  Future<void> skip() async {
    state = '';
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kCityKey, '');
  }

  Future<void> clearCity() async {
    state = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kCityKey);
  }
}

final cityPreferenceProvider =
    StateNotifierProvider<CityPreferenceNotifier, String?>((ref) {
  return CityPreferenceNotifier(ref);
});
