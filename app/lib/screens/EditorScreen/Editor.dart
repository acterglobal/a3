import 'package:effektio/common/store/Colors.dart';
import 'package:effektio/common/widget/TagItem.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:html_editor_enhanced/html_editor.dart';

// void main() => runApp(const HtmlEditorExampleApp());

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

List<String> _tagList = [];
List<Color> _tagColorList = [];

Color? tagColor;

// class HtmlEditorExampleApp extends StatelessWidget {
//   const HtmlEditorExampleApp({Key? key}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Editor',
//       theme: ThemeData.dark(),
//       darkTheme: ThemeData.dark(),
//       home: const HtmlEditorExample(title: 'Create FAQ'),
//     );
//   }
// }

class HtmlEditorExample extends StatefulWidget {
  const HtmlEditorExample({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  _HtmlEditorExampleState createState() => _HtmlEditorExampleState();
}

class _HtmlEditorExampleState extends State<HtmlEditorExample> {
  String result = '';
  OverlayEntry? entry;
  TextEditingController tagTitleController = TextEditingController();

  final HtmlEditorController controller = HtmlEditorController();

  @override
  void initState() {
    super.initState();
    if (_tagList.isNotEmpty) {
      _tagList.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: widget.title,
      theme: ThemeData.dark(),
      darkTheme: ThemeData.dark(),
      home: GestureDetector(
        onTap: () {
          if (!kIsWeb) {
            controller.clearFocus();
          }
        },
        child: Scaffold(
          appBar: AppBar(
            backgroundColor: AppColors.backgroundColor,
            leading: TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Icon(
                Icons.close,
                color: Colors.white,
              ),
            ),
            title: Text(widget.title),
            centerTitle: true,
            elevation: 0,
            actions: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    primary: AppColors.primaryColor,
                    shape: const StadiumBorder(),
                  ),
                  onPressed: () async {
                    var txt = await controller.getText();
                    if (txt.contains('src="data:')) {
                      txt =
                          '<text removed due to base-64 data, displaying the text could cause the app to crash>';
                    }
                    setState(() {
                      result = txt;
                      print(result);
                    });
                  },
                  child: const Text('Save'),
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
                  htmlEditorOptions: const HtmlEditorOptions(
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
                      return true;
                    },
                    onDropdownChanged: (
                      DropdownType type,
                      dynamic changed,
                      Function(dynamic)? updateSelectedItem,
                    ) {
                      return true;
                    },
                    mediaUploadInterceptor:
                        (PlatformFile file, InsertFileType type) async {
                      return true;
                    },
                  ),
                  otherOptions: OtherOptions(
                    height: MediaQuery.of(context).size.height - 115,
                  ),
                  callbacks: Callbacks(
                    onBeforeCommand: (String? currentHtml) {},
                    onChangeContent: (String? changed) {},
                    onChangeCodeview: (String? changed) {},
                    onChangeSelection: (EditorSettings settings) {},
                    onDialogShown: () {},
                    onEnter: () {},
                    onFocus: () {},
                    onBlur: () {},
                    onBlurCodeview: () {},
                    onInit: () {},
                    onImageUploadError: (
                      FileUpload? file,
                      String? base64Str,
                      UploadError error,
                    ) {},
                    onKeyDown: (int? keyCode) {},
                    onKeyUp: (int? keyCode) {},
                    onMouseDown: () {},
                    onMouseUp: () {},
                    onNavigationRequestMobile: (String url) {
                      return NavigationActionPolicy.ALLOW;
                    },
                    onPaste: () {},
                    onScroll: () {},
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
                      onSelect: (String value) {},
                    )
                  ],
                )
              ],
            ),
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
          floatingActionButton: SizedBox(
            height: 120.0,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 65.0, left: 8.0),
              child: Row(
                children: [
                  FloatingActionButton.extended(
                    backgroundColor: Colors.grey[800],
                    onPressed: () {
                      showBottomSheet();
                    },
                    label: const Text(
                      'Tags',
                      style: TextStyle(color: Colors.white),
                    ),
                    icon: const Icon(
                      Icons.add,
                      color: Colors.white,
                    ),
                  ),
                  if (_tagList.isNotEmpty)
                    Expanded(
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _tagList.length,
                        itemBuilder: (context, index) {
                          return TagListItem(
                            tagTitle: _tagList[index],
                            tagColor: _tagColorList[index],
                          );
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
      ),
    );
  }

  void showBottomSheet() {
    Color? primaryColor = Colors.grey;

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(12.0),
              child: Align(
                alignment: Alignment.center,
                child: Text(
                  'Edit Tag',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(10),
              child: Container(
                width: double.infinity,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.textFieldColor,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: TextField(
                  style: TextStyle(color: primaryColor),
                  controller: tagTitleController,
                  cursorColor: Colors.white,
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    hintText: 'Tag Name',
                    hintStyle: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                    ),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(12.0),
              child: Align(
                alignment: Alignment.center,
                child: Text(
                  'Select a color',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
            Expanded(
              child: GridView.count(
                crossAxisCount: 4,
                children: List.generate(8, (index) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8.0, right: 8.0),
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            tagColor = arr[index];
                            print(tagColor?.value.toString());
                          });
                        },
                        child: const Text(''),
                        style: ElevatedButton.styleFrom(primary: arr[index]),
                      ),
                    ),
                  );
                }),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 20.0),
              child: ElevatedButton(
                onPressed: () => {
                  setState(() {
                    if (tagTitleController.text.isNotEmpty) {
                      _tagList.add(tagTitleController.text.toString());
                      _tagColorList
                          .add(tagColor == null ? Colors.white : tagColor!);
                      print(_tagColorList.toString());
                      Navigator.of(context).pop();
                      tagTitleController.clear();
                    } else {
                      Fluttertoast.showToast(
                        msg: 'Please fill the title of Tag',
                        toastLength: Toast.LENGTH_SHORT,
                        gravity: ToastGravity.CENTER,
                        timeInSecForIosWeb: 1,
                        textColor: Colors.white,
                        fontSize: 16.0,
                      );
                    }
                  })
                },
                style: ElevatedButton.styleFrom(
                  primary: AppColors.primaryColor,
                  shape: const StadiumBorder(),
                ),
                child: const Padding(
                  padding: EdgeInsets.only(left: 80.0, right: 80.0),
                  child: Text('Submit'),
                ),
              ),
            )
          ],
        );
      },
    );
  }
}
