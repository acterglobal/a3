import 'package:effektio/common/widget/TagItem.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:html_editor_enhanced/html_editor.dart';

void main() => runApp(HtmlEditorExampleApp());

var arr = [
  Colors.grey,
  Colors.purple[300],
  Colors.pink[100],
  Colors.teal[400],
  Colors.purple[700],
  Colors.orange,
  Colors.blue[300],
  Colors.green,
  Colors.yellow[100],
  Colors.yellow,
  Colors.pink,
  Colors.red
];

List<Widget> _tagList = [];

class HtmlEditorExampleApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Editor',
      theme: ThemeData(),
      darkTheme: ThemeData.dark(),
      home: HtmlEditorExample(title: 'Create FAQ'),
    );
  }
}

class HtmlEditorExample extends StatefulWidget {
  HtmlEditorExample({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  _HtmlEditorExampleState createState() => _HtmlEditorExampleState();
}

class _HtmlEditorExampleState extends State<HtmlEditorExample> {
  String result = '';
  OverlayEntry? entry;

  final HtmlEditorController controller = HtmlEditorController();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (!kIsWeb) {
          controller.clearFocus();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: TextButton(
            onPressed: () {},
            child: Text(
              'X',
              style: TextStyle(color: Colors.white),
            ),
          ),
          title: Text(widget.title),
          centerTitle: true,
          elevation: 0,
          actions: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton(
                onPressed: () {
                  showBottomSheet();
                },
                child: Text('Save'),
              ),
            )
          ],
        ),
        body: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              HtmlEditor(
                controller: controller,
                htmlEditorOptions: HtmlEditorOptions(
                  hint: 'Write about the FAQ',
                  shouldEnsureVisible: true,
                ),
                htmlToolbarOptions: HtmlToolbarOptions(
                  toolbarPosition: ToolbarPosition.belowEditor,
                  toolbarType: ToolbarType.nativeScrollable,
                  onButtonPressed: (
                    ButtonType type,
                    bool? status,
                    Function()? updateStatus,
                  ) {
                    print(
                      "button '${describeEnum(type)}'pressed, current status is $status",
                    );
                    return true;
                  },
                  onDropdownChanged: (
                    DropdownType type,
                    dynamic changed,
                    Function(dynamic)? updateSelectedItem,
                  ) {
                    print(
                      "dropdown '${describeEnum(type)}' changed to $changed",
                    );
                    return true;
                  },
                  mediaUploadInterceptor:
                      (PlatformFile file, InsertFileType type) async {
                    print(file.name);
                    print(file.size);
                    print(file.extension);
                    return true;
                  },
                ),
                otherOptions: OtherOptions(
                  height: MediaQuery.of(context).size.height - 115,
                ),
                callbacks: Callbacks(
                  onBeforeCommand: (String? currentHtml) {
                    print('html before change is $currentHtml');
                  },
                  onChangeContent: (String? changed) {
                    print('content changed to $changed');
                  },
                  onChangeCodeview: (String? changed) {
                    print('change changed to $changed');
                  },
                  onChangeSelection: (EditorSettings settings) {
                    print('Parent element is ${settings.parentElement}');
                    print('font name is ${settings.fontName}');
                  },
                  onDialogShown: () {
                    print('Dialog shown');
                  },
                  onEnter: () {
                    print('Enter pressed');
                  },
                  onFocus: () {
                    print('Editor focused');
                  },
                  onBlur: () {
                    print('Edtior unfocused');
                  },
                  onBlurCodeview: () {
                    print('code review either focused or unfocused');
                  },
                  onInit: () {
                    print('Init');
                  },
                  onImageUploadError:
                      (FileUpload? file, String? base64Str, UploadError error) {
                    print(describeEnum(error));
                    print(base64Str ?? '');
                    if (file != null) {
                      print(file.name);
                      print(file.size);
                      print(file.type);
                    }
                  },
                  onKeyDown: (int? keyCode) {
                    print('$keyCode key downed');
                    print(
                        'current character count: ${controller.characterCount}');
                  },
                  onKeyUp: (int? keyCode) {
                    print('$keyCode key released');
                  },
                  onMouseDown: () {
                    print('mouse downed');
                  },
                  onMouseUp: () {
                    print('Mouse Released');
                  },
                  onNavigationRequestMobile: (String url) {
                    print(url);
                    return NavigationActionPolicy.ALLOW;
                  },
                  onPaste: () {
                    print('Pasted into editor');
                  },
                  onScroll: () {
                    print('Editor Scrolled');
                  },
                ),
                plugins: [
                  SummernoteAtMention(
                    getSuggestionsMobile: (String value) {
                      var mentions = <String>['test1', 'test2', 'test3'];
                      return mentions
                          .where((element) => element.contains(value))
                          .toList();
                    },
                    mentionsWeb: ['test1', 'test2', 'test3'],
                    onSelect: (String value) {
                      print(value);
                    },
                  )
                ],
              )
            ],
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
        floatingActionButton: Container(
          height: 100.0,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 65.0, left: 8.0),
            child: Row(
              children: [
                FloatingActionButton.extended(
                  backgroundColor: Colors.grey[800],
                  onPressed: showBottomSheet,
                  label: Text(
                    'Tags',
                    style: TextStyle(color: Colors.white),
                  ),
                  icon: Icon(
                    Icons.add,
                    color: Colors.white,
                  ),
                ),
                if (_tagList.isNotEmpty)
                  Flexible(
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _tagList.length,
                      itemBuilder: (context, index) {
                        return _tagList[index];
                      },
                    ),
                  )
                else
                  Container()
              ],
            ),
          ),
        ),
      ),
    );
  }

  void showBottomSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Align(
                  alignment: Alignment.center,
                  child: Text(
                    'Edit Tag',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.all(10),
                child: Container(
                  width: double.infinity,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Color(0xFF242632),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: TextField(
                    cursorColor: Color.fromARGB(255, 255, 255, 255),
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      hintText: 'Sample',
                      hintStyle: TextStyle(
                        color:
                            Color.fromARGB(255, 255, 255, 255).withOpacity(0.5),
                      ),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Align(
                  alignment: Alignment.center,
                  child: Text(
                    'Select a color',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
              Container(
                child: Expanded(
                  child: GridView.count(
                    crossAxisCount: 4,
                    children: List.generate(8, (index) {
                      return Center(
                        child: Padding(
                          padding: EdgeInsets.only(left: 8.0, right: 8.0),
                          child: Container(
                            height: 80,
                            decoration: BoxDecoration(
                              color: arr[index],
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 20.0),
                child: Container(
                  child: ElevatedButton(
                    onPressed: () => {
                      setState(() {
                        _tagList.add(TagListItem(tagTitle: 'tagTitle'));
                        Navigator.of(context).pop();
                      })
                    },
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all(Colors.pink),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.only(left: 80.0, right: 80.0),
                      child: Text('Submit'),
                    ),
                  ),
                ),
              )
            ],
          ),
        );
      },
    );
  }
}
