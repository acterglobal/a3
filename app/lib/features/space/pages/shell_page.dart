import 'package:acter/features/space/providers/space_providers.dart';
import 'package:acter/features/space/widgets/top_nav.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
  String _dropDownValue = 'Member';
  List<String> dropDownItems = [
    'Member',
    'Admin',
  ];
  @override
  Widget build(BuildContext context) {
    // get platform of context.
    final space = ref.watch(spaceProvider(widget.spaceIdOrAlias));
    double h = MediaQuery.of(context).size.height;
    return space.when(
      data: (space) {
        final profileData = ref.watch(spaceProfileDataProvider(space));
        final canonicalParent =
            ref.watch(canonicalParentProvider(widget.spaceIdOrAlias));
        return profileData.when(
          data: (profile) => Scaffold(
            body: SafeArea(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 300,
                      child: Stack(
                        children: <Widget>[
                          Container(
                            height: 200,
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
                            child: ActerAvatar(
                              mode: DisplayMode.Space,
                              displayName: profile.displayName,
                              tooltip: TooltipStyle.None,
                              uniqueId: space.getRoomId().toString(),
                              avatar: profile.getAvatarImage(),
                              size: 160,
                            ),
                          ),
                          ...canonicalParent.when(
                            data: (parentProfile) {
                              if (parentProfile == null) {
                                return [];
                              }
                              return [
                                Positioned(
                                  left: 150,
                                  top: 250,
                                  child: Tooltip(
                                    message: parentProfile.profile.displayName,
                                    child: InkWell(
                                      onTap: () {
                                        final roomId =
                                            parentProfile.space.getRoomId();
                                        context.go('/$roomId');
                                      },
                                      child: ActerAvatar(
                                        mode: DisplayMode.Space,
                                        displayName:
                                            parentProfile.profile.displayName,
                                        uniqueId: parentProfile.space
                                            .getRoomId()
                                            .toString(),
                                        avatar: parentProfile.profile
                                            .getAvatarImage(),
                                        size: 40,
                                      ),
                                    ),
                                  ),
                                ),
                              ];
                            },
                            error: (error, stackTrace) => [],
                            loading: () => [],
                          ),
                          Positioned(
                            left: 180,
                            top: 210,
                            child: Container(
                              margin: const EdgeInsets.only(left: 20),
                              child: Text(
                                profile.displayName,
                                style:
                                    Theme.of(context).textTheme.headlineMedium,
                              ),
                            ),
                          ),
                          Positioned(
                            right: 40,
                            top: 230,
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton(
                                elevation: 0,
                                focusColor: Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                value: _dropDownValue,
                                onChanged: (String? value) {
                                  _dropDownValue = value!;
                                },
                                items: dropDownItems
                                    .map<DropdownMenuItem<String>>(
                                        (String item) {
                                  return DropdownMenuItem<String>(
                                    value: item,
                                    child: Text(
                                      item,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium!
                                          .copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .tertiary,
                                          ),
                                    ),
                                  );
                                }).toList(),
                                icon: Icon(
                                  Icons.expand_more,
                                  color: Theme.of(context).colorScheme.tertiary,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const TopNavBar(isDesktop: true),
                    SizedBox(
                      height: h < 800 ? h * 2 : h,
                      child: widget.child,
                    ),
                  ],
                ),
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
