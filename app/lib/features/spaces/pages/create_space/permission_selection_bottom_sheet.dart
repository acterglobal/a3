import 'package:flutter/material.dart';
import 'package:acter/features/spaces/model/space_permission_levels.dart';

class PermissionSelectionBottomSheet extends StatelessWidget {
  final PermissionLevel currentPermission;
  final Function(PermissionLevel) onPermissionSelected;

  const PermissionSelectionBottomSheet({
    super.key,
    required this.currentPermission,
    required this.onPermissionSelected,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Select Permission Level',
              style: textTheme.titleMedium,
            ),
          ),
          const SizedBox(height: 16),
          ...PermissionLevel.values.map((level) {
            final isSelected = level == currentPermission;
            return ListTile(
              leading: Icon(
                level == PermissionLevel.admin
                    ? Icons.admin_panel_settings
                    : level == PermissionLevel.moderator
                    ? Icons.groups
                    : Icons.person,
                color:
                    isSelected ? Theme.of(context).colorScheme.primary : null,
              ),
              title: Text(
                level.name.toUpperCase(),
                style: textTheme.bodyMedium?.copyWith(
                  color:
                      isSelected ? Theme.of(context).colorScheme.primary : null,
                ),
              ),
              trailing:
                  isSelected
                      ? Icon(
                        Icons.check,
                        color: Theme.of(context).colorScheme.primary,
                      )
                      : null,
              onTap: () {
                onPermissionSelected(level);
                Navigator.pop(context);
              },
            );
          }),
        ],
      ),
    );
  }
}
