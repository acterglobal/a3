import 'package:flutter/material.dart';

enum AttachmentIconType {
  link(icon: Icons.link, color: Colors.blue),
  camera(icon: Icons.camera, color: Colors.deepOrangeAccent),
  image(icon: Icons.image, color: Colors.tealAccent),
  video(icon: Icons.video_library, color: Colors.amberAccent),
  audio(icon: Icons.headphones, color: Colors.cyanAccent),
  file(icon: Icons.file_present, color: Colors.purpleAccent);

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
