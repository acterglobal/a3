import 'package:acter/common/controllers/spaces_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SpaceOverview extends ConsumerStatefulWidget {
  final String spaceIdOrAlias;
  const SpaceOverview({super.key, required this.spaceIdOrAlias});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _SpaceOverviewState();
}

class _SpaceOverviewState extends ConsumerState<SpaceOverview> {
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
                          'https://images.unsplash.com/photo-1439405326854-014607f694d7?ixlib=rb-4.0.3&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=2070&q=80',
                        ),
                        fit: BoxFit.cover,
                      ),
                    ),
                    child: Container(
                      width: double.infinity,
                      height: 200,
                      child: Container(
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
                    ),
                  ),
                  const SizedBox(
                    height: 60,
                  ),
                  Text(
                    profile.displayName,
                    style: const TextStyle(
                      fontSize: 25.0,
                      color: Colors.blueGrey,
                      letterSpacing: 2.0,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
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
