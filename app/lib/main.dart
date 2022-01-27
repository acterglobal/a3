import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:effektio_flutter_sdk/effektio_flutter_sdk.dart';

void main() async {
  runApp(Effektio());
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

class EffektioSidebar extends StatefulWidget {
  Client _client;
  EffektioSidebar(this._client);

  @override
  _EffektioSidebarState createState() => _EffektioSidebarState(
      _client, _client.displayName(), _client.userId(), _client.avatar());
}

class _EffektioSidebarState extends State<EffektioSidebar> {
  String dropdownValue = 'All';
  int _currentIndex = 0;
  final Client _client;
  final Future<String> name;
  final Future<String> username;
  final Future<List<int>> avatar;

  _EffektioSidebarState(this._client, this.name, this.username, this.avatar);

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
                    child: const Text('AH'));
              }
            }));
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

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
            items: <String>['All', 'Greenpeace', '104er', 'Badminton 1905 e.V.']
                .map<DropdownMenuItem<String>>((String value) {
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
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text('Hello and welcome to home'),
            ElevatedButton(
                child: Text("Let's log in"),
                onPressed: () {
                  Navigator.pushNamed(context, '/login');
                })
          ],
        ),
      ),
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
                          return EffektioSidebar(snapshot.requireData);
                        } else {
                          return Text("loading...");
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
    return Material(child: Center(child: Text("Hello World")));
  }
}

class Login extends StatelessWidget {
  const Login({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
        child: Center(
            child: Form(
                child: Wrap(
      children: [
        TextFormField(
            decoration: InputDecoration(
          border: OutlineInputBorder(),
          labelText: '@user:server.ltd',
        )),
        TextFormField(
            obscureText: true,
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Password',
            )),
      ],
    ))));
  }
}
