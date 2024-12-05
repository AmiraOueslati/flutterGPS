import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class AnimalImagePicker extends StatelessWidget {
  final Function(File?) onImagePicked;

  const AnimalImagePicker({required this.onImagePicked, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        IconButton(
          icon: const Icon(Icons.camera_alt, size: 40, color: Colors.teal),
          onPressed: () async {
            final picker = ImagePicker();
            final pickedFile = await picker.pickImage(source: ImageSource.gallery);
            if (pickedFile != null) {
              onImagePicked(File(pickedFile.path));
            }
          },
        ),
        const SizedBox(height: 10),
        const Text("Pick an image for the animal", style: TextStyle(color: Colors.teal)),
      ],
    );
  }
}
