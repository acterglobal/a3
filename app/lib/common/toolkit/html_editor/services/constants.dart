const String userMentionChar = '@';
const String roomMentionChar = '#';
final userMentionRegExp = RegExp(
  r'\[([^\]]+)\]\(https://matrix\.to/#/(@[^)]+)\)',
);
final roomMentionRegExp = RegExp(
  r'\[([^\]]+)\]\(https://matrix\.to/#/(!|#[^)]+)\)',
);
final userMentionLinkRegExp = RegExp(
  r'https://matrix.to/#/(?<alias>@.+):(?<server>.+)',
);
