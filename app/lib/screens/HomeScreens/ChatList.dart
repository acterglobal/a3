// ignore_for_file: prefer_const_constructors, avoid_unnecessary_containers, sized_box_for_whitespace, prefer_final_fields

import 'package:effektio/common/store/separatedThemes.dart';
import 'package:effektio/common/widget/ChatOverview.dart';
import 'package:effektio_flutter_sdk/effektio_flutter_sdk_ffi.dart'
    show Client, FfiListConversation;
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:themed/themed.dart';

class ChatList extends StatefulWidget {
  const ChatList({Key? key, required this.client}) : super(key: key);
  final Future<Client> client;

  @override
  State<ChatList> createState() => _ChatListState();
}

class _ChatListState extends State<ChatList> {
  String? user;

  @override
  void initState() {
    super.initState();
    _getUser().whenComplete(() => {setState(() {})});
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _getUser() async {
    var fetchClient = await widget.client;
    user = await fetchClient.userId().then((u) => u.toString());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leadingWidth: MediaQuery.of(context).size.width / 5,
        toolbarHeight: MediaQuery.of(context).size.height / 15,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.only(left: 10),
          child: TextButton(
            onPressed: () {},
            child: Text(
              AppLocalizations.of(context)!.select,
              style: ChatTheme01.chatTitleStyle + AppCommonTheme.primaryColor,
            ),
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            padding: const EdgeInsets.only(
              right: 10,
            ),
            icon: SvgPicture.asset(
              'assets/images/edit.svg',
              color: AppCommonTheme.svgIconColor,
              width: 20,
              height: 20,
            ),
          ),
        ],
      ),
      body: Container(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              margin: const EdgeInsets.only(
                left: 18,
              ),
              child: Text(
                AppLocalizations.of(context)!.chat,
                style: AppCommonTheme.appBartitleStyle,
              ),
            ),
            const SizedBox(
              height: 10,
            ),
            Expanded(
              child: Container(
                child: FutureBuilder<Client>(
                  future: widget.client,
                  builder:
                      (BuildContext context, AsyncSnapshot<Client> snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return SizedBox(
                        height: MediaQuery.of(context).size.height / 1.5,
                        width: MediaQuery.of(context).size.width,
                        child: Center(
                          child: CircularProgressIndicator(
                            color: AppCommonTheme.primaryColor,
                          ),
                        ),
                      );
                    }
                    if (snapshot.hasData) {
                      return FutureBuilder<FfiListConversation>(
                        future: snapshot.requireData
                            .conversations(), // a previously-obtained Future<String> or null
                        builder: (
                          BuildContext context,
                          AsyncSnapshot<FfiListConversation> snapshot,
                        ) {
                          if (snapshot.hasData) {
                            return ChatOverview(
                              user: user,
                              rooms: snapshot.requireData.toList(),
                            );
                          } else {
                            return Center(
                              child: Container(
                                height: MediaQuery.of(context).size.height,
                                width: MediaQuery.of(context).size.width,
                                color: AppCommonTheme.backgroundColor,
                                child: Text(
                                  AppLocalizations.of(context)!.loadingConvo,
                                  style: ChatTheme01.emptyMsgTitle,
                                ),
                              ),
                            );
                          }
                        },
                      );
                    } else {
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          SizedBox(
                            height: MediaQuery.of(context).size.height / 6,
                          ),
                          Center(
                            child: Container(
                              child: SvgPicture.asset(
                                'assets/images/empty_messages.svg',
                              ),
                            ),
                          ),
                          SizedBox(
                            height: 20,
                          ),
                          Text(
                            AppLocalizations.of(context)!.loadingConvo + '...',
                            style: ChatTheme01.emptyMsgTitle,
                          ),
                          SizedBox(
                            height: 5,
                          ),
                          Center(
                            child: Container(
                              height: MediaQuery.of(context).size.height / 3,
                              width: MediaQuery.of(context).size.width / 1.5,
                              child: Text(
                                'Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.',
                                style: ChatTheme01.chatBodyStyle,
                                overflow: TextOverflow.clip,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ],
                      );
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
