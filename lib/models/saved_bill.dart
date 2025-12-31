import 'package:flutter/material.dart';
import 'bill_item.dart';
import 'item_participant.dart';
import 'user.dart';

class SavedBill {
  // Método helper para parsear items con participantes desde diferentes formatos
  static List<BillItem> _parseItemsWithParticipants(Map<String, dynamic> json) {
    final itemsJson = json['items'] as List;
    final items = itemsJson.map((itemJson) => BillItem.fromJson(itemJson as Map<String, dynamic>)).toList();
    
    // Si los items ya tienen participantes, retornarlos tal cual
    if (items.any((item) => item.participants.isNotEmpty)) {
      return items;
    }
    
    // Migración desde formato antiguo: participations separado
    if (json.containsKey('participations') && json['participations'] is List) {
      final participations = json['participations'] as List;
      final Map<String, List<String>> itemParticipantsMap = {};
      
      for (var p in participations) {
        final participation = p as Map<String, dynamic>;
        final itemId = participation['itemId'] as String;
        final userId = participation['userId'] as String;
        
        if (!itemParticipantsMap.containsKey(itemId)) {
          itemParticipantsMap[itemId] = [];
        }
        itemParticipantsMap[itemId]!.add(userId);
      }
      
      // Agregar participantes a los items
      for (var item in items) {
        if (itemParticipantsMap.containsKey(item.id)) {
          final userIds = itemParticipantsMap[item.id]!;
          final share = item.price / userIds.length;
          final participants = userIds.map((userId) => ItemParticipant(
            userId: userId,
            share: share,
            shareType: 'equal',
            paid: false,
            paidAmount: 0.0,
          )).toList();
          
          items[items.indexOf(item)] = BillItem(
            id: item.id,
            name: item.name,
            price: item.price,
            quantity: item.quantity,
            participants: participants,
          );
        }
      }
    }
    
    // Migración desde formato itemParticipants (Map)
    if (json.containsKey('itemParticipants') && json['itemParticipants'] is Map) {
      final itemParticipants = json['itemParticipants'] as Map<String, dynamic>;
      
      itemParticipants.forEach((itemId, value) {
        final participants = value as List;
        final item = items.firstWhere((i) => i.id == itemId, orElse: () => items.first);
        final itemIndex = items.indexOf(item);
        
        if (itemIndex != -1) {
          final share = item.price / participants.length;
          final itemParticipantsList = participants.map((p) {
            if (p is String) {
              return ItemParticipant(
                userId: p,
                share: share,
                shareType: 'equal',
                paid: false,
                paidAmount: 0.0,
              );
            } else {
              final userId = (p as Map)['id'] as String;
              return ItemParticipant(
                userId: userId,
                share: share,
                shareType: 'equal',
                paid: false,
                paidAmount: 0.0,
              );
            }
          }).toList();
          
          items[itemIndex] = BillItem(
            id: item.id,
            name: item.name,
            price: item.price,
            quantity: item.quantity,
            participants: itemParticipantsList,
          );
        }
      });
    }
    
    return items;
  }
  final String id;
  final String? patchId; // Link to a Patch (Group)
  final String name;
  final DateTime date;
  final double total;
  final List<BillItem> items;
  // Los participantes ahora están dentro de cada item (items[].participants)
  // Esto es más semántico y permite información rica (share, paid, etc.)
  final List<dynamic> taxes;

  SavedBill({
    required this.id,
    this.patchId,
    required this.name,
    required this.date,
    required this.total,
    required this.items,
    required this.taxes,
  });

  factory SavedBill.fromJson(Map<String, dynamic> json) {
    // Helper para parsear números que pueden venir como string o num
    double _parseDouble(dynamic value) {
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }
    
    // El backend puede enviar parche_id o patchId
    final patchIdValue = json['parche_id'] ?? json['patchId'];
    
    return SavedBill(
      id: json['id'] as String,
      patchId: patchIdValue as String?,
      name: json['name'] as String? ?? '', // El backend puede no enviar name en algunos casos
      date: DateTime.parse(json['date'] as String),
      total: _parseDouble(json['total']),
      // Los participantes están dentro de cada item
      // Soporta formato antiguo con participations separado para migración
      items: _parseItemsWithParticipants(json),
      taxes: json['taxes'] as List<dynamic>? ?? [],
    );
  }

  Map<String, dynamic> toJson({bool includeId = true, bool includeName = true}) {
    final json = <String, dynamic>{};
    
    // El backend espera parche_id en lugar de patchId
    if (patchId != null) {
      json['parche_id'] = patchId;
    }
    
    // Solo incluir name si se solicita (el backend puede no requerirlo en POST inicial)
    if (includeName) {
      json['name'] = name;
    }
    
    json['date'] = date.toIso8601String();
    json['total'] = total;
    json['items'] = items.map((item) => item.toJson()).toList();
    
    // Taxes: el backend espera objetos con name y amount, pero puede devolver id, value, etc.
    // Solo enviamos name y amount si no tienen id (nuevos taxes)
    json['taxes'] = taxes.map((tax) {
      if (tax is Map<String, dynamic>) {
        // Si ya tiene id, enviar completo; si no, solo name y amount
        if (tax.containsKey('id')) {
          return tax;
        } else {
          return {
            'name': tax['name'],
            'amount': tax['amount'],
          };
        }
      }
      return tax;
    }).toList();
    
    // Solo incluir ID si se solicita (para crear nuevos, no enviar ID)
    if (includeId && id.isNotEmpty) {
      json['id'] = id;
    }
    
    return json;
  }
}
