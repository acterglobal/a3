/// Based on https://github.com/gamako/shared_preferences_riverpod/blob/master/lib/shared_preferences_riverpod.dart
/// but bound to the specific client deviceIDs;
///
/// In essence this provides a SharedPreferences provider which, whenever set,
/// will store the current value under `$currentDeviceId-$prefKey` in the system
/// preference allowing the app to save and restore local app settings.
///
library;

import 'package:acter/common/providers/common_providers.dart';
import 'package:acter/features/main/providers/client_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk.dart';
import 'package:riverpod/riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The type parameter `T` is the type of value that will
/// be persisted in [SharedPreferences].
///
/// To update the value, use the [update()] function.
/// Direct assignment to state cannot be used.
///
/// ```dart
/// await watch(booPrefProvider.notifier).update(v);
/// ```
///
///
class PrefNotifier<T> extends StateNotifier<T> {
  PrefNotifier(this.prefKey, this.defaultValue) : super(defaultValue) {
    _init();
  }

  late SharedPreferences prefs;
  String prefKey;
  T defaultValue;

  void _init() async {
    prefs = await sharedPrefs();
    final newValue = (prefs.get(prefKey) as T? ?? defaultValue);
    state = newValue;
  }

  /// Updates the value asynchronously.
  Future<void> update(T value) async {
    if (value is String) {
      await prefs.setString(prefKey, value);
    } else if (value is bool) {
      await prefs.setBool(prefKey, value);
    } else if (value is int) {
      await prefs.setInt(prefKey, value);
    } else if (value is double) {
      await prefs.setDouble(prefKey, value);
    } else if (value is List<String>) {
      await prefs.setStringList(prefKey, value);
    }
    super.state = value;
  }

  /// Do not use the setter for state.
  /// Instead, use `await update(value).`
  @override
  set state(T value) {
    assert(
      false,
      'Don’t use the setter for state. Instead use `await update(value)`.',
    );
    Future(() async {
      await update(value);
    });
  }
}

/// Returns the [Provider] that has access to the value of preferences.
///
/// Persist the value of the type parameter T type in SharedPreferences.
/// The argument [prefs] specifies an instance of SharedPreferences.
/// The arguments [prefKey] and [defaultValue] specify the key name and default
/// value of the preference.
///
/// ```dart
///
/// Future<void> main() async {
///   WidgetsFlutterBinding.ensureInitialized();
///
///   final prefs = await SharedPreferences.getInstance();
///
///   final booPrefProvider = createPrefProvider<bool>(
///     prefs: (_) => prefs,
///     prefKey: "boolValue",
///     defaultValue: false,
///   );
///
/// ```
///
/// When referring to a value, use it as you would a regular provider.
///
/// ```dart
///
///   Consumer(builder: (context, watch, _) {
///     final value = watch(booPrefProvider);
///
/// ```
///
/// To change the value, use the update() method.
///
/// ```dart
///
///   await watch(booPrefProvider.notifier).update(true);
///
/// ```
///
StateNotifierProvider<PrefNotifier<T>, T> createPrefProvider<T>({
  required String prefKey,
  required T defaultValue,
}) {
  return StateNotifierProvider<PrefNotifier<T>, T>((ref) {
    final clientId =
        ref.watch(alwaysClientProvider.select((v) => v.deviceId().toString()));
    return PrefNotifier<T>('$clientId-$prefKey', defaultValue);
  });
}

/// Converts the value of type parameter `T` to a String and persists
/// it in SharedPreferences.
///
/// To update the value, use the [update()] function.
/// Direct assignment to state cannot be used.
///
/// ```dart
/// await watch(mapPrefProvider.notifier).update(v);
/// ```
///
class MapPrefNotifier<T> extends StateNotifier<T> {
  MapPrefNotifier(this.prefKey, this.mapFrom, this.mapTo)
      : super(mapFrom(null)) {
    _init();
  }

  late SharedPreferences prefs;
  String prefKey;
  T Function(String?) mapFrom;
  String Function(T) mapTo;

  void _init() async {
    prefs = await sharedPrefs();
    final newValue = mapFrom(prefs.getString(prefKey));
    super.state = newValue;
  }

  /// Updates the value asynchronously.
  Future<void> update(T value) async {
    await prefs.setString(prefKey, mapTo(value));
    super.state = value;
  }

  /// Do not use the setter for state.
  /// Instead, use `await update(value).`
  @override
  set state(T value) {
    assert(
      false,
      'Don’t use the setter for state. Instead use `await update(value)`.',
    );
    Future(() async {
      await update(value);
    });
  }
}

/// Returns a [Provider] that can access the preference with any type you want.
///
/// Persist to SharePreferences after converting to String.
/// The argument [prefs] specifies an instance of SharedPreferences.
/// The arguments [prefKey] and [defaultValue] specify the key name and default
/// value of the preference.
/// Specify how to convert from String to type T in [mapFrom].
/// Specifies how to convert from type T to String in [mapTo].
///
/// ```dart
///
/// enum EnumValues {
///   foo,
///   bar,
/// }
///
/// Future<void> main() async {
///   WidgetsFlutterBinding.ensureInitialized();
///
///   final prefs = await SharedPreferences.getInstance();
///
///   final enumPrefProvider = createMapPrefProvider<EnumValues>(
///     prefs: (_) => prefs,
///     prefKey: "enumValue",
///     mapFrom: (v) => EnumValues.values
///         .firstWhere((e) => e.toString() == v, orElse: () => EnumValues.foo),
///     mapTo: (v) => v.toString(),
///   );
///
/// ```
///
/// When referring to a value, use it as you would a regular provider.
///
/// ```dart
///
///   Consumer(builder: (context, watch, _) {
///     final value = watch(enumPrefProvider);
///
/// ```
///
/// To change the value, use the update() method.
///
/// ```dart
///
///   await watch(enumPrefProvider.notifier).update(EnumValues.bar);
///
/// ```
///
StateNotifierProvider<MapPrefNotifier<T>, T> createMapPrefProvider<T>({
  required String prefKey,
  required T Function(String?) mapFrom,
  required String Function(T) mapTo,
}) {
  return StateNotifierProvider<MapPrefNotifier<T>, T>((ref) {
    final clientId = ref.watch(deviceIdProvider);
    return MapPrefNotifier<T>('$clientId-$prefKey', mapFrom, mapTo);
  });
}
