import 'package:acter/features/read_receipts/providers/read_receipts.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';

class MockReadReceiptsManager extends Mock implements ReadReceiptsManager {
  final int count;
  final bool haveIseen;

  MockReadReceiptsManager({this.count = 0, this.haveIseen = false});

  @override
  int readCount() => count;

  @override
  bool readByMe() => haveIseen;
}

class MockAsyncReadReceiptsManagerNotifier
    extends AutoDisposeFamilyAsyncNotifier<ReadReceiptsManager,
        Future<ReadReceiptsManager>>
    with Mock
    implements AsyncReadReceiptsManagerNotifier {
  @override
  Future<ReadReceiptsManager> build(Future<ReadReceiptsManager> arg) async {
    print("new arg");
    return await arg;
  }
}
