import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/widgets/spaces/space_card.dart';
import 'package:acter/features/home/data/keys.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class MySpacesSection extends ConsumerWidget {
  final int? limit;

  const MySpacesSection({super.key, this.limit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spaces = ref.watch(spacesProvider);

    int spacesLimit =
        (limit != null && spaces.length > limit!) ? limit! : spaces.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          key: DashboardKeys.widgetMySpacesHeader,
          onTap: () => context.pushNamed(Routes.spaces.name),
          child: Text(
            'My Spaces',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        spaces.isEmpty
            ? const _NoSpacesWidget()
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ListView.builder(
                    shrinkWrap: true,
                    itemCount: spacesLimit,
                    physics: const NeverScrollableScrollPhysics(),
                    itemBuilder: (context, index) {
                      return SpaceCard(space: spaces[index]);
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: spacesLimit != spaces.length
                        ? OutlinedButton(
                            onPressed: () {
                              context.pushNamed(Routes.spaces.name);
                            },
                            child: Text('See all my ${spaces.length} spaces'),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              OutlinedButton(
                                onPressed: () =>
                                    context.pushNamed(Routes.createSpace.name),
                                child: const Text('Create Space'),
                              ),
                              const SizedBox(height: 10),
                              ElevatedButton(
                                onPressed: () =>
                                    context.pushNamed(Routes.joinSpace.name),
                                child: const Text('Join Space'),
                              ),
                            ],
                          ),
                  ),
                ],
              ),
      ],
    );
  }
}

class _NoSpacesWidget extends ConsumerWidget {
  const _NoSpacesWidget();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: <Widget>[
        const SizedBox(height: 15),
        Text(
          'You are currently not connected to any spaces',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 30),
        RichText(
          text: TextSpan(
            children: <TextSpan>[
              TextSpan(
                text: 'Create\t',
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      decoration: TextDecoration.underline,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const TextSpan(text: 'or\t'),
              TextSpan(
                text: 'join\t',
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      decoration: TextDecoration.underline,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              TextSpan(
                text: 'a space, to start organizing and collaborating',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
          softWrap: true,
        ),
        SizedBox(height: MediaQuery.of(context).size.height * 0.15),
        Center(
          child: ElevatedButton(
            onPressed: () => context.pushNamed(Routes.createSpace.name),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.neutral6,
              foregroundColor: Theme.of(context).colorScheme.neutral,
              textStyle: Theme.of(context).textTheme.bodyLarge,
              fixedSize: const Size(311, 61),
              shape: RoundedRectangleBorder(
                side: BorderSide.none,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Create New Space'),
                SizedBox(width: 10),
                Icon(Icons.chevron_right_outlined),
              ],
            ),
          ),
        ),
        const SizedBox(height: 36),
        Center(
          child: ElevatedButton(
            onPressed: () {
              context.pushNamed(Routes.joinSpace.name);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              foregroundColor: Theme.of(context).colorScheme.neutral6,
              textStyle: Theme.of(context).textTheme.bodyLarge,
              fixedSize: const Size(311, 61),
              shape: RoundedRectangleBorder(
                side: BorderSide(
                  color: Theme.of(context).colorScheme.neutral6,
                ),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            child: const Text('Join Existing Space'),
          ),
        ),
      ],
    );
  }
}
