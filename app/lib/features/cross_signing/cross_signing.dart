import 'dart:async';
import 'dart:io' show Platform;

import 'package:acter/common/themes/app_theme.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart'
    show
        Client,
        DeviceChangedEvent,
        FfiListVerificationEmoji,
        VerificationEvent;
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:get/get.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:sprintf/sprintf.dart';

Widget elevatedButton(
  String title,
  Color color,
  VoidCallback? callback,
  TextStyle textstyle,
) {
  return ElevatedButton(
    onPressed: callback,
    style: ElevatedButton.styleFrom(
      backgroundColor: color,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
    ),
    child: Text(title, style: textstyle),
  );
}

class VerifEvent {
  bool verifyingThisDev;
  String stage;

  VerifEvent({
    required this.verifyingThisDev,
    required this.stage,
  });
}

class CrossSigning {
  Client client;
  bool acceptingRequest = false;
  bool waitForMatch = false;
  late StreamSubscription<DeviceChangedEvent>? _deviceSubscription;
  late StreamSubscription<VerificationEvent>? _verificationSubscription;
  final Map<String, VerifEvent> _eventMap = {};
  bool _mounted = true;
  bool isDesktop = Platform.isWindows || Platform.isMacOS || Platform.isLinux;

  CrossSigning({required this.client}) {
    _installDeviceEvent();
    _installVerificationEvent();
  }

  void dispose() {
    _mounted = false;
    _deviceSubscription?.cancel();
    _verificationSubscription?.cancel();
  }

  void _installDeviceEvent() {
    _deviceSubscription = client.deviceChangedEventRx()?.listen((event) async {
      var records = await event.deviceRecords(false);
      for (var record in records) {
        debugPrint('found device id: ' + record.deviceId().toString());
      }

      if (!_shouldShowNewDevicePopup()) {
        return;
      }
      showSimpleNotification(
        ListTile(
          leading:
              isDesktop ? const Icon(Atlas.laptop) : const Icon(Atlas.phone),
          title: const Text(
            'New Session Alert',
          ),
          subtitle: const Text(
            'Tap to review and verify!',
          ),
        ),
        duration: const Duration(seconds: 1),
      );
    });
  }

  bool _shouldShowNewDevicePopup() {
    // between `m.key.verification.mac` event and `m.key.verification.done` event,
    // device changed event occurs automatically.
    // on this event, `New device` popup must not appear.
    // thus skip this event.
    bool result = true;
    _eventMap.forEach((key, value) {
      if (value.stage == 'm.key.verification.mac') {
        result = false;
        return;
      }
    });
    return result;
  }

  void _installVerificationEvent() {
    _verificationSubscription = client.verificationEventRx()?.listen((event) {
      String eventType = event.eventType();
      debugPrint(eventType);
      switch (eventType) {
        case 'm.key.verification.request':
          _onKeyVerificationRequest(event);
          break;
        case 'm.key.verification.ready':
          _onKeyVerificationReady(event, false);
          break;
        case 'm.key.verification.start':
          _onKeyVerificationStart(event);
          break;
        case 'm.key.verification.cancel':
          _onKeyVerificationCancel(event, false);
          break;
        case 'm.key.verification.accept':
          _onKeyVerificationAccept(event);
          break;
        case 'm.key.verification.key':
          _onKeyVerificationKey(event);
          break;
        case 'm.key.verification.mac':
          _onKeyVerificationMac(event);
          break;
        case 'm.key.verification.done':
          _onKeyVerificationDone(event);
          break;
      }
    });
  }

  void _onKeyVerificationRequest(VerificationEvent event) {
    String? flowId = event.flowId();
    if (flowId == null || _eventMap.containsKey(flowId)) {
      return;
    }
    // this case is bob side
    _eventMap[flowId] = VerifEvent(
      verifyingThisDev: true,
      stage: 'm.key.verification.request',
    );
    acceptingRequest = false;
    Get.bottomSheet(
      StatefulBuilder(
        builder: (context, setState) => Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
          ),
          child: _buildOnRequest(context, event, flowId, setState),
        ),
      ),
      isDismissible: false,
    );
  }

  Widget _buildOnRequest(
    BuildContext context,
    VerificationEvent event,
    String flowId,
    Function setState,
  ) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          flex: isDesktop ? 2 : 1,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: isDesktop
                      ? const Icon(Atlas.laptop)
                      : const Icon(Atlas.phone),
                ),
                Text(
                  AppLocalizations.of(context)!.sasIncomingReqNotifTitle,
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () async {
                      // cancel verification request from other device
                      await event.cancelVerificationRequest();
                      Get.back();
                      _eventMap.remove(flowId);
                    },
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
        Flexible(
          flex: 1,
          child: Text(
            sprintf(
              AppLocalizations.of(context)!.sasIncomingReqNotifContent,
              [event.sender()],
            ),
          ),
        ),
        const Spacer(flex: 1),
        const Flexible(
          flex: 3,
          child: Icon(Atlas.lock_keyhole),
        ),
        const Spacer(flex: 1),
        Flexible(flex: 1, child: _buildBodyOnRequest(context, event, setState)),
        const Spacer(flex: 1),
      ],
    );
  }

  Widget _buildBodyOnRequest(
    BuildContext context,
    VerificationEvent event,
    Function setState,
  ) {
    if (acceptingRequest) {
      return const CircularProgressIndicator();
    }
    return elevatedButton(
      AppLocalizations.of(context)!.acceptRequest,
      Theme.of(context).colorScheme.success,
      () async {
        if (_mounted) {
          setState(() => acceptingRequest = true);
        }
        // accept verification request from other device
        await event.acceptVerificationRequest();
        // go to onReady status
        Get.back();
        Future.delayed(const Duration(milliseconds: 500), () {
          _onKeyVerificationReady(event, true);
        });
      },
      const TextStyle(),
    );
  }

  void _onKeyVerificationReady(VerificationEvent event, bool manual) {
    String? flowId = event.flowId();
    if (flowId == null) {
      return;
    }
    if (manual) {
      _eventMap[flowId]!.stage = 'm.key.verification.ready';
    } else {
      // this device is alice side
      _eventMap[flowId] = VerifEvent(
        verifyingThisDev: false,
        stage: 'm.key.verification.ready',
      );
    }
    Get.bottomSheet(
      StatefulBuilder(
        builder: (context, setState) => Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
          ),
          child: _buildOnReady(context, event, flowId),
        ),
      ),
      isDismissible: false,
    );
  }

  Widget _buildOnReady(
    BuildContext context,
    VerificationEvent event,
    String flowId,
  ) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          flex: 1,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  child: isDesktop
                      ? const Icon(Atlas.laptop)
                      : const Icon(Atlas.phone),
                ),
                const SizedBox(width: 5),
                Text(
                  _eventMap[flowId]!.verifyingThisDev
                      ? AppLocalizations.of(context)!.verifyThisSession
                      : AppLocalizations.of(context)!.verifySession,
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () async {
                      // cancel the current verification
                      await event.cancelVerificationRequest();
                      // finish verification
                      Get.back();
                      _eventMap.remove(flowId);
                    },
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
        Flexible(
          flex: 1,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
            child: Text(
              AppLocalizations.of(context)!.verificationScanSelfNotice,
            ),
          ),
        ),
        const Flexible(
          flex: 2,
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(25),
              child: SizedBox(
                width: 50,
                height: 50,
                child: CircularProgressIndicator(),
              ),
            ),
          ),
        ),
        Flexible(
          flex: 1,
          child: TextButton(
            onPressed: () {},
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Padding(
                  padding: EdgeInsets.all(8),
                  child: Icon(Atlas.camera),
                ),
                Text(
                  AppLocalizations.of(context)!.verificationScanWithThisDevice,
                ),
              ],
            ),
          ),
        ),
        Flexible(
          flex: 1,
          child: Wrap(
            children: [
              ListTile(
                title: Text(
                  AppLocalizations.of(context)!.verificationScanEmojiTitle,
                ),
                subtitle: Text(
                  AppLocalizations.of(context)!
                      .verificationScanSelfEmojiSubtitle,
                ),
                trailing: const Icon(
                  Icons.keyboard_arrow_right_outlined,
                ),
                onTap: () async {
                  // start sas verification from this device
                  await event.startSasVerification();
                  // go to onStart status
                  _onKeyVerificationStart(event);
                },
              ),
            ],
          ),
        ),
        const Spacer(flex: 1),
      ],
    );
  }

  void _onKeyVerificationStart(VerificationEvent event) {
    if (Get.isBottomSheetOpen == true) {
      Get.back();
    }
    String? flowId = event.flowId();
    if (flowId == null) {
      return;
    }
    if (_eventMap[flowId]?.stage != 'm.key.verification.request' &&
        _eventMap[flowId]?.stage != 'm.key.verification.ready') {
      return;
    }
    _eventMap[flowId]?.stage = 'm.key.verification.start';
    Get.bottomSheet(
      StatefulBuilder(
        builder: (context, setState) => Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
          ),
          child: _buildOnStart(context, event, flowId),
        ),
      ),
      isDismissible: false,
    );
    // accept the sas verification that other device started
    Future.delayed(const Duration(milliseconds: 500), () async {
      await event.acceptSasVerification();
    });
  }

  Widget _buildOnStart(
    BuildContext context,
    VerificationEvent event,
    String flowId,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          flex: 1,
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                child: isDesktop
                    ? const Icon(Atlas.laptop)
                    : const Icon(Atlas.phone),
              ),
              const SizedBox(width: 5),
              Text(
                _eventMap[flowId]?.verifyingThisDev == true
                    ? AppLocalizations.of(context)!.verifyThisSession
                    : AppLocalizations.of(context)!.verifySession,
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () async {
                    // cancel sas verification
                    await event.cancelSasVerification();
                    // go to onCancel status
                    _onKeyVerificationCancel(event, true);
                  },
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        const Flexible(
          flex: 3,
          child: Center(
            child: SizedBox(
              height: 100,
              width: 100,
              child: CircularProgressIndicator(),
            ),
          ),
        ),
        Flexible(
          flex: 1,
          child: Center(
            child: Text(
              AppLocalizations.of(context)!.pleaseWait,
            ),
          ),
        ),
        const Spacer(flex: 1),
      ],
    );
  }

  void _onKeyVerificationCancel(VerificationEvent event, bool manual) {
    if (Get.isBottomSheetOpen == true) {
      Get.back();
    }
    String? flowId = event.flowId();
    if (flowId == null) {
      return;
    }
    _eventMap[flowId]?.stage = 'm.key.verification.cancel';
    Get.bottomSheet(
      StatefulBuilder(
        builder: (context, setState) => Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
          ),
          child: _buildOnCancel(context, event, flowId, manual),
        ),
      ),
    );
  }

  Widget _buildOnCancel(
    BuildContext context,
    VerificationEvent event,
    String flowId,
    bool manual,
  ) {
    if (manual) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            flex: isDesktop ? 2 : 1,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    child: isDesktop
                        ? const Icon(Atlas.laptop)
                        : const Icon(Atlas.phone),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    _eventMap[flowId]?.verifyingThisDev == true
                        ? AppLocalizations.of(context)!.verifyThisSession
                        : AppLocalizations.of(context)!.verifySession,
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ),
          const Flexible(
            flex: 3,
            child: Center(
              child: Icon(Atlas.lock_keyhole),
            ),
          ),
          Flexible(
            flex: isDesktop ? 4 : 3,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: Text(
                AppLocalizations.of(context)!.verificationConclusionCompromised,
                softWrap: false,
              ),
            ),
          ),
          const Spacer(flex: 1),
          Flexible(
            flex: 1,
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.40,
              child: elevatedButton(
                AppLocalizations.of(context)!.sasGotIt,
                Theme.of(context).colorScheme.success,
                () {
                  // finish verification
                  Get.back();
                  _eventMap.remove(flowId);
                },
                const TextStyle(),
              ),
            ),
          ),
          const Spacer(flex: 1),
        ],
      );
    } else {
      return Column(
        mainAxisAlignment: MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            flex: isDesktop ? 2 : 1,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    child: isDesktop
                        ? const Icon(Atlas.laptop)
                        : const Icon(Atlas.phone),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    _eventMap[flowId]?.verifyingThisDev == true
                        ? AppLocalizations.of(context)!.verifyThisSession
                        : AppLocalizations.of(context)!.verifySession,
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ),
          const Spacer(flex: 1),
          const Flexible(
            flex: 3,
            child: Icon(Atlas.lock_keyhole),
          ),
          Flexible(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                event.reason()!,
              ),
            ),
          ),
          const Spacer(flex: 1),
          Flexible(
            flex: 1,
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.40,
              child: elevatedButton(
                AppLocalizations.of(context)!.sasGotIt,
                Theme.of(context).colorScheme.success,
                () {
                  // finish verification
                  Get.back();
                  _eventMap.remove(flowId);
                },
                const TextStyle(),
              ),
            ),
          ),
          const Spacer(flex: 1),
        ],
      );
    }
  }

  void _onKeyVerificationAccept(VerificationEvent event) {
    if (Get.isBottomSheetOpen == true) {
      Get.back();
    }
    String? flowId = event.flowId();
    if (flowId == null) {
      return;
    }
    _eventMap[flowId]?.stage = 'm.key.verification.accept';
    Get.bottomSheet(
      StatefulBuilder(
        builder: (context, setState) => Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
          ),
          child: _buildOnAccept(context, event, flowId),
        ),
      ),
    );
  }

  Widget _buildOnAccept(
    BuildContext context,
    VerificationEvent event,
    String flowId,
  ) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          flex: isDesktop ? 2 : 1,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  child: isDesktop
                      ? const Icon(Atlas.laptop)
                      : const Icon(Atlas.phone),
                ),
                const SizedBox(width: 5),
                Text(
                  _eventMap[flowId]?.verifyingThisDev == true
                      ? AppLocalizations.of(context)!.verifyThisSession
                      : AppLocalizations.of(context)!.verifySession,
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
        const Spacer(flex: 1),
        const Flexible(
          flex: 3,
          child: Center(
            child: SizedBox(
              height: 100,
              width: 100,
              child: CircularProgressIndicator(),
            ),
          ),
        ),
        const Spacer(flex: 1),
        Flexible(
          flex: 2,
          child: Text(
            sprintf(
              AppLocalizations.of(context)!.verificationRequestWaitingFor,
              [event.sender()],
            ),
          ),
        ),
        const Spacer(flex: 1),
      ],
    );
  }

  void _onKeyVerificationKey(VerificationEvent event) {
    if (Get.isBottomSheetOpen == true) {
      Get.back();
    }
    String? flowId = event.flowId();
    if (flowId == null) {
      return;
    }
    _eventMap[flowId]?.stage = 'm.key.verification.key';
    event.getVerificationEmoji().then((emoji) {
      Get.bottomSheet(
        StatefulBuilder(
          builder: (context, setState) => Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
            ),
            child: _buildOnKey(context, event, flowId, emoji, setState),
          ),
        ),
        isDismissible: false,
      );
    });
  }

  Widget _buildOnKey(
    BuildContext context,
    VerificationEvent event,
    String flowId,
    FfiListVerificationEmoji emoji,
    Function setState,
  ) {
    List<int> emojiCodes = emoji.map((e) => e.symbol()).toList();
    List<String> emojiDescriptions = emoji.map((e) => e.description()).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.max,
      children: [
        Expanded(
          flex: isDesktop ? 1 : 2,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  child: isDesktop
                      ? const Icon(Atlas.laptop)
                      : const Icon(Atlas.phone),
                ),
                const SizedBox(width: 5),
                Text(
                  _eventMap[flowId]?.verifyingThisDev == true
                      ? AppLocalizations.of(context)!.verifyThisSession
                      : AppLocalizations.of(context)!.verifySession,
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () async {
                      // cancel key verification
                      await event.cancelVerificationKey();
                      // go to onCancel status
                      _onKeyVerificationCancel(event, true);
                    },
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          flex: isDesktop ? 1 : 2,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Text(
              AppLocalizations.of(context)!.verificationEmojiNotice,
            ),
          ),
        ),
        const Spacer(flex: 1),
        Expanded(
          flex: isDesktop ? 2 : 7,
          child: Center(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsets.only(top: 10),
                child: GridView.count(
                  crossAxisCount: isDesktop ? 7 : 4,
                  children: List.generate(emoji.length, (index) {
                    return GridTile(
                      child: Column(
                        children: <Widget>[
                          Text(
                            String.fromCharCode(emojiCodes[index]),
                            style: const TextStyle(fontSize: 32),
                            textAlign: TextAlign.center,
                          ),
                          Text(
                            emojiDescriptions[index],
                            maxLines: 1,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ),
            ),
          ),
        ),
        const Spacer(flex: 1),
        Expanded(
          flex: isDesktop ? 1 : 2,
          child: _buildBodyOnKey(context, event, setState),
        ),
        const Spacer(flex: 1),
      ],
    );
  }

  Widget _buildBodyOnKey(
    BuildContext context,
    VerificationEvent event,
    Function setState,
  ) {
    if (waitForMatch) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Text(
            sprintf(
              AppLocalizations.of(context)!.verificationRequestWaitingFor,
              [event.sender()],
            ),
          ),
        ),
      );
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.only(left: 20),
          width: MediaQuery.of(context).size.width * 0.48,
          child: elevatedButton(
            AppLocalizations.of(context)!.verificationSasDoNotMatch,
            Theme.of(context).colorScheme.success,
            () async {
              // mismatch sas verification
              await event.mismatchSasVerification();
              // go to onCancel status
              Get.back();
              _onKeyVerificationCancel(event, true);
            },
            const TextStyle(),
          ),
        ),
        const Spacer(flex: 1),
        Container(
          padding: const EdgeInsets.only(right: 20),
          width: MediaQuery.of(context).size.width * 0.48,
          child: elevatedButton(
            AppLocalizations.of(context)!.verificationSasMatch,
            Theme.of(context).colorScheme.success,
            () async {
              if (_mounted) {
                setState(() => waitForMatch = true);
              }
              // confirm sas verification
              await event.confirmSasVerification();
              // close dialog
              if (_mounted) {
                setState(() => waitForMatch = false);
              }
              // go to onMac status
              Get.back();
              _onKeyVerificationMac(event);
            },
            const TextStyle(),
          ),
        ),
      ],
    );
  }

  void _onKeyVerificationMac(VerificationEvent event) {
    String? flowId = event.flowId();
    if (flowId == null) {
      return;
    }
    _eventMap[flowId]?.stage = 'm.key.verification.mac';
    Future.delayed(const Duration(milliseconds: 500), () async {
      await event.reviewVerificationMac();
    });
  }

  void _onKeyVerificationDone(VerificationEvent event) {
    if (Get.isBottomSheetOpen == true) {
      Get.back();
    }
    String? flowId = event.flowId();
    if (flowId == null) {
      return;
    }
    _eventMap[flowId]?.stage = 'm.key.verification.done';
    Get.bottomSheet(
      StatefulBuilder(
        builder: (context, setState) => Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
          ),
          child: _buildOnDone(context, event, flowId),
        ),
      ),
      isDismissible: false,
    );
  }

  Widget _buildOnDone(
    BuildContext context,
    VerificationEvent event,
    String flowId,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          flex: isDesktop ? 2 : 1,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  child: isDesktop
                      ? const Icon(Atlas.laptop)
                      : const Icon(Atlas.phone),
                ),
                const SizedBox(width: 5),
                Text(
                  AppLocalizations.of(context)!.sasVerified,
                ),
              ],
            ),
          ),
        ),
        Flexible(
          flex: 1,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
            ),
            child: Text(
              _eventMap[flowId]!.verifyingThisDev
                  ? AppLocalizations.of(context)!
                      .verificationConclusionOkSelfNotice
                  : AppLocalizations.of(context)!.verificationConclusionOkDone,
              textAlign: TextAlign.center,
            ),
          ),
        ),
        const Flexible(
          flex: 2,
          child: Center(
            child: Icon(Atlas.lock_keyhole),
          ),
        ),
        Flexible(
          flex: 1,
          child: Center(
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.40,
              child: elevatedButton(
                AppLocalizations.of(context)!.sasGotIt,
                Theme.of(context).colorScheme.success,
                () {
                  // finish verification
                  Get.back();
                  _eventMap.remove(flowId);
                },
                const TextStyle(),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
