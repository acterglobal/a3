import 'package:effektio/common/store/themes/SeperatedThemes.dart';
import 'package:effektio/widgets/AppCommon.dart';
import 'package:effektio/widgets/CrossSigning.dart';
import 'package:effektio/widgets/CustomAvatar.dart';
import 'package:effektio_flutter_sdk/effektio_flutter_sdk.dart'
    show EffektioSdk;
import 'package:effektio_flutter_sdk/effektio_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_icons_null_safety/flutter_icons_null_safety.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:themed/themed.dart';

class SideDrawer extends StatelessWidget {
  final bool isGuest;
  final String? displayName;
  final String userId;
  final Future<FfiBufferUint8>? displayAvatar;

  const SideDrawer({
    Key? key,
    required this.isGuest,
    required this.userId,
    this.displayName,
    this.displayAvatar,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Drawer(
      backgroundColor: AppCommonTheme.backgroundColor,
      child: ScrollConfiguration(
        behavior: const ScrollBehavior().copyWith(overscroll: false),
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 20),
              buildHeader(context),
              SizedBox(height: size.height * 0.04),
              buildPinsItem(context),
              buildTodoItem(context),
              buildVaultsItem(context),
              buildEventItem(context),
              buildSharedResourcesItem(context),
              buildPollsItem(context),
              buildGroupBudgetingItem(context),
              buildSharedDocumentsItem(context),
              buildGalleryItem(context),
              const SizedBox(height: 5),
              if (!isGuest) buildLogoutItem(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildHeader(BuildContext context) {
    if (isGuest) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            margin: const EdgeInsets.only(right: 20),
            alignment: Alignment.bottomCenter,
            child: ElevatedButton(
              style: ButtonStyle(
                alignment: Alignment.center,
                backgroundColor: MaterialStateProperty.all<Color>(
                  AppCommonTheme.primaryColor,
                ),
              ),
              onPressed: () {
                Navigator.pushNamed(context, '/login');
              },
              child: Text(AppLocalizations.of(context)!.login),
            ),
          ),
          Container(
            alignment: Alignment.bottomCenter,
            child: ElevatedButton(
              style: ButtonStyle(
                alignment: Alignment.center,
                backgroundColor: MaterialStateProperty.all<Color>(
                  AppCommonTheme.primaryColor,
                ),
              ),
              onPressed: () {
                Navigator.pushNamed(context, '/signup');
              },
              child: Text(AppLocalizations.of(context)!.signUp),
            ),
          ),
        ],
      );
    }
    return GestureDetector(
      onTap: () {
        showNotYetImplementedMsg(
          context,
          'Profile View not implemented yet',
        );
      },
      child: Row(
        children: [
          Container(
            margin: const EdgeInsets.all(10),
            child: CustomAvatar(
              uniqueKey: userId,
              radius: 24,
              cacheHeight: 120,
              cacheWidth: 120,
              avatar: displayAvatar,
              displayName: displayName,
              isGroup: false,
              stringName: displayName!,
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildDisplayName(),
              buildUserId(),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildDisplayName() {
    if (displayName == null) {
      return const SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(color: AppCommonTheme.primaryColor),
      );
    }
    return Text(
      displayName!,
      style: SideMenuAndProfileTheme.sideMenuProfileStyle,
    );
  }

  Widget buildUserId() {
    return Text(
      userId,
      style: SideMenuAndProfileTheme.sideMenuProfileStyle + const FontSize(14),
    );
  }

  Widget buildTodoItem(BuildContext context) {
    return ListTile(
      leading: SvgPicture.asset(
        'assets/images/task.svg',
        width: 25,
        height: 25,
        color: Colors.teal[700],
      ),
      title: Text(
        AppLocalizations.of(context)!.toDoList,
        style: SideMenuAndProfileTheme.sideMenuStyle,
      ),
      onTap: () {
        Navigator.pushNamed(context, '/todo');
      },
    );
  }

  Widget buildGalleryItem(BuildContext context) {
    return ListTile(
      leading: SvgPicture.asset(
        'assets/images/gallery.svg',
        width: 25,
        height: 25,
        color: Colors.teal[700],
      ),
      title: Text(
        AppLocalizations.of(context)!.gallery,
        style: SideMenuAndProfileTheme.sideMenuStyle,
      ),
      onTap: () {
        Navigator.pushNamed(context, '/gallery');
      },
    );
  }

  Widget buildEventItem(BuildContext context) {
    return ListTile(
      leading: SvgPicture.asset(
        'assets/images/event.svg',
        width: 25,
        height: 25,
        color: Colors.teal[900],
      ),
      title: Text(
        AppLocalizations.of(context)!.events,
        style: SideMenuAndProfileTheme.sideMenuStyleDisabled,
      ),
      onTap: () {
        showNotYetImplementedMsg(
          context,
          'Events is not implemented yet',
        );
      },
    );
  }

  Widget buildSharedResourcesItem(BuildContext context) {
    return ListTile(
      leading: SvgPicture.asset(
        'assets/images/shared_resources.svg',
        width: 25,
        height: 25,
        color: Colors.teal[900],
      ),
      title: Text(
        AppLocalizations.of(context)!.sharedResource,
        style: SideMenuAndProfileTheme.sideMenuStyleDisabled,
      ),
      onTap: () {
        showNotYetImplementedMsg(
          context,
          'Shared Resources is not implemented yet',
        );
      },
    );
  }

  Widget buildPollsItem(BuildContext context) {
    return ListTile(
      leading: SvgPicture.asset(
        'assets/images/polls.svg',
        width: 25,
        height: 25,
        color: Colors.teal[900],
      ),
      title: Text(
        AppLocalizations.of(context)!.pollsVotes,
        style: SideMenuAndProfileTheme.sideMenuStyleDisabled,
      ),
      onTap: () {
        showNotYetImplementedMsg(
          context,
          'Polls are not implemented yet',
        );
      },
    );
  }

  Widget buildGroupBudgetingItem(BuildContext context) {
    return ListTile(
      leading: SvgPicture.asset(
        'assets/images/group_budgeting.svg',
        width: 25,
        height: 25,
        color: Colors.teal[900],
      ),
      title: Text(
        AppLocalizations.of(context)!.groupBudgeting,
        style: SideMenuAndProfileTheme.sideMenuStyleDisabled,
      ),
      onTap: () {
        showNotYetImplementedMsg(
          context,
          'Co-Budgeting is not implemented yet',
        );
      },
    );
  }

  Widget buildVaultsItem(BuildContext context) {
    return ListTile(
      leading: Icon(
        FlutterIcons.safe_mco,
        color: Colors.teal[700],
      ),
      title: Text(
        AppLocalizations.of(context)!.vault,
        style: SideMenuAndProfileTheme.sideMenuStyleDisabled,
      ),
      onTap: () {
        showNotYetImplementedMsg(
          context,
          'Vault is not implemented yet',
        );
      },
    );
  }

  Widget buildSharedDocumentsItem(BuildContext context) {
    return ListTile(
      leading: SvgPicture.asset(
        'assets/images/shared_documents.svg',
        width: 25,
        height: 25,
        color: Colors.teal[900],
      ),
      title: Text(
        AppLocalizations.of(context)!.sharedDocuments,
        style: SideMenuAndProfileTheme.sideMenuStyleDisabled,
      ),
      onTap: () {
        showNotYetImplementedMsg(
          context,
          'Shared Docs is not implemented yet',
        );
      },
    );
  }

  Widget buildPinsItem(BuildContext context) {
    return ListTile(
      leading: Icon(
        FlutterIcons.pin_ent,
        color: Colors.teal[700],
      ),
      title: Text(
        AppLocalizations.of(context)!.pins,
        style: SideMenuAndProfileTheme.sideMenuStyle,
      ),
      onTap: () {
        showNotYetImplementedMsg(
          context,
          'Pins from Sidebar is not implemented yet',
        );
      },
    );
  }

  Widget buildLogoutItem(BuildContext context) {
    return ListTile(
      leading: SvgPicture.asset(
        'assets/images/logout.svg',
        width: 25,
        height: 25,
        color: AppCommonTheme.primaryColor,
      ),
      title: Text(
        AppLocalizations.of(context)!.logOut,
        style: SideMenuAndProfileTheme.signOutText,
      ),
      onTap: () async {
        if (Get.isRegistered<CrossSigning>()) {
          var crossSigning = Get.find<CrossSigning>();
          crossSigning.dispose();
          Get.delete<CrossSigning>();
        }
        final sdk = await EffektioSdk.instance;
        await sdk.logout();
        Navigator.pushReplacementNamed(context, '/');
      },
    );
  }
}
