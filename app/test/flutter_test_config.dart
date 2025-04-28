import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

const _kGoldenTestsThreshold = 1 / 20; // 5% tolerance

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  if (goldenFileComparator is LocalFileComparator) {
    final testUrl = (goldenFileComparator as LocalFileComparator).basedir;

    goldenFileComparator = LocalFileComparatorWithThreshold(
      Uri.parse('$testUrl/test. dart'),
      _kGoldenTestsThreshold,
    );
  } else {
    throw Exception(
      'Expected goldenFileComparator to be of type'
      'LocalFileComparator'
      'but it is of type ${goldenFileComparator.runtimeType}`',
    );
  }
  await testMain();
}

/// Works just like [LocalFileComparator] but includes a [threshold] that, when
/// exceeded, marks the test as a failure.
class LocalFileComparatorWithThreshold extends LocalFileComparator {
  /// Threshold above which tests will be marked as failing.
  /// Ranges from 0 to 1, both inclusive.
  final double threshold;

  // ignore: use_super_parameters
  LocalFileComparatorWithThreshold(Uri testFile, this.threshold)
    : assert(threshold >= 0 && threshold <= 1),
      super(testFile);

  /// Copy of [LocalFileComparator]'s [compare] method, except for the fact that
  /// it checks if the [ComparisonResult.diffPercent] is not greater than
  /// [threshold] to decide whether this test is successful or a failure.
  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    final result = await GoldenFileComparator.compareLists(
      imageBytes,
      await getGoldenBytes(golden),
    );

    if (!result.passed && result.diffPercent <= threshold) {
      // ignore: avoid_print
      print(
        'A difference of ${result.diffPercent * 100}% was found, but it is '
        'acceptable since it is not greater than the threshold of '
        '${threshold * 100}%',
      );

      return true;
    }

    if (!result.passed) {
      final error = await generateFailureOutput(result, golden, basedir);
      throw FlutterError(error);
    }
    return result.passed;
  }
}
