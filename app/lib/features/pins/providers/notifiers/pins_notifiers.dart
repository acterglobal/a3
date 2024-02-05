import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter/features/pins/models/pin_edit_state/pin_edit_state.dart';
import 'package:acter/features/pins/providers/pins_provider.dart';
import 'package:acter/features/search/providers/pins.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AsyncPinsNotifier extends AutoDisposeAsyncNotifier<List<ActerPin>> {
  late Stream<void> _listener;

  Future<List<ActerPin>> _getPins() async {
    final client = ref.watch(alwaysClientProvider);
    return (await client.pins()).toList(); // this might throw internally
  }

  @override
  Future<List<ActerPin>> build() async {
    final client = ref.watch(alwaysClientProvider);
    _listener = client.subscribeStream('PINS'); // stay up to date
    _listener.forEach((e) async {
      state = await AsyncValue.guard(() => _getPins());
    });
    return _getPins();
  }
}

class AsyncPinNotifier
    extends AutoDisposeFamilyAsyncNotifier<ActerPin, String> {
  late Stream<void> _listener;

  Future<ActerPin> _getPin() async {
    final client = ref.watch(alwaysClientProvider);
    try {
      return await client.pin(arg);
    } catch (e) {
      return await client.waitForPin(arg, null);
    }
    // this might throw internally
  }

  @override
  Future<ActerPin> build(String arg) async {
    final client = ref.watch(alwaysClientProvider);
    _listener = client.subscribeStream(arg); // stay up to date
    _listener.forEach((e) async {
      state = await AsyncValue.guard(() => _getPin());
    });
    return _getPin();
  }
}

class AsyncSpacePinsNotifier
    extends AutoDisposeFamilyAsyncNotifier<List<ActerPin>, Space> {
  late Stream<void> _listener;

  Future<List<ActerPin>> _getPins() async {
    return (await arg.pins()).toList(); // this might throw internally
  }

  @override
  Future<List<ActerPin>> build(Space arg) async {
    final client = ref.watch(alwaysClientProvider);
    final spaceId = arg.getRoomId();
    _listener = client.subscribeStream('$spaceId::PINS'); // stay up to date
    _listener.forEach((e) async {
      state = await AsyncValue.guard(() => _getPins());
    });
    return _getPins();
  }
}

class PinEditNotifier extends StateNotifier<PinEditState> {
  final ActerPin pin;
  final Ref ref;
  PinEditNotifier({required this.pin, required this.ref})
      : super(
          const PinEditState(
            title: '',
            link: '',
          ),
        ) {
    _init();
  }

  void _init() {
    final msgContent = pin.contentText();
    String plainText = '';
    String? formattedBody;
    if (msgContent != null) {
      if (msgContent.formattedBody() != null) {
        formattedBody = msgContent.formattedBody();
      } else {
        plainText = msgContent.body();
      }
    }
    state = state.copyWith(
      title: pin.title(),
      link: pin.isLink() ? pin.url() ?? '' : '',
      plain: plainText,
      htmlBody: formattedBody,
    );
  }

  void setTitle(String title) => state = state.copyWith(title: title);

  void setLink(String link) => state = state.copyWith(link: link);

  void setPlainText(String text) => state = state.copyWith(plain: text);

  void setHtml(String? html) => state = state.copyWith(htmlBody: html);

  Future<String> onSave(BuildContext context) async {
    EasyLoading.show(status: 'Updating Pin');
    try {
      final updateBuilder = pin.updateBuilder();
      updateBuilder.title(state.title);
      if (pin.isLink()) {
        updateBuilder.url(state.link);
      }
      updateBuilder.contentText(state.plain);
      if (state.htmlBody != null) {
        updateBuilder.contentMarkdown(state.htmlBody!);
      }
      await updateBuilder.send();
      final updatedPin = await pin.refresh();
      // make sure we refresh the pin over list too.
      ref.invalidate(pinsProvider);
      ref.invalidate(spacePinsProvider);
      ref.invalidate(pinsFoundProvider);
      EasyLoading.dismiss();
      EasyLoading.showSuccess('Pin Updated Successfully');
      return updatedPin.eventIdStr();
    } catch (e) {
      EasyLoading.dismiss();
      EasyLoading.showError(e.toString());
      return e.toString();
    }
  }
}
