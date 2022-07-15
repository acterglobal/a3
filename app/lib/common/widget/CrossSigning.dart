// ignore_for_file: prefer_const_constructors

import 'dart:async';

import 'package:effektio/common/store/separatedThemes.dart';
import 'package:effektio/common/widget/AppCommon.dart';
import 'package:effektio_flutter_sdk/effektio_flutter_sdk_ffi.dart'
    show SyncState, CrossSigningEvent, Client, FfiListEmojiUnit;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

class CrossSigning {
  bool waitForMatch = false;
  bool isLoading = false;
  late String eventName;
  late String eventId;
  late String sender;
  Stream<CrossSigningEvent>? _toDeviceRx;
  late StreamSubscription<CrossSigningEvent> _toDeviceSubscription;

  void startCrossSigning(Client client) async {
    SyncState syncer = client.startSync();
    _toDeviceRx = syncer.getToDeviceRx();
    _toDeviceSubscription = _toDeviceRx!.listen((event) async {
      eventName = event.getEventName();
      eventId = event.getEventId();
      sender = event.getSender();
      waitForMatch = false;
      debugPrint(eventName);
      if (eventName == 'AnyToDeviceEvent::KeyVerificationRequest') {
        await _onKeyVerificationRequest(sender, eventId, client);
      } else if (eventName == 'AnyToDeviceEvent::KeyVerificationReady') {
        await _onKeyVerificationReady(sender, eventId, client);
      } else if (eventName == 'AnyToDeviceEvent::KeyVerificationStart') {
        await _onKeyVerificationStart(sender, eventId, client);
      } else if (eventName == 'AnyToDeviceEvent::KeyVerificationCancel') {
        await _onKeyVerificationCancel(sender, eventId);
      } else if (eventName == 'AnyToDeviceEvent::KeyVerificationAccept') {
        await _onKeyVerificationAccept(sender, eventId);
      } else if (eventName == 'AnyToDeviceEvent::KeyVerificationKey') {
        await _onKeyVerificationKey(sender, eventId, client);
      } else if (eventName == 'AnyToDeviceEvent::KeyVerificationMac') {
        await _onKeyVerificationMac(sender, eventId, client);
      } else if (eventName == 'AnyToDeviceEvent::KeyVerificationDone') {
        await _onKeyVerificationDone(sender, eventId);
        // clean up event listener
        Future.delayed(const Duration(seconds: 1), () {
          _toDeviceSubscription.cancel();
        });
      }
    });
  }

  Future<void> _onKeyVerificationRequest(
    String sender,
    String eventId,
    Client client,
  ) async {
    Completer<void> c = Completer();
    isLoading = false;
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
                      'Verification Request',
                      style: CrossSigningSheetTheme.primaryTextStyle,
                    ),
                    const Spacer(),
                    Padding(
                      padding: const EdgeInsets.only(right: 10.0),
                      child: IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          Get.back();
                        },
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10.0),
                RichText(
                  text: TextSpan(
                    text: 'Verification Requested from ',
                    style: CrossSigningSheetTheme.secondaryTextStyle,
                    children: <TextSpan>[
                      TextSpan(
                        text: sender,
                        style:
                            CrossSigningSheetTheme.secondaryTextStyle.copyWith(
                          color: CrossSigningSheetTheme.redButtonColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 50.0),
                SvgPicture.asset(
                  'assets/images/lock.svg',
                  width: MediaQuery.of(context).size.width * 0.15,
                  height: MediaQuery.of(context).size.height * 0.15,
                ),
                const SizedBox(height: 50.0),
                isLoading
                    ? SizedBox(
                        child: CircularProgressIndicator(
                          color: CrossSigningSheetTheme.loadingIndicatorColor,
                        ),
                      )
                    : elevatedButton(
                        'Start Verifying',
                        AppCommonTheme.greenButtonColor,
                        () => {
                          setState(() {
                            isLoading = true;
                          }),
                          _onKeyVerificationReady(sender, eventId, client),
                          c.complete()
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
    return c.future;
  }

  Future<void> _onKeyVerificationReady(
    String sender,
    String eventId,
    Client _client,
  ) async {
    await _client.acceptVerificationRequest(sender, eventId);
  }

  Future<void> _onKeyVerificationStart(
    String sender,
    String eventId,
    Client client,
  ) async {
    isLoading = false;
    Get.back();
    Completer<void> c = Completer();
    Get.bottomSheet(
      Container(
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
                  'Verify your new session',
                  style: CrossSigningSheetTheme.primaryTextStyle,
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.only(right: 10.0),
                  child: IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () {
                      Get.back();
                    },
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Text(
                'Scan the QR code below to verify',
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
                    'Scan other code/device',
                    style: CrossSigningSheetTheme.secondaryTextStyle.copyWith(
                      color: AppCommonTheme.primaryColor,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(15.0),
              child: RichText(
                textAlign: TextAlign.center,
                softWrap: true,
                text: TextSpan(
                  text:
                      'If this wasn\'t you, your account may be compromised. Manage your security in ',
                  style: CrossSigningSheetTheme.secondaryTextStyle.copyWith(
                    fontSize: 12,
                  ),
                  children: <TextSpan>[
                    TextSpan(
                      text: 'Settings.',
                      style: CrossSigningSheetTheme.secondaryTextStyle.copyWith(
                        fontSize: 12,
                        color: AppCommonTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Center(
              child: TextButton(
                onPressed: () async {
                  await client.acceptVerificationStart(sender, eventId);
                  Get.back();
                  c.complete();
                },
                child: Text(
                  'Can\'t Scan',
                  style: CrossSigningSheetTheme.secondaryTextStyle.copyWith(
                    fontSize: 12,
                    color: AppCommonTheme.primaryColor,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      isDismissible: false,
    );
    return c.future;
  }

  Future<void> _onKeyVerificationCancel(String sender, String eventId) async {}

  Future<void> _onKeyVerificationAccept(String sender, String eventId) async {}

  Future<void> _onKeyVerificationKey(
    String sender,
    String eventId,
    Client client,
  ) async {
    Completer<void> c = Completer();
    FfiListEmojiUnit emoji = await client.getVerificationEmoji(sender, eventId);
    List<int> emojiCodes = emoji.map((e) => e.getSymbol()).toList();
    List<String> emojiDescriptions =
        emoji.map((e) => e.getDescription()).toList();
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
                    const SizedBox(width: 5),
                    Text(
                      'Verify by Emoji',
                      style: CrossSigningSheetTheme.primaryTextStyle,
                    ),
                    const Spacer(),
                    Padding(
                      padding: const EdgeInsets.only(right: 10.0),
                      child: IconButton(
                        icon: Icon(Icons.close),
                        onPressed: () {
                          Get.back();
                        },
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 10.0),
                  child: Text(
                    'Confirm the unique emoji appears on the other session, that are in the same order.',
                    style: CrossSigningSheetTheme.secondaryTextStyle,
                  ),
                ),
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    height: MediaQuery.of(context).size.height * 0.28,
                    width: MediaQuery.of(context).size.width * 0.90,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15.0),
                      color: CrossSigningSheetTheme.gridBackgroundColor,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: GridView.count(
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
                                color: CrossSigningSheetTheme.primaryTextColor,
                              ),
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
                            'Waiting for match...',
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
                              'They don\'t match',
                              CrossSigningSheetTheme.redButtonColor,
                              () async {
                                await client.mismatchVerificationKey(
                                  sender,
                                  eventId,
                                );
                                Get.back();
                                c.complete();
                              },
                              CrossSigningSheetTheme.buttonTextStyle,
                            ),
                          ),
                          const SizedBox(width: 5.0),
                          Container(
                            padding: const EdgeInsets.only(right: 20),
                            width: MediaQuery.of(context).size.width * 0.48,
                            child: elevatedButton(
                              'They match',
                              CrossSigningSheetTheme.greenButtonColor,
                              () async {
                                setState(() {
                                  waitForMatch = true;
                                });
                                await _onKeyVerificationMac(
                                  sender,
                                  eventId,
                                  client,
                                );
                                client.confirmVerificationKey(sender, eventId);
                                Get.back();
                                c.complete();
                              },
                              CrossSigningSheetTheme.buttonTextStyle,
                            ),
                          ),
                        ],
                      ),
                Center(
                  child: TextButton(
                    onPressed: () async {},
                    child: Text(
                      'QR Scan Instead',
                      style: CrossSigningSheetTheme.secondaryTextStyle.copyWith(
                        color: AppCommonTheme.primaryColor,
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
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
    return c.future;
  }

  Future<void> _onKeyVerificationMac(
    String sender,
    String eventId,
    Client client,
  ) async {
    await client.reviewVerificationMac(sender, eventId);
  }

  Future<void> _onKeyVerificationDone(String sender, String eventId) async {
    Get.back();
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
                      'Verified',
                      style: CrossSigningSheetTheme.primaryTextStyle,
                    ),
                    const Spacer(),
                    Padding(
                      padding: const EdgeInsets.only(right: 10.0),
                      child: IconButton(
                        icon: Icon(Icons.close),
                        onPressed: () {
                          Get.back();
                        },
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 10.0),
                  child: Text(
                    'You can now read secure messages on your new device, and other users will know they can trust it.',
                    style: CrossSigningSheetTheme.secondaryTextStyle,
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(height: 25.0),
                Center(
                  child: SvgPicture.asset(
                    'assets/images/lock.svg',
                    width: MediaQuery.of(context).size.width * 0.15,
                    height: MediaQuery.of(context).size.height * 0.15,
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
