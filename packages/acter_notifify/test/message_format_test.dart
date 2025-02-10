import 'package:acter_notifify/matrix.dart';
import 'package:acter_notifify/util.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

void main() {
  setUp(() {});

  group("Message Format tests ", () {
    test("Ensure doesn't fail for empty", () async {
      await handleMatrixMessage({});
    });

    test("Ensure doesn't fail for count update only", () async {
      when(() => updateBadgeCount(any()));
      await handleMatrixMessage({
        // this comes on iOS
        'sender': '',
        'unread': 1,
        'missed_calls': null,
        'prio': 'high',
        'device_id': 'JCQZTNXBDI',
      });

      // this comes through ntfy
      await handleMatrixMessage({
        'counts': {'unread': 12},
        'devices': [
          {
            'app_id': 'global.acter.a3.linux',
            'data': {
              'default_payload': {'device_id': 'EACAZQUGOA'}
            },
            'pushkey': 'https://ntfy.XXX.global/XX',
            'pushkey_ts': 1638600870
          }
        ],
        'id': '',
        'sender': '',
        'type': null,
        'device_id': 'EACXZQUGOA'
      });
    });
  });
}
