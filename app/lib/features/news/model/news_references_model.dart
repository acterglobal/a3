enum NewsReferencesType {
  shareEvent,
}

class NewsReferencesModel {
  NewsReferencesType type;
  String? id;

  NewsReferencesModel({
    required this.type,
    this.id,
  });
}
