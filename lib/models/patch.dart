class Patch {
  final String id;
  final String name;
  final String? icon;
  final List<String> memberIds;
  final DateTime createdAt;

  Patch({
    required this.id,
    required this.name,
    this.icon,
    required this.memberIds,
    required this.createdAt,
  });

  factory Patch.fromJson(Map<String, dynamic> json) {
    // El backend devuelve 'date' en lugar de 'createdAt'
    final dateValue = json['date'] ?? json['createdAt'];
    return Patch(
      id: json['id'] as String,
      name: json['name'] as String,
      icon: json['icon'] as String?,
      memberIds: (json['memberIds'] as List).cast<String>(),
      createdAt: DateTime.parse(dateValue as String),
    );
  }

  Map<String, dynamic> toJson({bool includeId = true}) {
    final json = <String, dynamic>{
      'name': name,
      'icon': icon,
      'memberIds': memberIds,
      'createdAt': createdAt.toIso8601String(),
    };
    
    // Solo incluir ID si se solicita (para crear nuevos, no enviar ID)
    if (includeId) {
      json['id'] = id;
    }
    
    return json;
  }
}
