import 'package:acter/common/controllers/spaces_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SpaceShell extends ConsumerStatefulWidget {
  final String spaceIdOrAlias;
  final Widget child;
  const SpaceShell({
    super.key,
    required this.spaceIdOrAlias,
    required this.child,
  });

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _SpaceShellState();
}

class _SpaceShellState extends ConsumerState<SpaceShell> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // get platform of context.
    final space = ref.watch(spaceProvider(widget.spaceIdOrAlias));
    return space.when(
      data: (space) {
        final profileData = ref.watch(spaceProfileDataProvider(space));
        return profileData.when(
          data: (profile) => Scaffold(
            body: SafeArea(
              child: Column(
                children: [
                  Container(
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
                    child: SizedBox(
                      width: double.infinity,
                      height: 200,
                      child: Row(
                        children: [
                          Container(
                            alignment: const Alignment(-0.95, 5.0),
                            child: profile.avatar != null
                                ? CircleAvatar(
                                    foregroundImage: MemoryImage(
                                      profile.avatar!,
                                    ),
                                    radius: 80,
                                  )
                                : SvgPicture.asset(
                                    'assets/icon/acter.svg',
                                    height: 24,
                                    width: 24,
                                  ),
                          ),
                          Container(
                            alignment: const Alignment(2, 1.70),
                            child: Text(
                              profile.displayName,
                              style: const TextStyle(
                                fontSize: 25.0,
                                color: Colors.blueGrey,
                                letterSpacing: 2.0,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 110,
                    width: double.infinity,
                  ),
                  const SizedBox(
                    height: 70,
                    width: double.infinity,
                    child: Text('Submenu'),
                  ),
                  Expanded(child: widget.child),
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
