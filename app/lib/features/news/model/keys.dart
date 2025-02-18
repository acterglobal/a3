import 'package:flutter/foundation.dart';

class NewsUpdateKeys {
  // News Slide Post Button
  static const addNewsUpdate = Key('add-news-updates');
  static const addUpdateSlide = Key('add-news-slide');

  // News - Text Slide
  static const addTextSlide = Key('news-add-text-slide');
  static const textSlideInputField = Key('news-text-field');
  static const slideBackgroundColor = Key('news-slide-background-color');
  static const textUpdateContent = Key('news-text-update-content');

  // News - Image Slide
  static const addImageSlide = Key('news-add-image-slide');
  static const imageUpdateContent = Key('news-image-update-content');
  static const imageCaption = Key('news-imageCaption');

  // News - Video Slide
  static const addVideoSlide = Key('news-add-video-slide');
  static const videoNewsContent = Key('news-video-content');

  // News - Select Space
  static const selectSpace = Key('news-select-space');

  // Cancel Button
  static const cancelButton = Key('news-cancel-attachments');

  // Submit News Button
  static const newsSubmitBtn = Key('news-submit-btn');

  // News Side Bar Actions
  static const newsSidebarActionBottomSheet =
      Key('news-sidebar-action-bottom-sheet');
  static const newsSidebarActionRemoveBtn =
      Key('news-sidebar-action-remove-btn');
  static const newsSidebarActionReportBtn =
      Key('news-sidebar-action-report-btn');

  // Remove Button
  static const removeButton = Key('news-remove-btn');

  static const closeEditor = Key('news-editor-close');
  static const confirmDeleteDraft = Key('news-confirm-delete-draft');
  static const cancelClose = Key('news-cancel-close');
}
