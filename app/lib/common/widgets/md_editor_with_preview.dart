import 'package:acter/common/providers/sdk_provider.dart';
import 'package:acter/common/widgets/input_text_field.dart';
import 'package:acter/common/widgets/render_html.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

final markdownProvider =
    FutureProvider.family<String, String>((ref, input) async {
  final sdk = await ref.watch(sdkProvider.future);
  return sdk.api.parseMarkdown(input) ?? '';
});

class MdEditorWithPreview extends ConsumerStatefulWidget {
  final ValueChanged<String>? onChanged;
  final FormFieldValidator<String>? validator;
  final String? hintText;
  final String? labelText;
  final TextEditingController? controller;

  const MdEditorWithPreview({
    super.key,
    this.onChanged,
    this.validator,
    this.hintText,
    this.labelText,
    this.controller,
  });

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _MdEditorWithPreviewState();
}

class _MdEditorWithPreviewState extends ConsumerState<MdEditorWithPreview> {
  bool _showPreview = false;
  final TextEditingController _textCtr = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller ?? _textCtr;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Stack(
        children: [
          _showPreview
              ? FormField(
                  builder: (x) => Container(
                    constraints: const BoxConstraints(minHeight: 200),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.tertiary,
                        width: 1.5,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 10,
                      ),
                      child: SingleChildScrollView(
                        child: Consumer(
                          builder: (context, ref, child) => ref
                              .watch(markdownProvider(controller.text))
                              .when(
                                data: (text) => RenderHtml(text: text),
                                error: (error, stackTrace) => Text(
                                    L10n.of(context)
                                        .parsingMarkdownFailed(error),
                                ),
                                loading: () => Text(L10n.of(context).parsing),
                              ),
                        ),
                      ),
                    ),
                  ),
                  validator: widget
                      .validator, // make sure we still have the validator in the tree
                )
              : InputTextField(
                  controller: controller,
                  hintText: widget.hintText ?? L10n.of(context).description,
                  maxLines: 10,
                  textInputType: TextInputType.multiline,
                  textInputAction: TextInputAction.newline,
                  validator: widget.validator,
                  onInputChanged: (String? value) {
                    widget.onChanged ?? (value);
                  },
                ),
          Positioned(
            right: 10,
            bottom: 10,
            child: Tooltip(
              message: L10n.of(context).togglePreview,
              child: IconButton(
                onPressed: () => setState(() => _showPreview = !_showPreview),
                icon: _showPreview
                    ? const Icon(Atlas.xmark_circle_thin)
                    : const Icon(Atlas.vision_thin),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
