import 'package:acter_flutter_sdk/acter_flutter_sdk.dart';

enum CustomizationType {
  activism,
  localGroup,
  unionizing,
  cooperation,
  networkingLearning,
  communityDrivenProjects,
  forAnEvent,
  justFrdAndFamily,
  lookAround,
}

Future<List<CustomizationType>> loadSelectedCustomizations() async {
  final prefs = await sharedPrefs();
  final items = prefs.getStringList('selected_customizations') ?? [];
  return items
      .map((e) {
        try {
          return CustomizationType.values.firstWhere((type) => type.name == e);
        } catch (_) {
          return null;
        }
      })
      .where((type) => type != null)
      .cast<CustomizationType>()
      .toList();
}

Future<void> updateSelectedCustomizations(
  List<CustomizationType> currentItems,
  CustomizationType type,
  bool isSelected
) async {
  final prefs = await sharedPrefs();
  final updatedItems = List<CustomizationType>.from(currentItems);

  if (isSelected) {
    if (!updatedItems.contains(type)) {
      updatedItems.add(type);
    }
  } else {
    updatedItems.remove(type);
  }

  await prefs.setStringList(
    'selected_customizations',
    updatedItems.map((e) => e.name).toList(),
  );
}
