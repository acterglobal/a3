import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:acter/l10n/l10n.dart';

void showNoInternetNotification(context) {
  EasyLoading.showToast(L10n.of(context).limitedInternConnection);
}
