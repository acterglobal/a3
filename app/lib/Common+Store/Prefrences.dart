import 'package:effektio/Common+Store/KeyConstants.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPrefrence {
  Future<bool> setLoggedIn(bool status) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setBool(KeyConstants.userLoggedIn, status);
  }

  Future<bool> getLogedIn() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(KeyConstants.userLoggedIn) ?? false;
  }

  Future<bool> setFlow(bool status) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setBool(KeyConstants.flowStarted, status);
  }

  Future<bool?> getFlow() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(KeyConstants.flowStarted);
  }

  Future<bool> setToken(String token) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setString(KeyConstants.token, token);
  }

  Future<bool> setEmail(String email) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setString(KeyConstants.email, email);
  }

  Future<bool> setPassword(String password) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setString(KeyConstants.password, password);
  }

  Future<String> getToken() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(KeyConstants.token) ?? '';
  }

  Future<bool> setEmailVerified(bool status) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setBool(KeyConstants.emailVerified, status);
  }

  Future<bool> getEmailVerified() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(KeyConstants.emailVerified) ?? false;
  }

  Future<bool> setProfilePhoto(String photo) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setString(KeyConstants.profilePic, photo);
  }

  Future<bool> setSubscription(String subs) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setString(KeyConstants.subscriptions, subs);
  }

  Future<bool> setUserId(String userId) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setString(KeyConstants.userId, userId);
  }

  Future<Future<bool>> removeValue(String key) async {
    SharedPreferences myPrefs = await SharedPreferences.getInstance();
    return myPrefs.remove(key);
  }

  Future<Future<bool>> removeAll() async {
    SharedPreferences myPrefs = await SharedPreferences.getInstance();
    return myPrefs.clear();
  }
}
