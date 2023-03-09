import 'package:acter/common/themes/seperated_themes.dart';
import 'package:acter/common/widgets/search_widget.dart';
import 'package:acter/features/pin/controllers/pin_controller.dart';
import 'package:acter/features/pin/widgets/pin_list_item.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PinPage extends StatefulWidget {
  final Client client;

  const PinPage({Key? key, required this.client}) : super(key: key);

  @override
  State<PinPage> createState() => _PinPageState();
}

class _PinPageState extends State<PinPage> {
  final pinController = Get.put(PinController());

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<FfiListActerPin>(
      future: widget.client.pins(),
      builder: (BuildContext context, AsyncSnapshot<FfiListActerPin> snapshot) {
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
                        searchController: pinController.searchController,
                        onChanged: (text) {
                          pinController.searchedData(
                            text.toString(),
                            snapshot,
                          );
                        },
                        onReset: () {
                          pinController.searchData.clear();
                          setState(() {});
                        },
                      ),
                      GetBuilder<PinController>(
                        builder: (PinController controller) {
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
                                return PinListItem(
                                  client: widget.client,
                                  pin: controller.searchData.isEmpty
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
