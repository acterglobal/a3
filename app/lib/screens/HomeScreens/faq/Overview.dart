import 'package:effektio/common/store/themes/SeperatedThemes.dart';
// import 'package:effektio/screens/HomeScreens/faq/Editor.dart';
import 'package:effektio/widgets/FaqListItem.dart';
import 'package:effektio_flutter_sdk/effektio_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';

class FaqOverviewScreen extends StatelessWidget {
  final Client client;

  const FaqOverviewScreen({Key? key, required this.client}) : super(key: key);

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
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Padding(
                        padding: EdgeInsets.only(left: 12),
                        child: Text('Pins', style: PinsTheme.titleTextStyle),
                      ),
                      ListView.builder(
                        padding: const EdgeInsets.all(8),
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: snapshot.requireData.length,
                        itemBuilder: (BuildContext context, int index) {
                          return FaqListItem(
                            client: client,
                            faq: snapshot.requireData[index],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }
      },
    );
  }
}
