import 'dart:io';
import 'package:image_picker/image_picker.dart';

class CameraService {
  static final ImagePicker _picker = ImagePicker();
  
  static Future<File?> takePicture() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.front,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 70,
    );
    
    if (image != null) {
      return File(image.path);
    }
    return null;
  }
}