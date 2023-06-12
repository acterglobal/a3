class ReceiptUser {
  String eventId;
  String userId;
  int? ts;

  ReceiptUser({
    required this.eventId,
    required this.userId,
    this.ts,
  });
}
