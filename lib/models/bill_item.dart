import 'item_participant.dart';

class BillItem {
  final String id;
  final String name;
  final double price;
  final int quantity;
  final List<ItemParticipant> participants;

  BillItem({
    required this.id,
    required this.name,
    required this.price,
    this.quantity = 1,
    this.participants = const [],
  });

  factory BillItem.fromJson(Map<String, dynamic> json) {
    // Helper para parsear números que pueden venir como string o num
    double _parseDouble(dynamic value) {
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }
    
    int _parseInt(dynamic value) {
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value) ?? 1;
      return 1;
    }
    
    return BillItem(
      id: json['id'] as String? ?? json['name'] as String, // Fallback para compatibilidad
      name: json['name'] as String,
      price: _parseDouble(json['price']),
      quantity: _parseInt(json['quantity']),
      participants: json['participants'] != null
          ? (json['participants'] as List)
              .map((p) => ItemParticipant.fromJson(p as Map<String, dynamic>))
              .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'quantity': quantity,
      'participants': participants.map((p) => p.toJson()).toList(),
    };
  }
}
