import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

void showAddEditLinkBottomSheet({
  required BuildContext context,
  String? bottomSheetTitle,
  String? pinTitle,
  String? pinLink,
  required Function(String, String) onSave,
}) {
  showModalBottomSheet(
    showDragHandle: true,
    useSafeArea: true,
    context: context,
    isDismissible: true,
    isScrollControlled: true,
    builder: (context) {
      return LinkBottomSheet(
        bottomSheetTitle: bottomSheetTitle,
        pinTitle: pinTitle,
        pinLink: pinLink,
        onSave: onSave,
      );
    },
  );
}

class LinkBottomSheet extends ConsumerStatefulWidget {
  final String? bottomSheetTitle;
  final String? pinTitle;
  final String? pinLink;
  final Function(String, String) onSave;

  const LinkBottomSheet({
    super.key,
    this.bottomSheetTitle,
    this.pinTitle,
    this.pinLink,
    required this.onSave,
  });

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _PinLinkBottomSheet();
}

class _PinLinkBottomSheet extends ConsumerState<LinkBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _linkController = TextEditingController();
  final prefixText = 'https://';

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.pinTitle ?? '';
    _linkController.text = (widget.pinLink ?? '').replaceAll(prefixText, '');
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: MediaQuery.of(context).viewInsets,
      child: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.bottomSheetTitle ?? L10n.of(context).editLink,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 40),
              _widgetTitleField(),
              const SizedBox(height: 10),
              _widgetLinkField(),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(L10n.of(context).cancel),
                  ),
                  const SizedBox(width: 20),
                  ActerPrimaryActionButton(
                    onPressed: () {
                      if (!_formKey.currentState!.validate()) return;

                      // no changes to submit
                      if (_titleController.text.trim() ==
                              widget.pinTitle?.trim() &&
                          _linkController.text.trim() ==
                              widget.pinLink?.trim()) {
                        Navigator.pop(context);
                        return;
                      }

                      // Need to update change of tile
                      widget.onSave(
                        _titleController.text.trim(),
                        '$prefixText${_linkController.text.trim()}',
                      );
                    },
                    child: Text(L10n.of(context).save),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _widgetTitleField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(L10n.of(context).title),
        const SizedBox(height: 6),
        TextFormField(
          keyboardType: TextInputType.text,
          textInputAction: TextInputAction.next,
          controller: _titleController,
          autofocus: true,
          minLines: 1,
          maxLines: 1,
        ),
      ],
    );
  }

  Widget _widgetLinkField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(L10n.of(context).link),
        const SizedBox(height: 6),
        TextFormField(
          keyboardType: TextInputType.text,
          textInputAction: TextInputAction.done,
          controller: _linkController,
          minLines: 1,
          maxLines: 1,
          decoration: InputDecoration(prefixText: prefixText),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return L10n.of(context).pleaseEnterALink;
            } else if (!urlValidatorRegexp.hasMatch(value)) {
              return L10n.of(context).pleaseEnterAValidLink;
            }
            return null;
          },
        ),
      ],
    );
  }
}
