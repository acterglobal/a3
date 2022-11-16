import 'package:effektio/common/store/themes/SeperatedThemes.dart';
// import 'package:effektio/screens/HomeScreens/faq/Editor.dart';
import 'package:effektio/widgets/FaqListItem.dart';
import 'package:effektio_flutter_sdk/effektio_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';

class FaqOverviewScreen extends StatefulWidget {
  final Client client;
  const FaqOverviewScreen({Key? key, required this.client}) : super(key: key);

  @override
  State<FaqOverviewScreen> createState() =>
      _FaqOverviewScreenState(this.client);
}

class _FaqOverviewScreenState extends State<FaqOverviewScreen> {
  final TextEditingController SearchController = TextEditingController();
  final Client client;
  _FaqOverviewScreenState(this.client);
  List<Faq> searchdata = [];
  bool searchvalue = false;
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<FfiListFaq>(
      future: client.faqs(),
      builder: (BuildContext context, AsyncSnapshot<FfiListFaq> snapshot) {
        if (!snapshot.hasData) {
          return Container(
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width,
            color: AppCommonTheme.backgroundColor,
            child: const Center(
              child: SizedBox(
                height: 50,
                width: 50,
                child: CircularProgressIndicator(
                  color: AppCommonTheme.primaryColor,
                ),
              ),
            ),
          );
        } else {
          return Scaffold(
            body: Container(
              decoration: PinsTheme.pinsDecoration,
              child: Padding(
                padding: const EdgeInsets.only(top: 25),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Padding(
                      padding: EdgeInsets.only(left: 12),
                      child: Text('Pins', style: PinsTheme.titleTextStyle),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(
                          top: 5, bottom: 6, left: 10, right: 10),
                      child: TextField(
                        onChanged: (value) {
                          setState(() {
                            searchdata.clear();
                            for (var element in snapshot.requireData) {
                              for (var tagElement in element.tags()) {
                                if (tagElement.title() ==
                                    (value.toLowerCase().trim())) {
                                  searchdata.add(element);
                                }
                              }
                            }
                          });
                        },
                        controller: SearchController,
                        style: ToDoTheme.taskTitleTextStyle.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                        cursorColor: ToDoTheme.primaryTextColor,
                        decoration: InputDecoration(
                            hintStyle: const TextStyle(
                                color: Colors.white, fontSize: 13),
                            suffixIcon: const Icon(
                              Icons.search,
                              color: Colors.white,
                            ),
                            contentPadding: const EdgeInsets.only(
                                left: 12, bottom: 2, top: 2),
                            border: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.white),
                              borderRadius: BorderRadius.circular(20.0),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: const BorderSide(color: Colors.white),
                              borderRadius: BorderRadius.circular(30.0),
                            ),
                            enabledBorder: OutlineInputBorder(
                                borderSide:
                                    const BorderSide(color: Colors.white),
                                borderRadius: BorderRadius.circular(30.0))),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(8),
                        shrinkWrap: true,
                        itemCount: searchdata.isEmpty
                            ? snapshot.requireData.length
                            : searchdata.length,
                        itemBuilder: (BuildContext context, int index) {
                          return FaqListItem(
                              client: client,
                              faq: searchdata.isEmpty
                                  ? snapshot.requireData[index]
                                  : searchdata[index]);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
      },
    );
  }
}
