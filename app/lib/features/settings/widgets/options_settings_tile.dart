import 'package:acter/common/extensions/options.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:acter/l10n/l10n.dart';
import 'package:settings_ui/settings_ui.dart';

typedef OnOptionSelect<T> = void Function(T value);

class _OptionsSettingsTile<T> extends StatefulWidget {
  final String title;
  final String? explainer;
  final List<(T, String)> options;
  final T selected;
  final Widget? icon;
  final OnOptionSelect<T> onSelect;

  const _OptionsSettingsTile({
    required this.title,
    required this.selected,
    required this.onSelect,
    required this.options,
    this.explainer,
    this.icon,
    super.key,
  });

  @override
  __OptionsSettingsTileState<T> createState() =>
      __OptionsSettingsTileState<T>();
}

class __OptionsSettingsTileState<T> extends State<_OptionsSettingsTile<T>> {
  final menuController = MenuController();

  @override
  Widget build(BuildContext context) {
    final (selectedEnum, selectedTitle) = widget.options.firstWhere(
      (element) => element.$1 == widget.selected,
      orElse: () => (widget.selected, L10n.of(context).unknown),
    );
    return SettingsTile(
      onPressed: (context) => menuController.open(),
      title: Text(widget.title, style: Theme.of(context).textTheme.bodySmall),
      description: widget.explainer.map((explainer) => Text(explainer)),
      leading: widget.icon,
      trailing: MenuAnchor(
        controller: menuController,
        menuChildren: menuChildren(context),
        child: Text(selectedTitle),
      ),
    );
  }

  List<Widget> menuChildren(context) {
    return widget.options.map((r) => menuItem(context, r.$1, r.$2)).toList();
  }

  ListTile menuItem(BuildContext context, T key, String title) {
    return ListTile(
      selected: widget.selected == key,
      onTap: () {
        widget.onSelect.call(key);
        menuController.close();
      },
      title: Text(title, style: Theme.of(context).textTheme.bodyMedium),
      trailing:
          widget.selected == key
              ? Icon(
                Atlas.check_circle,
                size: 18,
                color: Theme.of(context).colorScheme.onSurface,
              )
              : null,
    );
  }
}

class OptionsSettingsTile<T> extends AbstractSettingsTile {
  final String title;
  final String? explainer;
  final List<(T, String)> options;
  final T selected;
  final OnOptionSelect<T> onSelect;
  final Widget? icon;

  const OptionsSettingsTile({
    required this.title,
    required this.selected,
    required this.onSelect,
    required this.options,
    this.icon,
    this.explainer,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return _OptionsSettingsTile(
      title: title,
      explainer: explainer,
      selected: selected,
      options: options,
      icon: icon,
      onSelect: onSelect,
    );
  }
}
