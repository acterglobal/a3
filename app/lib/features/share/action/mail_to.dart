import 'package:url_launcher/url_launcher.dart';

Future<void> mailTo({required String toAddress, String? subject}) async {
  final emailLaunchUri = Uri(scheme: 'mailto', path: toAddress, query: subject);
  await launchUrl(emailLaunchUri);
}
