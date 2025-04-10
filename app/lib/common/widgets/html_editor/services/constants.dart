const String userMentionChar = '@';
const String roomMentionChar = '#';
const userMentionMarker = '‖';
final userMentionRegExp = RegExp(
  r'\[@([^\]]+)\]\(https:\/\/matrix\.to\/#\/(@[^)]+)\)',
);
final userMentionLinkRegExp = RegExp(
  r'https://matrix.to/#/(?<alias>@.+):(?<server>.+)',
);
