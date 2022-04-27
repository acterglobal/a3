// ignore_for_file: prefer_const_constructors, avoid_unnecessary_containers, sized_box_for_whitespace, prefer_final_fields

import 'package:effektio/common/store/Colors.dart';
import 'package:effektio/common/widget/ChatOverview.dart';
import 'package:effektio/repository/client.dart';
import 'package:effektio_flutter_sdk/effektio_flutter_sdk_ffi.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ChatList extends StatefulWidget {
  const ChatList({Key? key, required this.client}) : super(key: key);
  final Future<Client> client;

  @override
  State<ChatList> createState() => _ChatListState();
}

class _ChatListState extends State<ChatList> {
  String? userId = '';

  @override
  void initState() {
    _getUser();
    super.initState();
  }

  static const TextStyle optionStyle =
      TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.white);

  Future<void> _getUser() async {
    final String? id = await getUser(widget.client);
    setState(() {
      userId = id;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromRGBO(36, 38, 50, 1),
      appBar: AppBar(
        leadingWidth: MediaQuery.of(context).size.width / 5,
        toolbarHeight: MediaQuery.of(context).size.height / 15,
        backgroundColor: Color.fromRGBO(36, 38, 50, 1),
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.only(left: 10),
          child: TextButton(
            onPressed: () {},
            child: Text(
              'Select',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.primaryColor,
              ),
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
              width: 20,
              height: 20,
            ),
          ),
        ],
      ),
      body: Container(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                margin: const EdgeInsets.only(
                  left: 18,
                ),
                child: Text(
                  'Chat',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              FutureBuilder<Client>(
                future: widget.client,
                builder:
                    (BuildContext context, AsyncSnapshot<Client> snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return SizedBox(
                      height: MediaQuery.of(context).size.height / 1.5,
                      width: MediaQuery.of(context).size.width,
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primaryColor,
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
                            userId: userId,
                            rooms: snapshot.requireData.toList(),
                          );
                        } else {
                          return Center(
                            child: Container(
                              height: MediaQuery.of(context).size.height,
                              width: MediaQuery.of(context).size.width,
                              color: AppColors.backgroundColor,
                              child: Text(
                                AppLocalizations.of(context)!.loadingConvo,
                                style: optionStyle,
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
                          'Looks Empty here...',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(
                          height: 5,
                        ),
                        Center(
                          child: Container(
                            height: MediaQuery.of(context).size.height / 3,
                            width: MediaQuery.of(context).size.width / 2,
                            child: Text(
                              'Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
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
            ],
          ),
        ),
      ),
    );
  }
}
