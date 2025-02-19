import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:acter_notifify/acter_notifify.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:acter_notifify/matrix.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:dio/dio.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::notifify::ntfy');

Map<String, StreamSubscription<String>> _subscriptions = {};

Future<bool?> setupNtfyNotificationsForDevice(
  Client client, {
  required String appName,
  required String appIdPrefix,
  required String ntfyServer,
  ShouldShowCheck? shouldShowCheck,
}) async {
  // let's get the token
  final deviceId = client.deviceId().toString();

  final token = 'up$deviceId';

  // submit to server
  await addToken(
    client,
    'https://$ntfyServer/$token',
    appIdPrefix: appIdPrefix,
    appName: appName,
    pushServerUrl: 'https://$ntfyServer/_matrix/push/v1/notify',
  );

  if (_subscriptions.containsKey(token)) {
    // clear any pending streams
    await _subscriptions[token]?.cancel();
    _subscriptions.remove(token);
  }

  // and start listening to the server
  Response<ResponseBody> rs = await Dio().get<ResponseBody>(
    'https://$ntfyServer/$token/json',
    options: Options(headers: {
      // "Authorization":
      //     'vhdrjb token"',
      'Accept': 'text/event-stream',
      'Cache-Control': 'no-cache',
    }, responseType: ResponseType.stream), // set responseType to `stream`
  );
  StreamTransformer<Uint8List, List<int>> unit8Transformer =
      StreamTransformer.fromHandlers(
    handleData: (data, sink) {
      sink.add(List<int>.from(data));
    },
  );
  if (rs.data == null) {
    _log.severe('Connecting to ntfy server failed: $rs');
    Sentry.captureMessage('Connecting to ntfy server failed: $rs');
    return false;
  }
  _subscriptions[token] = rs.data!.stream
      .transform(unit8Transformer)
      .transform(const Utf8Decoder())
      .transform(const LineSplitter())
      .listen((event) {
    try {
      final eventJson = json.decode(event);
      if (eventJson['event'] != 'message') {
        // not anything we care about
        return;
      }
      final message = json
          .decode(eventJson['message']); // we have to decode the content again
      final notification = message['notification'];
      // we plug our device ID as it is needed for the inner workings
      notification['device_id'] = deviceId;
      _log.info('Message received: $notification');
      handleMatrixMessage(
        notification as Map<String?, Object?>,
        shouldShowCheck: shouldShowCheck,
      );
    } catch (error, stack) {
      _log.severe('Failed to show push notification $event', error, stack);
      Sentry.captureException(error, stackTrace: stack);
    }
  });
  return true;
}
