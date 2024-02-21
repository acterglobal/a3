enum NewsReferencesType {
  inviteToSpace,
  inviteToChat,
}

class NewsReferencesModel {
  NewsReferencesType type;
  String? id;

  NewsReferencesModel({
    required this.type,
    this.id,
  });
}
