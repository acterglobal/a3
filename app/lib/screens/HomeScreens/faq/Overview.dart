import 'package:effektio/common/store/themes/SeperatedThemes.dart';
import 'package:effektio/controllers/FaqController.dart';
// import 'package:effektio/screens/HomeScreens/faq/Editor.dart';
import 'package:effektio/widgets/FaqListItem.dart';
import 'package:effektio_flutter_sdk/effektio_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class FaqOverviewScreen extends StatefulWidget {
  final Client client;
  const FaqOverviewScreen({Key? key, required this.client}) : super(key: key);

  @override
  State<FaqOverviewScreen> createState() => _FaqOverviewScreenState();
}

class _FaqOverviewScreenState extends State<FaqOverviewScreen> {
  final faqController = Get.put(FaqController());

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<FfiListFaq>(
      future: widget.client.faqs(),
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
                        top: 5,
                        bottom: 6,
                        left: 10,
                        right: 10,
                      ),
                      child: TextField(
                        onChanged: (value) {
                          faqController.searchedData(value, snapshot);
                        },
                        controller: faqController.searchController,
                        style: ToDoTheme.taskTitleTextStyle.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                        cursorColor: ToDoTheme.primaryTextColor,
                        decoration: InputDecoration(
                          hintStyle: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                          ),
                          suffixIcon: const Icon(
                            Icons.search,
                            color: Colors.white,
                          ),
                          contentPadding: const EdgeInsets.only(
                            left: 12,
                            bottom: 2,
                            top: 2,
                          ),
                          border: OutlineInputBorder(
                            borderSide: const BorderSide(color: Colors.white),
                            borderRadius: BorderRadius.circular(20.0),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: Colors.white),
                            borderRadius: BorderRadius.circular(30.0),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: Colors.white),
                            borderRadius: BorderRadius.circular(30.0),
                          ),
                        ),
                      ),
                    ),
                    GetBuilder<FaqController>(
                      builder: (FaqController controller) {
                        return Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.all(8),
                            shrinkWrap: true,
                            itemCount: controller.searchData.isEmpty
                                ? snapshot.requireData.length
                                : controller.searchData.length,
                            itemBuilder: (BuildContext context, int index) {
                              return FaqListItem(
                                client: widget.client,
                                faq: controller.searchData.isEmpty
                                    ? snapshot.requireData[index]
                                    : controller.searchData[index],
                              );
                            },
                          ),
                        );
                      },
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
