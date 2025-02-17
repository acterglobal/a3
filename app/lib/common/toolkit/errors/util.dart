typedef ErrorTextBuilder = String Function(Object error, ErrorCode code);

enum ErrorCode {
  notFound,
  forbidden,
  unknown,
  other;

  static ErrorCode guessFromError(Object error) {
    final errorStr = error.toString();
    // yay, string-based error guessing!
    if (errorStr.contains('not found')) {
      return ErrorCode.notFound;
    } else if (errorStr.contains('[400 / UNKNOWN]')) {
      return ErrorCode.unknown;
    } else if (errorStr.contains('[403 / M_FORBIDDEN]')) {
      return ErrorCode.forbidden;
    }
    return ErrorCode.other;
  }
}

enum NewsLoadingState{
  showErrorImageOnly,
  showErrorImageWithText,
  showErrorWithTryAgain,
}