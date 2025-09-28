class GeneratorModel {
  final String id;
  final String name;
  final String description;

  GeneratorModel({
    required this.id,
    required this.name,
    required this.description,
  });

  factory GeneratorModel.fromJson(Map<String, dynamic> json) {
    return GeneratorModel(
      id: json['id'],
      name: json['name'],
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
    };
  }
}
