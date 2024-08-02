class SectionConfig {
  /// How many to show of the initial list
  final int listingLimit;

  /// Whether or not show the "show all" button
  final bool isShowSeeAllButton;

  /// whether or not to render remote entires
  final bool renderRemote;

  /// how many remote entries to render
  final int remoteCount;

  SectionConfig({
    this.isShowSeeAllButton = false,
    this.listingLimit = 0,
    this.renderRemote = false,
    this.remoteCount = 0,
  });
}

/// Calculate the configuration for a specific space overview section
/// for chat or space
SectionConfig calculateSectionConfig({
  required int localListLen,
  required int limit,
  required int remoteListLen,
}) {
  int listingLimit = 0;
  bool isShowSeeAllButton = false;
  bool renderRemote = false;
  int remoteCount = 0;
  // our local list is already going beyond the limits
  if (localListLen > limit) {
    listingLimit = limit;
    isShowSeeAllButton = true;
  } else if (localListLen == limit) {
    // locally fills the list
    listingLimit = limit;
    isShowSeeAllButton = remoteListLen > 0;
  } else {
    // the local list is not filling the list
    listingLimit = localListLen;
    remoteCount = limit - localListLen;
    if (remoteCount > 0) {
      if (remoteListLen > 0) {
        renderRemote = true;
        if (remoteListLen < remoteCount) {
          remoteCount = remoteListLen;
        }
        if (remoteListLen > remoteCount) {
          isShowSeeAllButton = true;
        }
      }
    }
  }
  return SectionConfig(
    listingLimit: listingLimit,
    renderRemote: renderRemote,
    remoteCount: remoteCount,
    isShowSeeAllButton: isShowSeeAllButton,
  );
}
