import 'package:effektio/common/themes/seperated_themes.dart';
import 'package:effektio/common/widgets/search_widget.dart';
import 'package:effektio/features/faq/controllers/faq_controller.dart';
import 'package:effektio/features/faq/widgets/faq_list_item.dart';
import 'package:effektio_flutter_sdk/effektio_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class FaqPage extends StatefulWidget {
  final Client client;

  const FaqPage({Key? key, required this.client}) : super(key: key);

  @override
  State<FaqPage> createState() => _FaqPageState();
}

class _FaqPageState extends State<FaqPage> {
  final faqController = Get.put(FaqController());

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<FfiListFaq>(
      future: widget.client.faqs(),
      builder: (BuildContext context, AsyncSnapshot<FfiListFaq> snapshot) {
        return (!snapshot.hasData)
            ? Container(
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
              )
            : Scaffold(
                body: Padding(
                  padding: const EdgeInsets.only(top: 25),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Padding(
                        padding: EdgeInsets.only(left: 12),
                        child: Text(
                          'Pins',
                          style: PinsTheme.titleTextStyle,
                        ),
                      ),
                      SearchWidget(
                        searchController: faqController.searchController,
                        onChanged: (text) {
                          faqController.searchedData(
                            text.toString(),
                            snapshot,
                          );
                        },
                        onReset: () {
                          faqController.searchData.clear();
                          setState(() {});
                        },
                      ),
                      GetBuilder<FaqController>(
                        builder: (FaqController controller) {
                          return Expanded(
                            child: ListView.builder(
                              padding: const EdgeInsets.all(8),
                              shrinkWrap: true,
                              itemCount:
                                  controller.searchController.text.isEmpty
                                      ? snapshot.requireData.length
                                      : controller.searchData.length,
                              itemBuilder: (
                                BuildContext context,
                                int index,
                              ) {
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
              );
      },
    );
  }
}
