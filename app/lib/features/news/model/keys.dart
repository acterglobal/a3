import 'package:flutter/material.dart';

class NewsUpdateKeys {
  // News Slide Post Button
  static const addNewsUpdate = Key('add-news-updates');
  static const addNewsSlide = Key('add-news-slide');

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
}
