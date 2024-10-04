enum ErrorCode {
  notFound,
  other;

  static ErrorCode guessFromError(Object error) {
    final errorStr = error.toString();
    // yay, string-based error guessing!
    if (errorStr.contains('not found')) {
      return ErrorCode.notFound;
    }
    return ErrorCode.other;
  }
}
