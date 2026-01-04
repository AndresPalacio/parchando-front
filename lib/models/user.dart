import 'package:flutter/material.dart';

class User {
  final String id;
  final String name;
  final Color color;
  final String? email;
  final String? phone;
  final bool isCurrentUser;

  User({
    required this.id,
    required this.name,
    required this.color,
    this.email,
    this.phone,
    this.isCurrentUser = false,
  });

  String get initials {
    // Limpiar el nombre de espacios al inicio y final
    final cleanName = name.trim();
    
    // Si el nombre está vacío, retornar '?'
    if (cleanName.isEmpty) return '?';
    
    // Dividir por espacios y filtrar strings vacíos
    final parts = cleanName.split(' ').where((part) => part.isNotEmpty).toList();
    
    // Si no hay partes válidas, retornar '?'
    if (parts.isEmpty) return '?';
    
    // Si solo hay una parte, usar el primer carácter
    if (parts.length == 1) {
      return parts[0].isNotEmpty ? parts[0][0].toUpperCase() : '?';
    }
    
    // Si hay múltiples partes, usar el primer carácter de las dos primeras
    final first = parts[0].isNotEmpty ? parts[0][0] : '';
    final second = parts[1].isNotEmpty ? parts[1][0] : '';
    
    if (first.isEmpty && second.isEmpty) return '?';
    if (first.isEmpty) return second.toUpperCase();
    if (second.isEmpty) return first.toUpperCase();
    
    return '${first}${second}'.toUpperCase();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'color': color.value,
      'email': email,
      'phone': phone,
      'isCurrentUser': isCurrentUser,
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    // Manejar formato del backend que puede incluir PK, SK, type, etc.
    // El id puede venir directamente o extraerse del SK (ej: "FRIEND#id")
    String userId = json['id'] ?? '';
    if (userId.isEmpty && json.containsKey('SK')) {
      final sk = json['SK'] as String? ?? '';
      if (sk.startsWith('FRIEND#')) {
        userId = sk.substring(7); // Remover "FRIEND#"
      }
    }
    
    // El color puede venir como int o como string
    int colorValue;
    if (json['color'] is int) {
      colorValue = json['color'] as int;
    } else if (json['color'] is String) {
      colorValue = int.tryParse(json['color'] as String) ?? Colors.blue.value;
    } else if (json['color'] is num) {
      colorValue = (json['color'] as num).toInt();
    } else {
      colorValue = Colors.blue.value;
    }
    
    return User(
      id: userId,
      name: json['name'] as String? ?? '',
      color: Color(colorValue),
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      isCurrentUser: json['isCurrentUser'] as bool? ?? false,
    );
  }
}
