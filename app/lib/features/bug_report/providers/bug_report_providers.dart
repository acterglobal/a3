import 'package:acter/config/env.g.dart';
import 'package:riverpod/riverpod.dart';

// Loading Providers
final bugReporterLoadingProvider = StateProvider<bool>((ref) => false);

const isBugReportingEnabled = Env.rageshakeUrl != '';
