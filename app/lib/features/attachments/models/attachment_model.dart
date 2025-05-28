import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';

enum AttachmentIconType {
  link(icon: Atlas.link, color: Colors.blue),
  camera(icon: Atlas.camera, color: Colors.deepOrangeAccent),
  image(icon: Atlas.file_image, color: Colors.tealAccent),
  video(icon: Atlas.file_video, color: Colors.amberAccent),
  audio(icon: Atlas.audio_headphones, color: Colors.cyanAccent),
  file(icon: Atlas.file, color: Colors.purpleAccent);

  final IconData icon;
  final Color color;

  const AttachmentIconType({required this.icon, required this.color});
}

class AttachmentIcon {
  final IconData icon;
  final Color color;

  const AttachmentIcon({required this.icon, required this.color});
}

final Map<AttachmentIconType, AttachmentIcon> attachmentIcons = {
  for (var type in AttachmentIconType.values)
    type: AttachmentIcon(icon: type.icon, color: type.color),
};
