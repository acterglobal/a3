import 'package:freezed_annotation/freezed_annotation.dart';

part 'receipt_room.freezed.dart';

@freezed
class ReceiptRoom with _$ReceiptRoom {
  const factory ReceiptRoom({
    required String roomId,
    @Default({}) Map<String, List<String>> receipts,
  }) = _ReceiptRoom;
}
