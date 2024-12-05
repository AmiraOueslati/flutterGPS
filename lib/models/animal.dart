class Animal {
  final String id;
  final String name;
  final String age;
  final String color;
  final String type;  // Type de l'animal
  final String species;  // Espèce de l'animal

  Animal({
    required this.id,
    required this.name,
    required this.age,
    required this.color,
    required this.type,
    required this.species,  // Champ espèce ajouté
  });

  // Convertir l'animal en format JSON pour l'envoyer à l'API
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'age': age,
      'color': color,
      'type': type,
      'species': species,  // Inclure l'espèce
    };
  }
}
