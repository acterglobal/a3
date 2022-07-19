// ignore_for_file: prefer_const_constructors

import 'dart:async';

import 'package:effektio/common/store/separatedThemes.dart';
import 'package:effektio/common/widget/AppCommon.dart';
import 'package:effektio_flutter_sdk/effektio_flutter_sdk_ffi.dart'
    show Client, EmojiVerificationEvent, FfiListEmojiUnit;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:get/get.dart';

class CrossSigning {
  bool waitForMatch = false;
  bool isLoading = false;
  late StreamSubscription<EmojiVerificationEvent> _subscription;

  void startCrossSigning(
    Stream<EmojiVerificationEvent> receiver,
    Client client,
  ) async {
    _subscription = receiver.listen((event) async {
      String eventName = event.getEventName();
      String eventId = event.getEventId();
      String sender = event.getSender();
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
          _subscription.cancel();
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
                      AppLocalizations.of(context)!.verificationRequestText1,
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
                    text:
                        AppLocalizations.of(context)!.verificationRequestText2,
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
                        AppLocalizations.of(context)!.startVerifying,
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
                      AppLocalizations.of(context)!.verifySessionText1,
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
                    AppLocalizations.of(context)!.verifySessionText2,
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
                        AppLocalizations.of(context)!.verifySessionText3,
                        style:
                            CrossSigningSheetTheme.secondaryTextStyle.copyWith(
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
                      text: AppLocalizations.of(context)!.verifySessionText4,
                      style: CrossSigningSheetTheme.secondaryTextStyle.copyWith(
                        fontSize: 12,
                      ),
                      children: <TextSpan>[
                        TextSpan(
                          text: AppLocalizations.of(context)!.settings,
                          style: CrossSigningSheetTheme.secondaryTextStyle
                              .copyWith(
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
                      AppLocalizations.of(context)!.verifySessionText5,
                      style: CrossSigningSheetTheme.secondaryTextStyle.copyWith(
                        fontSize: 12,
                        color: AppCommonTheme.primaryColor,
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
                      AppLocalizations.of(context)!.emojiVerificationText1,
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
                    AppLocalizations.of(context)!.emojiVerificationText2,
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
                            AppLocalizations.of(context)!
                                .emojiVerificationText3,
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
                              AppLocalizations.of(context)!
                                  .emojiVerificationText4,
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
                              AppLocalizations.of(context)!
                                  .emojiVerificationText5,
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
                      AppLocalizations.of(context)!.emojiVerificationText6,
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
                      AppLocalizations.of(context)!.verified,
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
                    AppLocalizations.of(context)!.emojiVerifiedText1,
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
                    width: MediaQuery.of(context).size.width * 0.25,
                    child: elevatedButton(
                      AppLocalizations.of(context)!.emojiVerifiedText2,
                      CrossSigningSheetTheme.greenButtonColor,
                      () {
                        Get.back();
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
