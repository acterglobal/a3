import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:acter/l10n/generated/l10n.dart';

void showNoInternetNotification(L10n lang) {
  EasyLoading.showToast(lang.limitedInternConnection);
}
