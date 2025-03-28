import 'package:acter/features/spaces/model/permission_config.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:flutter/material.dart';

class SelectPermission extends StatelessWidget {
  final PermissionLevel currentPermission;
  final Function(PermissionLevel) onPermissionSelected;

  const SelectPermission({
    super.key,
    required this.currentPermission,
    required this.onPermissionSelected,
  });

  @override
  Widget build(BuildContext context) {
    final lang = L10n.of(context);
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
              lang.selectPermissionLevel,
              style: textTheme.titleMedium,
            ),
          ),
          const SizedBox(height: 16),
          ...PermissionLevel.values.map(
            (level) => buildPermissionItem(context, level),
          ),
        ],
      ),
    );
  }

  Widget buildPermissionItem(BuildContext context, PermissionLevel level) {
    final textTheme = Theme.of(context).textTheme;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final isSelected = level == currentPermission;
    final permissionIcon = getIconBasedOnPermissionLevel(level);
    final permissionColor = isSelected ? primaryColor : null;

    return ListTile(
      onTap: () {
        onPermissionSelected(level);
        Navigator.pop(context);
      },
      leading: Icon(permissionIcon, color: permissionColor),
      title: Text(
        level.name.toUpperCase(),
        style: textTheme.bodyMedium?.copyWith(color: permissionColor),
      ),
      trailing: isSelected ? Icon(Icons.check, color: primaryColor) : null,
    );
  }

  IconData getIconBasedOnPermissionLevel(PermissionLevel level) {
    return switch (level) {
      PermissionLevel.admin => Icons.admin_panel_settings,
      PermissionLevel.moderator => Icons.person,
      PermissionLevel.everyone => Icons.group,
    };
  }
}
