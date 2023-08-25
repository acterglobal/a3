import 'package:acter/common/providers/sdk_provider.dart';
import 'package:acter/common/widgets/render_html.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final markdownProvider =
    FutureProvider.family<String, String>((ref, input) async {
  final sdk = await ref.watch(sdkProvider.future);
  return (sdk.parseMarkdown(input) ?? '');
});

class MdEditorWithPreview extends ConsumerStatefulWidget {
  final ValueChanged<String>? onChanged;
  final FormFieldValidator<String>? validator;

  const MdEditorWithPreview({
    Key? key,
    this.onChanged,
    this.validator,
  }) : super(key: key);

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _MdEditorWithPreviewState();
}

class _MdEditorWithPreviewState extends ConsumerState<MdEditorWithPreview> {
  bool _showPreview = false;
  final TextEditingController _textCtr = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Stack(
          children: [
            _showPreview
                ? FormField(
                    builder: (x) => Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            width: 3,
                          ),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Consumer(
                            builder: (context, ref, child) => ref
                                .watch(markdownProvider(_textCtr.text))
                                .when(
                                  data: (text) => RenderHtml(text: text),
                                  error: (error, stackTrace) =>
                                      Text('Parsing markdown failed: $error'),
                                  loading: () => const Text('Parsing ...'),
                                ),
                          ),
                        ),
                      ),
                    ),
                    validator: widget
                        .validator, // make sure we still have the validator in the tree
                  )
                : TextFormField(
                    decoration: InputDecoration(
                      hintText: 'The description',
                      labelText: 'Description',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                    textAlignVertical: TextAlignVertical.top,
                    controller: _textCtr,
                    expands: true,
                    minLines: null,
                    maxLines: null,
                    keyboardType: TextInputType.multiline,
                    validator: widget.validator,
                    onChanged: (String? value) {
                      widget.onChanged ?? (value);
                    },
                  ),
            Positioned(
              right: 10,
              bottom: 10,
              child: Tooltip(
                message: 'Toggle preview',
                child: IconButton(
                  onPressed: () => setState(() => _showPreview = !_showPreview),
                  icon: _showPreview
                      ? const Icon(Atlas.xmark_circle_thin)
                      : const Icon(Atlas.vision_thin),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
