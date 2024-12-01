import 'dart:io';

// Classe pour représenter un animal
class Animal {
  final String name;
  final String age;
  final String color;
  final String type;
  final File? image;

  Animal({
    required this.name,
    required this.age,
    required this.color,
    required this.type,
    this.image,
  });
}
