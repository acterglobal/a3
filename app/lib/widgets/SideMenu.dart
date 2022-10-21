import 'package:effektio/common/store/themes/SeperatedThemes.dart';
import 'package:effektio/screens/UserScreens/SocialProfile.dart';
import 'package:effektio/widgets/CustomAvatar.dart';
import 'package:effektio_flutter_sdk/effektio_flutter_sdk.dart'
    show EffektioSdk;
import 'package:effektio_flutter_sdk/effektio_flutter_sdk_ffi.dart' hide Color;
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:themed/themed.dart';

class SideDrawer extends StatefulWidget {
  final Client client;

  const SideDrawer({Key? key, required this.client}) : super(key: key);

  @override
  State<SideDrawer> createState() => _SideDrawerState();
}

class _SideDrawerState extends State<SideDrawer> {
  late Future<String> displayName;
  late Future<FfiBufferUint8> avatar;

  @override
  void initState() {
    super.initState();

    if (!widget.client.isGuest()) {
      displayName = getDisplayName();
      avatar = getAvatar();
    }
  }

  Future<String> getDisplayName() async => await widget.client.displayName();
  Future<FfiBufferUint8> getAvatar() async => await widget.client.avatar();

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
              buildHeader(),
              SizedBox(height: size.height * 0.04),
              buildTodoItem(),
              buildGalleryItem(),
              buildEventItem(),
              buildSharedResourcesItem(),
              buildPollsItem(),
              buildGroupBudgetingItem(),
              buildSharedDocumentsItem(),
              buildFaqItem(),
              const SizedBox(height: 5),
              buildLogoutItem(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildHeader() {
    if (widget.client.isGuest()) {
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
        Navigator.pushNamed(context, '/profile', arguments: widget.client);
      },
      child: Row(
        children: [
          Container(
            margin: const EdgeInsets.all(10),
            child: CustomAvatar(
              radius: 24,
              avatar: avatar,
              displayName: displayName,
              isGroup: false,
              stringName: '',
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
    return FutureBuilder<String>(
      future: displayName, // a previously-obtained Future<String> or null
      builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                '${snapshot.error} occurred',
                style: const TextStyle(fontSize: 18),
              ),
            );
          }
          if (snapshot.hasData) {
            return Text(
              snapshot.data ?? AppLocalizations.of(context)!.noName,
              style: SideMenuAndProfileTheme.sideMenuProfileStyle,
            );
          }
        }
        return const SizedBox(
          height: 20,
          width: 20,
          child: CircularProgressIndicator(color: AppCommonTheme.primaryColor),
        );
      },
    );
  }

  Widget buildUserId() {
    return Text(
      widget.client.userId().toString(),
      style: SideMenuAndProfileTheme.sideMenuProfileStyle + const FontSize(14),
    );
  }

  Widget buildTodoItem() {
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

  Widget buildGalleryItem() {
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

  Widget buildEventItem() {
    return ListTile(
      leading: SvgPicture.asset(
        'assets/images/event.svg',
        width: 25,
        height: 25,
        color: Colors.teal[700],
      ),
      title: Text(
        AppLocalizations.of(context)!.events,
        style: SideMenuAndProfileTheme.sideMenuStyle,
      ),
      onTap: () {},
    );
  }

  Widget buildSharedResourcesItem() {
    return ListTile(
      leading: SvgPicture.asset(
        'assets/images/shared_resources.svg',
        width: 25,
        height: 25,
        color: Colors.teal[700],
      ),
      title: Text(
        AppLocalizations.of(context)!.sharedResource,
        style: SideMenuAndProfileTheme.sideMenuStyle,
      ),
      onTap: () => {},
    );
  }

  Widget buildPollsItem() {
    return ListTile(
      leading: SvgPicture.asset(
        'assets/images/polls.svg',
        width: 25,
        height: 25,
        color: Colors.teal[700],
      ),
      title: Text(
        AppLocalizations.of(context)!.pollsVotes,
        style: SideMenuAndProfileTheme.sideMenuStyle,
      ),
      onTap: () => {},
    );
  }

  Widget buildGroupBudgetingItem() {
    return ListTile(
      leading: SvgPicture.asset(
        'assets/images/group_budgeting.svg',
        width: 25,
        height: 25,
        color: Colors.teal[700],
      ),
      title: Text(
        AppLocalizations.of(context)!.groupBudgeting,
        style: SideMenuAndProfileTheme.sideMenuStyle,
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const SocialProfileScreen(),
          ),
        );
      },
    );
  }

  Widget buildSharedDocumentsItem() {
    return ListTile(
      leading: SvgPicture.asset(
        'assets/images/shared_documents.svg',
        width: 25,
        height: 25,
        color: Colors.teal[700],
      ),
      title: Text(
        AppLocalizations.of(context)!.sharedDocuments,
        style: SideMenuAndProfileTheme.sideMenuStyle,
      ),
      onTap: () {},
    );
  }

  Widget buildFaqItem() {
    return ListTile(
      leading: SvgPicture.asset(
        'assets/images/faq.svg',
        width: 25,
        height: 25,
        color: Colors.teal[700],
      ),
      title: Text(
        AppLocalizations.of(context)!.faqs,
        style: SideMenuAndProfileTheme.sideMenuStyle,
      ),
      onTap: () {},
    );
  }

  Widget buildLogoutItem(BuildContext context) {
    if (widget.client.isGuest()) {
      return const SizedBox();
    }
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
        final sdk = await EffektioSdk.instance;
        await sdk.logout();
        Navigator.pushReplacementNamed(context, '/login');
      },
    );
  }
}
