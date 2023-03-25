import 'package:acter/common/controllers/spaces_controller.dart';
import 'package:acter/features/space/widgets/top_nav.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SpaceShell extends ConsumerWidget {
  final String spaceIdOrAlias;
  final Widget child;
  const SpaceShell({
    super.key,
    required this.spaceIdOrAlias,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // get platform of context.
    final space = ref.watch(spaceProvider(spaceIdOrAlias));
    return space.when(
      data: (space) {
        final profileData = ref.watch(spaceProfileDataProvider(space));
        return profileData.when(
          data: (profile) => Scaffold(
            body: SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.42,
                    child: Stack(
                      children: <Widget>[
                        Container(
                          height: MediaQuery.of(context).size.height * 0.28,
                          decoration: const BoxDecoration(
                            image: DecorationImage(
                              image: NetworkImage(
                                // FIXME: load image from actual settings
                                // and add default fallback to assets
                                'https://images.unsplash.com/photo-1439405326854-014607f694d7?ixlib=rb-4.0.3&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=2070&q=80',
                              ),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          left: 30,
                          top: 110,
                          child: profile.avatar != null
                              ? CircleAvatar(
                                  foregroundImage: MemoryImage(
                                    profile.avatar!,
                                  ),
                                  radius: 80,
                                )
                              : CircleAvatar(
                                  radius: 80,
                                  backgroundColor:
                                      Theme.of(context).colorScheme.secondary,
                                  child: SvgPicture.asset(
                                    'assets/icon/acter.svg',
                                  ),
                                ),
                        ),
                        Positioned(
                          left: 180,
                          top: 210,
                          child: Container(
                            margin: const EdgeInsets.only(left: 20),
                            child: Text(
                              profile.displayName,
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const TopNavBar(isDesktop: true),
                  Expanded(child: child),
                ],
              ),
            ),
          ),
          error: (error, stack) => Text('Loading failed: $error'),
          loading: () => const Text('Loading'),
        );
      },
      error: (error, stack) => Text('Loading failed: $error'),
      loading: () => const Text('Loading'),
    );
  }
}
