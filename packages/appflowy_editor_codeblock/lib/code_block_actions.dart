/// Used to control which actions are available in the
/// Code Block editor, along with the callbacks for each.
///
class CodeBlockActions {
  const CodeBlockActions({this.onCopy, this.onLanguageChanged});

  /// Callback for when the user taps on the "Copy" action.
  ///
  /// If null, the "Copy" action will not be available.
  ///
  final void Function(String)? onCopy;

  /// Callback for when the language has changed.
  ///
  /// This is an informative callback, and the node will be
  /// modified by the editor to reflect the new language.
  ///
  final void Function(String language)? onLanguageChanged;
}
