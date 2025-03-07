import 'package:acter/common/extensions/options.dart';
import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:flutter/material.dart';

class SliverScaffold extends StatelessWidget {
  final String header;
  final Widget? body;
  final List<Widget>? delegates;
  final bool addBackIconButton;
  final bool addCloseIconButton;
  final bool addActions;
  final bool addDivider;
  final Key? confirmActionKey;
  final String? confirmActionTitle;
  final String? cancelActionTitle;
  final String? closeButtonTooltip;
  final String? backButtonTooltip;
  final List<Widget>? actions;

  final void Function()? confirmActionOnPressed;
  final void Function()? cancelActionOnPressed;

  static const closeKey = Key('sliver-scaffold-close');

  const SliverScaffold({
    super.key,
    required this.header,
    this.body,
    this.delegates,
    this.actions,
    this.addBackIconButton = false,
    this.addActions = false,
    this.addDivider = false,
    this.cancelActionOnPressed,
    this.confirmActionOnPressed,
    this.cancelActionTitle = 'Cancel',
    this.confirmActionTitle = 'Save',
    this.closeButtonTooltip,
    this.backButtonTooltip,
    this.addCloseIconButton = true,
    this.confirmActionKey,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      elevation: 1,
      surfaceTintColor: colorScheme.surfaceTint,
      borderRadius: const BorderRadius.horizontal(left: Radius.circular(28)),
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        body: Container(
          // keep space shell top bar to prevent us being covered by front-camera etc.
          padding: const EdgeInsets.only(top: 12),
          child: CustomScrollView(
            shrinkWrap: true,
            slivers: [
              SliverList(
                delegate: SliverChildListDelegate([
                  _SliverHeader(
                    header: header,
                    addBackIconButton: addBackIconButton,
                    addCloseIconButton: addCloseIconButton,
                    backButtonTooltip: backButtonTooltip,
                    closeButtonTooltip: closeButtonTooltip,
                  ),
                  if (body != null) SingleChildScrollView(child: body),
                  ...(delegates ?? []),
                ]),
              ),
              SliverFillRemaining(
                hasScrollBody: false,
                child: Visibility(
                  visible: addActions,
                  child: _SliverFooter(
                    addDivider: addDivider,
                    confirmActionTitle: confirmActionTitle,
                    confirmActionKey: confirmActionKey,
                    cancelActionTitle: cancelActionTitle,
                    actions: actions,
                    confirmActionOnPressed: confirmActionOnPressed,
                    cancelActionOnPressed: cancelActionOnPressed,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SliverHeader extends StatelessWidget {
  final String header;
  final bool addBackIconButton;
  final bool addCloseIconButton;
  final String? backButtonTooltip;
  final String? closeButtonTooltip;

  const _SliverHeader({
    required this.header,
    required this.addBackIconButton,
    required this.addCloseIconButton,
    this.backButtonTooltip,
    this.closeButtonTooltip,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(addBackIconButton ? 16 : 24, 16, 16, 16),
      child: Row(
        children: [
          Visibility(
            visible: addBackIconButton,
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              child: IconButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                tooltip: backButtonTooltip,
                icon: const Icon(Icons.arrow_back),
              ),
            ),
          ),
          Text(
            header,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.titleSmall,
          ),
          Flexible(
            fit: FlexFit.tight,
            child: SizedBox(width: addCloseIconButton ? 12 : 8),
          ),
          Visibility(
            visible: addCloseIconButton,
            child: IconButton(
              onPressed: () {
                Navigator.pop(context);
              },
              tooltip: closeButtonTooltip,
              icon: const Icon(Icons.close, key: SliverScaffold.closeKey),
            ),
          ),
        ],
      ),
    );
  }
}

class _SliverFooter extends StatelessWidget {
  final bool addDivider;
  final Key? confirmActionKey;
  final String? confirmActionTitle;
  final String? cancelActionTitle;
  final List<Widget>? actions;

  final void Function()? confirmActionOnPressed;
  final void Function()? cancelActionOnPressed;

  const _SliverFooter({
    required this.addDivider,
    required this.confirmActionTitle,
    required this.cancelActionTitle,
    this.actions,
    this.confirmActionOnPressed,
    this.cancelActionOnPressed,
    this.confirmActionKey,
  });

  @override
  Widget build(BuildContext context) {
    final cancelTitle = cancelActionTitle;
    final confirmTitle = confirmActionTitle;
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Visibility(
          visible: addDivider,
          child: const Divider(indent: 24, endIndent: 24),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children:
                actions ??
                [
                  if (cancelTitle != null)
                    OutlinedButton(
                      onPressed: () => onCancel(context),
                      child: Text(cancelTitle),
                    ),
                  const SizedBox(width: 12),
                  if (confirmTitle != null)
                    ActerPrimaryActionButton(
                      key: confirmActionKey,
                      onPressed: confirmActionOnPressed,
                      child: Text(confirmTitle),
                    ),
                ],
          ),
        ),
      ],
    );
  }

  void onCancel(BuildContext context) {
    cancelActionOnPressed.map(
      (cb) => cb(),
      orElse: () => Navigator.pop(context),
    );
  }
}
