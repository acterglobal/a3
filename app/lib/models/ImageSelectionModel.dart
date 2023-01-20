import 'package:file_picker/file_picker.dart';

class ImageSelectionModel {
  ImageSelectionModel({
    required this.imageList, required this.roomName,
  });

  List<PlatformFile> imageList;
  String roomName;

}