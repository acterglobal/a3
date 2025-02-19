import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const largeScreenBreakPoint = 770;

extension ActerBuildContext on BuildContext {
  bool get isLargeScreen =>
      MediaQuery.of(this).size.width >= largeScreenBreakPoint;

  /// Get provider right from the context no matter where we are
  // Custom call a provider for reading method only
  // It will be helpful for us for calling the read function
  // without Consumer,ConsumerWidget or ConsumerStatefulWidget
  // Incase if you face any issue using this then please wrap your widget
  // with consumer and then call your provider
  T read<T>(ProviderListenable<T> provider) {
    return ProviderScope.containerOf(this, listen: false).read(provider);
  }
}
