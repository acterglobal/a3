import 'dart:async';

import 'package:effektio/common/store/themes/SeperatedThemes.dart';
import 'package:effektio/widgets/AppCommon.dart';
import 'package:effektio_flutter_sdk/effektio_flutter_sdk_ffi.dart'
    show
        Client,
        DeviceChangedEvent,
        FfiListVerificationEmoji,
        VerificationEvent;
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:sprintf/sprintf.dart';

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
  late StreamSubscription<DeviceChangedEvent>? _deviceSubscription;
  late StreamSubscription<VerificationEvent>? _verifSubscription;
  final Map<String, VerifEvent> _eventMap = {};
  bool acceptingRequest = false;
  bool waitForMatch = false;

  CrossSigning({required this.client}) {
    _installDeviceChangedEvent();
    _installVerificationEvent();
  }

  void dispose() {
    _deviceSubscription?.cancel();
    _verifSubscription?.cancel();
  }

  void _installDeviceChangedEvent() {
    _deviceSubscription = client.deviceChangedEventRx()?.listen((event) async {
      var records = await event.deviceRecords(false);
      for (var record in records) {
        debugPrint('found device id: ' + record.deviceId());
      }
      Get.generalDialog(
        pageBuilder: (context, anim1, anim2) {
          return Container(
            width: MediaQuery.of(context).size.width,
            color: Colors.white,
            child: Card(
              child: ListView(
                shrinkWrap: true,
                children: [
                  ListTile(
                    title: const Text('New device detected'),
                    onTap: () async {
                      await event.requestVerificationToUser();
                      Get.back();
                    },
                  ),
                ],
              ),
            ),
          );
        },
      );
    });
  }

  void _installVerificationEvent() {
    _verifSubscription = client.verificationEventRx()?.listen((event) {
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
    String flowId = event.flowId();
    if (_eventMap.containsKey(flowId)) {
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
            color: CrossSigningSheetTheme.backgroundColor,
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
    String notifContent = sprintf(
      AppLocalizations.of(context)!.sasIncomingReqNotifContent,
      [event.sender()],
    );
    return Column(
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              child: SvgPicture.asset('assets/images/baseline-devices.svg'),
            ),
            const SizedBox(width: 5),
            Text(
              AppLocalizations.of(context)!.sasIncomingReqNotifTitle,
              style: CrossSigningSheetTheme.primaryTextStyle,
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () async {
                  await event.cancelVerificationRequest();
                  Get.back();
                  _eventMap.remove(flowId);
                },
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(notifContent, style: CrossSigningSheetTheme.secondaryTextStyle),
        const SizedBox(height: 50),
        SvgPicture.asset(
          'assets/images/lock.svg',
          width: MediaQuery.of(context).size.width * 0.15,
          height: MediaQuery.of(context).size.height * 0.15,
        ),
        const SizedBox(height: 50),
        acceptingRequest
            ? const SizedBox(
                width: 100,
                height: 100,
                child: CircularProgressIndicator(
                  color: CrossSigningSheetTheme.loadingIndicatorColor,
                ),
              )
            : elevatedButton(
                AppLocalizations.of(context)!.acceptRequest,
                AppCommonTheme.greenButtonColor,
                () async {
                  setState(() => acceptingRequest = true);
                  await event.acceptVerificationRequest();
                  Get.back();
                  Future.delayed(const Duration(milliseconds: 500), () {
                    _onKeyVerificationReady(event, true);
                  });
                },
                CrossSigningSheetTheme.buttonTextStyle,
              ),
      ],
    );
  }

  void _onKeyVerificationReady(VerificationEvent event, bool manual) {
    String flowId = event.flowId();
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
            color: CrossSigningSheetTheme.backgroundColor,
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
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              child: SvgPicture.asset('assets/images/baseline-devices.svg'),
            ),
            const SizedBox(width: 5),
            Text(
              _eventMap[flowId]!.verifyingThisDev
                  ? AppLocalizations.of(context)!.verifyThisSession
                  : AppLocalizations.of(context)!.verifySession,
              style: CrossSigningSheetTheme.primaryTextStyle,
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () async {
                  await event.cancelVerificationRequest();
                  Get.back();
                  _eventMap.remove(flowId);
                },
                color: Colors.white,
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
          child: Text(
            AppLocalizations.of(context)!.verificationScanSelfNotice,
            style: CrossSigningSheetTheme.secondaryTextStyle,
          ),
        ),
        const Center(
          child: Padding(
            padding: EdgeInsets.all(25),
            child: SizedBox(
              height: 100,
              width: 100,
              child: CircularProgressIndicator(
                color: CrossSigningSheetTheme.loadingIndicatorColor,
              ),
            ),
          ),
        ),
        TextButton(
          onPressed: () {},
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.all(8),
                child: SvgPicture.asset(
                  'assets/images/camera.svg',
                  color: AppCommonTheme.primaryColor,
                  height: 14,
                  width: 14,
                ),
              ),
              Text(
                AppLocalizations.of(context)!.verificationScanWithThisDevice,
                style: CrossSigningSheetTheme.secondaryTextStyle.copyWith(
                  color: AppCommonTheme.primaryColor,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        Wrap(
          children: [
            ListTile(
              title: Text(
                AppLocalizations.of(context)!.verificationScanEmojiTitle,
                style: CrossSigningSheetTheme.primaryTextStyle,
              ),
              subtitle: Text(
                AppLocalizations.of(context)!.verificationScanSelfEmojiSubtitle,
                style: CrossSigningSheetTheme.secondaryTextStyle,
              ),
              trailing: const Icon(
                Icons.keyboard_arrow_right_outlined,
                color: CrossSigningSheetTheme.primaryTextColor,
              ),
              onTap: () async {
                await event.startSasVerification();
                Get.back();
                Future.delayed(const Duration(milliseconds: 500), () {
                  _onKeyVerificationStart(event);
                });
              },
            ),
          ],
        )
      ],
    );
  }

  void _onKeyVerificationStart(VerificationEvent event) {
    if (Get.isBottomSheetOpen == true) {
      Get.back();
    }
    String flowId = event.flowId();
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
            color: CrossSigningSheetTheme.backgroundColor,
          ),
          child: _buildOnStart(context, event, flowId),
        ),
      ),
      isDismissible: false,
    );
  }

  Widget _buildOnStart(
    BuildContext context,
    VerificationEvent event,
    String flowId,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              child: SvgPicture.asset('assets/images/baseline-devices.svg'),
            ),
            const SizedBox(width: 5),
            Text(
              _eventMap[flowId]?.verifyingThisDev == true
                  ? AppLocalizations.of(context)!.verifyThisSession
                  : AppLocalizations.of(context)!.verifySession,
              style: CrossSigningSheetTheme.primaryTextStyle,
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () async {
                  await event.cancelSasVerification();
                  Future.delayed(const Duration(milliseconds: 500), () {
                    _onKeyVerificationCancel(event, true);
                  });
                },
                color: Colors.white,
              ),
            ),
          ],
        ),
        const Center(
          child: Padding(
            padding: EdgeInsets.all(50),
            child: SizedBox(
              height: 100,
              width: 100,
              child: CircularProgressIndicator(
                color: CrossSigningSheetTheme.loadingIndicatorColor,
              ),
            ),
          ),
        ),
        Center(
          child: Text(
            AppLocalizations.of(context)!.pleaseWait,
            style: CrossSigningSheetTheme.secondaryTextStyle,
          ),
        ),
      ],
    );
  }

  void _onKeyVerificationCancel(VerificationEvent event, bool manual) {
    if (Get.isBottomSheetOpen == true) {
      Get.back();
    }
    String flowId = event.flowId();
    _eventMap[flowId]?.stage = 'm.key.verification.cancel';
    Get.bottomSheet(
      StatefulBuilder(
        builder: (context, setState) => Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            color: CrossSigningSheetTheme.backgroundColor,
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
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                child: SvgPicture.asset('assets/images/baseline-devices.svg'),
              ),
              const SizedBox(width: 5),
              Text(
                _eventMap[flowId]?.verifyingThisDev == true
                    ? AppLocalizations.of(context)!.verifyThisSession
                    : AppLocalizations.of(context)!.verifySession,
                style: CrossSigningSheetTheme.primaryTextStyle,
              ),
              const Spacer(),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(50, 50, 50, 20),
            child: SvgPicture.asset(
              'assets/images/lock.svg',
              width: MediaQuery.of(context).size.width * 0.15,
              height: MediaQuery.of(context).size.height * 0.15,
              color: CrossSigningSheetTheme.secondaryTextColor,
            ),
          ),
          Text(
            AppLocalizations.of(context)!.verificationConclusionCompromised,
            style: CrossSigningSheetTheme.secondaryTextStyle,
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: MediaQuery.of(context).size.width * 0.40,
            child: elevatedButton(
              AppLocalizations.of(context)!.sasGotIt,
              AppCommonTheme.greenButtonColor,
              () {
                Get.back();
                _eventMap.remove(flowId);
              },
              CrossSigningSheetTheme.buttonTextStyle,
            ),
          ),
        ],
      );
    } else {
      return Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                child: SvgPicture.asset('assets/images/baseline-devices.svg'),
              ),
              const SizedBox(width: 5),
              Text(
                _eventMap[flowId]?.verifyingThisDev == true
                    ? AppLocalizations.of(context)!.verifyThisSession
                    : AppLocalizations.of(context)!.verifySession,
                style: CrossSigningSheetTheme.primaryTextStyle,
              ),
              const Spacer(),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(50),
            child: SvgPicture.asset(
              'assets/images/lock.svg',
              width: MediaQuery.of(context).size.width * 0.15,
              height: MediaQuery.of(context).size.height * 0.15,
              color: CrossSigningSheetTheme.secondaryTextColor,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Text(
              event.reason()!,
              style: CrossSigningSheetTheme.secondaryTextStyle,
            ),
          ),
          SizedBox(
            width: MediaQuery.of(context).size.width * 0.40,
            child: elevatedButton(
              AppLocalizations.of(context)!.sasGotIt,
              AppCommonTheme.greenButtonColor,
              () {
                Get.back();
                _eventMap.remove(flowId);
              },
              CrossSigningSheetTheme.buttonTextStyle,
            ),
          ),
        ],
      );
    }
  }

  void _onKeyVerificationAccept(VerificationEvent event) {
    if (Get.isBottomSheetOpen == true) {
      Get.back();
    }
    String flowId = event.flowId();
    _eventMap[flowId]?.stage = 'm.key.verification.accept';
    Get.bottomSheet(
      StatefulBuilder(
        builder: (context, setState) => Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            color: CrossSigningSheetTheme.backgroundColor,
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
    String waitingFor = sprintf(
      AppLocalizations.of(context)!.verificationRequestWaitingFor,
      [event.sender()],
    );
    return Column(
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              child: SvgPicture.asset('assets/images/baseline-devices.svg'),
            ),
            const SizedBox(width: 5),
            Text(
              _eventMap[flowId]?.verifyingThisDev == true
                  ? AppLocalizations.of(context)!.verifyThisSession
                  : AppLocalizations.of(context)!.verifySession,
              style: CrossSigningSheetTheme.primaryTextStyle,
            ),
            const Spacer(),
          ],
        ),
        const Center(
          child: Padding(
            padding: EdgeInsets.all(50),
            child: SizedBox(
              height: 100,
              width: 100,
              child: CircularProgressIndicator(
                color: CrossSigningSheetTheme.loadingIndicatorColor,
              ),
            ),
          ),
        ),
        Text(waitingFor, style: CrossSigningSheetTheme.secondaryTextStyle),
      ],
    );
  }

  void _onKeyVerificationKey(VerificationEvent event) {
    if (Get.isBottomSheetOpen == true) {
      Get.back();
    }
    String flowId = event.flowId();
    _eventMap[flowId]?.stage = 'm.key.verification.key';
    event.getVerificationEmoji().then((emoji) {
      Get.bottomSheet(
        StatefulBuilder(
          builder: (context, setState) => Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              color: CrossSigningSheetTheme.backgroundColor,
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
    String waitingFor = sprintf(
      AppLocalizations.of(context)!.verificationRequestWaitingFor,
      [event.sender()],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              child: SvgPicture.asset('assets/images/baseline-devices.svg'),
            ),
            const SizedBox(width: 5),
            Text(
              _eventMap[flowId]?.verifyingThisDev == true
                  ? AppLocalizations.of(context)!.verifyThisSession
                  : AppLocalizations.of(context)!.verifySession,
              style: CrossSigningSheetTheme.primaryTextStyle,
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () async {
                  await event.cancelVerificationKey();
                  Get.back();
                  Future.delayed(const Duration(milliseconds: 500), () {
                    _onKeyVerificationCancel(event, true);
                  });
                },
                color: Colors.white,
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Text(
            AppLocalizations.of(context)!.verificationEmojiNotice,
            style: CrossSigningSheetTheme.secondaryTextStyle,
          ),
        ),
        Center(
          child: Container(
            padding: const EdgeInsets.all(10),
            height: MediaQuery.of(context).size.height * 0.28,
            width: MediaQuery.of(context).size.width * 0.90,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              color: CrossSigningSheetTheme.gridBackgroundColor,
            ),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: GridView.count(
                physics: const BouncingScrollPhysics(),
                crossAxisCount: 4,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                children: List.generate(emoji.length, (index) {
                  return GridTile(
                    child: Text(
                      String.fromCharCode(emojiCodes[index]),
                      style: const TextStyle(fontSize: 32),
                      textAlign: TextAlign.center,
                    ),
                    footer: Text(
                      emojiDescriptions[index],
                      style: CrossSigningSheetTheme.secondaryTextStyle.copyWith(
                        color: CrossSigningSheetTheme.primaryTextColor,
                        overflow: TextOverflow.ellipsis,
                      ),
                      maxLines: 1,
                      textAlign: TextAlign.center,
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
        const SizedBox(height: 5),
        waitForMatch
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Text(
                    waitingFor,
                    style: CrossSigningSheetTheme.secondaryTextStyle,
                  ),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.only(left: 20),
                    width: MediaQuery.of(context).size.width * 0.48,
                    child: elevatedButton(
                      AppLocalizations.of(context)!.verificationSasDoNotMatch,
                      CrossSigningSheetTheme.redButtonColor,
                      () async {
                        await event.mismatchSasVerification();
                        Get.back();
                        Future.delayed(const Duration(milliseconds: 500), () {
                          _onKeyVerificationCancel(event, true);
                        });
                      },
                      CrossSigningSheetTheme.buttonTextStyle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Container(
                    padding: const EdgeInsets.only(right: 20),
                    width: MediaQuery.of(context).size.width * 0.48,
                    child: elevatedButton(
                      AppLocalizations.of(context)!.verificationSasMatch,
                      CrossSigningSheetTheme.greenButtonColor,
                      () async {
                        setState(() => waitForMatch = true);
                        await event.confirmSasVerification();
                        Get.back();
                        setState(() => waitForMatch = false);
                        Future.delayed(const Duration(milliseconds: 500), () {
                          _onKeyVerificationMac(event);
                        });
                      },
                      CrossSigningSheetTheme.buttonTextStyle,
                    ),
                  ),
                ],
              ),
      ],
    );
  }

  void _onKeyVerificationMac(VerificationEvent event) {
    _eventMap[event.flowId()]?.stage = 'm.key.verification.mac';
    Future.delayed(const Duration(milliseconds: 500), () async {
      await event.reviewVerificationMac();
    });
  }

  void _onKeyVerificationDone(VerificationEvent event) {
    if (Get.isBottomSheetOpen == true) {
      Get.back();
    }
    String flowId = event.flowId();
    _eventMap[flowId]?.stage = 'm.key.verification.done';
    Get.bottomSheet(
      StatefulBuilder(
        builder: (context, setState) => Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            color: CrossSigningSheetTheme.backgroundColor,
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
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              child: SvgPicture.asset('assets/images/baseline-devices.svg'),
            ),
            const SizedBox(width: 5),
            Text(
              AppLocalizations.of(context)!.sasVerified,
              style: CrossSigningSheetTheme.primaryTextStyle,
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 10,
          ),
          child: Text(
            _eventMap[flowId]!.verifyingThisDev
                ? AppLocalizations.of(context)!
                    .verificationConclusionOkSelfNotice
                : AppLocalizations.of(context)!.verificationConclusionOkDone,
            style: CrossSigningSheetTheme.secondaryTextStyle,
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 25),
        Center(
          child: SvgPicture.asset(
            'assets/images/lock.svg',
            width: MediaQuery.of(context).size.width * 0.15,
            height: MediaQuery.of(context).size.height * 0.15,
          ),
        ),
        const SizedBox(height: 25),
        Center(
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.40,
            child: elevatedButton(
              AppLocalizations.of(context)!.sasGotIt,
              CrossSigningSheetTheme.greenButtonColor,
              () {
                Get.back();
                _eventMap.remove(flowId);
              },
              CrossSigningSheetTheme.buttonTextStyle,
            ),
          ),
        ),
      ],
    );
  }
}
