import 'package:acter/l10n/generated/l10n.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk.dart';

enum OrganizationType {
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

class OrganizationActions {
  static Future<List<OrganizationType>> loadSelectedOrganizations(L10n l10n) async {
    final prefs = await sharedPrefs();
    final items = prefs.getStringList(l10n.selectedOrganizations) ?? [];
    return items.map((e) {
      try {
        return OrganizationType.values.firstWhere((type) => type.name == e);
      } catch (_) {
        return null;
      }
    }).where((type) => type != null).cast<OrganizationType>().toList();
  }

  static Future<void> updateSelectedOrganizations(
    List<OrganizationType> currentItems,
    OrganizationType type,
    bool isSelected,
    L10n l10n,
  ) async {
    final prefs = await sharedPrefs();
    final updatedItems = List<OrganizationType>.from(currentItems);
    
    if (isSelected) {
      if (!updatedItems.contains(type)) {
        updatedItems.add(type);
      }
    } else {
      updatedItems.remove(type);
    }
    
    await prefs.setStringList(
      l10n.selectedOrganizations,
      updatedItems.map((e) => e.name).toList(),
    );
  }
} 