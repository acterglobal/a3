import 'package:flutter/material.dart';

class PinDetailsPage extends StatefulWidget {
  static const pinPageKey = Key('pin-page');
  static const actionMenuKey = Key('pin-action-menu');
  static const editBtnKey = Key('pin-edit-btn');
  static const titleFieldKey = Key('edit-pin-title-field');

  final String pinId;

  // ignore: use_key_in_widget_constructors
  const PinDetailsPage({
    Key key = pinPageKey,
    required this.pinId,
  });

  @override
  State<PinDetailsPage> createState() => _PinDetailsPageState();
}

class _PinDetailsPageState extends State<PinDetailsPage> {
  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
