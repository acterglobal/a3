import 'dart:typed_data';
import 'package:effektio_flutter_sdk/effektio_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:effektio_flutter_sdk/effektio_flutter_sdk.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:effektio_flutter_sdk/effektio_flutter_sdk.dart';
import 'Screens/OnboardingScreens/LogIn.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // SharedPreferences prefs = await SharedPreferences.getInstance();
  // final flowStarted = prefs.getBool(KeyConstants.flowStarted) ?? false;
  // final userLoggedIn = prefs.getBool(KeyConstants.userLoggedIn) ?? false;
  // ignore: prefer_const_constructors
  runApp(MaterialApp(
  //  builder: EasyLoading.init(),
    debugShowCheckedModeBanner: false,
    // ignore: prefer_const_constructors
    home: LoginScreen()
  ));
}

class Effektio extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Effektio',
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
  Client _client;

  AccountHeader(this._client);

  @override
  _AccountHeaderState createState() => _AccountHeaderState(
      _client, _client.displayName(), _client.userId(), _client.avatar().then((fb) => fb.toUint8List()));
}

class _AccountHeaderState extends State<AccountHeader> {
  String dropdownValue = 'All';
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
                return Text(snapshot.data ?? "no name");
              } else {
                return Text("loading...");
              }
            }),
        accountEmail: FutureBuilder<String>(
            future: username, // a previously-obtained Future<String> or null
            builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
              if (snapshot.hasData) {
                return Text(snapshot.data ?? "no addr");
              } else {
                return Text("loading...");
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
          future: room.avatar().then((fb) => fb.toUint8List()), // a previously-obtained Future<String> or null
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
              return Text("loading name");
            }
          }),
    );
  }
}

class ChatOverview extends StatelessWidget {
  final FfiListRoom rooms;

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
        'Index 0: News',
        style: optionStyle,
      )),
      Center(
          child: Text(
        'Index 1: FAQ',
        style: optionStyle,
      )),
      Center(
          child: Text(
        'Index 4: Community',
        style: optionStyle,
      )),
      FutureBuilder<Client>(
          future: _client, // a previously-obtained Future<String> or null
          builder: (BuildContext context, AsyncSnapshot<Client> snapshot) {
            if (snapshot.hasData) {
              if (snapshot.requireData.hasFirstSynced()) {
                return ChatOverview(
                    rooms: snapshot.requireData.conversations());
              } else {
                return Center(
                    child: Text(
                  'loading conversations',
                  style: optionStyle,
                ));
              }
            } else {
              return Center(
                  child: Text(
                'Index 3: Chat: waiting',
                style: optionStyle,
              ));
            }
          }),
    ];

    return DefaultTabController(
        length: 3,
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
                          future: _client,
                          // a previously-obtained Future<String> or null
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
                                          'Guest',
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
                                          child: const Text('Log In'),
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
                        title: Text('Tasks'),
                      ),
                      ListTile(
                        leading: Icon(Icons.calendar_today_outlined),
                        title: Text('Events'),
                      ),
                      ListTile(
                        leading: Icon(Icons.photo_library_outlined),
                        title: Text('Images'),
                      ),
                      ListTile(
                        leading: Icon(Icons.video_collection_outlined),
                        title: Text('Videos'),
                      ),
                      ListTile(
                        leading: Icon(Icons.folder_outlined),
                        title: Text('Documents'),
                      ),
                      ListTile(
                        leading: Icon(Icons.real_estate_agent_outlined),
                        title: Text('Resources'),
                      ),
                      ListTile(
                        leading: Icon(Icons.payments_outlined),
                        title: Text('Budget'),
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
                label: 'News',
                icon: Icon(Icons.dashboard),
              ),
              BottomNavigationBarItem(
                label: 'FAQ',
                icon: Icon(Icons.help_outline),
              ),
              BottomNavigationBarItem(
                label: 'Community',
                icon: Icon(Icons.groups),
              ),
              BottomNavigationBarItem(
                label: 'Chat',
                icon: Icon(Icons.chat),
              ),
            ],
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
    return Material(child: Center(child: Text("Hello World")));
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
                            return 'Please enter some text';
                          }
                          if (!value[0].startsWith("@")) {
                            return "Matrix accounts must start with @";
                          }
                          return null;
                        }),
                    TextFormField(
                        controller: passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Password',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Password can't empty";
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
                              const SnackBar(
                                  backgroundColor: Colors.greenAccent,
                                  content: Text('Login successful')),
                            );
                            Navigator.pop(context);
                          }).catchError((e) {
                            print(e);
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              backgroundColor: Colors.redAccent,
                              content: Text("Login failed: $e"),
                            ));
                          });
                        }
                      },
                      child: const Text('Login'),
                    ),
                  ],
                ))));
  }
}
