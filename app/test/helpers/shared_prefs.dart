import 'package:acter_flutter_sdk/acter_flutter_sdk.dart';
import 'package:shared_preferences/shared_preferences.dart';

void mockSharedPrefs(Map<String, Object> value) async {
  try {
    SharedPreferences.setPrefix('dev.flutter');
  } catch (e) {
    // ignore
  }
  SharedPreferences.setMockInitialValues(value);
  await resetSharedPrefs();
}
