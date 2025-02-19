/// Based on https://github.com/gamako/shared_preferences_riverpod/blob/master/lib/shared_preferences_riverpod.dart
/// but bound to the specific client deviceIDs;
///
/// In essence this provides a SharedPreferences provider which, whenever set,
/// will store the current value under `$currentDeviceId-$prefKey` in the system
/// preference allowing the app to save and restore local app settings.
///
library;

import 'dart:async';

import 'package:acter/common/providers/common_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk.dart';
import 'package:riverpod/riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The type parameter `T` is the type of value that will
/// be persisted in [SharedPreferences].
///
/// To update the value, use the [set()] function.
/// Direct assignment to state cannot be used.
///
/// ```dart
/// await watch(booPrefProvider.notifier).set(v);
/// ```
///
///
class PrefNotifier<T> extends Notifier<T> {
  PrefNotifier(this.prefKeySuffix, this.defaultValue);

  final String prefKeySuffix;
  late String deviceId;
  late SharedPreferences prefs;

  String get prefKey => '$deviceId-$prefKeySuffix';
  T defaultValue;

  /// Updates the value asynchronously.
  Future<void> set(T value) async {
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

  @override
  T build() {
    _init();
    return defaultValue;
  }

  void _init() async {
    prefs = await sharedPrefs();
    deviceId = await ref.watch(deviceIdProvider.future);
    Future.delayed(Duration(milliseconds: 10), () {
      // make sure we do this _after_ the initial build function has passed
      state = (prefs.get(prefKey) as T? ?? defaultValue);
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
///   await watch(booPrefProvider.notifier).set(true);
///
/// ```
///
NotifierProvider<PrefNotifier<T>, T> createPrefProvider<T>({
  required String prefKey,
  required T defaultValue,
}) =>
    NotifierProvider<PrefNotifier<T>, T>(
      () => PrefNotifier<T>(prefKey, defaultValue),
    );

/// Converts the value of type parameter `T` to a String and persists
/// it in SharedPreferences.
///
/// To update the value, use the [set()] function.
/// Direct assignment to state cannot be used.
///
/// ```dart
/// await watch(mapPrefProvider.notifier).set(v);
/// ```
///
class MapPrefNotifier<T> extends Notifier<T> {
  MapPrefNotifier(this.prefKeySuffix, this.mapFrom, this.mapTo);

  late String deviceId;
  late SharedPreferences prefs;

  final String prefKeySuffix;
  T Function(String?) mapFrom;
  String Function(T) mapTo;

  String get prefKey => '$deviceId-$prefKeySuffix';

  void _init() async {
    deviceId = await ref.watch(deviceIdProvider.future);
    prefs = await sharedPrefs();
    final newValue = mapFrom(prefs.getString(prefKey));
    Future.delayed(Duration(milliseconds: 10), () {
      // make sure we do this _after_ the initial build function has passed
      state = newValue;
    });
  }

  /// Updates the value asynchronously.
  Future<void> set(T value) async {
    await prefs.setString(prefKey, mapTo(value));
    state = value;
  }

  @override
  T build() {
    _init();
    return mapFrom(null);
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
///   await watch(enumPrefProvider.notifier).set(EnumValues.bar);
///
/// ```
///
NotifierProvider<MapPrefNotifier<T>, T> createMapPrefProvider<T>({
  required String prefKey,
  required T Function(String?) mapFrom,
  required String Function(T) mapTo,
}) =>
    NotifierProvider<MapPrefNotifier<T>, T>(
      () => MapPrefNotifier<T>(prefKey, mapFrom, mapTo),
    );
