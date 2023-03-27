import 'package:acter/common/controllers/spaces_controller.dart';
import 'package:acter/features/space/widgets/top_nav.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
                            child: profile.hasAvatar()
                                ? CircleAvatar(
                                    foregroundImage: profile.getAvatarImage(),
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
                          ...canonicalParent.when(
                            data: (parentProfile) {
                              if (parentProfile == null) {
                                return [];
                              }
                              return [
                                Positioned(
                                  left: 145,
                                  top: 230,
                                  child: Tooltip(
                                    message: parentProfile.profile.displayName,
                                    child: InkWell(
                                      onTap: () {
                                        final roomId =
                                            parentProfile.space.getRoomId();
                                        context.go("/$roomId");
                                      },
                                      child: parentProfile.profile.hasAvatar()
                                          ? CircleAvatar(
                                              foregroundImage: parentProfile
                                                  .profile
                                                  .getAvatarImage(),
                                              radius: 20,
                                            )
                                          : CircleAvatar(
                                              radius: 20,
                                              backgroundColor: Theme.of(context)
                                                  .colorScheme
                                                  .secondary,
                                              child: SvgPicture.asset(
                                                'assets/icon/acter.svg',
                                              ),
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
                      height: MediaQuery.of(context).size.height * 1.2,
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
