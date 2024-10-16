import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';
import 'package:url_launcher/url_launcher.dart';

final _log = Logger('a3::common::actions::open_link');

Future<bool> openLink(String target, BuildContext context) async {
  final Uri? url = Uri.tryParse(target);
  if (url == null || !url.hasAuthority) {
    _log.info('Opening internally: $url');
    // not a valid URL, try local routing
    await context.push(target);
    return true;
  } else {
    _log.info('Opening external URL: $url');
    return await launchUrl(url);
  }
}
