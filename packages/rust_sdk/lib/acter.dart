library uniffi;

import "dart:async";
import "dart:convert";
import "dart:ffi";
import "dart:io" show Platform, File, Directory;
import "dart:isolate";
import "dart:typed_data";
import "package:ffi/ffi.dart";

class UniffiInternalError implements Exception {
  static const int bufferOverflow = 0;
  static const int incompleteData = 1;
  static const int unexpectedOptionalTag = 2;
  static const int unexpectedEnumCase = 3;
  static const int unexpectedNullPointer = 4;
  static const int unexpectedRustCallStatusCode = 5;
  static const int unexpectedRustCallError = 6;
  static const int unexpectedStaleHandle = 7;
  static const int rustPanic = 8;

  final int errorCode;
  final String? panicMessage;

  const UniffiInternalError(this.errorCode, this.panicMessage);

  static UniffiInternalError panicked(String message) {
    return UniffiInternalError(rustPanic, message);
  }

  @override
  String toString() {
    switch (errorCode) {
      case bufferOverflow:
        return "UniFfi::BufferOverflow";
      case incompleteData:
        return "UniFfi::IncompleteData";
      case unexpectedOptionalTag:
        return "UniFfi::UnexpectedOptionalTag";
      case unexpectedEnumCase:
        return "UniFfi::UnexpectedEnumCase";
      case unexpectedNullPointer:
        return "UniFfi::UnexpectedNullPointer";
      case unexpectedRustCallStatusCode:
        return "UniFfi::UnexpectedRustCallStatusCode";
      case unexpectedRustCallError:
        return "UniFfi::UnexpectedRustCallError";
      case unexpectedStaleHandle:
        return "UniFfi::UnexpectedStaleHandle";
      case rustPanic:
        return "UniFfi::rustPanic: \$\$panicMessage";
      default:
        return "UniFfi::UnknownError: \$\$errorCode";
    }
  }
}

const int CALL_SUCCESS = 0;
const int CALL_ERROR = 1;
const int CALL_UNEXPECTED_ERROR = 2;

class RustCallStatus extends Struct {
  @Int8()
  external int code;

  external RustBuffer errorBuf;
}

void checkCallStatus(
    UniffiRustCallStatusErrorHandler errorHandler, RustCallStatus status) {
  if (status.code == CALL_SUCCESS) {
    return;
  } else if (status.code == CALL_ERROR) {
    throw errorHandler.lift(status.errorBuf);
  } else if (status.code == CALL_UNEXPECTED_ERROR) {
    if (status.errorBuf.len > 0) {
      throw UniffiInternalError.panicked(
          FfiConverterString.lift(status.errorBuf));
    } else {
      throw UniffiInternalError.panicked("Rust panic");
    }
  } else {
    throw UniffiInternalError.panicked(
        "Unexpected RustCallStatus code: \${status.code}");
  }
}

T rustCall<T>(T Function(Pointer<RustCallStatus>) callback) {
  final status = calloc<RustCallStatus>();
  try {
    return callback(status);
  } finally {
    calloc.free(status);
  }
}

class NullRustCallStatusErrorHandler extends UniffiRustCallStatusErrorHandler {
  @override
  Exception lift(RustBuffer errorBuf) {
    errorBuf.free();
    return UniffiInternalError.panicked("Unexpected CALL_ERROR");
  }
}

abstract class UniffiRustCallStatusErrorHandler {
  Exception lift(RustBuffer errorBuf);
}

class RustBuffer extends Struct {
  @Uint64()
  external int capacity;

  @Uint64()
  external int len;

  external Pointer<Uint8> data;

  static RustBuffer alloc(int size) {
    return rustCall((status) =>
        _UniffiLib.instance.ffi_acter_rustbuffer_alloc(size, status));
  }

  static RustBuffer fromBytes(ForeignBytes bytes) {
    return rustCall((status) =>
        _UniffiLib.instance.ffi_acter_rustbuffer_from_bytes(bytes, status));
  }

  void free() {
    rustCall((status) =>
        _UniffiLib.instance.ffi_acter_rustbuffer_free(this, status));
  }

  RustBuffer reserve(int additionalCapacity) {
    return rustCall((status) => _UniffiLib.instance
        .ffi_acter_rustbuffer_reserve(this, additionalCapacity, status));
  }

  Uint8List asUint8List() {
    final dataList = data.asTypedList(len);
    final byteData = ByteData.sublistView(dataList);
    return Uint8List.view(byteData.buffer);
  }

  @override
  String toString() {
    return "RustBuffer{capacity: \$capacity, len: \$len, data: \$data}";
  }
}

RustBuffer toRustBuffer(Uint8List data) {
  final length = data.length;

  final Pointer<Uint8> frameData = calloc<Uint8>(length);
  final pointerList = frameData.asTypedList(length);
  pointerList.setAll(0, data);

  final bytes = calloc<ForeignBytes>();
  bytes.ref.len = length;
  bytes.ref.data = frameData;
  return RustBuffer.fromBytes(bytes.ref);
}

class ForeignBytes extends Struct {
  @Int32()
  external int len;
  external Pointer<Uint8> data;

  void free() {
    calloc.free(data);
  }
}

class LiftRetVal<T> {
  final T value;
  final int bytesRead;
  const LiftRetVal(this.value, this.bytesRead);

  LiftRetVal<T> copyWithOffset(int offset) {
    return LiftRetVal(value, bytesRead + offset);
  }
}

abstract class FfiConverter<D, F> {
  const FfiConverter();

  D lift(F value);
  F lower(D value);
  D read(ByteData buffer, int offset);
  void write(D value, ByteData buffer, int offset);
  int size(D value);
}

mixin FfiConverterPrimitive<T> on FfiConverter<T, T> {
  @override
  T lift(T value) => value;

  @override
  T lower(T value) => value;
}

Uint8List createUint8ListFromInt(int value) {
  int length = value.bitLength ~/ 8 + 1;

  if (length != 4 && length != 8) {
    length = (value < 0x100000000) ? 4 : 8;
  }

  Uint8List uint8List = Uint8List(length);

  for (int i = length - 1; i >= 0; i--) {
    uint8List[i] = value & 0xFF;
    value >>= 8;
  }

  return uint8List;
}

class FfiConverterString {
  static String lift(RustBuffer buf) {
    return utf8.decoder.convert(buf.asUint8List());
  }

  static RustBuffer lower(String value) {
    return toRustBuffer(Utf8Encoder().convert(value));
  }

  static LiftRetVal<String> read(Uint8List buf) {
    final end = buf.buffer.asByteData(buf.offsetInBytes).getInt32(0) + 4;
    return LiftRetVal(utf8.decoder.convert(buf, 4, end), end);
  }

  static int allocationSize([String value = ""]) {
    return utf8.encoder.convert(value).length + 4;
  }

  static int write(String value, Uint8List buf) {
    final list = utf8.encoder.convert(value);
    buf.buffer.asByteData(buf.offsetInBytes).setInt32(0, list.length);
    buf.setAll(4, list);
    return list.length + 4;
  }
}

class FfiConverterBool {
  static bool lift(int value) {
    return value == 1;
  }

  static int lower(bool value) {
    return value ? 1 : 0;
  }

  static LiftRetVal<bool> read(Uint8List buf) {
    return LiftRetVal(FfiConverterBool.lift(buf.first), 1);
  }

  static RustBuffer lowerIntoRustBuffer(bool value) {
    return toRustBuffer(Uint8List.fromList([FfiConverterBool.lower(value)]));
  }

  static int allocationSize([bool value = false]) {
    return 1;
  }

  static int write(bool value, Uint8List buf) {
    buf.setAll(0, [value ? 1 : 0]);
    return allocationSize();
  }
}

const int UNIFFI_RUST_FUTURE_POLL_READY = 0;
const int UNIFFI_RUST_FUTURE_POLL_MAYBE_READY = 1;

typedef UniffiRustFutureContinuationCallback = Void Function(Uint64, Int8);

Future<T> uniffiRustCallAsync<T, F>(
  int Function() rustFutureFunc,
  void Function(int,
          Pointer<NativeFunction<UniffiRustFutureContinuationCallback>>, int)
      pollFunc,
  F Function(int, Pointer<RustCallStatus>) completeFunc,
  void Function(int) freeFunc,
  T Function(F) liftFunc, [
  UniffiRustCallStatusErrorHandler? errorHandler,
]) async {
  final rustFuture = rustFutureFunc();
  final completer = Completer<int>();

  late final NativeCallable<UniffiRustFutureContinuationCallback> callback;

  void poll() {
    pollFunc(
      rustFuture,
      callback.nativeFunction,
      0,
    );
  }

  void onResponse(int _idx, int pollResult) {
    if (pollResult == UNIFFI_RUST_FUTURE_POLL_READY) {
      completer.complete(pollResult);
    } else {
      poll();
    }
  }

  callback =
      NativeCallable<UniffiRustFutureContinuationCallback>.listener(onResponse);

  try {
    poll();
    await completer.future;
    callback.close();

    final status = calloc<RustCallStatus>();
    try {
      final result = completeFunc(rustFuture, status);

      return liftFunc(result);
    } finally {
      calloc.free(status);
    }
  } finally {
    freeFunc(rustFuture);
  }
}

class _UniffiLib {
  _UniffiLib._();

  static final DynamicLibrary _dylib = _open();

  static DynamicLibrary _open() {
    if (Platform.isAndroid) return DynamicLibrary.open("libacter.so");
    if (Platform.isIOS) return DynamicLibrary.executable();
    if (Platform.isLinux) return DynamicLibrary.open("libacter.so");
    if (Platform.isMacOS) return DynamicLibrary.open("libacter.dylib");
    if (Platform.isWindows) return DynamicLibrary.open("acter.dll");
    throw UnsupportedError(
        "Unsupported platform: \${Platform.operatingSystem}");
  }

  static final _UniffiLib instance = _UniffiLib._();

  late final RustBuffer Function(int, Pointer<RustCallStatus>)
      ffi_acter_rustbuffer_alloc = _dylib.lookupFunction<
          RustBuffer Function(Uint64, Pointer<RustCallStatus>),
          RustBuffer Function(
              int, Pointer<RustCallStatus>)>("ffi_acter_rustbuffer_alloc");
  late final RustBuffer Function(ForeignBytes, Pointer<RustCallStatus>)
      ffi_acter_rustbuffer_from_bytes = _dylib.lookupFunction<
          RustBuffer Function(ForeignBytes, Pointer<RustCallStatus>),
          RustBuffer Function(ForeignBytes,
              Pointer<RustCallStatus>)>("ffi_acter_rustbuffer_from_bytes");
  late final void Function(RustBuffer, Pointer<RustCallStatus>)
      ffi_acter_rustbuffer_free = _dylib.lookupFunction<
          Void Function(RustBuffer, Pointer<RustCallStatus>),
          void Function(RustBuffer,
              Pointer<RustCallStatus>)>("ffi_acter_rustbuffer_free");
  late final RustBuffer Function(RustBuffer, int, Pointer<RustCallStatus>)
      ffi_acter_rustbuffer_reserve = _dylib.lookupFunction<
          RustBuffer Function(RustBuffer, Uint64, Pointer<RustCallStatus>),
          RustBuffer Function(RustBuffer, int,
              Pointer<RustCallStatus>)>("ffi_acter_rustbuffer_reserve");
  late final void Function(
    int,
    Pointer<NativeFunction<UniffiRustFutureContinuationCallback>>,
    int,
  ) ffi_acter_rust_future_poll_u8 = _dylib.lookupFunction<
      Void Function(
        Uint64,
        Pointer<NativeFunction<UniffiRustFutureContinuationCallback>>,
        Uint64,
      ),
      void Function(
        int,
        Pointer<NativeFunction<UniffiRustFutureContinuationCallback>>,
        int,
      )>("ffi_acter_rust_future_poll_u8");
  late final void Function(
    int,
  ) ffi_acter_rust_future_cancel_u8 = _dylib.lookupFunction<
      Void Function(
        Uint64,
      ),
      void Function(
        int,
      )>("ffi_acter_rust_future_cancel_u8");
  late final void Function(
    int,
  ) ffi_acter_rust_future_free_u8 = _dylib.lookupFunction<
      Void Function(
        Uint64,
      ),
      void Function(
        int,
      )>("ffi_acter_rust_future_free_u8");
  late final int Function(int, Pointer<RustCallStatus>)
      ffi_acter_rust_future_complete_u8 = _dylib.lookupFunction<
          Uint8 Function(Uint64, Pointer<RustCallStatus>),
          int Function(int,
              Pointer<RustCallStatus>)>("ffi_acter_rust_future_complete_u8");
  late final void Function(
    int,
    Pointer<NativeFunction<UniffiRustFutureContinuationCallback>>,
    int,
  ) ffi_acter_rust_future_poll_i8 = _dylib.lookupFunction<
      Void Function(
        Uint64,
        Pointer<NativeFunction<UniffiRustFutureContinuationCallback>>,
        Uint64,
      ),
      void Function(
        int,
        Pointer<NativeFunction<UniffiRustFutureContinuationCallback>>,
        int,
      )>("ffi_acter_rust_future_poll_i8");
  late final void Function(
    int,
  ) ffi_acter_rust_future_cancel_i8 = _dylib.lookupFunction<
      Void Function(
        Uint64,
      ),
      void Function(
        int,
      )>("ffi_acter_rust_future_cancel_i8");
  late final void Function(
    int,
  ) ffi_acter_rust_future_free_i8 = _dylib.lookupFunction<
      Void Function(
        Uint64,
      ),
      void Function(
        int,
      )>("ffi_acter_rust_future_free_i8");
  late final int Function(int, Pointer<RustCallStatus>)
      ffi_acter_rust_future_complete_i8 = _dylib.lookupFunction<
          Int8 Function(Uint64, Pointer<RustCallStatus>),
          int Function(int,
              Pointer<RustCallStatus>)>("ffi_acter_rust_future_complete_i8");
  late final void Function(
    int,
    Pointer<NativeFunction<UniffiRustFutureContinuationCallback>>,
    int,
  ) ffi_acter_rust_future_poll_u16 = _dylib.lookupFunction<
      Void Function(
        Uint64,
        Pointer<NativeFunction<UniffiRustFutureContinuationCallback>>,
        Uint64,
      ),
      void Function(
        int,
        Pointer<NativeFunction<UniffiRustFutureContinuationCallback>>,
        int,
      )>("ffi_acter_rust_future_poll_u16");
  late final void Function(
    int,
  ) ffi_acter_rust_future_cancel_u16 = _dylib.lookupFunction<
      Void Function(
        Uint64,
      ),
      void Function(
        int,
      )>("ffi_acter_rust_future_cancel_u16");
  late final void Function(
    int,
  ) ffi_acter_rust_future_free_u16 = _dylib.lookupFunction<
      Void Function(
        Uint64,
      ),
      void Function(
        int,
      )>("ffi_acter_rust_future_free_u16");
  late final int Function(int, Pointer<RustCallStatus>)
      ffi_acter_rust_future_complete_u16 = _dylib.lookupFunction<
          Uint16 Function(Uint64, Pointer<RustCallStatus>),
          int Function(int,
              Pointer<RustCallStatus>)>("ffi_acter_rust_future_complete_u16");
  late final void Function(
    int,
    Pointer<NativeFunction<UniffiRustFutureContinuationCallback>>,
    int,
  ) ffi_acter_rust_future_poll_i16 = _dylib.lookupFunction<
      Void Function(
        Uint64,
        Pointer<NativeFunction<UniffiRustFutureContinuationCallback>>,
        Uint64,
      ),
      void Function(
        int,
        Pointer<NativeFunction<UniffiRustFutureContinuationCallback>>,
        int,
      )>("ffi_acter_rust_future_poll_i16");
  late final void Function(
    int,
  ) ffi_acter_rust_future_cancel_i16 = _dylib.lookupFunction<
      Void Function(
        Uint64,
      ),
      void Function(
        int,
      )>("ffi_acter_rust_future_cancel_i16");
  late final void Function(
    int,
  ) ffi_acter_rust_future_free_i16 = _dylib.lookupFunction<
      Void Function(
        Uint64,
      ),
      void Function(
        int,
      )>("ffi_acter_rust_future_free_i16");
  late final int Function(int, Pointer<RustCallStatus>)
      ffi_acter_rust_future_complete_i16 = _dylib.lookupFunction<
          Int16 Function(Uint64, Pointer<RustCallStatus>),
          int Function(int,
              Pointer<RustCallStatus>)>("ffi_acter_rust_future_complete_i16");
  late final void Function(
    int,
    Pointer<NativeFunction<UniffiRustFutureContinuationCallback>>,
    int,
  ) ffi_acter_rust_future_poll_u32 = _dylib.lookupFunction<
      Void Function(
        Uint64,
        Pointer<NativeFunction<UniffiRustFutureContinuationCallback>>,
        Uint64,
      ),
      void Function(
        int,
        Pointer<NativeFunction<UniffiRustFutureContinuationCallback>>,
        int,
      )>("ffi_acter_rust_future_poll_u32");
  late final void Function(
    int,
  ) ffi_acter_rust_future_cancel_u32 = _dylib.lookupFunction<
      Void Function(
        Uint64,
      ),
      void Function(
        int,
      )>("ffi_acter_rust_future_cancel_u32");
  late final void Function(
    int,
  ) ffi_acter_rust_future_free_u32 = _dylib.lookupFunction<
      Void Function(
        Uint64,
      ),
      void Function(
        int,
      )>("ffi_acter_rust_future_free_u32");
  late final int Function(int, Pointer<RustCallStatus>)
      ffi_acter_rust_future_complete_u32 = _dylib.lookupFunction<
          Uint32 Function(Uint64, Pointer<RustCallStatus>),
          int Function(int,
              Pointer<RustCallStatus>)>("ffi_acter_rust_future_complete_u32");
  late final void Function(
    int,
    Pointer<NativeFunction<UniffiRustFutureContinuationCallback>>,
    int,
  ) ffi_acter_rust_future_poll_i32 = _dylib.lookupFunction<
      Void Function(
        Uint64,
        Pointer<NativeFunction<UniffiRustFutureContinuationCallback>>,
        Uint64,
      ),
      void Function(
        int,
        Pointer<NativeFunction<UniffiRustFutureContinuationCallback>>,
        int,
      )>("ffi_acter_rust_future_poll_i32");
  late final void Function(
    int,
  ) ffi_acter_rust_future_cancel_i32 = _dylib.lookupFunction<
      Void Function(
        Uint64,
      ),
      void Function(
        int,
      )>("ffi_acter_rust_future_cancel_i32");
  late final void Function(
    int,
  ) ffi_acter_rust_future_free_i32 = _dylib.lookupFunction<
      Void Function(
        Uint64,
      ),
      void Function(
        int,
      )>("ffi_acter_rust_future_free_i32");
  late final int Function(int, Pointer<RustCallStatus>)
      ffi_acter_rust_future_complete_i32 = _dylib.lookupFunction<
          Int32 Function(Uint64, Pointer<RustCallStatus>),
          int Function(int,
              Pointer<RustCallStatus>)>("ffi_acter_rust_future_complete_i32");
  late final void Function(
    int,
    Pointer<NativeFunction<UniffiRustFutureContinuationCallback>>,
    int,
  ) ffi_acter_rust_future_poll_u64 = _dylib.lookupFunction<
      Void Function(
        Uint64,
        Pointer<NativeFunction<UniffiRustFutureContinuationCallback>>,
        Uint64,
      ),
      void Function(
        int,
        Pointer<NativeFunction<UniffiRustFutureContinuationCallback>>,
        int,
      )>("ffi_acter_rust_future_poll_u64");
  late final void Function(
    int,
  ) ffi_acter_rust_future_cancel_u64 = _dylib.lookupFunction<
      Void Function(
        Uint64,
      ),
      void Function(
        int,
      )>("ffi_acter_rust_future_cancel_u64");
  late final void Function(
    int,
  ) ffi_acter_rust_future_free_u64 = _dylib.lookupFunction<
      Void Function(
        Uint64,
      ),
      void Function(
        int,
      )>("ffi_acter_rust_future_free_u64");
  late final int Function(int, Pointer<RustCallStatus>)
      ffi_acter_rust_future_complete_u64 = _dylib.lookupFunction<
          Uint64 Function(Uint64, Pointer<RustCallStatus>),
          int Function(int,
              Pointer<RustCallStatus>)>("ffi_acter_rust_future_complete_u64");
  late final void Function(
    int,
    Pointer<NativeFunction<UniffiRustFutureContinuationCallback>>,
    int,
  ) ffi_acter_rust_future_poll_i64 = _dylib.lookupFunction<
      Void Function(
        Uint64,
        Pointer<NativeFunction<UniffiRustFutureContinuationCallback>>,
        Uint64,
      ),
      void Function(
        int,
        Pointer<NativeFunction<UniffiRustFutureContinuationCallback>>,
        int,
      )>("ffi_acter_rust_future_poll_i64");
  late final void Function(
    int,
  ) ffi_acter_rust_future_cancel_i64 = _dylib.lookupFunction<
      Void Function(
        Uint64,
      ),
      void Function(
        int,
      )>("ffi_acter_rust_future_cancel_i64");
  late final void Function(
    int,
  ) ffi_acter_rust_future_free_i64 = _dylib.lookupFunction<
      Void Function(
        Uint64,
      ),
      void Function(
        int,
      )>("ffi_acter_rust_future_free_i64");
  late final int Function(int, Pointer<RustCallStatus>)
      ffi_acter_rust_future_complete_i64 = _dylib.lookupFunction<
          Int64 Function(Uint64, Pointer<RustCallStatus>),
          int Function(int,
              Pointer<RustCallStatus>)>("ffi_acter_rust_future_complete_i64");
  late final void Function(
    int,
    Pointer<NativeFunction<UniffiRustFutureContinuationCallback>>,
    int,
  ) ffi_acter_rust_future_poll_f32 = _dylib.lookupFunction<
      Void Function(
        Uint64,
        Pointer<NativeFunction<UniffiRustFutureContinuationCallback>>,
        Uint64,
      ),
      void Function(
        int,
        Pointer<NativeFunction<UniffiRustFutureContinuationCallback>>,
        int,
      )>("ffi_acter_rust_future_poll_f32");
  late final void Function(
    int,
  ) ffi_acter_rust_future_cancel_f32 = _dylib.lookupFunction<
      Void Function(
        Uint64,
      ),
      void Function(
        int,
      )>("ffi_acter_rust_future_cancel_f32");
  late final void Function(
    int,
  ) ffi_acter_rust_future_free_f32 = _dylib.lookupFunction<
      Void Function(
        Uint64,
      ),
      void Function(
        int,
      )>("ffi_acter_rust_future_free_f32");
  late final double Function(int, Pointer<RustCallStatus>)
      ffi_acter_rust_future_complete_f32 = _dylib.lookupFunction<
          Float Function(Uint64, Pointer<RustCallStatus>),
          double Function(int,
              Pointer<RustCallStatus>)>("ffi_acter_rust_future_complete_f32");
  late final void Function(
    int,
    Pointer<NativeFunction<UniffiRustFutureContinuationCallback>>,
    int,
  ) ffi_acter_rust_future_poll_f64 = _dylib.lookupFunction<
      Void Function(
        Uint64,
        Pointer<NativeFunction<UniffiRustFutureContinuationCallback>>,
        Uint64,
      ),
      void Function(
        int,
        Pointer<NativeFunction<UniffiRustFutureContinuationCallback>>,
        int,
      )>("ffi_acter_rust_future_poll_f64");
  late final void Function(
    int,
  ) ffi_acter_rust_future_cancel_f64 = _dylib.lookupFunction<
      Void Function(
        Uint64,
      ),
      void Function(
        int,
      )>("ffi_acter_rust_future_cancel_f64");
  late final void Function(
    int,
  ) ffi_acter_rust_future_free_f64 = _dylib.lookupFunction<
      Void Function(
        Uint64,
      ),
      void Function(
        int,
      )>("ffi_acter_rust_future_free_f64");
  late final double Function(int, Pointer<RustCallStatus>)
      ffi_acter_rust_future_complete_f64 = _dylib.lookupFunction<
          Double Function(Uint64, Pointer<RustCallStatus>),
          double Function(int,
              Pointer<RustCallStatus>)>("ffi_acter_rust_future_complete_f64");
  late final void Function(
    int,
    Pointer<NativeFunction<UniffiRustFutureContinuationCallback>>,
    int,
  ) ffi_acter_rust_future_poll_pointer = _dylib.lookupFunction<
      Void Function(
        Uint64,
        Pointer<NativeFunction<UniffiRustFutureContinuationCallback>>,
        Uint64,
      ),
      void Function(
        int,
        Pointer<NativeFunction<UniffiRustFutureContinuationCallback>>,
        int,
      )>("ffi_acter_rust_future_poll_pointer");
  late final void Function(
    int,
  ) ffi_acter_rust_future_cancel_pointer = _dylib.lookupFunction<
      Void Function(
        Uint64,
      ),
      void Function(
        int,
      )>("ffi_acter_rust_future_cancel_pointer");
  late final void Function(
    int,
  ) ffi_acter_rust_future_free_pointer = _dylib.lookupFunction<
      Void Function(
        Uint64,
      ),
      void Function(
        int,
      )>("ffi_acter_rust_future_free_pointer");
  late final Pointer<Void> Function(int, Pointer<RustCallStatus>)
      ffi_acter_rust_future_complete_pointer = _dylib.lookupFunction<
              Pointer<Void> Function(Uint64, Pointer<RustCallStatus>),
              Pointer<Void> Function(int, Pointer<RustCallStatus>)>(
          "ffi_acter_rust_future_complete_pointer");
  late final void Function(
    int,
    Pointer<NativeFunction<UniffiRustFutureContinuationCallback>>,
    int,
  ) ffi_acter_rust_future_poll_rust_buffer = _dylib.lookupFunction<
      Void Function(
        Uint64,
        Pointer<NativeFunction<UniffiRustFutureContinuationCallback>>,
        Uint64,
      ),
      void Function(
        int,
        Pointer<NativeFunction<UniffiRustFutureContinuationCallback>>,
        int,
      )>("ffi_acter_rust_future_poll_rust_buffer");
  late final void Function(
    int,
  ) ffi_acter_rust_future_cancel_rust_buffer = _dylib.lookupFunction<
      Void Function(
        Uint64,
      ),
      void Function(
        int,
      )>("ffi_acter_rust_future_cancel_rust_buffer");
  late final void Function(
    int,
  ) ffi_acter_rust_future_free_rust_buffer = _dylib.lookupFunction<
      Void Function(
        Uint64,
      ),
      void Function(
        int,
      )>("ffi_acter_rust_future_free_rust_buffer");
  late final RustBuffer Function(int, Pointer<RustCallStatus>)
      ffi_acter_rust_future_complete_rust_buffer = _dylib.lookupFunction<
              RustBuffer Function(Uint64, Pointer<RustCallStatus>),
              RustBuffer Function(int, Pointer<RustCallStatus>)>(
          "ffi_acter_rust_future_complete_rust_buffer");
  late final void Function(
    int,
    Pointer<NativeFunction<UniffiRustFutureContinuationCallback>>,
    int,
  ) ffi_acter_rust_future_poll_void = _dylib.lookupFunction<
      Void Function(
        Uint64,
        Pointer<NativeFunction<UniffiRustFutureContinuationCallback>>,
        Uint64,
      ),
      void Function(
        int,
        Pointer<NativeFunction<UniffiRustFutureContinuationCallback>>,
        int,
      )>("ffi_acter_rust_future_poll_void");
  late final void Function(
    int,
  ) ffi_acter_rust_future_cancel_void = _dylib.lookupFunction<
      Void Function(
        Uint64,
      ),
      void Function(
        int,
      )>("ffi_acter_rust_future_cancel_void");
  late final void Function(
    int,
  ) ffi_acter_rust_future_free_void = _dylib.lookupFunction<
      Void Function(
        Uint64,
      ),
      void Function(
        int,
      )>("ffi_acter_rust_future_free_void");
  late final void Function(int, Pointer<RustCallStatus>)
      ffi_acter_rust_future_complete_void = _dylib.lookupFunction<
          Void Function(Uint64, Pointer<RustCallStatus>),
          void Function(int,
              Pointer<RustCallStatus>)>("ffi_acter_rust_future_complete_void");
  late final int Function() ffi_acter_uniffi_contract_version =
      _dylib.lookupFunction<Uint32 Function(), int Function()>(
          "ffi_acter_uniffi_contract_version");

  static void _checkApiVersion() {
    final bindingsVersion = 26;
    final scaffoldingVersion =
        _UniffiLib.instance.ffi_acter_uniffi_contract_version();
    if (bindingsVersion != scaffoldingVersion) {
      throw UniffiInternalError.panicked(
          "UniFFI contract version mismatch: bindings version \$bindingsVersion, scaffolding version \$scaffoldingVersion");
    }
  }

  static void _checkApiChecksums() {}
}

void initialize() {
  _UniffiLib._open();
}

void ensureInitialized() {
  _UniffiLib._checkApiVersion();
  _UniffiLib._checkApiChecksums();
}
