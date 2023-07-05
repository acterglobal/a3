import 'package:acter/common/snackbars/custom_msg.dart';
import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/widgets/input_text_field.dart';
import 'package:acter/common/widgets/side_sheet.dart';
import 'package:acter/features/home/widgets/space_chip.dart';
import 'package:acter/common/providers/space_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:acter/features/spaces/dialogs/space_selector_sheet.dart';

// interface data providers
final titleProvider = StateProvider<String>((ref) => '');

class CreateEventSheet extends ConsumerStatefulWidget {
  final String? initialSelectedSpace;
  const CreateEventSheet({super.key, this.initialSelectedSpace});

  @override
  ConsumerState<CreateEventSheet> createState() =>
      _CreateEventSheetConsumerState();
}

class _CreateEventSheetConsumerState extends ConsumerState<CreateEventSheet> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _linkController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future(() {
      ref.read(parentSpaceProvider.notifier).state =
          widget.initialSelectedSpace;
    });
  }

  @override
  Widget build(BuildContext context) {
    final _titleInput = ref.watch(titleProvider);
    final currentParentSpace = ref.watch(parentSpaceProvider);
    final _selectParentSpace = currentParentSpace != null;
    return SideSheet(
      header: 'Create new event',
      addActions: true,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text('Create new event for your community'),
            const SizedBox(height: 15),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Padding(
                  padding: EdgeInsets.only(bottom: 5),
                  child: Text('Name'),
                ),
                InputTextField(
                  hintText: 'Type Name',
                  textInputType: TextInputType.multiline,
                  controller: _nameController,
                  onInputChanged: _handleTitleChange,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Padding(
                        padding: EdgeInsets.only(bottom: 5),
                        child: Text('Date'),
                      ),
                      InputTextField(
                        hintText: 'Select Date',
                        textInputType: TextInputType.multiline,
                        onInputChanged: _handleTitleChange,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Padding(
                        padding: EdgeInsets.only(bottom: 5),
                        child: Text('Time'),
                      ),
                      InputTextField(
                        hintText: 'Select Time',
                        textInputType: TextInputType.multiline,
                        onInputChanged: _handleTitleChange,
                      ),
                    ],
                  ),
                )
              ],
            ),
            const SizedBox(height: 15),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text('Description'),
                const SizedBox(height: 15),
                InputTextField(
                  controller: _descriptionController,
                  hintText: 'Type Description (Optional)',
                  textInputType: TextInputType.multiline,
                  maxLines: 10,
                ),
                const SizedBox(height: 15),
                const Text('Link'),
                const SizedBox(height: 15),
                InputTextField(
                  controller: _descriptionController,
                  hintText: 'Insert a link',
                  textInputType: TextInputType.multiline,
                  maxLines: 1,
                ),
                const SizedBox(height: 15),
                ListTile(
                  title: Text(
                    _selectParentSpace ? 'Space' : 'No space selected',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  trailing: _selectParentSpace
                      ? Consumer(
                          builder: (context, ref, child) =>
                              ref.watch(parentSpaceDetailsProvider).when(
                                    data: (space) => space != null
                                        ? SpaceChip(space: space)
                                        : Text(currentParentSpace),
                                    error: (e, s) => Text('error: $e'),
                                    loading: () => const Text('loading'),
                                  ),
                        )
                      : null,
                  onTap: () async {
                    final currentSpaceId = ref.read(parentSpaceProvider);
                    final newSelectedSpaceId = await selectSpaceDrawer(
                      context: context,
                      currentSpaceId: currentSpaceId,
                      title: const Text('Select parent space'),
                    );
                    ref.read(parentSpaceProvider.notifier).state =
                        newSelectedSpaceId;
                  },
                )
              ],
            ),
          ],
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
            if (_titleInput.isEmpty) {
              customMsgSnackbar(
                context,
                'Please enter event name',
              );
              return;
            }
            return;
          },
          child: const Text('Create Event'),
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

  void _handleTitleChange(String? value) {
    ref.read(titleProvider.notifier).update((state) => value!);
  }
}
