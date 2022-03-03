import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:effektio_flutter_sdk/effektio_flutter_sdk.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'l10n/l10n.dart';

void main() async {
  runApp(Effektio());
}

class Effektio extends StatelessWidget {
  const Effektio({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Effektio',
      localizationsDelegates: [
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
        '/login': (BuildContext context) => const Login(),
      },
    );
  }
}

Future<Client> makeClient() async {
  final sdk = await EffektioSdk.instance;
  Client client = await sdk.currentClient;
  return client;
}

Future<Client> login(String username, String password) async {
  final sdk = await EffektioSdk.instance;
  Client client = await sdk.login(username, password);
  return client;
}

class AccountHeader extends StatefulWidget {
  final Client _client;
  AccountHeader(this._client);

  @override
  _AccountHeaderState createState() => _AccountHeaderState(
      _client,
      _client.displayName(),
      _client.userId(),
      _client.avatar().then((fb) => fb.toUint8List()));
}

class _AccountHeaderState extends State<AccountHeader> {
  // String dropdownValue = AppLocalizations.of(context).all;
  int _currentIndex = 0;
  final Client _client;
  final Future<String> name;
  final Future<String> username;
  final Future<List<int>> avatar;

  _AccountHeaderState(this._client, this.name, this.username, this.avatar);

  @override
  Widget build(BuildContext context) {
    return UserAccountsDrawerHeader(
        accountName: FutureBuilder<String>(
            future: name, // a previously-obtained Future<String> or null
            builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
              if (snapshot.hasData) {
                return Text(
                    snapshot.data ?? AppLocalizations.of(context)!.noName);
              } else {
                return Text(AppLocalizations.of(context)!.loading + "...");
              }
            }),
        accountEmail: FutureBuilder<String>(
            future: username, // a previously-obtained Future<String> or null
            builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
              if (snapshot.hasData) {
                return Text(
                    snapshot.data ?? AppLocalizations.of(context)!.noAddr);
              } else {
                return Text(AppLocalizations.of(context)!.loading + "...");
              }
            }),
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
                    child: const Text('G'));
              }
            }));
  }
}

class ChatListItem extends StatelessWidget {
  final Room room;
  const ChatListItem({Key? key, required this.room}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // ToDo: UnreadCounter
    return ListTile(
      leading: FutureBuilder<List<int>>(
          future: room.avatar().then((fb) =>
              fb.toUint8List()), // a previously-obtained Future<String> or null
          builder: (BuildContext context, AsyncSnapshot<List<int>> snapshot) {
            if (snapshot.hasData) {
              return CircleAvatar(
                  backgroundImage:
                      MemoryImage(Uint8List.fromList(snapshot.requireData)));
            } else {
              return CircleAvatar(
                  backgroundColor: Colors.brown.shade800,
                  child: const Text('H'));
            }
          }),
      title: FutureBuilder<String>(
          future: room.displayName(),
          builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
            if (snapshot.hasData) {
              return Text(snapshot.requireData);
            } else {
              return Text(AppLocalizations.of(context)!.loadingName);
            }
          }),
    );
  }
}

class ChatOverview extends StatelessWidget {
  final Future<List<Room>> rooms;
  const ChatOverview({Key? key, required this.rooms}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Room>>(
        future: rooms, // a previously-obtained Future<String> or null
        builder: (BuildContext context, AsyncSnapshot<List<Room>> snapshot) {
          if (snapshot.hasData) {
            if (snapshot.requireData.isEmpty)
              return Center(
                  child: Text(AppLocalizations.of(context)!.noMessages));
            return ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: snapshot.requireData.length,
                itemBuilder: (BuildContext context, int index) {
                  return ChatListItem(room: snapshot.requireData[index]);
                });
          } else {
            return Center(child: Text(AppLocalizations.of(context)!.loading));
          }
        });
  }
}

class EffektioHome extends StatefulWidget {
  @override
  _EffektioHomeState createState() => _EffektioHomeState(makeClient());
}

class _EffektioHomeState extends State<EffektioHome> {
  String dropdownValue = 'All';
  int _currentIndex = 0;
  final Future<Client> _client;
  _EffektioHomeState(this._client);
  static const TextStyle optionStyle =
      TextStyle(fontSize: 30, fontWeight: FontWeight.bold);

  @override
  Widget build(BuildContext context) {
    List<Widget> _widgetOptions = <Widget>[
      Center(
          child: Text(
        AppLocalizations.of(context)!.index1,
        style: optionStyle,
      )),
      Center(
          child: Text(
        AppLocalizations.of(context)!.index2,
        style: optionStyle,
      )),
      Center(
          child: Text(
        AppLocalizations.of(context)!.index4,
        style: optionStyle,
      )),
      FutureBuilder<Client>(
          future: _client, // a previously-obtained Future<String> or null
          builder: (BuildContext context, AsyncSnapshot<Client> snapshot) {
            if (snapshot.hasData) {
              if (snapshot.requireData.hasFirstSynced()) {
                return ChatOverview(
                    rooms: snapshot.requireData.conversations().toList());
              } else {
                return Center(
                    child: Text(
                  AppLocalizations.of(context)!.loadingConvo,
                  style: optionStyle,
                ));
              }
            } else {
              return Center(
                  child: Text(
                AppLocalizations.of(context)!.index3,
                style: optionStyle,
              ));
            }
          }),
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
                elevation: 0.0,
                shadowColor: Colors.transparent,
                actions: [
                  Icon(Icons.login_outlined),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Icon(Icons.settings),
                  ),
                ]),
            body: _widgetOptions.elementAt(_currentIndex),
            drawer: Drawer(
              child: Column(
                children: <Widget>[
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.zero,
                      children: <Widget>[
                        FutureBuilder<Client>(
                            future:
                                _client, // a previously-obtained Future<String> or null
                            builder: (BuildContext context,
                                AsyncSnapshot<Client> snapshot) {
                              if (snapshot.hasData) {
                                if (snapshot.requireData.isGuest()) {
                                  return DrawerHeader(
                                      decoration: BoxDecoration(
                                        color: Colors.purple,
                                      ),
                                      child: Column(
                                        children: [
                                          Text(
                                            'Effektio',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 24,
                                            ),
                                          ),
                                          Text(
                                            AppLocalizations.of(context)!.guest,
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 18,
                                            ),
                                          ),
                                          OutlinedButton(
                                            onPressed: () {
                                              Navigator.pushNamed(
                                                  context, "/login");
                                            },
                                            child: Text(
                                                AppLocalizations.of(context)!
                                                    .login),
                                          )
                                        ],
                                      ));
                                } else {
                                  return AccountHeader(snapshot.requireData);
                                }
                              } else {
                                return DrawerHeader(
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
                            }),
                        ListTile(
                          leading: Icon(Icons.task_alt_outlined),
                          title: Text(AppLocalizations.of(context)!.tasks),
                        ),
                        ListTile(
                          leading: Icon(Icons.calendar_today_outlined),
                          title: Text(AppLocalizations.of(context)!.tasks),
                        ),
                        ListTile(
                          leading: Icon(Icons.photo_library_outlined),
                          title: Text(AppLocalizations.of(context)!.images),
                        ),
                        ListTile(
                          leading: Icon(Icons.video_collection_outlined),
                          title: Text(AppLocalizations.of(context)!.videos),
                        ),
                        ListTile(
                          leading: Icon(Icons.folder_outlined),
                          title: Text(AppLocalizations.of(context)!.documents),
                        ),
                        ListTile(
                          leading: Icon(Icons.real_estate_agent_outlined),
                          title: Text(AppLocalizations.of(context)!.resources),
                        ),
                        ListTile(
                          leading: Icon(Icons.payments_outlined),
                          title: Text(AppLocalizations.of(context)!.budget),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    child: Align(
                      alignment: FractionalOffset.bottomCenter,
                      child: Container(
                          padding: EdgeInsets.all(15.0),
                          child: Container(
                              child: Column(children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: <Widget>[
                                Icon(Icons.settings),
                              ],
                            ),
                            Divider(),
                            Text("Effektio 0.0.1"),
                          ]))),
                    ),
                  ),
                ],
              ),
            ),
            bottomNavigationBar: BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              currentIndex: _currentIndex,
              backgroundColor: Color(0xFF6200EE),
              selectedItemColor: Colors.white,
              unselectedItemColor: Colors.white.withOpacity(.6),
              selectedFontSize: 0,
              unselectedFontSize: 0,
              onTap: (value) {
                // Respond to item press.
                setState(() => _currentIndex = value);
              },
              items: [
                BottomNavigationBarItem(
                  label: AppLocalizations.of(context)!.news,
                  icon: Icon(Icons.dashboard),
                ),
                BottomNavigationBarItem(
                  label: AppLocalizations.of(context)!.faq,
                  icon: Icon(Icons.help_outline),
                ),
                BottomNavigationBarItem(
                  label: AppLocalizations.of(context)!.community,
                  icon: Icon(Icons.groups),
                ),
                BottomNavigationBarItem(
                  label: AppLocalizations.of(context)!.chat,
                  icon: Icon(Icons.chat),
                ),
              ],
            ),
          ),
        ));

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
        child: Center(child: Text(AppLocalizations.of(context)!.helloWorld)));
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
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: '@user:server.ltd',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return AppLocalizations.of(context)!.validator;
                          }
                          if (!value[0].startsWith("@")) {
                            return AppLocalizations.of(context)!.matrixValidate;
                          }
                          return null;
                        }),
                    TextFormField(
                        controller: passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: AppLocalizations.of(context)!.password,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return AppLocalizations.of(context)!
                                .passwordValidate;
                          }
                          return null;
                        }),
                    ElevatedButton(
                      onPressed: () {
                        // Validate returns true if the form is valid, or false otherwise.
                        if (_formKey.currentState!.validate()) {
                          login(usernameController.text,
                                  passwordController.text)
                              .then((a) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  backgroundColor: Colors.greenAccent,
                                  content: Text(AppLocalizations.of(context)!
                                      .loginSuccess)),
                            );
                            Navigator.pop(context);
                          }).catchError((e) {
                            print(e);
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              backgroundColor: Colors.redAccent,
                              content: Text(
                                  AppLocalizations.of(context)!.loginFailed +
                                      ": $e"),
                            ));
                          });
                        }
                      },
                      child: Text(AppLocalizations.of(context)!.login),
                    ),
                  ],
                ))));
  }
}
