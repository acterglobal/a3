import 'package:acter/features/chat_ui_showcase/mocks/convo/timeline/mock_reaction_record.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:mocktail/mocktail.dart';

class MockFfiListReactionRecord extends Mock implements FfiListReactionRecord {
  final List<MockReactionRecord> records;

  MockFfiListReactionRecord({required this.records});

  @override
  List<MockReactionRecord> toList({bool growable = false}) =>
      records.toList(growable: growable);
}
