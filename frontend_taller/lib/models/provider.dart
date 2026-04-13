class ProviderModel {
  final int id;
  final String name;
  final String code;

  ProviderModel({
    required this.id,
    required this.name,
    required this.code,
  });

  factory ProviderModel.fromJson(Map<String, dynamic> json) {
    return ProviderModel(
      id: json['id'],
      name: json['name'],
      code: json['code'],
    );
  }
}