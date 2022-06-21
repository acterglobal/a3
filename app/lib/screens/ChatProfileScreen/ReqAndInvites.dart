// ignore_for_file: non_constant_identifier_names

import 'package:effektio/common/store/separatedThemes.dart';
import 'package:flutter/material.dart';

class RequestScreen extends StatefulWidget {
  const RequestScreen({Key? key}) : super(key: key);

  @override
  _RequestScreenState createState() => _RequestScreenState();
}

class _RequestScreenState extends State<RequestScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const AppBarTheme().backgroundColor,
        elevation: 0.0,
        title: const Text('Request & Invites'),
        centerTitle: true,
      ),
      body: Container(
        child: Tabbar(context, 5, 3),
      ),
    );
  }

  Widget Tabbar(BuildContext context, int reqLength, int pendingLength) {
    return DefaultTabController(
      length: 2,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: TabBar(
              labelColor: Colors.white, //<-- selected text color
              unselectedLabelColor: Colors.white,
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(15), // Creates border
                color: AppCommonTheme.primaryColor,
              ),
              indicatorPadding: const EdgeInsets.only(top: 6, bottom: 6),
              tabs: const [
                Tab(
                  text: 'Invites',
                ),
                Tab(text: 'Requests'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                Column(
                  children: [
                    Visibility(
                      visible: (pendingLength > 0) ? true : false,
                      child: ListView.builder(
                        itemCount: pendingLength,
                        shrinkWrap: true,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.only(
                              left: 8.0,
                              right: 8.0,
                              top: 8.0,
                            ),
                            child: ListTile(
                              leading: const CircleAvatar(
                                backgroundColor: Colors.white,
                              ),
                              title: const Text(
                                'Ben',
                                style: TextStyle(color: Colors.white),
                              ),
                              trailing: Text(
                                'Pending',
                                style: TextStyle(color: Colors.grey[700]),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 200),
                      child: Visibility(
                        visible: (pendingLength == 0),
                        child: Column(
                          children: [
                            SizedBox(
                              height: 200,
                              width: 200,
                              child: FittedBox(
                                fit: BoxFit.contain,
                                child: Image.asset(
                                  'assets/images/no_req.png',
                                ),
                              ),
                            ),
                            const Text(
                              'No Invite Yet',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18.0,
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text(
                                'People on this list are attempting to join via the group link.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16.0,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  ],
                ),
                Column(
                  children: [
                    Visibility(
                      visible: (reqLength > 0),
                      child: ListView.builder(
                        itemCount: reqLength,
                        shrinkWrap: true,
                        itemBuilder: (context, index) {
                          return const Padding(
                            padding: EdgeInsets.only(
                              left: 8.0,
                              right: 8.0,
                              top: 8.0,
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.white,
                              ),
                              title: Text(
                                'Ben',
                                style: TextStyle(color: Colors.white),
                              ),
                              trailing: Text(
                                'Accept',
                                style: TextStyle(
                                    color: AppCommonTheme.primaryColor),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 200),
                      child: Visibility(
                        visible: (reqLength == 0),
                        child: Column(
                          children: [
                            SizedBox(
                              height: 200,
                              width: 200,
                              child: FittedBox(
                                fit: BoxFit.contain,
                                child: Image.asset(
                                  'assets/images/no_req.png',
                                ),
                              ),
                            ),
                            const Text(
                              'No Requests Yet',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18.0,
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text(
                                'People on this list are attempting to join via the group link.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16.0,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
