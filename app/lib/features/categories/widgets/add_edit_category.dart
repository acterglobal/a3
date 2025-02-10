import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:acter/common/widgets/acter_icon_picker/acter_icon_widget.dart';
import 'package:acter/common/widgets/acter_icon_picker/model/acter_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void showAddEditCategoryBottomSheet({
  required BuildContext context,
  String? bottomSheetTitle,
  String? title,
  Color? color,
  ActerIcon? icon,
  required Function(String, Color, ActerIcon) onSave,
}) {
  showModalBottomSheet(
    showDragHandle: true,
    useSafeArea: true,
    context: context,
    isDismissible: true,
    isScrollControlled: true,
    builder: (context) {
      return AddEditCategoryBottomSheet(
        bottomSheetTitle: bottomSheetTitle,
        title: title,
        color: color,
        icon: icon,
        onSave: onSave,
      );
    },
  );
}

class AddEditCategoryBottomSheet extends ConsumerStatefulWidget {
  final String? bottomSheetTitle;
  final String? title;
  final Color? color;
  final ActerIcon? icon;
  final Function(String, Color, ActerIcon) onSave;

  const AddEditCategoryBottomSheet({
    super.key,
    this.bottomSheetTitle,
    this.title,
    this.color,
    this.icon,
    required this.onSave,
  });

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _AddEditCategoryBottomSheet();
}

class _AddEditCategoryBottomSheet
    extends ConsumerState<AddEditCategoryBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  late Color color;
  late ActerIcon icon;

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.title ?? '';
    color = widget.color ?? Colors.blueGrey;
    icon = widget.icon ?? ActerIcon.list;
  }

  @override
  Widget build(BuildContext context) {
    final lang = L10n.of(context);
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
                widget.bottomSheetTitle ?? lang.editCategory,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 40),
              ActerIconWidget(
                color: color,
                icon: icon,
                showEditIconIndicator: true,
                onIconSelection: (clr, icn) {
                  setState(() {
                    color = clr;
                    icon = icn;
                  });
                },
              ),
              const SizedBox(height: 40),
              _widgetTitleField(),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(lang.cancel),
                  ),
                  const SizedBox(width: 20),
                  ActerPrimaryActionButton(
                    onPressed: () {
                      if (!_formKey.currentState!.validate()) return;

                      // no changes to submit
                      final title = _titleController.text.trim();
                      if (title == widget.title?.trim() &&
                          color == widget.color &&
                          icon == widget.icon) {
                        Navigator.pop(context);
                        return;
                      }

                      // Need to update change of tile
                      widget.onSave(title, color, icon);
                      Navigator.pop(context);
                    },
                    child: Text(lang.save),
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
}
