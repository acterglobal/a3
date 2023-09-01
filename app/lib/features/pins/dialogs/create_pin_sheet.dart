import 'package:acter/common/dialogs/pop_up_dialog.dart';
import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/snackbars/custom_msg.dart';
import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/widgets/md_editor_with_preview.dart';
import 'package:acter/common/widgets/side_sheet.dart';
import 'package:acter/common/widgets/spaces/select_space_form_field.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// interface data providers
final titleProvider = StateProvider<String>((ref) => '');
final textProvider = StateProvider<String>((ref) => '');
final linkProvider = StateProvider<String>((ref) => '');

class CreatePinSheet extends ConsumerStatefulWidget {
  final String? initialSelectedSpace;
  const CreatePinSheet({super.key, this.initialSelectedSpace});

  @override
  ConsumerState<CreatePinSheet> createState() => _CreatePinSheetConsumerState();
}

class _CreatePinSheetConsumerState extends ConsumerState<CreatePinSheet> {
  final TextEditingController _titleController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((Duration duration) {
      final spaceNotifier = ref.read(selectedSpaceIdProvider.notifier);
      spaceNotifier.state = widget.initialSelectedSpace;
    });
  }

  @override
  Widget build(BuildContext context) {
    final titleInput = ref.watch(titleProvider);
    final titleNotifier = ref.watch(titleProvider.notifier);
    final textNotifier = ref.watch(textProvider.notifier);
    final linkNotifier = ref.watch(linkProvider.notifier);

    return SideSheet(
      header: 'Create new Pin',
      addActions: true,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: TextFormField(
                          decoration: InputDecoration(
                            hintText: 'Your title',
                            labelText: 'Title',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                          controller: _titleController,
                          onChanged: (String? value) {
                            titleNotifier.state = value ?? '';
                          },
                          validator: (value) =>
                              (value != null && value.isNotEmpty)
                                  ? null
                                  : 'Please enter a title',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              TextFormField(
                decoration: InputDecoration(
                  icon: const Icon(Atlas.link_thin),
                  hintText: 'https://',
                  labelText: 'link',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                validator: (value) => (value != null && value.isNotEmpty)
                    ? textNotifier.state.isEmpty
                        ? 'Text or URL must be given'
                        : null
                    : 'Please enter a link',
                onChanged: (String? value) {
                  linkNotifier.state = value ?? '';
                },
              ),
              MdEditorWithPreview(
                validator: (value) => (value != null && value.isNotEmpty)
                    ? linkNotifier.state.isEmpty
                        ? 'Text or URL must be given'
                        : null
                    : 'Please enter a text',
                onChanged: (String? value) {
                  textNotifier.state = value ?? '';
                },
              ),
              const SelectSpaceFormField(canCheck: 'CanPostPin'),
            ],
          ),
        ),
      ),
      actions: [
        ElevatedButton(
          onPressed: () => context.canPop()
              ? context.pop()
              : context.goNamed(Routes.main.name),
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
            foregroundColor: Theme.of(context).colorScheme.neutral6,
            textStyle: Theme.of(context).textTheme.bodySmall,
          ),
          child: const Text('Cancel'),
        ),
        const SizedBox(width: 10),
        ElevatedButton(
          onPressed: () async {
            if (_formKey.currentState!.validate()) {
              popUpDialog(
                context: context,
                title: Text(
                  'Posting Pin',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                isLoader: true,
              );
              try {
                final spaceId = ref.read(selectedSpaceIdProvider);
                final space = await ref.read(spaceProvider(spaceId!).future);
                final pinDraft = space.pinDraft();
                final text = ref.read(textProvider);
                final url = ref.read(linkProvider);
                pinDraft.title(ref.read(titleProvider));
                if (text.isNotEmpty) {
                  pinDraft.contentMarkdown(text);
                }
                if (url.isNotEmpty) {
                  pinDraft.url(url);
                }
                final pinId = await pinDraft.send();
                // reset providers
                titleNotifier.state = '';
                textNotifier.state = '';

                // We are doing as expected, but the lints triggers.
                // ignore: use_build_context_synchronously
                if (!context.mounted) {
                  return;
                }
                Navigator.of(context, rootNavigator: true).pop();
                context.goNamed(
                  Routes.pin.name,
                  pathParameters: {'pinId': pinId.toString()},
                );
              } catch (e) {
                // We are doing as expected, but the lints triggers.
                // ignore: use_build_context_synchronously
                if (!context.mounted) {
                  return;
                }
                customMsgSnackbar(context, 'Failed to pin: $e');
              }
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: titleInput.isNotEmpty
                ? Theme.of(context).colorScheme.success
                : Theme.of(context).colorScheme.success.withOpacity(0.6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
            foregroundColor: Theme.of(context).colorScheme.neutral6,
            textStyle: Theme.of(context).textTheme.bodySmall,
          ),
          child: const Text('Create Pin'),
        ),
      ],
    );
  }
}
