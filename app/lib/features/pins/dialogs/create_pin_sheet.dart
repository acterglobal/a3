import 'package:acter/common/dialogs/pop_up_dialog.dart';
import 'package:acter/common/snackbars/custom_msg.dart';
import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/widgets/side_sheet.dart';
import 'package:acter/features/home/widgets/space_chip.dart';
import 'package:acter/common/providers/space_providers.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:acter/features/spaces/dialogs/space_selector_sheet.dart';

final selectedSpaceIdProvider = StateProvider<String?>((ref) => null);
final selectedSpaceDetailsProvider =
    FutureProvider.autoDispose<SpaceItem?>((ref) async {
  final selectedSpaceId = ref.watch(selectedSpaceIdProvider);
  if (selectedSpaceId == null) {
    return null;
  }

  final spaces = await ref.watch(briefSpaceItemsProviderWithMembership.future);
  return spaces.firstWhere((element) => element.roomId == selectedSpaceId);
});

// upload avatar path
final titleProvider = StateProvider<String>((ref) => '');
final selectedTypeProvider = StateProvider<String>((ref) => 'link');
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
  final TextEditingController _typeController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    Future(() {
      ref.read(selectedSpaceIdProvider.notifier).state =
          widget.initialSelectedSpace;
    });
  }

  @override
  Widget build(BuildContext context) {
    final _titleInput = ref.watch(titleProvider);
    final currentSelectedSpace = ref.watch(selectedSpaceIdProvider);
    final _selectedSpace = currentSelectedSpace != null;
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
                    DropdownMenu<String>(
                      initialSelection: 'link',
                      controller: _typeController,
                      label: const Text('Type'),
                      dropdownMenuEntries: const [
                        DropdownMenuEntry(label: 'Link', value: 'link'),
                        DropdownMenuEntry(label: 'Text', value: 'text'),
                      ],
                      onSelected: (String? typus) {
                        if (typus != null) {
                          ref.read(selectedTypeProvider.notifier).state = typus;
                        }
                      },
                    ),
                    Expanded(
                      child: TextFormField(
                        decoration: const InputDecoration(
                          hintText: 'Your title',
                          labelText: 'Title',
                        ),
                        controller: _titleController,
                        onChanged: (String? value) {
                          ref.read(titleProvider.notifier).state = value ?? '';
                        },
                        validator: (value) =>
                            (value != null && value.isNotEmpty)
                                ? null
                                : 'Please enter a title',
                      ),
                    ),
                  ],
                ),
              ),
              Consumer(
                builder: ((context, ref, child) {
                  final subselection = ref.watch(selectedTypeProvider);
                  if (subselection == 'text') {
                    return Expanded(
                      child: TextFormField(
                        decoration: const InputDecoration(
                          hintText: 'the content of the pin',
                          labelText: 'Content',
                        ),
                        expands: true,
                        minLines: null,
                        maxLines: null,
                        keyboardType: TextInputType.multiline,
                        validator: (value) =>
                            (value != null && value.isNotEmpty)
                                ? null
                                : 'Please enter a text',
                        onChanged: (String? value) {
                          ref.read(textProvider.notifier).state = value ?? '';
                        },
                      ),
                    );
                  } else {
                    return TextFormField(
                      decoration: const InputDecoration(
                        icon: Icon(Atlas.link_thin),
                        hintText: 'https://',
                        labelText: 'link',
                      ),
                      validator: (value) => (value != null && value.isNotEmpty)
                          ? null
                          : 'Please enter a link',
                      onChanged: (String? value) {
                        ref.read(linkProvider.notifier).state = value ?? '';
                      },
                    );
                  }
                }),
              ),
              FormField(
                builder: (state) => ListTile(
                  title: Text(
                    _selectedSpace ? 'Space' : 'Please select a space',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  subtitle: state.errorText != null
                      ? Text(
                          state.errorText!,
                          style:
                              Theme.of(context).textTheme.bodySmall!.copyWith(
                                    color: Theme.of(context).colorScheme.error,
                                  ),
                        )
                      : null,
                  trailing: _selectedSpace
                      ? Consumer(
                          builder: (context, ref, child) =>
                              ref.watch(selectedSpaceDetailsProvider).when(
                                    data: (space) => space != null
                                        ? SpaceChip(space: space)
                                        : Text(currentSelectedSpace),
                                    error: (e, s) => Text('error: $e'),
                                    loading: () => const Text('loading'),
                                  ),
                        )
                      : null,
                  onTap: () async {
                    final currentSpaceId = ref.read(selectedSpaceIdProvider);
                    final newSelectedSpaceId = await selectSpaceDrawer(
                      context: context,
                      currentSpaceId: currentSpaceId,
                      canCheck: 'CanPostPin',
                      title: const Text('Select parent space'),
                    );
                    ref.read(selectedSpaceIdProvider.notifier).state =
                        newSelectedSpaceId;
                  },
                ),
                validator: (x) => (ref.read(selectedSpaceIdProvider) != null)
                    ? null
                    : 'You must select a space',
              ),
            ],
          ),
        ),
      ),
      actions: [
        ElevatedButton(
          onPressed: () => context.canPop()
              ? context.pop()
              : context.goNamed(Routes.main.name),
          child: const Text('Cancel'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.neutral,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
            side: BorderSide(
              color: Theme.of(context).colorScheme.success,
            ),
            foregroundColor: Theme.of(context).colorScheme.neutral6,
            textStyle: Theme.of(context).textTheme.bodySmall,
          ),
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
                final space = await ref.watch(spaceProvider(spaceId!).future);
                final pinDraft = space.pinDraft();
                pinDraft.title(ref.read(titleProvider));
                if (ref.read(selectedTypeProvider) == 'text') {
                  pinDraft.contentMarkdown(ref.read(textProvider));
                } else {
                  pinDraft.url(ref.read(linkProvider));
                }
                final pinId = await pinDraft.send();
                // reset providers
                ref.read(titleProvider.notifier).state = '';
                ref.read(textProvider.notifier).state = '';
                Navigator.of(context, rootNavigator: true).pop();
                context.goNamed(
                  Routes.pin.name,
                  pathParameters: {'pinId': pinId.toString()},
                );
              } catch (e) {
                customMsgSnackbar(context, 'Failed to pin: $e');
              }
            }
          },
          child: const Text('Create Pin'),
          style: ElevatedButton.styleFrom(
            backgroundColor: _titleInput.isNotEmpty
                ? Theme.of(context).colorScheme.success
                : Theme.of(context).colorScheme.success.withOpacity(0.6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
            foregroundColor: Theme.of(context).colorScheme.neutral6,
            textStyle: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    );
  }
}
