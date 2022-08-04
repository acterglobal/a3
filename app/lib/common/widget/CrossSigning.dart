// ignore_for_file: prefer_const_constructors

import 'dart:async';
import 'package:effektio/common/store/separatedThemes.dart';
import 'package:effektio/common/widget/AppCommon.dart';
import 'package:effektio_flutter_sdk/effektio_flutter_sdk_ffi.dart'
    show DevicesChangedEvent, EmojiVerificationEvent;
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:sprintf/sprintf.dart';

class VerifEvent {
  final bool verifyingThisDev;
  String stage;

  VerifEvent({
    required this.verifyingThisDev,
    required this.stage,
  });
}

class CrossSigning {
  late StreamSubscription<DevicesChangedEvent> _devicesChangedEventSubscription;
  late StreamSubscription<EmojiVerificationEvent>
      _emojiVerificationEventSubscription;
  final Map<String, VerifEvent> _eventMap = {};
  bool acceptingRequest = false;
  bool waitForMatch = false;

  void dispose() {
    _devicesChangedEventSubscription.cancel();
    _emojiVerificationEventSubscription.cancel();
  }

  void listenToDevicesChangedEvent(Stream<DevicesChangedEvent> receiver) async {
    debugPrint('listenToDevicesChangedEvent');
    _devicesChangedEventSubscription = receiver.listen((event) async {
      debugPrint('listenToDevicesChangedEvent');
      var devices = await event.getDevices(false);
      for (var device in devices) {
        debugPrint('found device id: ' + device.getDeviceId());
      }
      Get.generalDialog(
        pageBuilder: (context, anim1, anim2) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Container(
                width: MediaQuery.of(context).size.width,
                color: Colors.white,
                child: Card(
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      ListTile(
                        title: Text('New device detected'),
                        onTap: () async {
                          await event.requestVerificationToUser();
                          Get.back();
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      );
    });
  }

  void listenToEmojiVerificationEvent(
    Stream<EmojiVerificationEvent> receiver,
  ) async {
    _emojiVerificationEventSubscription = receiver.listen((event) async {
      String eventName = event.getEventName();
      debugPrint(eventName);
      if (eventName == 'm.key.verification.request') {
        _onKeyVerificationRequest(event);
      } else if (eventName == 'm.key.verification.ready') {
        _onKeyVerificationReady(event, false);
      } else if (eventName == 'm.key.verification.start') {
        _onKeyVerificationStart(event);
      } else if (eventName == 'm.key.verification.cancel') {
        _onKeyVerificationCancel(event, false);
      } else if (eventName == 'm.key.verification.accept') {
        _onKeyVerificationAccept(event);
      } else if (eventName == 'm.key.verification.key') {
        _onKeyVerificationKey(event);
      } else if (eventName == 'm.key.verification.mac') {
        _onKeyVerificationMac(event);
      } else if (eventName == 'm.key.verification.done') {
        _onKeyVerificationDone(event);
      }
    });
  }

  void _onKeyVerificationRequest(EmojiVerificationEvent event) {
    String txnId = event.getTxnId();
    if (_eventMap.containsKey(txnId)) {
      return;
    }
    // this case is bob side
    _eventMap[txnId] = VerifEvent(
      verifyingThisDev: true,
      stage: 'm.key.verification.request',
    );
    acceptingRequest = false;
    Get.bottomSheet(
      StatefulBuilder(
        builder: (context, setState) {
          String notifContent = sprintf(
            AppLocalizations.of(context)!.sasIncomingReqNotifContent,
            [event.getSender()],
          );
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15.0),
              color: CrossSigningSheetTheme.backgroundColor,
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10.0),
                      child: SvgPicture.asset(
                        'assets/images/baseline-devices.svg',
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      AppLocalizations.of(context)!.sasIncomingReqNotifTitle,
                      style: CrossSigningSheetTheme.primaryTextStyle,
                    ),
                    const Spacer(),
                    Padding(
                      padding: const EdgeInsets.only(right: 10.0),
                      child: IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () async {
                          await event.cancelVerificationRequest();
                          Get.back();
                          _eventMap.remove(txnId);
                        },
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10.0),
                Text(
                  notifContent,
                  style: CrossSigningSheetTheme.secondaryTextStyle,
                ),
                const SizedBox(height: 50.0),
                SvgPicture.asset(
                  'assets/images/lock.svg',
                  width: MediaQuery.of(context).size.width * 0.15,
                  height: MediaQuery.of(context).size.height * 0.15,
                ),
                const SizedBox(height: 50.0),
                acceptingRequest
                    ? SizedBox(
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
                          Future.delayed(
                            const Duration(milliseconds: 500),
                            () {
                              _onKeyVerificationReady(event, true);
                            },
                          );
                        },
                        CrossSigningSheetTheme.buttonTextStyle,
                      ),
              ],
            ),
          );
        },
      ),
      isDismissible: false,
    );
  }

  void _onKeyVerificationReady(EmojiVerificationEvent event, bool manual) {
    String txnId = event.getTxnId();
    if (manual) {
      _eventMap[txnId]!.stage = 'm.key.verification.ready';
    } else {
      // this device is alice side
      _eventMap[txnId] = VerifEvent(
        verifyingThisDev: false,
        stage: 'm.key.verification.ready',
      );
    }
    Get.bottomSheet(
      StatefulBuilder(
        builder: (context, setState) {
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15.0),
              color: CrossSigningSheetTheme.backgroundColor,
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10.0),
                      child: SvgPicture.asset(
                        'assets/images/baseline-devices.svg',
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      AppLocalizations.of(context)!.verifyThisSession,
                      style: CrossSigningSheetTheme.primaryTextStyle,
                    ),
                    const Spacer(),
                    Padding(
                      padding: const EdgeInsets.only(right: 10.0),
                      child: IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () async {
                          await event.cancelVerificationRequest();
                          Get.back();
                          _eventMap.remove(txnId);
                        },
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(15.0, 8.0, 15, 8.0),
                  child: Text(
                    AppLocalizations.of(context)!.verificationScanSelfNotice,
                    style: CrossSigningSheetTheme.secondaryTextStyle,
                  ),
                ),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(25.0),
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
                        padding: const EdgeInsets.all(8.0),
                        child: SvgPicture.asset(
                          'assets/images/camera.svg',
                          color: AppCommonTheme.primaryColor,
                          height: 14,
                          width: 14,
                        ),
                      ),
                      Text(
                        AppLocalizations.of(context)!
                            .verificationScanWithThisDevice,
                        style:
                            CrossSigningSheetTheme.secondaryTextStyle.copyWith(
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
                        AppLocalizations.of(context)!
                            .verificationScanEmojiTitle,
                        style: CrossSigningSheetTheme.primaryTextStyle,
                      ),
                      subtitle: Text(
                        AppLocalizations.of(context)!
                            .verificationScanSelfEmojiSubtitle,
                        style: CrossSigningSheetTheme.secondaryTextStyle,
                      ),
                      trailing: Icon(
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
            ),
          );
        },
      ),
      isDismissible: false,
    );
  }

  void _onKeyVerificationStart(EmojiVerificationEvent event) {
    if (Get.isBottomSheetOpen == true) {
      Get.back();
    }
    String txnId = event.getTxnId();
    if (_eventMap[txnId]?.stage != 'm.key.verification.request' &&
        _eventMap[txnId]?.stage != 'm.key.verification.ready') {
      return;
    }
    _eventMap[txnId]?.stage = 'm.key.verification.start';
    Get.bottomSheet(
      StatefulBuilder(
        builder: (context, setState) {
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15.0),
              color: CrossSigningSheetTheme.backgroundColor,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10.0),
                      child: SvgPicture.asset(
                        'assets/images/baseline-devices.svg',
                      ),
                    ),
                    const SizedBox(width: 5.0),
                    Text(
                      _eventMap[txnId]?.verifyingThisDev == true
                          ? AppLocalizations.of(context)!.verifyThisSession
                          : AppLocalizations.of(context)!.verifySession,
                      style: CrossSigningSheetTheme.primaryTextStyle,
                    ),
                    const Spacer(),
                    Padding(
                      padding: const EdgeInsets.only(right: 10.0),
                      child: IconButton(
                        icon: Icon(Icons.close),
                        onPressed: () async {
                          await event.cancelSasVerification();
                          Future.delayed(
                            const Duration(milliseconds: 500),
                            () {
                              _onKeyVerificationCancel(event, true);
                            },
                          );
                        },
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(50.0),
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
            ),
          );
        },
      ),
      isDismissible: false,
    );
  }

  void _onKeyVerificationCancel(EmojiVerificationEvent event, bool manual) {
    if (Get.isBottomSheetOpen == true) {
      Get.back();
    }
    String txnId = event.getTxnId();
    _eventMap[txnId]?.stage = 'm.key.verification.cancel';
    Get.bottomSheet(
      StatefulBuilder(
        builder: (context, setState) {
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15.0),
              color: CrossSigningSheetTheme.backgroundColor,
            ),
            child: Column(
              children: manual == true
                  ? [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10.0),
                            child: SvgPicture.asset(
                              'assets/images/baseline-devices.svg',
                            ),
                          ),
                          const SizedBox(width: 5.0),
                          Text(
                            _eventMap[txnId]?.verifyingThisDev == true
                                ? AppLocalizations.of(context)!
                                    .verifyThisSession
                                : AppLocalizations.of(context)!.verifySession,
                            style: CrossSigningSheetTheme.primaryTextStyle,
                          ),
                          const Spacer(),
                        ],
                      ),
                      Padding(
                        padding:
                            const EdgeInsets.fromLTRB(50.0, 50.0, 50.0, 20.0),
                        child: SvgPicture.asset(
                          'assets/images/lock.svg',
                          width: MediaQuery.of(context).size.width * 0.15,
                          height: MediaQuery.of(context).size.height * 0.15,
                          color: CrossSigningSheetTheme.secondaryTextColor,
                        ),
                      ),
                      Text(
                        AppLocalizations.of(context)!
                            .verificationConclusionCompromised,
                        style: CrossSigningSheetTheme.secondaryTextStyle,
                      ),
                      const SizedBox(height: 10.0),
                      SizedBox(
                        width: MediaQuery.of(context).size.width * 0.40,
                        child: elevatedButton(
                          AppLocalizations.of(context)!.sasGotIt,
                          AppCommonTheme.greenButtonColor,
                          () {
                            Get.back();
                            _eventMap.remove(txnId);
                          },
                          CrossSigningSheetTheme.buttonTextStyle,
                        ),
                      ),
                    ]
                  : [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10.0),
                            child: SvgPicture.asset(
                              'assets/images/baseline-devices.svg',
                            ),
                          ),
                          const SizedBox(width: 5.0),
                          Text(
                            _eventMap[txnId]?.verifyingThisDev == true
                                ? AppLocalizations.of(context)!
                                    .verifyThisSession
                                : AppLocalizations.of(context)!.verifySession,
                            style: CrossSigningSheetTheme.primaryTextStyle,
                          ),
                          const Spacer(),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.all(50.0),
                        child: SvgPicture.asset(
                          'assets/images/lock.svg',
                          width: MediaQuery.of(context).size.width * 0.15,
                          height: MediaQuery.of(context).size.height * 0.15,
                          color: CrossSigningSheetTheme.secondaryTextColor,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          event.getReason()!,
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
                            _eventMap.remove(txnId);
                          },
                          CrossSigningSheetTheme.buttonTextStyle,
                        ),
                      ),
                    ],
            ),
          );
        },
      ),
    );
  }

  void _onKeyVerificationAccept(EmojiVerificationEvent event) {
    if (Get.isBottomSheetOpen == true) {
      Get.back();
    }
    String txnId = event.getTxnId();
    _eventMap[txnId]?.stage = 'm.key.verification.accept';
    Get.bottomSheet(
      StatefulBuilder(
        builder: (context, setState) {
          String waitingFor = sprintf(
            AppLocalizations.of(context)!.verificationRequestWaitingFor,
            [event.getSender()],
          );
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15.0),
              color: CrossSigningSheetTheme.backgroundColor,
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10.0),
                      child: SvgPicture.asset(
                        'assets/images/baseline-devices.svg',
                      ),
                    ),
                    const SizedBox(width: 5.0),
                    Text(
                      _eventMap[txnId]?.verifyingThisDev == true
                          ? AppLocalizations.of(context)!.verifyThisSession
                          : AppLocalizations.of(context)!.verifySession,
                      style: CrossSigningSheetTheme.primaryTextStyle,
                    ),
                    const Spacer(),
                  ],
                ),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(50.0),
                    child: SizedBox(
                      height: 100,
                      width: 100,
                      child: CircularProgressIndicator(
                        color: CrossSigningSheetTheme.loadingIndicatorColor,
                      ),
                    ),
                  ),
                ),
                Text(
                  waitingFor,
                  style: CrossSigningSheetTheme.secondaryTextStyle,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _onKeyVerificationKey(EmojiVerificationEvent event) {
    if (Get.isBottomSheetOpen == true) {
      Get.back();
    }
    String txnId = event.getTxnId();
    _eventMap[txnId]?.stage = 'm.key.verification.key';
    event.getVerificationEmoji().then((emoji) {
      List<int> emojiCodes = emoji.map((e) => e.getSymbol()).toList();
      List<String> emojiDescriptions =
          emoji.map((e) => e.getDescription()).toList();
      Get.bottomSheet(
        StatefulBuilder(
          builder: (context, setState) {
            String waitingFor = sprintf(
              AppLocalizations.of(context)!.verificationRequestWaitingFor,
              [event.getSender()],
            );
            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15.0),
                color: CrossSigningSheetTheme.backgroundColor,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10.0),
                        child: SvgPicture.asset(
                          'assets/images/baseline-devices.svg',
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        _eventMap[txnId]?.verifyingThisDev == true
                            ? AppLocalizations.of(context)!.verifyThisSession
                            : AppLocalizations.of(context)!.verifySession,
                        style: CrossSigningSheetTheme.primaryTextStyle,
                      ),
                      const Spacer(),
                      Padding(
                        padding: const EdgeInsets.only(right: 10.0),
                        child: IconButton(
                          icon: Icon(Icons.close),
                          onPressed: () async {
                            await event.cancelVerificationKey();
                            Get.back();
                            Future.delayed(
                              const Duration(milliseconds: 500),
                              () {
                                _onKeyVerificationCancel(event, true);
                              },
                            );
                          },
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20.0,
                      vertical: 10.0,
                    ),
                    child: Text(
                      AppLocalizations.of(context)!.verificationEmojiNotice,
                      style: CrossSigningSheetTheme.secondaryTextStyle,
                    ),
                  ),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(10.0),
                      height: MediaQuery.of(context).size.height * 0.28,
                      width: MediaQuery.of(context).size.width * 0.90,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15.0),
                        color: CrossSigningSheetTheme.gridBackgroundColor,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: GridView.count(
                          physics: BouncingScrollPhysics(),
                          crossAxisCount: 4,
                          crossAxisSpacing: 10.0,
                          mainAxisSpacing: 10.0,
                          children: List.generate(emoji.length, (index) {
                            return GridTile(
                              child: Text(
                                String.fromCharCode(emojiCodes[index]),
                                style: TextStyle(fontSize: 32),
                                textAlign: TextAlign.center,
                              ),
                              footer: Text(
                                emojiDescriptions[index],
                                style: CrossSigningSheetTheme.secondaryTextStyle
                                    .copyWith(
                                  color:
                                      CrossSigningSheetTheme.primaryTextColor,
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
                  const SizedBox(height: 5.0),
                  waitForMatch
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
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
                              padding: const EdgeInsets.only(left: 20.0),
                              width: MediaQuery.of(context).size.width * 0.48,
                              child: elevatedButton(
                                AppLocalizations.of(context)!
                                    .verificationSasDoNotMatch,
                                CrossSigningSheetTheme.redButtonColor,
                                () async {
                                  await event.mismatchSasVerification();
                                  Get.back();
                                  Future.delayed(
                                    const Duration(milliseconds: 500),
                                    () async {
                                      _onKeyVerificationCancel(event, true);
                                    },
                                  );
                                },
                                CrossSigningSheetTheme.buttonTextStyle,
                              ),
                            ),
                            const SizedBox(width: 5.0),
                            Container(
                              padding: const EdgeInsets.only(right: 20.0),
                              width: MediaQuery.of(context).size.width * 0.48,
                              child: elevatedButton(
                                AppLocalizations.of(context)!
                                    .verificationSasMatch,
                                CrossSigningSheetTheme.greenButtonColor,
                                () async {
                                  setState(() => waitForMatch = true);
                                  await event.confirmSasVerification();
                                  Get.back();
                                  setState(() => waitForMatch = false);
                                  Future.delayed(
                                    const Duration(milliseconds: 500),
                                    () {
                                      _onKeyVerificationMac(event);
                                    },
                                  );
                                },
                                CrossSigningSheetTheme.buttonTextStyle,
                              ),
                            ),
                          ],
                        ),
                ],
              ),
            );
          },
        ),
        isDismissible: false,
      );
    });
  }

  void _onKeyVerificationMac(EmojiVerificationEvent event) {
    _eventMap[event.getTxnId()]?.stage = 'm.key.verification.mac';
    Future.delayed(const Duration(milliseconds: 500), () async {
      await event.reviewVerificationMac();
    });
  }

  void _onKeyVerificationDone(EmojiVerificationEvent event) {
    if (Get.isBottomSheetOpen == true) {
      Get.back();
    }
    String txnId = event.getTxnId();
    _eventMap[txnId]?.stage = 'm.key.verification.done';
    Get.bottomSheet(
      StatefulBuilder(
        builder: (context, setState) {
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15.0),
              color: CrossSigningSheetTheme.backgroundColor,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10.0),
                      child: SvgPicture.asset(
                        'assets/images/baseline-devices.svg',
                      ),
                    ),
                    const SizedBox(width: 5.0),
                    Text(
                      _eventMap[txnId]!.verifyingThisDev
                          ? AppLocalizations.of(context)!
                              .verificationConclusionOkTitle
                          : AppLocalizations.of(context)!
                              .verificationConclusionOkTitle,
                      style: CrossSigningSheetTheme.primaryTextStyle,
                    ),
                    const Spacer(),
                    Padding(
                      padding: const EdgeInsets.only(right: 10.0),
                      child: IconButton(
                        icon: Icon(Icons.close),
                        onPressed: () {
                          Get.back();
                          _eventMap.remove(txnId);
                        },
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20.0,
                    vertical: 10.0,
                  ),
                  child: Text(
                    _eventMap[txnId]!.verifyingThisDev
                        ? AppLocalizations.of(context)!
                            .verificationConclusionOkSelfNotice
                        : AppLocalizations.of(context)!
                            .verificationConclusionOkDone,
                    style: CrossSigningSheetTheme.secondaryTextStyle,
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 25.0),
                Center(
                  child: SvgPicture.asset(
                    'assets/images/lock.svg',
                    width: MediaQuery.of(context).size.width * 0.15,
                    height: MediaQuery.of(context).size.height * 0.15,
                  ),
                ),
                const SizedBox(height: 25.0),
                Center(
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width * 0.40,
                    child: elevatedButton(
                      AppLocalizations.of(context)!.sasGotIt,
                      CrossSigningSheetTheme.greenButtonColor,
                      () {
                        Get.back();
                        _eventMap.remove(txnId);
                      },
                      CrossSigningSheetTheme.buttonTextStyle,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      isDismissible: false,
    );
  }
}
