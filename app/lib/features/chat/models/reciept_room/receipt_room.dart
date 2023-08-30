import 'package:acter/features/chat/models/receipt_user.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'receipt_room.freezed.dart';

@freezed
class ReceiptRoom with _$ReceiptRoom {
  const factory ReceiptRoom({
    @Default({}) Map<String, ReceiptUser> users,
  }) = _ReceiptRoom;
}
