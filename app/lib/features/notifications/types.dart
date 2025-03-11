enum SubscriptionStatus {
  subscribed,
  unsubscribed,
  parentSubscribed,
  parentUnsubscribed,
  none,
}

enum SubscriptionSubType {
  comments,
  attachments;

  String asType() => switch (this) {
    SubscriptionSubType.comments => 'global.acter.dev.comment',
    SubscriptionSubType.attachments => throw UnimplementedError(),
  };
}
