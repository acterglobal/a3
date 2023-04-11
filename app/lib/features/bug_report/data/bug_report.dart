import 'package:freezed_annotation/freezed_annotation.dart';

part 'bug_report.freezed.dart';

@freezed
class BugReport with _$BugReport {
  const factory BugReport({
    required String description,
    required List<String> tags,
    @Default(false) bool withLog,
    @Default(false) bool withScreenshot,
  }) = _BugReport;
}
