import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:ffi/ffi.dart';
import 'package:isolate/ports.dart';

import 'effektio-ffi.dart';

// ignore_for_file: unused_import, camel_case_types, non_constant_identifier_names
final DynamicLibrary _dl = _open();

/// Reference to the Dynamic Library, it should be only used for low-level access
DynamicLibrary _open() {
  if (Platform.isAndroid) return DynamicLibrary.open('libeffektio.so');
  if (Platform.isIOS) return DynamicLibrary.executable();
  throw UnsupportedError('This platform is not supported.');
}

/// Binding to `allo-isolate` crate
void store_dart_post_cobject(
  Pointer<NativeFunction<Int8 Function(Int64, Pointer<Dart_CObject>)>> ptr,
) {
  _store_dart_post_cobject(ptr);
}

final _store_dart_post_cobject_Dart _store_dart_post_cobject = _dl
    .lookupFunction<_store_dart_post_cobject_C, _store_dart_post_cobject_Dart>(
        'store_dart_post_cobject');
typedef _store_dart_post_cobject_C = Void Function(
  Pointer<NativeFunction<Int8 Function(Int64, Pointer<Dart_CObject>)>> ptr,
);
typedef _store_dart_post_cobject_Dart = void Function(
  Pointer<NativeFunction<Int8 Function(Int64, Pointer<Dart_CObject>)>> ptr,
);
final EffektioFFI sdk = EffektioFFI(_dl);

class EffekioSdk {
  static setup() {
    // give rust `allo-isolate` package a ref to the `NativeApi.postCObject` function.
    store_dart_post_cobject(NativeApi.postCObject);
    print("Effektio FFI Setup Done");
  }

  static const MethodChannel _channel = MethodChannel('effektio_flutter_sdk');

  static Future<String?> get platformVersion async {
    final String? version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }

  Future<String> echo(String url) {
    print("Attempting echo ${url}");
    var urlPointer = url.toNativeUtf8();
    final completer = Completer<String>();
    final sendPort = singleCompletePort(completer);
    final res = sdk.echo(
      sendPort.nativePort,
      urlPointer.cast<Int8>(),
    );
    print("it returned: ${res}");
    if (res != 1) {
      _throwError();
    }
    return completer.future;
  }

  void _throwError() {
    final length = sdk.last_error_length();
    final Pointer<Int8> message = calloc.allocate(length);
    sdk.error_message_utf8(message, length);
    final error = message.cast<Utf8>().toDartString();
    print(error);
    throw error;
  }
}
