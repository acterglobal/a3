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

final EffektioFFI sdk = EffektioFFI(_dl);

class EffekioSdk {
  static const MethodChannel _channel = MethodChannel('effektio_flutter_sdk');

  static Future<String?> get platformVersion async {
    final String? version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }

  Future<String> loadPage(String url) {
    var urlPointer = url.toNativeUtf8();
    final completer = Completer<String>();
    final sendPort = singleCompletePort(completer);
    final res = sdk.load_page(
      sendPort.nativePort,
      urlPointer.cast<Int8>(),
    );
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
