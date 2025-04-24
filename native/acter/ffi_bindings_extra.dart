// These are dart extensions we add to the generated ffi bindings after
// processing.

class _FfiSupport {
  _FfiSupport._();

  static final DynamicLibrary dylib = _open();

  static DynamicLibrary _open() {
    if (Platform.isAndroid) return DynamicLibrary.open('libacter.so');
    if (Platform.isIOS) return DynamicLibrary.executable();
    if (Platform.isLinux) return DynamicLibrary.open('libacter.so');
    if (Platform.isMacOS) return DynamicLibrary.open('libacter.dylib');
    if (Platform.isWindows) return DynamicLibrary.open('acter.dll');
    throw UnsupportedError(
        'Unsupported platform: \${Platform.operatingSystem}');
  }

  static final _FfiSupport instance = _FfiSupport._();

  late final Pointer<Void> Function(
    Pointer<Void>,
  ) ffigen_to_uniffi_client = dylib.lookupFunction<
      Pointer<Void> Function(Pointer<Void>),
      Pointer<Void> Function(
          Pointer<Void>)>('acter_support_ffigen_client_to_uniffi_client');
}

extension UniffiClientExtension on ffi.Client {
  UniffiClient toUniffiClient() => UniffiClient.lift(_FfiSupport.instance
      .ffigen_to_uniffi_client(Pointer.fromAddress(address)));
}
