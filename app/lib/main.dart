// ignore_for_file: prefer_const_constructors

import 'dart:typed_data';
import 'package:effektio/repository/client.dart';
import 'package:effektio/screens/HomeScreens/HomeTabBar.dart';
import 'package:effektio/screens/OnboardingScreens/LogIn.dart';
import 'package:effektio/screens/OnboardingScreens/splashScreen.dart';
import 'package:effektio/screens/UserScreens/SocialProfile.dart';
import 'package:effektio_flutter_sdk/effektio_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:effektio/l10n/l10n.dart';
import 'dart:async';

import 'screens/HomeScreens/News.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // SharedPreferences prefs = await SharedPreferences.getInstance();
  // final flowStarted = prefs.getBool(KeyConstants.flowStarted) ?? false;
  // final userLoggedIn = prefs.getBool(KeyConstants.userLoggedIn) ?? false;
  // ignore: prefer_const_constructors
  runApp(
    const MaterialApp(
      //  builder: EasyLoading.init(),
      debugShowCheckedModeBanner: false,
      // ignore: prefer_const_constructors
      home: SplashScreen(),
    ),
  );
}

class Effektio extends StatelessWidget {
  const Effektio({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Effektio',
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: ApplicationLocalizations.supportedLocales,
      // MaterialApp contains our top-level Navigator
      initialRoute: '/',
      routes: <String, WidgetBuilder>{
        '/': (BuildContext context) => EffektioHome(),
        '/login': (BuildContext context) => const LoginScreen(),
        '/profile': (BuildContext context) => const SocialProfileScreen(),
      },
    );
  }
}

class AccountHeader extends StatefulWidget {
  final Client _client;

  const AccountHeader(this._client, {Key? key}) : super(key: key);

  @override
  _AccountHeaderState createState() => _AccountHeaderState();
}

class _AccountHeaderState extends State<AccountHeader> {
  // String dropdownValue = AppLocalizations.of(context).all;
  late Future<String> name;
  late Future<String> username;
  late Future<List<int>> avatar;

  _AccountHeaderState();

  @override
  void initState() {
    super.initState();
    name = widget._client.displayName();
    username = widget._client.userId();
    avatar = widget._client.avatar().then((fb) => fb.asTypedList());
  }

  @override
  Widget build(BuildContext context) {
    return UserAccountsDrawerHeader(
      accountName: FutureBuilder<String>(
        future: name, // a previously-obtained Future<String> or null
        builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
          if (snapshot.hasData) {
            return Text(
              snapshot.data ?? AppLocalizations.of(context)!.noName,
            );
          } else {
            return Text(AppLocalizations.of(context)!.loading + '...');
          }
        },
      ),
      accountEmail: FutureBuilder<String>(
        future: username, // a previously-obtained Future<String> or null
        builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
          if (snapshot.hasData) {
            return Text(
              snapshot.data ?? AppLocalizations.of(context)!.noAddr,
            );
          } else {
            return Text(AppLocalizations.of(context)!.loading + '...');
          }
        },
      ),
      currentAccountPicture: FutureBuilder<List<int>>(
        future: avatar, // a previously-obtained Future<String> or null
        builder: (BuildContext context, AsyncSnapshot<List<int>> snapshot) {
          if (snapshot.hasData) {
            return CircleAvatar(
              backgroundImage:
                  MemoryImage(Uint8List.fromList(snapshot.requireData)),
            );
          } else {
            return CircleAvatar(
              backgroundColor: Colors.brown.shade800,
              child: const Text('G'),
            );
          }
        },
      ),
    );
  }
}

class ChatListItem extends StatelessWidget {
  final Room room;

  const ChatListItem({Key? key, required this.room}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // ToDo: UnreadCounter
    return ListTile(
      leading: FutureBuilder<Uint8List>(
        future: room.avatar().then((fb) => fb.asTypedList()),
        // a previously-obtained Future<String> or null
        builder: (BuildContext context, AsyncSnapshot<List<int>> snapshot) {
          if (snapshot.hasData) {
            return CircleAvatar(
              backgroundImage:
                  MemoryImage(Uint8List.fromList(snapshot.requireData)),
            );
          } else {
            return CircleAvatar(
              backgroundColor: Colors.brown.shade800,
              child: const Text('H'),
            );
          }
        },
      ),
      title: FutureBuilder<String>(
        future: room.displayName(),
        builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
          if (snapshot.hasData) {
            return Text(snapshot.requireData);
          } else {
            return Text(AppLocalizations.of(context)!.loadingName);
          }
        },
      ),
      trailing: FutureBuilder<FfiListRoomMember>(
        future: room.activeMembers(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return Text(snapshot.requireData.length.toString());
          } else {
            return const SizedBox();
          }
        },
      ),
    );
  }
}

class ChatOverview extends StatelessWidget {
  final List<Room> rooms;

  const ChatOverview({Key? key, required this.rooms}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: rooms.length,
      itemBuilder: (BuildContext context, int index) {
        return ChatListItem(room: rooms[index]);
      },
    );
  }
}

class EffektioHome extends StatefulWidget {
  const EffektioHome({Key? key}) : super(key: key);

  @override
  _EffektioHomeState createState() => _EffektioHomeState();
}

class _EffektioHomeState extends State<EffektioHome> {
  late Future<Client> _client;
  String dropdownValue = 'All';
  int _tabIndex = 0;

  static const TextStyle optionStyle =
      TextStyle(fontSize: 30, fontWeight: FontWeight.bold);

  @override
  void initState() {
    super.initState();
    _client = makeClient();
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> _widgetOptions = <Widget>[
      NewsScreen(),
      Center(
        child: Text(
          AppLocalizations.of(context)!.index2,
          style: optionStyle,
        ),
      ),
      Center(
        child: Text(
          AppLocalizations.of(context)!.index4,
          style: optionStyle,
        ),
      ),
      FutureBuilder<Client>(
        future: _client, // a previously-obtained Future<String> or null
        builder: (BuildContext context, AsyncSnapshot<Client> snapshot) {
          if (snapshot.hasData) {
            if (snapshot.requireData.hasFirstSynced()) {
              return ChatOverview(
                rooms: snapshot.requireData.conversations().toList(),
              );
            } else {
              return Center(
                child: Text(
                  AppLocalizations.of(context)!.loadingConvo,
                  style: optionStyle,
                ),
              );
            }
          } else {
            return Center(
              child: Text(
                AppLocalizations.of(context)!.index3,
                style: optionStyle,
              ),
            );
          }
        },
      ),
    ];

    return DefaultTabController(
      length: 3,
      child: SafeArea(
        child: Scaffold(
          appBar: AppBar(
            primary: false,
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.blue,
            centerTitle: true,
            title: DropdownButton<String>(
              value: dropdownValue,
              onChanged: (String? newValue) {
                setState(() {
                  dropdownValue = newValue!;
                });
              },
              items: <String>[
                'All',
                'Greenpeace',
                '104er',
                'Badminton 1905 e.V.'
              ].map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
          ),
          body: _widgetOptions.elementAt(_tabIndex),
          drawer: Drawer(
            child: Column(
              children: <Widget>[
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: <Widget>[
                      FutureBuilder<Client>(
                        future: _client,
                        // a previously-obtained Future<String> or null
                        builder: (
                          BuildContext context,
                          AsyncSnapshot<Client> snapshot,
                        ) {
                          if (snapshot.hasData) {
                            if (snapshot.requireData.isGuest()) {
                              return DrawerHeader(
                                decoration: const BoxDecoration(
                                  color: Colors.purple,
                                ),
                                child: Column(
                                  children: [
                                    const Text(
                                      'Effektio',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
                                      ),
                                    ),
                                    Text(
                                      AppLocalizations.of(context)!.guest,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                      ),
                                    ),
                                    OutlinedButton(
                                      onPressed: () {
                                        Navigator.pushNamed(
                                          context,
                                          '/login',
                                        );
                                      },
                                      child: Text(
                                        AppLocalizations.of(context)!.login,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            } else {
                              return AccountHeader(snapshot.requireData);
                            }
                          } else {
                            return const DrawerHeader(
                              decoration: BoxDecoration(
                                color: Colors.blue,
                              ),
                              child: Text(
                                'Effektio',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                ),
                              ),
                            );
                          }
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.task_alt_outlined),
                        title: Text(AppLocalizations.of(context)!.tasks),
                      ),
                      ListTile(
                        leading: const Icon(Icons.calendar_today_outlined),
                        title: Text(AppLocalizations.of(context)!.tasks),
                      ),
                      ListTile(
                        leading: const Icon(Icons.photo_library_outlined),
                        title: Text(AppLocalizations.of(context)!.images),
                      ),
                      ListTile(
                        leading: const Icon(Icons.video_collection_outlined),
                        title: Text(AppLocalizations.of(context)!.videos),
                      ),
                      ListTile(
                        leading: const Icon(Icons.folder_outlined),
                        title: Text(AppLocalizations.of(context)!.documents),
                      ),
                      ListTile(
                        leading: const Icon(Icons.real_estate_agent_outlined),
                        title: Text(AppLocalizations.of(context)!.resources),
                      ),
                      ListTile(
                        leading: const Icon(Icons.payments_outlined),
                        title: Text(AppLocalizations.of(context)!.budget),
                      ),
                    ],
                  ),
                ),
                Align(
                  alignment: FractionalOffset.bottomCenter,
                  child: Container(
                    padding: const EdgeInsets.all(15.0),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: const <Widget>[
                            Icon(Icons.settings),
                          ],
                        ),
                        const Divider(),
                        const Text('Effektio 0.0.1'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // bottomNavigationBar: BottomNavigationBar(
          //   type: BottomNavigationBarType.fixed,
          //   currentIndex: _tabIndex,
          //   backgroundColor: const Color(0xFF6200EE),
          //   selectedItemColor: Colors.white,
          //   unselectedItemColor: Colors.white.withOpacity(.6),
          //   selectedFontSize: 0,
          //   unselectedFontSize: 0,
          //   onTap: (value) {
          //     // Respond to item press.
          //     setState(() => _tabIndex = value);
          //   },
          //   items: [
          //     BottomNavigationBarItem(
          //       label: AppLocalizations.of(context)!.news,
          //       icon: const Icon(Icons.dashboard),
          //     ),
          //     BottomNavigationBarItem(
          //       label: AppLocalizations.of(context)!.faq,
          //       icon: const Icon(Icons.help_outline),
          //     ),
          //     BottomNavigationBarItem(
          //       label: AppLocalizations.of(context)!.community,
          //       icon: const Icon(Icons.groups),
          //     ),
          //     BottomNavigationBarItem(
          //       label: AppLocalizations.of(context)!.chat,
          //       icon: const Icon(Icons.chat),
          //     ),
          //   ],
          // ),
          bottomNavigationBar: HomeTabBar(_tabIndex),
        ),
      ),
    );

    // theme: ThemeData(
    //   primaryColor: _primaryColor,
    //   highlightColor: Colors.transparent,
    //   colorScheme: const ColorScheme(
    //     primary: _primaryColor,
    //     primaryContainer: Color(0xFF3700B3),
    //     secondary: Color(0xFF03DAC6),
    //     secondaryContainer: Color(0xFF018786),
    //     background: Colors.white,
    //     surface: Colors.white,
    //     onBackground: Colors.black,
    //     error: Color(0xFFB00020),
    //     onError: Colors.white,
    //     onPrimary: Colors.white,
    //     onSecondary: Colors.black,
    //     onSurface: Colors.black,
    //     brightness: Brightness.light,
    //   ),
    // dividerTheme: const DividerThemeData(
    //   thickness: 1,
    //   color: Color(0xFFE5E5E5),
    // ),
    // platform: GalleryOptions.of(context).platform,
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Center(child: Text(AppLocalizations.of(context)!.helloWorld)),
    );
  }
}

// Define a custom Form widget.
class Login extends StatefulWidget {
  const Login({Key? key}) : super(key: key);

  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final _formKey = GlobalKey<FormState>();
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Center(
        child: Form(
          key: _formKey,
          child: Wrap(
            children: [
              TextFormField(
                controller: usernameController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: '@user:server.ltd',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return AppLocalizations.of(context)!.validator;
                  }
                  if (!value[0].startsWith('@')) {
                    return AppLocalizations.of(context)!.matrixValidate;
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  labelText: AppLocalizations.of(context)!.password,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return AppLocalizations.of(context)!.passwordValidate;
                  }
                  return null;
                },
              ),
              ElevatedButton(
                onPressed: () {
                  // Validate returns true if the form is valid, or false otherwise.
                  if (_formKey.currentState!.validate()) {
                    login(
                      usernameController.text,
                      passwordController.text,
                    ).then((a) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: Colors.greenAccent,
                          content: Text(
                            AppLocalizations.of(context)!.loginSuccess,
                          ),
                        ),
                      );
                      Navigator.pop(context);
                    }).catchError((e) {
                      debugPrint(e);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: Colors.redAccent,
                          content: Text(
                            AppLocalizations.of(context)!.loginFailed + ': $e',
                          ),
                        ),
                      );
                    });
                  }
                },
                child: Text(AppLocalizations.of(context)!.login),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
